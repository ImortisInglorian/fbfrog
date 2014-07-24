''
'' AST merging based on longest-common-substring algorithm (diff'ing),
''    which results in individual sections of the AST being wrapped in VERBLOCK
''    nodes holding the conditions (e.g. #ifdef __FB_WIN32__) for that block of
''    code.
''
'' #if generation,
''    which (after all merging is done) converts the VERBLOCKs into #ifs and
''    tries to reduce the #if condition expressions as much as possible to
''    eliminate duplicate checks. For example, for a VERBLOCK that covers all
''    possible APIs, we don't need to generate any #if at all since its
''    condition would always be true. And in case we have a check like this:
''        #if (__FB_WIN32__ and __FB_64BIT__) or (__FB_LINUX__ and __FB_64BIT__)
''    that can be simplified to:
''        #if __FB_64BIT__ and (__FB_WIN32__ or __FB_LINUX__)
''    etc.
''

#include once "fbfrog.bi"

''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

type DECLNODE
	n	as ASTNODE ptr  '' The declaration at that index
	hash	as ulong        '' Precalculated hash value for the declaration
	veror	as ASTNODE ptr  '' Points to the VEROR expression of the declaration's parent VERBLOCK
end type

type DECLTABLE
	array	as DECLNODE ptr
	count	as integer
	room	as integer
end type

'' ASTNODE class and identifier are the 2 main points to quickly distinguish two declarations.
'' Care must be taken for dummyids though, because they're ignored by hAstLCS (ASTEQ_IGNOREDUMMYID).
private function decltableHash( byval n as ASTNODE ptr ) as ulong
	dim as ulong hash = n->class
	if( (n->text <> NULL) and ((n->attrib and ASTATTRIB_DUMMYID) = 0) ) then
		hash or= hashHash( n->text ) shl 8
	end if
	function = hash
end function

private sub decltableAdd _
	( _
		byval table as DECLTABLE ptr, _
		byval n as ASTNODE ptr, _
		byval veror as ASTNODE ptr _
	)

	assert( astIsVEROR( veror ) )

	if( table->count = table->room ) then
		table->room += 256
		table->array = reallocate( table->array, table->room * sizeof( DECLNODE ) )
	end if

	with( table->array[table->count] )
		.n = n
		.hash = decltableHash( n )
		.veror = veror
	end with

	table->count += 1

end sub

private sub decltableInit _
	( _
		byval table as DECLTABLE ptr, _
		byval code as ASTNODE ptr _
	)

	table->array = NULL
	table->count = 0
	table->room = 0

	'' Add each declaration node from the AST to the table
	'' For each VERBLOCK...
	assert( code->class = ASTCLASS_GROUP )
	var verblock = code->head
	while( verblock )
		assert( astIsVERBLOCK( verblock ) )

		'' For each declaration in that VERBLOCK...
		var decl = verblock->head
		while( decl )
			decltableAdd( table, decl, verblock->expr )
			decl = decl->next
		wend

		verblock = verblock->next
	wend
end sub

private sub decltableEnd( byval table as DECLTABLE ptr )
	deallocate( table->array )
end sub

''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

function astDumpPrettyVersion( byval n as ASTNODE ptr ) as string
	dim s as string

	select case( n->class )
	case ASTCLASS_VERAND
		var i = n->head
		while( i )
			s += astDumpPrettyVersion( i )
			i = i->next
			if( i ) then
				s += "."
			end if
		wend

	case ASTCLASS_EQ
		s = *n->head->text + "=" + *n->tail->text

	case ASTCLASS_DEFINED
		s = *n->head->text

	case ASTCLASS_NOT
		s = "(not " + astDumpPrettyVersion( n->head ) + ")"

	case else
		assert( FALSE )
	end select

	function = s
end function

private function astNewGroupLike _
	( _
		byval astclass as integer, _
		byval a as ASTNODE ptr, _
		byval b as ASTNODE ptr _
	) as ASTNODE ptr

	if( a andalso (a->class = astclass) ) then a->class = ASTCLASS_GROUP
	if( b andalso (b->class = astclass) ) then b->class = ASTCLASS_GROUP

	function = astNew( astclass, astNewGROUP( a, b ) )
end function

function astNewVERAND( byval a as ASTNODE ptr, byval b as ASTNODE ptr ) as ASTNODE ptr
	function = astNewGroupLike( ASTCLASS_VERAND, a, b )
end function

function astNewVEROR( byval a as ASTNODE ptr, byval b as ASTNODE ptr ) as ASTNODE ptr
	function = astNewGroupLike( ASTCLASS_VEROR, a, b )
end function

private function astNewVERBLOCK( byval veror as ASTNODE ptr, byval children as ASTNODE ptr ) as ASTNODE ptr
	assert( astIsVEROR( veror ) )
	var n = astNew( ASTCLASS_VERBLOCK, children )
	n->expr = veror
	function = n
end function

'' Just as the whole file AST is wrapped in a verblock, the fields of struct
'' should be aswell, so hMergeStructsManually() doesn't have to handle both
'' cases of "fresh still unwrapped fields" and "already wrapped from previous
'' merge", but only the latter.
private sub hWrapStructFieldsInVerblocks( byval veror as ASTNODE ptr, byval code as ASTNODE ptr )
	var i = code->head
	while( i )
		hWrapStructFieldsInVerblocks( veror, i )
		i = i->next
	wend

	if( astIsMergableBlock( code ) ) then
		var newfields = astNewVERBLOCK( astClone( veror ), astCloneChildren( code ) )
		astRemoveChildren( code )
		astAppend( code, newfields )
	end if
end sub

function astWrapFileInVerblock( byval veror as ASTNODE ptr, byval code as ASTNODE ptr ) as ASTNODE ptr
	hWrapStructFieldsInVerblocks( veror, code )
	function = astNewVERBLOCK( veror, code )
end function

private sub hVerblockAppend _
	( _
		byval n as ASTNODE ptr, _
		byval veror1 as ASTNODE ptr, _
		byval veror2 as ASTNODE ptr, _
		byval child as ASTNODE ptr _
	)

	var veror = astNewVEROR( veror1, veror2 )

	'' If the tree's last VERBLOCK covers the same versions, then just add
	'' the new children nodes to that instead of opening a new VERBLOCK.
	var verblock = n->tail
	if( verblock andalso astIsVERBLOCK( verblock ) ) then
		if( astIsEqual( n->tail->expr, veror ) ) then
			astAppend( n->tail, child )
			exit sub
		end if
	end if

	astAppend( n, astNewVERBLOCK( veror, child ) )
end sub

private sub hAddDecl _
	( _
		byval c as ASTNODE ptr, _
		byval array as DECLNODE ptr, _
		byval i as integer _
	)

	hVerblockAppend( c, astClone( array[i].veror ), NULL, astClone( array[i].n ) )

end sub

''
'' See also hTurnCallConvIntoExternBlock():
''
'' Procdecls with callconv covered by the Extern block are given the
'' ASTATTRIB_HIDECALLCONV flag.
''
'' If we're merging two procdecls here, and they both have ASTATTRIB_HIDECALLCONV,
'' then they can be emitted without explicit callconv, as the Extern blocks will
'' take care of that and remap the callconv as needed. In this case, the merged
'' node shouldn't have any callconv flag at all, but only ASTATTRIB_HIDECALLCONV.
'' hAstLCS() must use the proper option flags for astIsEqual() to allow this.
''
'' If merging two procdecls and only one side has ASTATTRIB_HIDECALLCONV, then they
'' must have the same callconv, otherwise the hAstLCS()'s astIsEqual() wouldn't
'' have treated them as equal. In this case the callconv must be preserved on the
'' merged node, so it will be emitted explicitly, since the Extern blocks don't
'' cover it. ASTATTRIB_HIDECALLCONV shouldn't be preserved in this case.
''
'' The same applies to procptr subtypes, and to be able to handle them, this
'' function is recursive.
''
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
		byval bi as integer, _
		byval btablecount as integer _
	)

	var adecl  = aarray[ai].n
	var bdecl  = barray[bi].n
	var averor = aarray[ai].veror
	var bveror = barray[bi].veror

	assert( adecl->class = bdecl->class )

	''
	'' The LCS may include merged blocks (structs/unions/enums/renamelists) that were put
	'' into the LCS despite having different children (fields/enumconsts/etc.) on both sides.
	''
	'' They should be merged recursively now, so the block itself can be common,
	'' while the children may be version dependant.
	''
	'' (This relies on blocks to be allowed to match in the hAstLCS() call,
	'' even if they have different children)
	''
	dim mdecl as ASTNODE ptr
	if( astIsMergableBlock( adecl ) ) then

		''
		'' For example:
		''
		''     verblock 1                   verblock 2
		''         struct FOO                   struct FOO
		''             field a as integer           field a as integer
		''             field b as integer           field c as integer
		''
		'' should become:
		''
		''     version 1, 2
		''         struct FOO
		''             version 1, 2
		''                 field a as integer
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

		var achildren = astCloneChildren( adecl )
		var bchildren = astCloneChildren( bdecl )

		'' Merge both set of children
		var mchildren = astMergeVerblocks( achildren, bchildren )

		'' Create a result block with the new set of children
		mdecl = astCloneNode( adecl )
		astAppend( mdecl, mchildren )

		'' If two structs with dummy ids were merged together, the result will
		'' a's id, and now we need to manually update all references to b's id
		'' following later in the code over to use a's id, so they'll be merged
		'' successfully (assuming merging walks through declarations in order
		'' like a single-pass compiler).
		select case( mdecl->class )
		case ASTCLASS_STRUCT, ASTCLASS_UNION, ASTCLASS_ENUM
			if( mdecl->attrib and ASTATTRIB_DUMMYID ) then
				assert( *mdecl->text = *adecl->text )
				assert( *mdecl->text <> *bdecl->text )
				for i as integer = bi+1 to btablecount-1
					astReplaceSubtypes( barray[i].n, ASTCLASS_TAGID, bdecl->text, ASTCLASS_TAGID, mdecl->text )
				next
			end if
		end select
	else
		'' "Merge" a and b by cloning a. They've compared equal in astIsEqual() so this works.
		'' Below we only need to cover a few additional cases where astIsEqual() is more permissive
		'' than a true equality check: it allows merging of a/b even if they're slightly different.
		'' This currently affects the calling convention only. In such cases, just cloning a isn't
		'' enough and some actual merging work is needed.
		mdecl = astClone( adecl )

		hFindCommonCallConvsOnMergedDecl( mdecl, adecl, bdecl )
	end if

	'' Add struct to result tree, under both a's and b's version numbers
	hVerblockAppend( c, astClone( averor ), astClone( bveror ), mdecl )

end sub

''
'' Determine the longest common substring, by building an l x r matrix:
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
'' To avoid a huge memory allocation, we don't allocate the whole matrix
'' but only 2 rows, which is really all the LCS algorithm needs.
''
'' For example, given 2 ASTs with 10k declarations each (that can happen
'' easily with huge libraries), allocating the whole matrix would mean:
''    4 bytes * 10k * 10k = 381 MiB
'' while with 2 rows it's only:
''    4 bytes * 10k * 2 = 78 KiB
''
'' And using 4 bytes to hold each length is overkill too - it's surely enough
'' to use 2 bytes and put a limit of max. 65535 declarations per API. Even the
'' whole GTK+/GLib/ATK/Cairo/Pango/etc API results in only ~20k declarations...
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

	'' Currently using USHORTs to store the lengths of common sequences of
	'' declarations. It should be enough...
	if( (llen > &hFFFF) or (rlen > &hFFFF) ) then
		oops( "hAstLCS(): soft-limited to 65535 declarations per " + _
			"API, but here we have " & llen & " and " & rlen )
	end if

	dim as integer maxlen, maxlenl, maxlenr

	'' previousrow = row for l-1 (NULL for l = 0)
	''  currentrow = row for l
	var rowsize = sizeof( ushort ) * rlen
	dim as ushort ptr  currentrow = callocate( rowsize )
	dim as ushort ptr previousrow = callocate( rowsize )

	for l as integer = 0 to llen-1
		for r as integer = 0 to rlen-1
			var length = 0

			var ldecl = @larray[lfirst+l]
			var rdecl = @rarray[rfirst+r]

			if( ldecl->hash = rdecl->hash ) then
				if( astIsEqual( ldecl->n, rdecl->n, ASTEQ_IGNOREHIDDENCALLCONV or ASTEQ_IGNOREMERGABLEBLOCKBODIES or ASTEQ_IGNOREDUMMYID ) ) then
					if( (l = 0) or (r = 0) ) then
						length = 1
					else
						length = previousrow[r-1] + 1
					end if
				end if
			end if

			if( maxlen < length ) then
				maxlen = length
				maxlenl = l
				maxlenr = r
			end if

			currentrow[r] = length
		next
		swap currentrow, previousrow
	next

	deallocate( currentrow )
	deallocate( previousrow )

	llcslast = lfirst + maxlenl
	rlcslast = rfirst + maxlenr
	llcsfirst = llcslast - maxlen + 1
	rlcsfirst = rlcslast - maxlen + 1
end sub

private sub hAstMerge _
	( _
		byval c as ASTNODE ptr, _
		byval aarray as DECLNODE ptr, _
		byval afirst as integer, _
		byval alast as integer, _
		byval barray as DECLNODE ptr, _
		byval bfirst as integer, _
		byval blast as integer, _
		byval btablecount as integer _
	)

	static reclevel as integer

	'' No longest common substring possible?
	if( afirst > alast ) then
		'' Add bfirst..blast to result
		for i as integer = bfirst to blast
			hAddDecl( c, barray, i )
		next
		exit sub
	elseif( bfirst > blast ) then
		'' Add afirst..alast to result
		for i as integer = afirst to alast
			hAddDecl( c, aarray, i )
		next
		exit sub
	end if

	'' Find longest common substring
	dim as integer alcsfirst, alcslast, blcsfirst, blcslast
	hAstLCS( aarray, afirst, alast, alcsfirst, alcslast, _
	         barray, bfirst, blast, blcsfirst, blcslast )

	'' No LCS found?
	if( alcsfirst > alcslast ) then
		'' Add a first, then b. This order makes the most sense: keeping
		'' the old declarations at the top, add new ones to the bottom.
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
		reclevel += 1
		hAstMerge( c, aarray, afirst, alcsfirst - 1, _
		              barray, bfirst, blcsfirst - 1, btablecount )
		reclevel -= 1
	elseif( alcsfirst > afirst ) then
		'' Only a has decls before the LCS; copy them into result first
		for i as integer = afirst to alcsfirst - 1
			hAddDecl( c, aarray, i )
		next
	elseif( blcsfirst > bfirst ) then
		'' Only b has decls before the LCS; copy them into result first
		for i as integer = bfirst to blcsfirst - 1
			hAddDecl( c, barray, i )
		next
	end if

	'' Add LCS
	assert( (alcslast - alcsfirst + 1) = (blcslast - blcsfirst + 1) )
	for i as integer = 0 to (alcslast - alcsfirst + 1)-1
		hAddMergedDecl( c, aarray, alcsfirst + i, barray, blcsfirst + i, btablecount )
	next

	'' Do both sides have decls behind the LCS?
	if( (alcslast < alast) and (blcslast < blast) ) then
		'' Do LCS on that recursively
		reclevel += 1
		hAstMerge( c, aarray, alcslast + 1, alast, barray, blcslast + 1, blast, btablecount )
		reclevel -= 1
	elseif( alcslast < alast ) then
		'' Only a has decls behind the LCS
		for i as integer = alcslast + 1 to alast
			hAddDecl( c, aarray, i )
		next
	elseif( blcslast < blast ) then
		'' Only b has decls behind the LCS
		for i as integer = blcslast + 1 to blast
			hAddDecl( c, barray, i )
		next
	end if

end sub

function astMergeVerblocks _
	( _
		byval a as ASTNODE ptr, _
		byval b as ASTNODE ptr _
	) as ASTNODE ptr

	var c = astNewGROUP( )
	a = astNewGROUP( a )
	b = astNewGROUP( b )

	'' Create a lookup table for each side, so the LCS algorithm can do
	'' index-based lookups in O(1) instead of having to cycle through the
	'' whole list of preceding nodes everytime which was terribly slow.
	dim atable as DECLTABLE
	dim btable as DECLTABLE

	decltableInit( @atable, a )
	decltableInit( @btable, b )

	''
	'' Precalculate hashes for A's and B's declarations. hAstLCS() can then
	'' quickly detect declarations that are different and avoid the slow
	'' astIsEqual() in such cases.
	''
	'' Using the hashes is worth it, because the LCS algorithm checks all
	'' the combinations of A's and B's declarations, i.e. an AxB matrix.
	'' Even if A and B are completely equal (and AxB is an identity matrix)
	'' there will be at most min(len(A), len(B)) true comparisons that need
	'' to be verified via astIsEqual(), while the vast majority of false
	'' comparisons can be quickly ignored due to the hash mismatch.
	''

	''
	'' Precalculating astIsEqual() results for every entry of the AxB matrix
	'' would probably not be worth it though, because it does not reduce the
	'' amount of astIsEqual() calls.
	''
	'' The only case where it could be an advantage to cache the
	'' astIsEqual() results would be if A and B differ a lot and the LCS
	'' algorithm ends up being run multiple times recursively to merge the
	'' sections above/below an LCS. In that case the same declarations will
	'' be compared multiple times and the caching would speed that up.
	''
	'' However, in practice A and B are usually very similar/almost equal,
	'' thus the LCS will typically be very big, and there won't be many
	'' subsections to merge recursively... and it would have a noticable
	'' memory cost even if compressed into bits: Assuming 20k x 20k
	'' declarations, that would be 400 million bitflags, ~48 MiB.
	''

	hAstMerge( c, atable.array, 0, atable.count - 1, _
	              btable.array, 0, btable.count - 1, btable.count )

	decltableEnd( @btable )
	decltableEnd( @atable )

	function = c
end function

''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

''
'' Structs/unions/enums can have nested verblocks (to allow fields to be
'' versioned). If a nested verblock covers >= of the parent verblock's versions,
'' then its checking expression would always evaluate to true, so it's useless
'' and can be removed.
''
'' At the very least,
''
''     verblock <foo>
''         struct UDT
''             verblock <foo>
''                 field x as integer
''
'' can be simplified to:
''
''     verblock <foo>
''         struct UDT
''             field x as integer
''
'' Similar to that, verblocks at the toplevel can be solved out, if they cover
'' all possible versions. (think of them as being nested in a global verblock)
''
private sub hSolveOutRedundantVerblocks( byval code as ASTNODE ptr, byval parentveror as ASTNODE ptr )
	assert( astIsVEROR( parentveror ) )

	var i = code->head
	while( i )
		var nxt = i->next

		if( i->class = ASTCLASS_VERBLOCK ) then
			hSolveOutRedundantVerblocks( i, i->expr )

			'' Has a parent?
			if( parentveror ) then
				'' Nested verblock covers at least the parent's versions?
				if( astGroupContainsAllChildrenOf( i->expr, parentveror ) ) then
					'' Remove this verblock, preserve only its children
					astReplace( code, i, astCloneChildren( i ) )
				end if
			end if
		else
			hSolveOutRedundantVerblocks( i, parentveror )
		end if

		i = nxt
	wend
end sub

''
'' verblocks must be turned into #if/#endif blocks. Doing that on the AST level
'' instead of when emitting allows us to generate #elseifs/#elses for adjacent
'' verblocks as long as they cover different versions.
''
'' For example: (VER=1, VER=2, VER=3).(defined(FOO), (not defined(FOO)))
''
''     verblock VER=1
''         <...>
''     verblock VER=2
''         <...>
''     <...>
''     verblock defined(FOO)
''         <...>
''     verblock (not defined(FOO))
''         <...>
''
'' becomes:
''
''     #if VER=1
''         <...>
''     #elseif VER=2
''         <...>
''     #endif
''     <...>
''     #ifdef FOO
''         <...>
''     #else
''         <...>
''     #endif
''
private sub hTurnVerblocksIntoPpIfs( byval code as ASTNODE ptr )
	var i = code->head
	while( i )

		'' Process verblocks nested inside structs etc.
		hTurnVerblocksIntoPpIfs( i )

		if( astIsVERBLOCK( i ) ) then
			'' Turn the 1st verblock into an #if
			i->class = ASTCLASS_PPIF

			'' Find all VERBLOCKs in a row, if any, as long as they cover different versions
			'' (as long as no duplicates would be added to the list of collected versions)
			'' and turn them into #elseif's while at it.
			var j = i->next
			var collected = astClone( i->expr )
			assert( astIsVEROR( collected ) )
			while( j andalso astIsVERBLOCK( j ) andalso _
			       (not astGroupContainsAnyChildrenOf( collected, j->expr )) )
				j->class = ASTCLASS_PPELSEIF
				collected = astNewVEROR( collected, astClone( j->expr ) )
				j = j->next
			wend

			'' j = node behind the last VERBLOCK in the row, or NULL if at EOF

			'' If the collected verblocks cover all versions, then only the first #if check
			'' and any intermediate #elseif checks are needed, but the last check can be turned
			'' into a simple #else.
			if( astIsEqual( collected, frog.fullveror ) ) then
				var last = iif( j, j->prev, code->tail )
				'' But only if we've got more than 1 verblock
				if( i <> last ) then
					assert( last->class = ASTCLASS_PPELSEIF )
					last->class = ASTCLASS_PPELSE
					astDelete( last->expr )
					last->expr = NULL
				end if
			end if

			'' Insert #endif
			astInsert( code, astNew( ASTCLASS_PPENDIF ), j )

			astDelete( collected )
		end if

		i = i->next
	wend
end sub

type CONDINFO
	cond		as ASTNODE ptr	'' The condition expression
	count		as integer	'' How often it was seen
end type

namespace condcounter
	dim shared conds as CONDINFO ptr
	dim shared condcount as integer
end namespace

private sub condcounterCount( byval cond as ASTNODE ptr )
	'' If this condition is already known, increase the count.
	for i as integer = 0 to condcounter.condcount - 1
		if( astIsEqual( condcounter.conds[i].cond, cond ) ) then
			condcounter.conds[i].count += 1
			exit sub
		end if
	next

	'' Otherwise, register it as new.
	var i = condcounter.condcount
	condcounter.condcount += 1
	condcounter.conds = reallocate( condcounter.conds, _
			condcounter.condcount * sizeof( CONDINFO ) )
	condcounter.conds[i].cond = cond
	condcounter.conds[i].count = 1
end sub

private sub condcounterEnd( )
	deallocate( condcounter.conds )
	condcounter.conds = NULL
	condcounter.condcount = 0
end sub

private function condcounterFindMostCommon( ) as ASTNODE ptr
	if( condcounter.condcount = 0 ) then
		return NULL
	end if

	var maxcount = 0
	var imaxcount = -1
	for i as integer = 0 to condcounter.condcount - 1
		if( maxcount < condcounter.conds[i].count ) then
			maxcount = condcounter.conds[i].count
			imaxcount = i
		end if
	next
	assert( (imaxcount >= 0) and (imaxcount < condcounter.condcount) )

	'' No point extracting a condition that only appeared once
	if( condcounter.conds[imaxcount].count < 2 ) then
		return NULL
	end if

	function = condcounter.conds[imaxcount].cond
end function

private function hDetermineMostCommonCondition( byval veror as ASTNODE ptr ) as ASTNODE ptr
	assert( astIsVEROR( veror ) )

	'' Build list of all conditions and count them. The one with the max
	'' count is the most common.

	var verand = veror->head
	while( verand )
		if( astIsVERAND( verand ) ) then
			var cond = verand->head
			while( cond )
				condcounterCount( cond )
				cond = cond->next
			wend
		end if
		verand = verand->next
	wend

	function = condcounterFindMostCommon( )

	condcounterEnd( )
end function

private function hIsCondition( byval n as ASTNODE ptr ) as integer
	function = (not astIsVEROR( n )) and (not astIsVERAND( n ))
end function

private function hSimplify( byval n as ASTNODE ptr, byref changed as integer ) as ASTNODE ptr
	if( n = NULL ) then return NULL
	if( hIsCondition( n ) ) then return n

	scope
		var i = n->head
		while( i )
			i = astReplace( n, i, hSimplify( astClone( i ), changed ) )
		wend
	end scope

	'' Single child, or none at all? Solve out the VEROR/VERAND.
	if( n->head = n->tail ) then
		changed = TRUE
		function = astClone( n->head )
		astDelete( n )
		exit function
	end if

	if( astIsVEROR( n ) = FALSE ) then
		return n
	end if

	'' Solve out "complete" VERORs - VERORs that cover all possible choices
	if( astGroupContains( frog.completeverors, n ) ) then
		changed = TRUE
		astDelete( n )
		return NULL
	end if

	''
	'' If two VERANDs in a VEROR have a common condition, they can be
	'' simplified:
	''    a.b, a.c        =  a.(b, c)
	''    x, a.b, a.c, y  =  x, a.(b, c), y
	'' and this applies not only to common prefixes/suffixes, but to
	'' just any common conditions:
	''    1.a.x, 2.a.y  =  a.(1.x, 2.y)
	'' The order of operands really doesn't matter:
	''    a.(b, c)
	'' is the same as:
	''    (b, c).a
	''
	'' Sometimes there are multiple solutions:
	''    a.1, a.2, b.2    =    a.(1, 2), b.2    vs.    a.1, 2.(a, b)
	''
	'' We should simplify as much as possible, and we should simplify the
	'' most common conditions first, because that's what you'd do if doing
	'' it manually. I.e., it produced the best and most expected results.
	''

	var mostcommoncond = hDetermineMostCommonCondition( n )
	if( mostcommoncond = NULL ) then
		return n
	end if
	mostcommoncond = astClone( mostcommoncond )

	var extracted = astNew( ASTCLASS_VEROR )

	'' Extract VERANDs that contain the most common condition
	scope
		var verand = n->head
		while( verand )
			var verandnext = verand->next
			if( astIsVERAND( verand ) ) then
				if( astGroupContains( verand, mostcommoncond ) ) then
					astAppend( extracted, astClone( verand ) )
					astRemove( n, verand )
				end if
			end if
			verand = verandnext
		wend
	end scope

	'' Remove the most common condition from the extracted VERANDs
	scope
		var verand = extracted->head
		while( verand )
			var verandnext = verand->next

			'' Remove common condition from this VERAND
			var cond = verand->head
			while( cond )
				var condnext = cond->next
				if( astIsEqual( cond, mostcommoncond ) ) then
					astRemove( verand, cond )
				end if
				cond = condnext
			wend

			'' If this VERAND now only contains 1 condition,
			'' solve out the VERAND
			if( verand->head = verand->tail ) then
				astReplace( extracted, verand, astClone( verand->head ) )
			end if

			verand = verandnext
		wend
	end scope

	'' Add the common condition on top of the extracted VERANDs
	extracted = astNewVERAND( mostcommoncond, extracted )

	'' And re-add that to the original VEROR
	astAppend( n, extracted )
	changed = TRUE

	function = n
end function

private function hSimplifyVersionExpr( byval n as ASTNODE ptr ) as ASTNODE ptr
	dim as integer changed
	do
		changed = FALSE
		n = hSimplify( n, changed )
	loop while( changed )
	function = n
end function

private sub hSimplifyVersionExpressions( byval code as ASTNODE ptr )
	var i = code->head
	while( i )
		var inext = i->next

		'' Handle #if checks nested inside structs
		hSimplifyVersionExpressions( i )

		select case( i->class )
		case ASTCLASS_PPIF, ASTCLASS_PPELSEIF
			i->expr = hSimplifyVersionExpr( i->expr )

			'' If we were able to solve it out completely that means
			'' the check was always true -- thus, we can remove this
			'' #if check and insert the body in its place.
			if( i->expr = NULL ) then
				astReplace( code, i, astCloneChildren( i ) )

				'' If the next node is an #endif, remove that too.
				'' If it's an #elseif, turn that into an #if.
				select case( inext->class )
				case ASTCLASS_PPENDIF
					inext = astRemove( code, inext )
				case ASTCLASS_PPELSEIF
					inext->class = ASTCLASS_PPIF
				end select
			end if
		end select

		i = inext
	wend
end sub

''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'' We add some #if checks at the top of the final binding to verify that the
'' proper symbols are defined, and/or that they're #defined to valid values (in
'' case of -declareversions). This means the user will be shown an error when
'' using the binding incorrectly, which should be a good thing.
''
'' -declaredefines: Selecting between multiple symbols, only one of which may be
'' defined (e.g. __FB_WIN32__, __FB_LINUX__). We emit a check to verify that at
'' least one and only one of these symbols is defined, unless that was disabled
'' with -unchecked.
''
'' -declareversions: We should emit a check to verify the symbol is defined to
'' a valid version number, and add a default version selection in front of that,
'' such that the default version will be used automatically if the user didn't
'' #define the symbol at all. The last version can be used as the default:
'' 1) If the version numbers are specified in oldest-to-newest order (as if
''    being enumerated), then the last one is the most recent version.
'' 2) It usually makes sense to use the latest version by default.
''
'' -declarebool: It's a boolean choice, so there's nothing to verify (either
'' it's #defined or it's not, both are valid).
''
'' The verification code corresponds directly to the fbfrog command line script.
'' We have to emit the checks at the position of each -declare* option in the
'' script, including those nested in -ifdef/-select blocks, so that the checks
'' are in the same order (less important) and have the same nesting (very
'' important) as in the script.
''

'' #ifndef SYMBOL
''     #define SYMBOL default
'' #endif
private sub hBuildDefaultVersionSelection( byval code as ASTNODE ptr, byval decl as ASTNODE ptr )
	var ppdefine = astNewPPDEFINE( decl->text )
	ppdefine->expr = astClone( decl->tail )

	var ppif = astNew( ASTCLASS_PPIF )
	ppif->expr = astNew( ASTCLASS_NOT, astNewDEFINED( decl->text ) )
	astAppend( ppif, ppdefine )

	astAppend( code, ppif )
	astAppend( code, astNew( ASTCLASS_PPENDIF ) )
end sub

private sub hVerifyDefinesOrVersions( byval code as ASTNODE ptr, byval decl as ASTNODE ptr )
	'' #if for the first choice, #elseifs for the rest
	scope
		var ppifclass = ASTCLASS_PPIF
		var k = decl->head
		do
			var ppif = astNew( ppifclass )
			if( decl->class = ASTCLASS_DECLAREDEFINES ) then
				'' defined(<symbol>)
				ppif->expr = astNewDEFINED( k->text )
			else
				'' <symbol> = <versionnumber>
				ppif->expr = astNew( ASTCLASS_EQ, astNewID( decl->text ), astClone( k ) )
			end if
			astAppend( code, ppif )
			ppifclass = ASTCLASS_PPELSEIF
			k = k->next
		loop while( k )
	end scope

	'' #else
	''     #error "..."
	scope
		'' Collect a pretty comma-separated list of the possible values
		dim valuelist as string
		scope
			var k = decl->head
			do
				valuelist += *k->text
				k = k->next
				if( k = NULL ) then exit do
				valuelist += ", "
			loop
		end scope
		var pperror = astNew( ASTCLASS_PPERROR )
		if( decl->class = ASTCLASS_DECLAREDEFINES ) then
			pperror->expr = astNew( ASTCLASS_STRING, "Not one of these symbols is #defined: " + valuelist )
		else
			pperror->expr = astNew( ASTCLASS_STRING, "'" + *decl->text + "' is #defined to an unsupported value; expected one of: " + valuelist )
		end if
		astAppend( code, astNew( ASTCLASS_PPELSE, pperror ) )
	end scope

	'' #endif
	astAppend( code, astNew( ASTCLASS_PPENDIF ) )
end sub

private function hIsSomeIfBlock( byval n as ASTNODE ptr ) as integer
	if( n ) then
		select case( n->class )
		case ASTCLASS_PPIF, ASTCLASS_PPELSEIF, ASTCLASS_PPELSE
			function = TRUE
		end select
	end if
end function

private function hCanEliminate( byval n as ASTNODE ptr ) as integer
	'' #if/#elseif/#else with empty body?
	function = hIsSomeIfBlock( n ) andalso (n->head = NULL)
end function

'' Eliminate all empty #if/#elseif/#else blocks at the end (can't eliminate
'' empty ones at the beginning, because their conditions must be checked before
'' the #elseif/#else code paths are allowed to be reached)
private sub hEliminateTrailingEmptyBlocks( byval code as ASTNODE ptr )
	while( hCanEliminate( code->tail ) )
		astRemove( code, code->tail )
	wend
end sub

private function hBuildVerificationCode( byref i as ASTNODE ptr ) as ASTNODE ptr
	var code = astNewGROUP( )

	while( i )
		select case( i->class )
		case ASTCLASS_DECLAREDEFINES
			if( (i->attrib and ASTATTRIB_UNCHECKED) = 0 ) then
				hVerifyDefinesOrVersions( code, i )
			end if

		case ASTCLASS_DECLAREVERSIONS
			hBuildDefaultVersionSelection( code, i )
			hVerifyDefinesOrVersions( code, i )

		case ASTCLASS_SELECT
			i = i->next

			'' #if for the first -case, #elseif for the rest, #else for -caseelse (if any)
			var ppifclass = ASTCLASS_PPIF
			do
				'' -case
				assert( (i->class = ASTCLASS_CASE) or _
					(i->class = ASTCLASS_CASEELSE) )
				var ppif = astNew( ppifclass )
				ppif->expr = astClone( i->expr )
				i = i->next

				'' -case's body
				astAppend( ppif, hBuildVerificationCode( i ) )
				astAppend( code, ppif )
				ppifclass = iif( i->class = ASTCLASS_CASEELSE, ASTCLASS_PPELSE, ASTCLASS_PPELSEIF )
			loop while( i->class <> ASTCLASS_ENDSELECT )

			hEliminateTrailingEmptyBlocks( code )

			'' #endif, if any #if left after the above elimination
			if( hIsSomeIfBlock( code->tail ) ) then
				astAppend( code, astNew( ASTCLASS_PPENDIF ) )
			end if

		case ASTCLASS_CASE, ASTCLASS_CASEELSE, ASTCLASS_ENDSELECT
			'' When reaching a case/caseelse/endselect instead of the corresponding
			'' select, that means we've been evaluating the nested code path of the
			'' previous case code path recursively, and should now return from the
			'' recursion.
			exit while
		end select

		i = i->next
	wend

	function = code
end function

''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

sub astProcessVerblocks( byval code as ASTNODE ptr )
	assert( code->class = ASTCLASS_GROUP )

	'' These 2 rely on version expressions not being simplified yet:
	'' It's much easier to check which versions are covered by a certain
	'' VERBLOCK if the VERBLOCK's version expression is just a VEROR of all
	'' VERANDs (each VERAND representing one version), as opposed to a
	'' simplified but arbitrary tree of VERORs/VERANDs.
	hSolveOutRedundantVerblocks( code, frog.fullveror )
	hTurnVerblocksIntoPpIfs( code )

	'' Beautification: Apply some trivial refactoring to the version
	'' conditions, to eliminate duplicate checks where possible.
	hSimplifyVersionExpressions( code )

	var i = frog.script->head
	astPrepend( code, hBuildVerificationCode( i ) )
end sub