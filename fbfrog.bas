#include once "common.bi"
#include once "tk.bi"

#define FROG_VERSION "0.1"
#define FROG_HELP _
	!"usage: fbfrog *.h\n" & _
	!"For every given C header (*.h) an FB header (*.bi) will be generated.\n" & _
	!"With some luck and not too complex headers the translation should be fine.\n" & _
	!"If something is wrong or requires a human eye, there will be TODOs written\n" & _
	!"into the .bi files."

sub _xassertfail _
	( _
		byval test as zstring ptr, _
		byval filename as zstring ptr, _
		byval funcname as zstring ptr, _
		byval linenum as integer _
	)
	print "bug: assertion failed at " & *filename & "(" & linenum & "):" & lcase(*funcname) & ": " & *test
end sub

sub xoops(byref message as string)
	print "oops, " & message
	end 1
end sub

private sub xoops_mem(byval size as ulong)
	xoops("oops, memory allocation failed (asked for " & size & " bytes)")
end sub

function xallocate(byval size as ulong) as any ptr
	dim as any ptr p = allocate(size)
	if (p = NULL) then
		xoops_mem(size)
	end if
	return p
end function

function xcallocate(byval size as ulong) as any ptr
	dim as any ptr p = callocate(size)
	if (p = NULL) then
		xoops_mem(size)
	end if
	return p
end function

function xreallocate(byval old as any ptr, byval size as ulong) as any ptr
	dim as any ptr p = reallocate(old, size)
	if (p = NULL) then
		xoops_mem(size)
	end if
	return p
end function

'' Searches backwards for the last '.' while still behind '/' or '\'.
private function find_ext_begin(byref path as string) as integer
	for i as integer = (len(path)-1) to 0 step -1
		dim as integer ch = path[i]
		if (ch = asc(".")) then
			return i
		elseif ((ch = asc("/")) or (ch = asc("\"))) then
			exit for
		end if
	next
	return len(path)
end function

function path_strip_ext(byref path as string) as string
	return left(path, find_ext_begin(path))
end function

''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

'' Skips the token and any following whitespace
private function skip(byval x as integer) as integer
	do
		x += 1

		select case (tk_get(x))
		case TK_EOL, TK_SPACE, TK_COMMENT, TK_LINECOMMENT

		case else
			exit do
		end select
	loop
	return x
end function

'' Same, but backwards
private function skiprev(byval x as integer) as integer
	do
		x -= 1

		select case (tk_get(x))
		case TK_EOL, TK_SPACE, TK_COMMENT, TK_LINECOMMENT

		case else
			exit do
		end select
	loop
	return x
end function

private function skip_if_match _
	( _
		byval x as integer, _
		byval id as integer _
	) as integer
	if (tk_get(x) = id) then
		x = skip(x)
	end if
	return x
end function

private function is_whitespace_until_eol(byval x as integer) as integer
	do
		select case (tk_get(x))
		case TK_EOL, TK_EOF
			exit do

		case TK_SPACE, TK_COMMENT, TK_LINECOMMENT

		case else
			return FALSE

		end select

		x += 1
	loop
	return TRUE
end function

private function parse_pp_directive(byval x as integer) as integer
	'' (Assuming all '#' are indicating a PP directive)
	if (tk_get(x) <> TK_HASH) then
		return x
	end if

	dim as integer begin = x

	'' Skip until EOL, but also handle PP line continuation
	do
		x += 1

		select case (tk_get(x))
		case TK_EOL
			if (tk_get(x - 1) <> TK_BACKSLASH) then
				exit do
			end if

		case TK_EOF
			exit do

		end select
	loop

	tk_mark_stmt(STMT_PP, begin, x - 1)

	return x
end function

private function find_parentheses_backwards(byval x as integer) as integer
	dim as integer opening_tk = any
	dim as integer closing_tk = tk_get(x)

	select case (closing_tk)
	case TK_RPAREN
		opening_tk = TK_LPAREN
	case TK_RBRACE
		opening_tk = TK_LBRACE
	case TK_RBRACKET
		opening_tk = TK_LBRACKET
	case else
		return x
	end select

	dim as integer level = 0
	dim as integer old = x
	do
		x -= 1

		select case (tk_get(x))
		case opening_tk
			if (level = 0) then
				'' Found it
				exit do
			end if
			level -= 1

		case closing_tk
			level += 1

		case TK_EOF
			'' Not in this file anyways
			return old

		end select
	loop

	return x
end function

private function parse_base_type(byval x as integer) as integer
	dim as integer old = x

	select case (tk_get(x))
	case KW_ENUM, KW_STRUCT
		'' {ENUM | STRUCT} id
		x = skip(x)
		if (tk_get(x) <> TK_ID) then
			return old
		end if
		return skip(x)

	case TK_ID
		'' Just a single id
		return skip(x)
	end select

	'' [SIGNED | UNSIGNED]
	select case (tk_get(x))
	case KW_SIGNED, KW_UNSIGNED
		x = skip(x)
	end select

	'' [ VOID
	'' | CHAR
	'' | FLOAT
	'' | DOUBLE
	'' | INT
	'' | SHORT [INT]
	'' | LONG [LONG] [INT]
	'' ]
	select case (tk_get(x))
	case KW_VOID, KW_CHAR, KW_FLOAT, KW_DOUBLE, KW_INT
		x = skip(x)

	case KW_SHORT
		x = skip(x)
		x = skip_if_match(x, KW_INT)

	case KW_LONG
		x = skip(x)
		x = skip_if_match(x, KW_LONG)
		x = skip_if_match(x, KW_INT)

	end select

	'' In case of no type keyword at all, x = old
	return x
end function

private function parse_enumfield(byval x as integer) as integer
	if (tk_get(x) <> TK_ID) then
		return x
	end if

	dim as integer begin = x
	x = skip(x)

	'' ['=' expression]
	if (tk_get(x) = TK_ASSIGN) then
		do
			x = skip(x)
			select case (tk_get(x))
			case TK_COMMA, TK_RBRACE, TK_EOF
				exit do
			end select
		loop
	end if

	select case (tk_get(x))
	case TK_COMMA
		'' Treat the comma as part of the constant declaration
		x = skip(x)

	case TK_RBRACE

	case else
		return begin
	end select

	'' Mark the constant declaration
	tk_mark_stmt(STMT_ENUMFIELD, begin, skiprev(x))

	return x
end function

private function parse_field(byval x as integer) as integer
	dim as integer begin = x

	'' type
	x = parse_base_type(begin)
	if (x = begin) then
		return begin
	end if

	'' '*'* identifier (',' '*'* identifier)*
	do
		'' Pointers: ('*')*
		while (tk_get(x) = TK_MUL)
			x = skip(x)
		wend

		if (tk_get(x) <> TK_ID) then
			return begin
		end if
		x = skip(x)

		if (tk_get(x) <> TK_COMMA) then
			exit do
		end if
		x = skip(x)
	loop

	'' ';'
	if (tk_get(x) <> TK_SEMI) then
		return begin
	end if
	x = skip(x)

	'' Mark the constant declaration
	tk_mark_stmt(STMT_FIELD, begin, skiprev(x))

	return x
end function

'' EXTERN/STRUCT/ENUM blocks
private function parse_compound(byval x as integer) as integer
	dim as integer stmt = any

	select case (tk_get(x))
	case KW_EXTERN
		stmt = STMT_EXTERN
	case KW_STRUCT
		stmt = STMT_STRUCT
	case KW_ENUM
		stmt = STMT_ENUM
	case else
		return x
	end select

	dim as integer begin = x
	x = skip(x)

	if (stmt = STMT_EXTERN) then
		'' EXTERN requires a following string
		'' (for example <EXTERN "C">)
		if (tk_get(x) <> TK_STRING) then
			return begin
		end if
		x = skip(x)
	else
		'' STRUCT/ENUM can have an optional id
		x = skip_if_match(x, TK_ID)
	end if

	'' Opening '{'?
	if (tk_get(x) <> TK_LBRACE) then
		return begin
	end if

	'' Mark the '{' too, but not the whitespace/comments behind it,
	'' since that's usually indentation belonging to something else.
	tk_mark_stmt(stmt, begin, x)

	'' EXTERN parsing is done here; the content is parsed as toplevel,
	'' and the '}' is handled later.
	if (stmt = STMT_EXTERN) then
		return x + 1
	end if

	'' '{'
	x = skip(x)

	'' Fields
	do
		dim as integer old = x
		x = parse_pp_directive(x)

		if (stmt = STMT_ENUM) then
			x = parse_enumfield(x)
		else
			x = parse_field(x)
		end if

		select case (tk_get(x))
		case TK_RBRACE
			exit do
		case TK_EOF
			return begin
		end select

		if (x = old) then
			'' The above parsers didn't catch anything, this is
			'' probably commentary/whitespace...
			x = skip(x)
		end if
	loop

	select case (stmt)
	case STMT_STRUCT
		stmt = STMT_ENDSTRUCT
	case STMT_ENUM
		stmt = STMT_ENDENUM
	end select

	tk_mark_stmt(stmt, x, x)

	return x + 1
end function

private function parse_extern_end(byval x as integer) as integer
	if (tk_get(x) <> TK_RBRACE) then
		return x
	end if

	dim as integer opening = find_parentheses_backwards(x)
	if (opening = x) then
		return x
	end if

	dim as integer stmt = tk_stmt(opening)
	if (stmt <> STMT_EXTERN) then
		return x
	end if

	tk_mark_stmt(STMT_ENDEXTERN, x, x)

	return x + 1
end function

private sub parse_toplevel()
	dim as integer x = 0
	do
		dim as integer old = x

		x = parse_pp_directive(x)
		x = parse_compound(x)
		x = parse_extern_end(x)

		if (x = old) then
			'' Token/construct couldn't be identified, so make
			'' sure the parsing advances somehow...
			x = skip(x)
		end if
	loop while (tk_get(x) <> TK_EOF)
end sub

'' EOL fixup -- in C it's possible to have constructs split over multiple
'' lines, which requires a '_' line continuation char in FB. Also, the CPP
'' \<EOL> line continuation needs to be converted to FB.
private sub fixup_eols()
	dim as integer x = 0
	do
		select case (tk_get(x))
		case TK_EOF
			exit do

		case TK_EOL
			select case (tk_stmt(x))
			case STMT_TOPLEVEL
				'' (EOLs at toplevel are supposed to stay)

			case STMT_PP
				'' EOLs can only be part of PP directives if
				'' the newline char is escaped with '\'.
				'' For FB that needs to be replaced with a '_'.
				'' That might require an extra space too,
				'' because '_' can be part of identifiers,
				'' unlike '\'...
				x -= 2
				if (tk_get(x) <> TK_SPACE) then
					tk_insert_space(x)
					x += 1
				end if

				'' Back to '\'
				x += 1

				'' Replace the '\' by '_'
				xassert(tk_get(x) = TK_BACKSLASH)
				tk_replace(x, TK_UNDERSCORE, NULL)

				'' Back to EOL
				x += 1

			case else
				'' For EOLs inside constructs, '_'s need to
				'' be added so it works in FB. It should be
				'' inserted in front of any line comment or
				'' space that aligns the line comment.
				dim as integer y = x - 1
				if (tk_get(y) = TK_LINECOMMENT) then
					y -= 1
				end if
				if (tk_get(y) = TK_SPACE) then
					y -= 1
				end if
				y += 1
				tk_insert_space(y)
				tk_insert(y + 1, TK_UNDERSCORE, NULL)
				x += 2

			end select

		end select

		x += 1
	loop
end sub

private function remove_following_lbrace(byval x as integer) as integer
	'' EXTERN "C" '{' -> EXTERN "C"
	'' Just jump to the '{' and remove it
	while (tk_get(x) <> TK_LBRACE)
		x += 1
	wend
	tk_remove(x)
	return x
end function

private function translate_compound_end _
	( _
		byval x as integer, _
		byval compound_kw as integer _
	) as integer

	'' '}' -> END EXTERN
	tk_replace(x, KW_END, NULL)
	x += 1
	tk_insert_space(x)
	x += 1
	tk_insert(x, compound_kw, NULL)

	return x
end function

private function translate_enumfield(byval x as integer) as integer
	'' identifer ['=' expression] [',']
	'' The only thing to do here is to remove the comma,
	'' unless there are more constants coming in this line.
	do
		x = skip(x)

		select case (tk_get(x))
		case TK_COMMA
			dim as integer more_coming = FALSE
			dim as integer y = x
			do
				y += 1

				select case (tk_get(y))
				case TK_SPACE, TK_COMMENT
					'' Space/comment is ok

				case TK_LINECOMMENT, TK_EOL
					'' Reaching these means there is
					'' nothing else coming in this line
					exit do

				case else
					more_coming = TRUE
					exit do

				end select
			loop

			if (more_coming = FALSE) then
				tk_remove(x)
			else
				x += 1
			end if

			exit do

		case TK_RBRACE, TK_EOF
			exit do

		end select
	loop

	return x
end function

private sub split_field_if_needed(byval x as integer)
	'' Split up a field if needed:
	'' Scan the whole field (from begin to ';'). If there are commas and
	'' pointers, then splits need to be made at the proper places, to
	'' bring the whole thing into a state allowing it to be translated to
	'' FB. The offsets of fields mustn't change of course.
	''    int *a, b, c, **d, **e, f;
	'' to:
	''    int *a; int b, c; int **d; int **e; int f;
	'' Declarations with pointers need to be split off, while non-pointer
	'' declarations and declarations with the same number of pointers can
	'' stay together (since they /can/ be translated to FB).

	dim as integer typebegin = x
	dim as integer typeend = parse_base_type(typebegin)
	x = typeend
	'' The type parser skips to the next non-type token,
	'' so to get the real typeend we need to skip back
	typeend = skiprev(typeend)


	'' Current ptrcount > 0 but <> next ptrcount?
	''  --> Replace following comma by semi, dup the type.
	'' As soon as a next decl is seen and it's different, split.

	'' Amount of pointers seen for the current sequence of declarations.
	'' As soon as a declaration with different ptrcount is seen,
	'' we know it's time to split.
	dim as integer ptrcount = 0     '' Active counter
	dim as integer declptrcount = 0 '' Amount for previous declaration(s)

	'' Begin of the current sequence of declarations with equal ptrcount,
	'' so we can go back and do the split there.
	dim as integer declbegin = typebegin

	do
		select case (tk_get(x))
		case TK_MUL
			ptrcount += 1

		case TK_COMMA, TK_SEMI
			'' Comma/semicolon terminate a declaration (not
			'' officially probably, hehe) and we need to decide
			'' whether to continue the current sequence (of decls
			'' with equal ptrcount) or split it off and start a new
			'' sequence, beginning with this last (just terminated)
			'' decl.
			if (ptrcount <> declptrcount) then
				'' Only split if this isn't the first decl,
				'' in which case there is no current sequence
				'' to split off...
				if (declbegin <> typebegin) then
					'' Replace ',' with ';'
					tk_replace(declbegin, TK_SEMI, NULL)

					'' Copy in the type
					tk_copy_range(declbegin + 1, typebegin, typeend)

					'' Take into account the added tokens
					x += typeend - typebegin + 1
				end if

				'' Continue with new sequence
				declptrcount = ptrcount
				declbegin = x
			end if

			if (tk_get(x) = TK_SEMI) then
				exit do
			end if

			ptrcount = 0

		end select

		x = skip(x)
	loop
end sub

private sub remove_unnecessary_ptrs(byval x as integer)
	'' Assuming field declarations with multiple identifiers but different
	'' ptrcounts on some of them have been split up already, we will only
	'' encounter fields of these forms here:
	''    int a;
	''    int *a;
	''    int a, b, c;
	''    int *a, *b, *c;
	'' i.e. all identifiers with equal ptrcounts.
	'' This translation step turns this:
	''    int *a, *b, *c;
	'' into:
	''    int *a, b, c;
	'' which is needed to get to this:
	''    as integer ptr a, b, c

	x = parse_base_type(x)

	'' Just remove all ptrs behind commas.
	'' TODO: should do space beautifications?
	dim as integer have_comma = FALSE
	do
		select case (tk_get(x))
		case TK_MUL
			if (have_comma) then
				tk_remove(x)
				x -= 1
			end if

		case TK_COMMA
			have_comma = TRUE

		case TK_SEMI
			exit do
		end select

		x += 1
	loop
end sub

private function translate_base_type(byval x as integer) as integer
	'' Insert the AS
	tk_insert(x, KW_AS, NULL)
	x += 1
	tk_insert_space(x)
	x += 1

	select case (tk_get(x))
	case KW_ENUM, KW_STRUCT
		'' {ENUM | STRUCT} id
		tk_remove_range(x, skip(x) - 1)

		xassert(tk_get(x) = TK_ID)
		return skip(x)

	case TK_ID
		'' Just a single id
		return skip(x)
	end select

	'' [SIGNED | UNSIGNED]
	'' [ VOID
	'' | CHAR
	'' | FLOAT
	'' | DOUBLE
	'' | INT
	'' | SHORT [INT]
	'' | LONG [LONG] [INT]
	'' ]
	''
	'' 1) Remember position of [UN]SIGNED
	'' 2) Parse base type (void/char/int/...)
	'' 3) If base type found, remove the [UN]SIGNED, otherwise translate it
	''    as [U]INTEGER

	dim as integer sign = x
	dim as integer signed = TRUE
	dim as integer basekw = -1

	select case (tk_get(sign))
	case KW_SIGNED
		x = skip(x)
	case KW_UNSIGNED
		signed = FALSE
		x = skip(x)
	end select

	select case (tk_get(x))
	case KW_VOID
		basekw = KW_ANY

	case KW_CHAR
		basekw = iif(signed, KW_BYTE, KW_UBYTE)

	case KW_FLOAT
		basekw = KW_SINGLE

	case KW_DOUBLE
		basekw = KW_DOUBLE

	case KW_INT
		basekw = iif(signed, KW_INTEGER, KW_UINTEGER)

	case KW_SHORT
		basekw = iif(signed, KW_SHORT, KW_USHORT)

		'' [INT]
		if (tk_get(skip(x)) = KW_INT) then
			tk_remove_range(x + 1, skip(x))
		end if

	case KW_LONG
		basekw = iif(signed, KW_LONG, KW_ULONG)

		'' [LONG]
		if (tk_get(skip(x)) = KW_LONG) then
			basekw = iif(signed, KW_LONGINT, KW_ULONGINT)
			tk_remove_range(x + 1, skip(x))
		end if

		'' [INT]
		if (tk_get(skip(x)) = KW_INT) then
			tk_remove_range(x + 1, skip(x))
		end if

	end select

	if (basekw >= 0) then
		tk_replace(x, basekw, NULL)
		x = skip(x)
	end if

	select case (tk_get(sign))
	case KW_SIGNED, KW_UNSIGNED
		if (basekw >= 0) then
			'' Remove the [UN]SIGNED, it's now encoded into the
			'' FB type (e.g. UINTEGER)
			dim as integer last = skip(sign) - 1
			tk_remove_range(sign, last)
			x -= (last - sign + 1)
		else
			'' Found [UN]SIGNED only, treat it as [U]INTEGER
			tk_replace(sign, iif(signed, KW_INTEGER, KW_UINTEGER), NULL)
		end if
	end select

	return x
end function

private function translate_ptrs(byval x as integer) as integer
	'' Pointers: '*' -> PTR, plus some space if needed
	while (tk_get(x) = TK_MUL)
		if ((skiprev(x) + 1) = x) then
			tk_insert_space(x - 1)
		end if
		tk_replace(x, KW_PTR, NULL)
		if ((skip(x) - 1) = x) then
			tk_insert_space(x + 1)
		end if
		x = skip(x)
	wend
	return x
end function

private function translate_field(byval x as integer) as integer
	'' The field parser accepts all possible variations, now here we need
	'' an ok way to translate them.
	''
	'' int *i;              ->      as integer ptr i
	'' int a, b, c;         ->      as integer a, b, c
	'' Simple: insert an AS, translate type and pointers, remove the ';'.
	''
	'' int *a, **b, c;      ->      int *a; int **b; int c;
	'' Commas + pointers can't be translated to FB 1:1, but we can split it
	'' up into separate declarations by replacing ',' by ';' and duplicating
	'' the type. Then the normal simple translation rules can work.

	split_field_if_needed(x)
	remove_unnecessary_ptrs(x)

	x = translate_base_type(x)
	x = translate_ptrs(x)

	'' identifier (',' identifier)*
	do
		'' identifier
		xassert(tk_get(x) = TK_ID)
		x = skip(x)

		'' ','
		if (tk_get(x) <> TK_COMMA) then
			exit do
		end if
		x = skip(x)
	loop

	'' ';'
	'' Remove it, and if there is no EOL following,
	'' insert a ':' statement separator.
	xassert(tk_get(x) = TK_SEMI)
	tk_remove(x)
	if (is_whitespace_until_eol(x) = FALSE) then
		tk_insert(x, TK_COLON, NULL)
		x += 1
	end if

	return x
end function

private sub translate_toplevel()
	dim as integer x = 0
	while (tk_get(x) <> TK_EOF)
		select case as const (tk_stmt(x))
		case STMT_EXTERN, STMT_ENUM
			'' Just remove the '{'
			x = remove_following_lbrace(x)

		case STMT_STRUCT
			'' STRUCT -> TYPE
			tk_replace(x, KW_TYPE, NULL)
			'' And also remove the '{'
			x = remove_following_lbrace(x)

		case STMT_ENDEXTERN
			x = translate_compound_end(x, KW_EXTERN)

		case STMT_ENDSTRUCT
			x = translate_compound_end(x, KW_TYPE)

		case STMT_ENDENUM
			x = translate_compound_end(x, KW_ENUM)

		case STMT_ENUMFIELD
			x = translate_enumfield(x)

		case STMT_FIELD
			x = translate_field(x)

		case else
			x += 1

		end select
	wend
end sub

''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

	if (__FB_ARGC__ = 1) then
		print FROG_HELP
		end 0
	end if

	'' Check for command line options
	dim as integer filecount = 0
	for i as integer = 1 to (__FB_ARGC__ - 1)
		dim as zstring ptr arg = __FB_ARGV__[i]
		if (*arg = "--version") then
			print "fbfrog " & FROG_VERSION
			end 0
		elseif (*arg = "--help") then
			print FROG_HELP
			end 0
		elseif (cptr(ubyte ptr, arg)[0] = asc("-")) then
			xoops("unknown option: '" & *arg & "', try --help")
		else
			filecount += 1
		end if
	next
	if (filecount = 0) then
		xoops("no input files")
	end if

	tk_init()

	'' Parse the files specified on the command line
	dim as string hfile, bifile
	for i as integer = 1 to (__FB_ARGC__ - 1)
		dim as zstring ptr arg = __FB_ARGV__[i]
		if (cptr(ubyte ptr, arg)[0] <> asc("-")) then
			hfile = *arg

			print "loading '" & hfile & "'..."
			tk_in_file(hfile)

			print "parsing..."
			parse_toplevel()

			print "translating..."
			fixup_eols()
			translate_toplevel()

			bifile = path_strip_ext(hfile) & ".bi"
			print "emitting '" & bifile & "'..."
			tk_emit_file(bifile)
		end if
	next

	tk_end()
	end 0