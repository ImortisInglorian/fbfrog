'' Main module, command line interface

#include once "fbfrog.bi"
#include once "file.bi"

dim shared verbose as integer

private sub hPrintHelp( byref message as string )
	if( len( message ) > 0 ) then
		print message
	end if
	print "fbfrog 0.1 from " + __DATE_ISO__ + ", usage: fbfrog [options] *.h"
	print "options:"
	print "  -m           Merge multiple headers into one"
	print "  -v           Show debugging info"
	print "By default, fbfrog will generate a *.bi file for each given *.h file."
	print "*.bi files need to be reviewed and tested! Watch out for calling conventions!"
	end (iif( len( message ) > 0, 1, 0 ))
end sub

type FROGSTUFF
	files		as TLIST '' FROGFILE
	filehash	as THASH
	commonparent	as string
end type

dim shared frog as FROGSTUFF

private function frogDownload( byref url as string, byref file as string ) as integer
	if( fileexists( "tarballs/" & file ) ) then
		function = TRUE
	else
		function = hShell( "mkdir -p tarballs" ) andalso _
			hShell( "wget " + url + " -O tarballs/" + file )
	end if
end function

private function frogExtract( byref tarball as string, byref dirname as string ) as integer
	if( strEndsWith( tarball, ".zip" ) ) then
		function = hShell( "unzip -q -d " + dirname + " tarballs/" + tarball )
	elseif( strEndsWith( tarball, ".tar.gz" ) or _
	        strEndsWith( tarball, ".tar.bz2" ) or _
	        strEndsWith( tarball, ".tar.xz" ) ) then
		function = hShell( "tar xf tarballs/" + tarball + " -C " + dirname )
	else
		function = FALSE
	end if
end function

private function hFindCommonParent( ) as string
	dim as string s
	dim as FROGFILE ptr f = listGetHead( @frog.files )
	while( f )
		if( f->missing = FALSE ) then
			if( len( s ) > 0 ) then
				s = pathFindCommonBase( s, f->normed )
			else
				s = pathOnly( f->normed )
			end if
		end if
		f = listGetNext( f )
	wend
	function = s
end function

private function frogAddFile _
	( _
		byval context as FROGFILE ptr, _
		byref pretty as string _
	) as FROGFILE ptr

	dim as string normed, report

	if( context ) then
		'' Search for #included files in one of the parent directories
		'' of the current file. Usually the #include will refer to a
		'' file in the same directory or in a sub-directory at the same
		'' level or some levels up.

		var parent = pathOnly( context->normed )
		do
			'' File not found anywhere, ignore it.
			if( len( parent ) = 0 ) then
				normed = ""
				exit do
			end if

			normed = parent + pretty
			if( hFileExists( normed ) ) then
				if( verbose ) then
					if( len( report ) ) then print report
					report = "    found: " + normed
				end if
				exit do
			end if

			if( verbose ) then
				if( len( report ) ) then print report
				report = "    not found: " + normed
			end if

			'' Stop searching parent directories after trying
			'' the common base
			if( parent = frog.commonparent ) then
				normed = ""
				exit do
			end if

			parent = pathStripLastComponent( parent )
		loop
	else
		normed = pathMakeAbsolute( pretty )
		if( verbose ) then
			report = "    root: " + pretty
		end if
	end if

	var missing = FALSE
	if( len( normed ) > 0 ) then
		normed = pathNormalize( normed )
	else
		'' File missing/not found; still add it to the hash
		normed = pretty
		missing = TRUE
	end if

	var hash = hashHash( normed )
	var item = hashLookup( @frog.filehash, normed, hash )
	if( item->s ) then
		'' Already exists
		if( verbose ) then
			print report + " (old news)"
		end if
		return item->data
	end if

	if( verbose ) then
		if( missing ) then
			print report + " (missing)"
		else
			print report + " (new)"
		end if
	end if

	'' Add file
	dim as FROGFILE ptr f = listAppend( @frog.files )
	f->pretty = pretty
	f->normed = normed
	f->missing = missing

	'' Add to hash table
	hashAdd( @frog.filehash, item, hash, f->normed, f )

	'' Update/recalculate common base path
	frog.commonparent = hFindCommonParent( )

	function = f
end function

private sub hRemoveNode _
	( _
		byval n as ASTNODE ptr, _
		byval astclass as integer, _
		byref id as string _
	)

	if( (n->class = astclass) and (*n->text = id) ) then
		n->class = ASTCLASS_NOP
		exit sub
	end if

	var child = n->head
	while( child )
		hRemoveNode( child, astclass, id )
		child = child->next
	wend

end sub

private sub hMakeProcsDefaultToCdecl( byval n as ASTNODE ptr )
	if( n->class = ASTCLASS_PROC ) then
		'' No calling convention specified yet?
		if( (n->attrib and (ASTATTRIB_CDECL or ASTATTRIB_STDCALL)) = 0 ) then
			n->attrib or= ASTATTRIB_CDECL
		end if
	end if

	'' Don't forget the procptr subtypes
	if( typeGetDt( n->dtype ) = TYPE_PROC ) then
		hMakeProcsDefaultToCdecl( n->subtype )
	end if

	var child = n->head
	while( child )
		hMakeProcsDefaultToCdecl( child )
		child = child->next
	wend
end sub

private function hCountCallConv _
	( _
		byval n as ASTNODE ptr, _
		byval callconv as integer _
	) as integer

	var count = 0

	if( n->class = ASTCLASS_PROC ) then
		if( n->attrib and callconv ) then
			count += 1
		end if
	end if

	'' Don't forget the procptr subtypes
	if( typeGetDt( n->dtype ) = TYPE_PROC ) then
		count += hCountCallConv( n->subtype, callconv )
	end if

	var child = n->head
	while( child )
		count += hCountCallConv( child, callconv )
		child = child->next
	wend

	function = count
end function

private sub hHideCallConv( byval n as ASTNODE ptr, byval callconv as integer )
	if( n->class = ASTCLASS_PROC ) then
		if( n->attrib and callconv ) then
			n->attrib or= ASTATTRIB_HIDECALLCONV
		end if
	end if

	'' Don't forget the procptr subtypes
	if( typeGetDt( n->dtype ) = TYPE_PROC ) then
		hHideCallConv( n->subtype, callconv )
	end if

	var child = n->head
	while( child )
		hHideCallConv( child, callconv )
		child = child->next
	wend
end sub

private function hFindMainCallConv( byval ast as ASTNODE ptr ) as integer
	var   cdeclcount = hCountCallConv( ast, ASTATTRIB_CDECL   )
	var stdcallcount = hCountCallConv( ast, ASTATTRIB_STDCALL )
	if( (cdeclcount = 0) and (stdcallcount = 0) ) then
		function = -1
	elseif( stdcallcount > cdeclcount ) then
		function = ASTATTRIB_STDCALL
	else
		function = ASTATTRIB_CDECL
	end if
end function

private sub hTurnCallConvIntoExternBlock _
	( _
		byval ast as ASTNODE ptr, _
		byval externcallconv as integer, _
		byval use_stdcallms as integer _
	)

	var externblock = @"C"
	if( externcallconv = ASTATTRIB_STDCALL ) then
		if( use_stdcallms ) then
			externblock = @"Windows-MS"
		else
			externblock = @"Windows"
		end if
	end if

	'' Remove the calling convention from all procdecls, the Extern block
	'' will take over
	hHideCallConv( ast, externcallconv )

	assert( ast->class = ASTCLASS_GROUP )
	astPrepend( ast, astNew( ASTCLASS_DIVIDER ) )
	astPrepend( ast, astNew( ASTCLASS_EXTERNBLOCKBEGIN, externblock ) )
	astAppend( ast, astNew( ASTCLASS_DIVIDER ) )
	astAppend( ast, astNew( ASTCLASS_EXTERNBLOCKEND ) )

end sub

private sub hRemoveParamNames( byval n as ASTNODE ptr )
	if( n->class = ASTCLASS_PARAM ) then
		astRemoveText( n )
	end if

	'' Don't forget the procptr subtypes
	if( typeGetDt( n->dtype ) = TYPE_PROC ) then
		hRemoveParamNames( n->subtype )
	end if

	var child = n->head
	while( child )
		hRemoveParamNames( child )
		child = child->next
	wend
end sub

private sub hFixArrayParams( byval n as ASTNODE ptr )
	if( n->class = ASTCLASS_PARAM ) then
		'' C array parameters are really just pointers (i.e. the array
		'' is passed byref), and FB doesn't support array parameters
		'' like that, so turn them into pointers:
		''    int a[5]  ->  byval a as long ptr
		if( n->array ) then
			astDelete( n->array )
			n->array = NULL
			n->dtype = typeAddrOf( n->dtype )
		end if
	end if

	var child = n->head
	while( child )
		hFixArrayParams( child )
		child = child->next
	wend
end sub

'' Removes typedefs where the typedef identifier is the same as the struct tag,
'' e.g. "typedef struct T T;" since FB doesn't have separate struct/type
'' namespaces and such typedefs aren't needed.
private sub hRemoveRedundantTypedefs( byval n as ASTNODE ptr )
	var child = n->head
	while( child )
		hRemoveRedundantTypedefs( child )
		child = child->next
	wend

	if( (n->class = ASTCLASS_TYPEDEF) and _
	    (typeGetDtAndPtr( n->dtype ) = TYPE_UDT) ) then
		assert( n->subtype->class = ASTCLASS_ID )
		if( ucase( *n->text, 1 ) = ucase( *n->subtype->text ) ) then
			n->class = ASTCLASS_NOP
		end if
	end if
end sub

private sub hMergeDIVIDERs( byval n as ASTNODE ptr )
	var child = n->head
	while( child )
		var nxt = child->next

		if( nxt ) then
			if( (child->class = ASTCLASS_DIVIDER) and _
			    (  nxt->class = ASTCLASS_DIVIDER) ) then
				astRemoveChild( n, child )
			end if
		end if

		child = nxt
	wend
end sub

type DECLNODE
	decl as ASTNODE ptr     '' The declaration at that index
	version as ASTNODE ptr  '' Parent VERSION node of the declaration
end type

type DECLTABLE
	array	as DECLNODE ptr
	count	as integer
	room	as integer
end type

private sub hAddDecl _
	( _
		byval c as ASTNODE ptr, _
		byval array as DECLNODE ptr, _
		byval i as integer _
	)

	astAddVersionedChild( c, _
		astNewVERSION( array[i].version, NULL, astClone( array[i].decl ) ) )

end sub

'' See also hTurnCallConvIntoExternBlock():
''
'' Procdecls with callconv covered by the Extern block are given the
'' ASTATTRIB_HIDECALLCONV flag.
''
'' If we're merging two procdecls here, and they both have
'' ASTATTRIB_HIDECALLCONV, then they can be emitted without explicit
'' callconv, as the Extern blocks will take care of that and remap
'' the callconv as needed. In this case, the merged node shouldn't have
'' any callconv flag at all, but only ASTATTRIB_HIDECALLCONV.
'' hAstLCS() calls astIsEqualDecl() with the proper flags to allow this.
''
'' If merging two procdecls and only one side has
'' ASTATTRIB_HIDECALLCONV, then they must have the same callconv,
'' otherwise hAstLCS()'s astIsEqualDecl() call wouldn't have treated
'' them as equal. In this case the callconv must be preserved on
'' the merged node, so it will be emitted explicitly, since the Extern
'' blocks don't cover it. ASTATTRIB_HIDECALLCONV shouldn't be preserved
'' in this case.
''
'' The same applies to procptr subtypes, though to handle it for those,
'' we need a recursive function.

private sub hFindCommonCallConvsOnMergedDecl _
	( _
		byval mdecl as ASTNODE ptr, _
		byval adecl as ASTNODE ptr, _
		byval bdecl as ASTNODE ptr _
	)

	assert( mdecl->class = adecl->class )
	assert( adecl->class = bdecl->class )

	if( mdecl->class = ASTCLASS_PROC ) then
		if( ((adecl->attrib and ASTATTRIB_HIDECALLCONV) <> 0) and _
		    ((bdecl->attrib and ASTATTRIB_HIDECALLCONV) <> 0) ) then
			mdecl->attrib and= not (ASTATTRIB_CDECL or ASTATTRIB_STDCALL)
			assert( mdecl->attrib and ASTATTRIB_HIDECALLCONV ) '' was preserved by astClone() already
		elseif( ((adecl->attrib and ASTATTRIB_HIDECALLCONV) <> 0) or _
			((bdecl->attrib and ASTATTRIB_HIDECALLCONV) <> 0) ) then
			assert( (adecl->attrib and (ASTATTRIB_CDECL or ASTATTRIB_STDCALL)) = _
				(bdecl->attrib and (ASTATTRIB_CDECL or ASTATTRIB_STDCALL)) )
			mdecl->attrib and= not ASTATTRIB_HIDECALLCONV
			assert( (mdecl->attrib and (ASTATTRIB_CDECL or ASTATTRIB_STDCALL)) <> 0 ) '' ditto
		end if
	end if

	'' Don't forget the procptr subtypes
	if( typeGetDt( mdecl->dtype ) = TYPE_PROC ) then
		assert( typeGetDt( adecl->dtype ) = TYPE_PROC )
		assert( typeGetDt( bdecl->dtype ) = TYPE_PROC )
		hFindCommonCallConvsOnMergedDecl( mdecl->subtype, adecl->subtype, bdecl->subtype )
	end if

	var mchild = mdecl->head
	var achild = adecl->head
	var bchild = bdecl->head
	while( mchild )
		assert( achild )
		assert( bchild )

		hFindCommonCallConvsOnMergedDecl( mchild, achild, bchild )

		mchild = mchild->next
		achild = achild->next
		bchild = bchild->next
	wend
	assert( mchild = NULL )
	assert( achild = NULL )
	assert( bchild = NULL )
end sub

private sub hAddMergedDecl _
	( _
		byval c as ASTNODE ptr, _
		byval aarray as DECLNODE ptr, _
		byval ai as integer, _
		byval barray as DECLNODE ptr, _
		byval bi as integer _
	)

	var adecl = aarray[ai].decl
	var bdecl = barray[bi].decl
	var mdecl = astClone( adecl )

	hFindCommonCallConvsOnMergedDecl( mdecl, adecl, bdecl )

	astAddVersionedChild( c, _
		astNewVERSION( aarray[ai].version, barray[bi].version, mdecl ) )

end sub

'' Determine longest common substring, by building an l x r matrix:
''
'' if l[i] = r[j] then
''     if( i-1 or j-1 would be out-of-bounds ) then
''         matrix[i][j] = 1
''     else
''         matrix[i][j] = matrix[i-1][j-1] + 1
''     end if
'' else
''     matrix[i][j] = 0
'' end if
''
'' 0 = characters not equal
'' 1 = characters equal
'' 2 = characters equal here, and also at one position to top/left
'' ...
'' i.e. the non-zero diagonal parts in the matrix determine the common
'' substrings.
''
'' Some examples:
''
''             Longest common substring:
''   b a a c           b a a c
'' a 0 1 1 0         a   1
'' a 0 1 2 0         a     2
'' b 1 0 0 0         b
'' c 0 0 0 1         c
''
''   c a a b           c a a b
'' a 0 1 1 0         a   1
'' a 0 1 2 0         a     2
'' b 1 0 0 3         b       3
'' c 1 0 0 0         c
''
''   b a b c           b a b c
'' c 0 1 0 1         c
'' a 0 1 0 0         a   1
'' b 1 0 2 0         b     2
'' c 0 0 0 3         c       3
''
private sub hAstLCS _
	( _
		byval larray as DECLNODE ptr, _
		byval lfirst as integer, _
		byval llast as integer, _
		byref llcsfirst as integer, _
		byref llcslast as integer, _
		byval rarray as DECLNODE ptr, _
		byval rfirst as integer, _
		byval rlast as integer, _
		byref rlcsfirst as integer, _
		byref rlcslast as integer _
	)

	var llen = llast - lfirst + 1
	var rlen = rlast - rfirst + 1
	var max = 0, maxi = 0, maxj = 0

	dim as integer ptr matrix = callocate( sizeof( integer ) * llen * rlen )

	for i as integer = 0 to llen-1
		for j as integer = 0 to rlen-1
			var newval = 0
			if( astIsEqualDecl( larray[lfirst+i].decl, _
			                    rarray[rfirst+j].decl, _
			                    TRUE, TRUE ) ) then
				if( (i = 0) or (j = 0) ) then
					newval = 1
				else
					newval = matrix[(i-1)+((j-1)*llen)] + 1
				end if
			end if
			if( max < newval ) then
				max = newval
				maxi = i
				maxj = j
			end if
			matrix[i+(j*llen)] = newval
		next
	next

	deallocate( matrix )

	llcsfirst = lfirst + maxi - max + 1
	rlcsfirst = rfirst + maxj - max + 1
	llcslast  = llcsfirst + max - 1
	rlcslast  = rlcsfirst + max - 1
end sub

declare function hMergeVersions _
	( _
		byval a as ASTNODE ptr, _
		byval b as ASTNODE ptr _
	) as ASTNODE ptr

private function hMergeStructsManually _
	( _
		byval astruct as ASTNODE ptr, _
		byval aversion as ASTNODE ptr, _
		byval bstruct as ASTNODE ptr, _
		byval bversion as ASTNODE ptr _
	) as ASTNODE ptr

	''
	'' For example:
	''
	''     version 1                   version 2
	''         struct FOO                  struct FOO
	''             field a as integer          field a as integer
	''             field b as integer          field c as integer
	''
	'' should become:
	''
	''     version 1, 2
	''         struct FOO
	''             field a as integer
	''             version 1
	''                 field b as integer
	''             version 2
	''                 field c as integer
	''
	'' instead of:
	''
	''     version 1
	''         struct FOO
	''             field a as integer
	''             field b as integer
	''     version 2
	''         struct FOO
	''             field a as integer
	''             field c as integer
	''

	'' Copy astruct's fields into temp VERSION for a's version(s)
	var afields = astNew( ASTCLASS_GROUP )
	astCloneAndAddAllChildrenOf( afields, astruct )
	afields = astNewVERSION( aversion, NULL, afields )

	'' Copy bstruct's fields into temp VERSION for b's version(s)
	var bfields = astNew( ASTCLASS_GROUP )
	astCloneAndAddAllChildrenOf( bfields, bstruct )
	bfields = astNewVERSION( bversion, NULL, bfields )

	'' Merge both set of fields
	var fields = hMergeVersions( hMergeVersions( NULL, afields ), bfields )

	'' Solve out any VERSIONs (but preserving their children) that have the
	'' same version numbers that the struct itself is going to have.
	var cleanfields = astSolveVersionsOut( fields, _
			astNewVERSION( aversion, bversion, NULL ) )

	'' Create a result struct with the new set of fields
	var cstruct = astCloneNode( astruct )
	astAppend( cstruct, cleanfields )

	function = cstruct
end function

private sub hAstMerge _
	( _
		byval c as ASTNODE ptr, _
		byval aarray as DECLNODE ptr, _
		byval afirst as integer, _
		byval alast as integer, _
		byval barray as DECLNODE ptr, _
		byval bfirst as integer, _
		byval blast as integer _
	)

	static reclevel as integer
	#if 0
		#define DEBUG( x ) print string( reclevel + 1, " " ) & x
	#else
		#define DEBUG( x )
	#endif

	DEBUG( "hAstMerge( reclevel=" & reclevel & ", a=" & afirst & ".." & alast & ", b=" & bfirst & ".." & blast & " )" )

	'' No longest common substring possible?
	if( afirst > alast ) then
		'' Add bfirst..blast to result
		DEBUG( "no LCS possible due to a, adding b as-is" )
		for i as integer = bfirst to blast
			hAddDecl( c, barray, i )
		next
		exit sub
	elseif( bfirst > blast ) then
		'' Add afirst..alast to result
		DEBUG( "no LCS possible due to b, adding a as-is" )
		for i as integer = afirst to alast
			hAddDecl( c, aarray, i )
		next
		exit sub
	end if

	'' Find longest common substring
	DEBUG( "searching LCS..." )
	dim as integer alcsfirst, alcslast, blcsfirst, blcslast
	hAstLCS( aarray, afirst, alast, alcsfirst, alcslast, _
	         barray, bfirst, blast, blcsfirst, blcslast )
	DEBUG( "LCS: a=" & alcsfirst & ".." & alcslast & ", b=" & blcsfirst & ".." & blcslast )

	'' No LCS found?
	if( alcsfirst > alcslast ) then
		'' Add a first, then b. This order makes the most sense: keeping
		'' the old declarations at the top, add new ones to the bottom.
		DEBUG( "no LCS found, adding both as-is" )
		for i as integer = afirst to alast
			hAddDecl( c, aarray, i )
		next
		for i as integer = bfirst to blast
			hAddDecl( c, barray, i )
		next
		exit sub
	end if

	'' Do both sides have decls before the LCS?
	if( (alcsfirst > afirst) and (blcsfirst > bfirst) ) then
		'' Do LCS on that recursively
		DEBUG( "both sides have decls before LCS, recursing" )
		reclevel += 1
		hAstMerge( c, aarray, afirst, alcsfirst - 1, _
		              barray, bfirst, blcsfirst - 1 )
		reclevel -= 1
	elseif( alcsfirst > afirst ) then
		'' Only a has decls before the LCS; copy them into result first
		DEBUG( "only a has decls before LCS" )
		for i as integer = afirst to alcsfirst - 1
			hAddDecl( c, aarray, i )
		next
	elseif( blcsfirst > bfirst ) then
		'' Only b has decls before the LCS; copy them into result first
		DEBUG( "only b has decls before LCS" )
		for i as integer = bfirst to blcsfirst - 1
			hAddDecl( c, barray, i )
		next
	end if

	'' Add LCS
	DEBUG( "adding LCS" )
	assert( (alcslast - alcsfirst + 1) = (blcslast - blcsfirst + 1) )
	for i as integer = 0 to (alcslast - alcsfirst + 1)-1
		'' The LCS may include structs but with different fields on both
		'' sides, they must be merged manually so the struct itself can
		'' be common, but the fields may be version dependant.
		'' (relying on hAstLCS() to allow structs to match even if they
		'' have different fields)
		var astruct = aarray[alcsfirst+i].decl
		if( astruct->class = ASTCLASS_STRUCT ) then
			var aversion = aarray[alcsfirst+i].version
			var bstruct  = barray[blcsfirst+i].decl
			var bversion = barray[blcsfirst+i].version
			assert( bstruct->class = ASTCLASS_STRUCT )

			var cstruct = hMergeStructsManually( astruct, aversion, bstruct, bversion )

			'' Add struct to result tree, under both a's and b's version numbers
			astAddVersionedChild( c, astNewVERSION( aversion, bversion, cstruct ) )

			continue for
		end if

		hAddMergedDecl( c, aarray, alcsfirst + i, barray, blcsfirst + i )
	next

	'' Do both sides have decls behind the LCS?
	if( (alcslast < alast) and (blcslast < blast) ) then
		'' Do LCS on that recursively
		DEBUG( "both sides have decls behind LCS, recursing" )
		reclevel += 1
		hAstMerge( c, aarray, alcslast + 1, alast, barray, blcslast + 1, blast )
		reclevel -= 1
	elseif( alcslast < alast ) then
		'' Only a has decls behind the LCS
		DEBUG( "only a has decls behind LCS" )
		for i as integer = alcslast + 1 to alast
			hAddDecl( c, aarray, i )
		next
	elseif( blcslast < blast ) then
		'' Only b has decls behind the LCS
		DEBUG( "only b has decls behind LCS" )
		for i as integer = blcslast + 1 to blast
			hAddDecl( c, barray, i )
		next
	end if

end sub

private sub decltableAdd _
	( _
		byval table as DECLTABLE ptr, _
		byval decl as ASTNODE ptr, _
		byval version as ASTNODE ptr _
	)

	if( table->count = table->room ) then
		table->room += 256
		table->array = reallocate( table->array, table->room * sizeof( DECLNODE ) )
	end if

	with( table->array[table->count] )
		.decl = decl
		.version = version
	end with

	table->count += 1

end sub

private sub decltableInit( byval table as DECLTABLE ptr, byval n as ASTNODE ptr )
	table->array = NULL
	table->count = 0
	table->room = 0

	'' Add each declaration node from the AST to the table
	if( n = NULL ) then
		exit sub
	end if

	var version = n
	if( version->class = ASTCLASS_GROUP ) then
		version = version->head
		if( version = NULL ) then
			exit sub
		end if
	end if

	'' For each VERSION...
	do
		assert( version->class = ASTCLASS_VERSION )

		'' For each declaration in that VERSION...
		var decl = version->head
		while( decl )
			decltableAdd( table, decl, version )
			decl = decl->next
		wend

		version = version->next
	loop while( version )
end sub

private sub decltableEnd( byval table as DECLTABLE ptr )
	deallocate( table->array )
end sub

private function hMergeVersions _
	( _
		byval a as ASTNODE ptr, _
		byval b as ASTNODE ptr _
	) as ASTNODE ptr

	'' a = existing GROUP( ) holding one or more VERSIONs( )
	'' b = new VERSION( ) that should be integrated into a
	'' c = resulting GROUP( ) holding one or more VERSIONs( )

	if( b = NULL ) then
		return astClone( a )
	end if

	var c = astNew( ASTCLASS_GROUP )

	if( a = NULL ) then
		astAppend( c, astClone( b ) )
		return c
	end if

	#if 0
		print "a:"
		astDump( a, 1 )
		print "b:"
		astDump( b, 1 )
	#endif

	assert( a->class = ASTCLASS_GROUP )
	assert( a->head->class = ASTCLASS_VERSION )
	assert( b->class = ASTCLASS_VERSION )

	'' Create a lookup table for each side, so we can find the declarations
	'' at certain indices in O(1) instead of having to cycle through the
	'' whole list of preceding nodes everytime. Especially by the LCS
	'' algorithm needs to find declaratinos by index a lot, this makes that
	'' much faster.
	dim atable as DECLTABLE
	dim btable as DECLTABLE

	decltableInit( @atable, a )
	decltableInit( @btable, b )

	hAstMerge( c, atable.array, 0, atable.count - 1, _
	              btable.array, 0, btable.count - 1 )

	decltableEnd( @btable )
	decltableEnd( @atable )

	#if 0
		print "c:"
		astDump( c, 1 )
	#endif

	function = c
end function

private sub hAutoExtern _
	( _
		byval ast as ASTNODE ptr, _
		byval use_stdcallms as integer = FALSE _
	)

	hMakeProcsDefaultToCdecl( ast )

	var maincallconv = hFindMainCallConv( ast )
	if( maincallconv >= 0 ) then
		hTurnCallConvIntoExternBlock( ast, maincallconv, use_stdcallms )
	end if

end sub

private function frogParseVersion _
	( _
		byval pre as FROGPRESET ptr, _
		byval f as FROGFILE ptr, _
		byval version as ASTNODE ptr _
	) as ASTNODE ptr

	if( verbose ) then
		if( version ) then
			print "version " + *version->text
		end if
	end if

	tkInit( )

	var comments = ((pre->options and PRESETOPT_COMMENTS) <> 0)
	lexLoadFile( 0, f, LEXMODE_C, comments )

	'' Parse PP directives, and expand #includes if wanted and possible.
	''
	'' If new tokens were loaded from an #include, we have to parse for PP
	'' directives etc. again, to handle any PP directives in the added
	'' tokens. There may even be new #include directives in them which
	'' themselves may need expanding.

	var have_new_tokens = TRUE
	while( have_new_tokens )

		ppComments( )
		ppDividers( )
		ppDirectives1( )
		have_new_tokens = FALSE

		if( (pre->options and PRESETOPT_NOMERGE) = 0 ) then
			var x = 0
			while( tkGet( x ) <> TK_EOF )

				'' #include?
				if( tkGet( x ) = TK_PPINCLUDE ) then
					var incfile = *tkGetText( x )
					var incf = frogAddFile( f, incfile )

					if( (not incf->missing) and (incf->refcount = 1) and _
					    ((incf->mergeparent = NULL) or (incf->mergeparent = f)) and _
					    (incf <> f) ) then
						'' Replace #include by included file's content
						tkRemove( x, x )
						lexLoadFile( x, incf, LEXMODE_C, comments )
						have_new_tokens = TRUE

						'' Counter the +1 below, so this position is re-parsed
						x -= 1

						incf->mergeparent = f
						if( verbose ) then
							print "    merged in: " + incf->pretty
						end if
					end if
				end if

				x += 1
			wend
		end if
	wend

	ppDirectives2( )

	''
	'' Macro expansion, #if evaluation
	''
	ppEvalInit( )
	if( (pre->options and PRESETOPT_NOPP) = 0 ) then
		ppEval( )
	else
		ppParseIfExprOnly( ((pre->options and PRESETOPT_NOPPFOLD) = 0) )
	end if
	ppEvalEnd( )
	ppRemoveEOLs( )

	'' Parse C constructs
	var ast = cFile( )

	tkEnd( )

	''
	'' Work on the AST
	''
	'hRemoveParamNames( ast )
	hFixArrayParams( ast )
	hRemoveRedundantTypedefs( ast )
	if( (pre->options and PRESETOPT_NOAUTOEXTERN) = 0 ) then
		hAutoExtern( ast )
	end if
	hMergeDIVIDERs( ast )

	function = ast
end function

private sub frogParse( byval pre as FROGPRESET ptr, byval f as FROGFILE ptr )
	print "parsing: ";f->pretty

	dim as ASTNODE ptr ast

	'' Any versions specified?
	var version = pre->versions->head
	if( version ) then
		var fullversion = astNewVERSION( )

		'' For each version...
		do
			'' Parse files into AST, put the AST into a VERSION block, and merge
			'' it with previous ones
			ast = hMergeVersions( ast, astNewVERSION( version, frogParseVersion( pre, f, version ) ) )

			'' Collect each version's version number
			astCloneAndAddAllChildrenOf( fullversion->expr, version->expr )

			version = version->next
		loop while( version )

		'' Remove VERSION blocks if they cover all versions, because if
		'' code they contain appears in all versions, then the VERSION
		'' block isn't needed. VERSION blocks are only needed for code
		'' that is specific to some versions but not all.
		ast = astSolveVersionsOut( ast, fullversion )
	else
		'' Just do a single pass, don't worry about version specifics or AST merging
		ast = frogParseVersion( pre, f, NULL )
	end if

	f->ast = ast
end sub

private sub frogWork( byval pre as FROGPRESET ptr, byref presetfile as string )
	listInit( @frog.files, sizeof( FROGFILE ) )
	hashInit( @frog.filehash, 6 )

	'' Download tarballs
	scope
		var child = pre->downloads->head
		while( child )
			if( frogDownload( *child->text, *child->comment ) = FALSE ) then
				oops( "failed to download " + *child->comment )
			end if
			child = child->next
		wend
	end scope

	'' Extract tarballs
	scope
		var child = pre->extracts->head
		while( child )
			if( frogExtract( *child->text, *child->comment ) = FALSE ) then
				oops( "failed to extract " + *child->text )
			end if
			child = child->next
		wend
	end scope

	'' Input files
	scope
		var child = pre->files->head
		while( child )
			'' File from command line, search in current directory
			frogAddFile( NULL, *child->text )
			child = child->next
		wend
	end scope

	'' Input files from directories
	scope
		var child = pre->dirs->head
		while( child )

			dim as TLIST list
			listInit( @list, sizeof( string ) )

			hScanDirectoryForH( *child->text, @list )

			dim as string ptr s = listGetHead( @list )
			while( s )
				frogAddFile( NULL, *s )
				*s = ""
				s = listGetNext( s )
			wend

			listEnd( @list )

			child = child->next
		wend
	end scope

	if( listGetHead( @frog.files ) = NULL ) then
		if( len( presetfile ) > 0 ) then
			oops( "no input files for '" + presetfile + "'" )
		else
			oops( "no input files" )
		end if
	end if

	dim as FROGFILE ptr f

	if( (pre->options and PRESETOPT_NOMERGE) = 0 ) then
		print "preparsing to determine #include dependencies..."

		'' Preparse to find #includes and calculate refcounts
		'' Files newly registered by the inner loop will eventually be worked
		'' off by the outer loop, as they're appended to the files list.
		f = listGetHead( @frog.files )
		while( f )
			if( f->missing = FALSE ) then
				print "preparsing: ";f->pretty

				tkInit( )
				lexLoadFile( 0, f, LEXMODE_C, FALSE )

				ppDirectives1( )

				'' Find #include directives
				var x = 0
				while( tkGet( x ) <> TK_EOF )

					if( tkGet( x ) = TK_PPINCLUDE ) then
						var incfile = *tkGetText( x )

						print "  #include: " & incfile;
						if( verbose ) then
							print
						end if

						var incf = frogAddFile( f, incfile )
						incf->refcount += 1

						if( verbose = FALSE ) then
							if( incf->missing ) then
								print " (not found)"
							end if
						end if
					end if

					x += 1
				wend

				tkEnd( )
			end if

			f = listGetNext( f )
		wend

		'' Pass 1: Process any files that don't look like they'll be
		'' merged, i.e. refcount <> 1.
		f = listGetHead( @frog.files )
		while( f )

			if( (not f->missing) and (f->refcount <> 1) ) then
				assert( f->mergeparent = NULL )
				frogParse( pre, f )

				dim as FROGFILE ptr incf = listGetHead( @frog.files )
				while( incf )
					if( incf->mergeparent = f ) then
						print "merged in: " + incf->pretty
					end if
					incf = listGetNext( incf )
				wend
			end if

			f = listGetNext( f )
		wend

		'' Pass 2: Process files that looked like they should be merged,
		'' but weren't. This happens with recursive #includes, where all
		'' have refcount > 0, so none of them were merged in anywhere
		'' during the 1st pass.
		f = listGetHead( @frog.files )
		while( f )

			if( (not f->missing) and (f->refcount = 1) and (f->mergeparent = NULL) ) then
				frogParse( pre, f )

				dim as FROGFILE ptr incf = listGetHead( @frog.files )
				while( incf )
					if( incf->mergeparent = f ) then
						print "merged in: " + incf->pretty
					end if
					incf = listGetNext( incf )
				wend
			end if

			f = listGetNext( f )
		wend

		'' Concatenate files with refcount=0
		dim as FROGFILE ptr first
		f = listGetHead( @frog.files )
		while( f )
			if( f->refcount = 0 ) then
				if( first ) then
					'' Already have a first; append to it
					if( f->ast ) then
						astAppend( first->ast, f->ast )
						f->ast = NULL
					end if
				else
					'' This is the first
					first = f
				end if
			end if
			f = listGetNext( f )
		wend
	else
		'' No merging requested, just process each file that was found
		'' individually.
		f = listGetHead( @frog.files )
		while( f )
			if( f->missing = FALSE ) then
				frogParse( pre, f )
			end if
			f = listGetNext( f )
		wend
	end if

	'' Emit all files that have an AST (i.e. weren't merged into or
	'' appended to anything)
	f = listGetHead( @frog.files )
	while( f )
		if( f->ast ) then
			var binormed = pathStripExt( f->normed ) + ".bi"
			var bipretty = pathStripExt( f->pretty ) + ".bi"
			print "emitting: " + bipretty
			'astDump( f->ast )
			emitFile( binormed, f->ast )
		end if
		f = listGetNext( f )
	wend

	hashEnd( @frog.filehash )
	do
		f = listGetHead( @frog.files )
		f->pretty = ""
		f->normed = ""
		astDelete( f->ast )
		listDelete( @frog.files, f )
	loop
end sub

''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

	'' Input files and various other info from command line
	dim cmdline as FROGPRESET
	presetInit( @cmdline )
	cmdline.options or= PRESETOPT_NOMERGE

	'' *.fbfrog files from command line
	var presetfiles = astNew( ASTCLASS_GROUP )

	for i as integer = 1 to __FB_ARGC__-1
		var arg = *__FB_ARGV__[i]

		'' option?
		if( left( arg, 1 ) = "-" ) then
			'' Strip all preceding '-'s
			do
				arg = right( arg, len( arg ) - 1 )
			loop while( left( arg, 1 ) = "-" )

			select case( arg )
			case "h", "?", "help", "version"
				hPrintHelp( "" )
			case "m", "merge"
				cmdline.options and= not PRESETOPT_NOMERGE
			case "v", "verbose"
				verbose = TRUE
			case else
				hPrintHelp( "unknown option: " + *__FB_ARGV__[i] )
			end select
		else
			select case( pathExtOnly( arg ) )
			case "h", "hh", "hxx", "hpp", "c", "cc", "cxx", "cpp"
				presetAddFile( @cmdline, arg )
			case ""
				'' No extension? Treat as directory
				presetAddDir( @cmdline, arg )
			case "fbfrog"
				astAppend( presetfiles, astNew( ASTCLASS_TEXT, arg ) )
			case else
				hPrintHelp( "'" + arg + "' is not a *.h file" )
			end select
		end if
	next

	'' If *.fbfrog files were given, work them off one by one
	var presetfile = presetfiles->head
	if( presetfile ) then
		'' For each *.fbfrog file...
		do
			var presetfilename = *presetfile->text

			'' Read in the *.fbfrog preset
			dim as FROGPRESET pre
			presetInit( @pre )
			presetParse( @pre, presetfilename )

			'' Any additional *.h input files given on the command
			'' line (besides the *.fbfrog file(s)) override input
			'' files from the *.fbfrog file. This allows the preset
			'' to be used on other files for testing.
			if( presetHasInput( @cmdline ) ) then
				presetOverrideInput( @pre, @cmdline )
			end if

			frogWork( @pre, presetfilename )
			presetEnd( @pre )

			presetfile = presetfile->next
		loop while( presetfile )
	else
		'' Otherwise just work off the input files and options given
		'' on the command line, it's basically a "preset" too, just not
		'' stored in a *.fbfrog file but given through command line
		'' options.
		frogWork( @cmdline, "" )
	end if
