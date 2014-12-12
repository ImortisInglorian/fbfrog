#pragma once

'' The following symbols have been renamed:
''     variable ABS => ABS_
''     variable ABSTRACT => ABSTRACT_
''     variable ACCESS => ACCESS_
''     variable ACOS => ACOS_
''     variable ALIAS => ALIAS_
''     variable ALLOCATE => ALLOCATE_
''     variable AND => AND_
''     variable ANDALSO => ANDALSO_
''     variable ANY => ANY_
''     variable APPEND => APPEND_
''     variable AS => AS_
''     variable ASC => ASC_
''     variable ASIN => ASIN_
''     variable ASM => ASM_
''     variable ASSERT => ASSERT_
''     variable ASSERTWARN => ASSERTWARN_
''     variable ATAN2 => ATAN2_
''     variable ATN => ATN_
''     variable BASE => BASE_
''     variable BEEP => BEEP_
''     variable BIN => BIN_
''     variable BINARY => BINARY_
''     variable BIT => BIT_
''     variable BITRESET => BITRESET_
''     variable BITSET => BITSET_
''     variable BLOAD => BLOAD_
''     variable BSAVE => BSAVE_
''     variable BYREF => BYREF_
''     variable BYTE => BYTE_
''     variable BYVAL => BYVAL_
''     variable CALL => CALL_
''     variable CALLOCATE => CALLOCATE_
''     variable CASE => CASE_
''     variable CAST => CAST_
''     variable CBYTE => CBYTE_
''     variable CDBL => CDBL_
''     variable CDECL => CDECL_
''     variable CHAIN => CHAIN_
''     variable CHDIR => CHDIR_
''     variable CHR => CHR_
''     variable CINT => CINT_
''     variable CIRCLE => CIRCLE_
''     variable CLASS => CLASS_
''     variable CLEAR => CLEAR_
''     variable CLNG => CLNG_
''     variable CLNGINT => CLNGINT_
''     variable CLOSE => CLOSE_
''     variable CLS => CLS_
''     variable COLOR => COLOR_
''     variable COMMAND => COMMAND_
''     variable COMMON => COMMON_
''     variable CONDBROADCAST => CONDBROADCAST_
''     variable CONDCREATE => CONDCREATE_
''     variable CONDDESTROY => CONDDESTROY_
''     variable CONDSIGNAL => CONDSIGNAL_
''     variable CONDWAIT => CONDWAIT_
''     variable CONST => CONST_
''     variable CONSTRUCTOR => CONSTRUCTOR_
''     variable CONTINUE => CONTINUE_
''     variable COS => COS_
''     variable CPTR => CPTR_
''     variable CSHORT => CSHORT_
''     variable CSIGN => CSIGN_
''     variable CSNG => CSNG_
''     variable CSRLIN => CSRLIN_
''     variable CUBYTE => CUBYTE_
''     variable CUINT => CUINT_
''     variable CULNG => CULNG_
''     variable CULNGINT => CULNGINT_
''     variable CUNSG => CUNSG_
''     variable CURDIR => CURDIR_
''     variable CUSHORT => CUSHORT_
''     variable CVD => CVD_
''     variable CVI => CVI_
''     variable CVL => CVL_
''     variable CVLONGINT => CVLONGINT_
''     variable CVS => CVS_
''     variable CVSHORT => CVSHORT_
''     variable DATA => DATA_
''     variable DATE => DATE_
''     variable DEALLOCATE => DEALLOCATE_
''     variable DECLARE => DECLARE_
''     variable DEFBYTE => DEFBYTE_
''     variable DEFDBL => DEFDBL_
''     variable DEFINE => DEFINE_
''     variable DEFINED => DEFINED_
''     variable DEFINT => DEFINT_
''     variable DEFLNG => DEFLNG_
''     variable DEFLONGINT => DEFLONGINT_
''     variable DEFSHORT => DEFSHORT_
''     variable DEFSNG => DEFSNG_
''     variable DEFSTR => DEFSTR_
''     variable DEFUBYTE => DEFUBYTE_
''     variable DEFUINT => DEFUINT_
''     variable DEFULNG => DEFULNG_
''     variable DEFULONGINT => DEFULONGINT_
''     variable DEFUSHORT => DEFUSHORT_
''     variable DELETE => DELETE_
''     variable DESTRUCTOR => DESTRUCTOR_
''     variable DIM => DIM_
''     variable DIR => DIR_
''     variable DO => DO_
''     variable DOUBLE => DOUBLE_
''     variable DRAW => DRAW_
''     variable DYLIBFREE => DYLIBFREE_
''     variable DYLIBLOAD => DYLIBLOAD_
''     variable DYLIBSYMBOL => DYLIBSYMBOL_
''     variable DYNAMIC => DYNAMIC_
''     variable ELSE => ELSE_
''     variable ELSEIF => ELSEIF_
''     variable ENCODING => ENCODING_
''     variable END => END_
''     variable ENDIF => ENDIF_
''     variable ENDMACRO => ENDMACRO_
''     variable ENUM => ENUM_
''     variable ENVIRON => ENVIRON_
''     variable EOF => EOF_
''     variable EQV => EQV_
''     variable ERASE => ERASE_
''     variable ERFN => ERFN_
''     variable ERL => ERL_
''     variable ERMN => ERMN_
''     variable ERR => ERR_
''     variable ERROR => ERROR_
''     variable EXEC => EXEC_
''     variable EXEPATH => EXEPATH_
''     variable EXIT => EXIT_
''     variable EXP => EXP_
''     variable EXPLICIT => EXPLICIT_
''     variable EXPORT => EXPORT_
''     variable EXTENDS => EXTENDS_
''     variable EXTERN => EXTERN_
''     variable FIELD => FIELD_
''     variable FIX => FIX_
''     variable FLIP => FLIP_
''     variable FOR => FOR_
''     variable FRAC => FRAC_
''     variable FRE => FRE_
''     variable FREEFILE => FREEFILE_
''     variable FUNCTION => FUNCTION_
''     variable GET => GET_
''     variable GETJOYSTICK => GETJOYSTICK_
''     variable GETKEY => GETKEY_
''     variable GETMOUSE => GETMOUSE_
''     variable GOSUB => GOSUB_
''     variable GOTO => GOTO_
''     variable HEX => HEX_
''     variable HIBYTE => HIBYTE_
''     variable HIWORD => HIWORD_
''     variable IF => IF_
''     variable IFDEF => IFDEF_
''     variable IFNDEF => IFNDEF_
''     variable IIF => IIF_
''     variable IMAGECONVERTROW => IMAGECONVERTROW_
''     variable IMAGECREATE => IMAGECREATE_
''     variable IMAGEDESTROY => IMAGEDESTROY_
''     variable IMAGEINFO => IMAGEINFO_
''     variable IMP => IMP_
''     variable IMPLEMENTS => IMPLEMENTS_
''     variable IMPORT => IMPORT_
''     variable INCLIB => INCLIB_
''     variable INCLUDE => INCLUDE_
''     variable INKEY => INKEY_
''     variable INP => INP_
''     variable INPUT => INPUT_
''     variable INSTR => INSTR_
''     variable INSTRREV => INSTRREV_
''     variable INT => INT_
''     variable INTEGER => INTEGER_
''     variable IS => IS_
''     variable KILL => KILL_
''     variable LANG => LANG_
''     variable LBOUND => LBOUND_
''     variable LCASE => LCASE_
''     variable LEFT => LEFT_
''     variable LEN => LEN_
''     variable LET => LET_
''     variable LIB => LIB_
''     variable LIBPATH => LIBPATH_
''     variable LINE => LINE_
''     variable LOBYTE => LOBYTE_
''     variable LOC => LOC_
''     variable LOCAL => LOCAL_
''     variable LOCATE => LOCATE_
''     variable LOCK => LOCK_
''     variable LOF => LOF_
''     variable LOG => LOG_
''     variable LONG => LONG_
''     variable LONGINT => LONGINT_
''     variable LOOP => LOOP_
''     variable LOWORD => LOWORD_
''     variable LPOS => LPOS_
''     variable LPRINT => LPRINT_
''     variable LSET => LSET_
''     variable LTRIM => LTRIM_
''     variable MACRO => MACRO_
''     variable MID => MID_
''     variable MKD => MKD_
''     variable MKDIR => MKDIR_
''     variable MKI => MKI_
''     variable MKL => MKL_
''     variable MKLONGINT => MKLONGINT_
''     variable MKS => MKS_
''     variable MKSHORT => MKSHORT_
''     variable MOD => MOD_
''     variable MULTIKEY => MULTIKEY_
''     variable MUTEXCREATE => MUTEXCREATE_
''     variable MUTEXDESTROY => MUTEXDESTROY_
''     variable MUTEXLOCK => MUTEXLOCK_
''     variable MUTEXUNLOCK => MUTEXUNLOCK_
''     variable NAME => NAME_
''     variable NAMESPACE => NAMESPACE_
''     variable NEW => NEW_
''     variable NEXT => NEXT_
''     variable NOT => NOT_
''     variable OBJECT => OBJECT_
''     variable OCT => OCT_
''     variable OFFSETOF => OFFSETOF_
''     variable ON => ON_
''     variable OPEN => OPEN_
''     variable OPERATOR => OPERATOR_
''     variable OPTION => OPTION_
''     variable OR => OR_
''     variable ORELSE => ORELSE_
''     variable OUT => OUT_
''     variable OUTPUT => OUTPUT_
''     variable OVERLOAD => OVERLOAD_
''     variable PAINT => PAINT_
''     variable PALETTE => PALETTE_
''     variable PASCAL => PASCAL_
''     variable PCOPY => PCOPY_
''     variable PEEK => PEEK_
''     variable PMAP => PMAP_
''     variable POINT => POINT_
''     variable POINTCOORD => POINTCOORD_
''     variable POINTER => POINTER_
''     variable POKE => POKE_
''     variable POS => POS_
''     variable PRAGMA => PRAGMA_
''     variable PRESERVE => PRESERVE_
''     variable PRESET => PRESET_
''     variable PRINT => PRINT_
''     variable PRIVATE => PRIVATE_
''     variable PROCPTR => PROCPTR_
''     variable PROPERTY => PROPERTY_
''     variable PROTECTED => PROTECTED_
''     variable PSET => PSET_
''     variable PTR => PTR_
''     variable PUBLIC => PUBLIC_
''     variable PUT => PUT_
''     variable RANDOM => RANDOM_
''     variable RANDOMIZE => RANDOMIZE_
''     variable READ => READ_
''     variable REALLOCATE => REALLOCATE_
''     variable REDIM => REDIM_
''     variable REM => REM_
''     variable RESET => RESET_
''     variable RESTORE => RESTORE_
''     variable RESUME => RESUME_
''     variable RETURN => RETURN_
''     variable RGB => RGB_
''     variable RGBA => RGBA_
''     variable RIGHT => RIGHT_
''     variable RMDIR => RMDIR_
''     variable RND => RND_
''     variable RSET => RSET_
''     variable RTRIM => RTRIM_
''     variable RUN => RUN_
''     variable SADD => SADD_
''     variable SCOPE => SCOPE_
''     variable SCREEN => SCREEN_
''     variable SCREENCONTROL => SCREENCONTROL_
''     variable SCREENCOPY => SCREENCOPY_
''     variable SCREENEVENT => SCREENEVENT_
''     variable SCREENGLPROC => SCREENGLPROC_
''     variable SCREENINFO => SCREENINFO_
''     variable SCREENLIST => SCREENLIST_
''     variable SCREENLOCK => SCREENLOCK_
''     variable SCREENPTR => SCREENPTR_
''     variable SCREENRES => SCREENRES_
''     variable SCREENSET => SCREENSET_
''     variable SCREENSYNC => SCREENSYNC_
''     variable SCREENUNLOCK => SCREENUNLOCK_
''     variable SEEK => SEEK_
''     variable SELECT => SELECT_
''     variable SETDATE => SETDATE_
''     variable SETENVIRON => SETENVIRON_
''     variable SETMOUSE => SETMOUSE_
''     variable SETTIME => SETTIME_
''     variable SGN => SGN_
''     variable SHARED => SHARED_
''     variable SHELL => SHELL_
''     variable SHL => SHL_
''     variable SHORT => SHORT_
''     variable SHR => SHR_
''     variable SIN => SIN_
''     variable SINGLE => SINGLE_
''     variable SIZEOF => SIZEOF_
''     variable SLEEP => SLEEP_
''     variable SPACE => SPACE_
''     variable SPC => SPC_
''     variable SQR => SQR_
''     variable STATIC => STATIC_
''     variable STDCALL => STDCALL_
''     variable STEP => STEP_
''     variable STOP => STOP_
''     variable STR => STR_
''     variable STRING => STRING_
''     variable STRPTR => STRPTR_
''     variable SUB => SUB_
''     variable SWAP => SWAP_
''     variable SYSTEM => SYSTEM_
''     variable TAB => TAB_
''     variable TAN => TAN_
''     variable THEN => THEN_
''     variable THREADCALL => THREADCALL_
''     variable THREADCREATE => THREADCREATE_
''     variable THREADWAIT => THREADWAIT_
''     variable TIME => TIME_
''     variable TIMER => TIMER_
''     variable TO => TO_
''     variable TRIM => TRIM_
''     variable TYPE => TYPE_
''     variable TYPEOF => TYPEOF_
''     variable UBOUND => UBOUND_
''     variable UBYTE => UBYTE_
''     variable UCASE => UCASE_
''     variable UINTEGER => UINTEGER_
''     variable ULONG => ULONG_
''     variable ULONGINT => ULONGINT_
''     variable UNDEF => UNDEF_
''     variable UNION => UNION_
''     variable UNLOCK => UNLOCK_
''     variable UNSIGNED => UNSIGNED_
''     variable UNTIL => UNTIL_
''     variable USHORT => USHORT_
''     variable USING => USING_
''     variable VAL => VAL_
''     variable VALINT => VALINT_
''     variable VALLNG => VALLNG_
''     variable VALUINT => VALUINT_
''     variable VALULNG => VALULNG_
''     variable VAR => VAR_
''     variable VARPTR => VARPTR_
''     variable VA_ARG => VA_ARG_
''     variable VA_FIRST => VA_FIRST_
''     variable VA_NEXT => VA_NEXT_
''     variable VIEW => VIEW_
''     variable VIRTUAL => VIRTUAL_
''     variable WAIT => WAIT_
''     variable WBIN => WBIN_
''     variable WCHR => WCHR_
''     variable WEND => WEND_
''     variable WHEX => WHEX_
''     variable WHILE => WHILE_
''     variable WIDTH => WIDTH_
''     variable WINDOW => WINDOW_
''     variable WINDOWTITLE => WINDOWTITLE_
''     variable WINPUT => WINPUT_
''     variable WITH => WITH_
''     variable WOCT => WOCT_
''     variable WRITE => WRITE_
''     variable WSPACE => WSPACE_
''     variable WSTR => WSTR_
''     variable WSTRING => WSTRING_
''     variable XOR => XOR_
''     variable ZSTRING => ZSTRING_
''     variable __DATE_ISO__ => __DATE_ISO___
''     variable __DATE__ => __DATE___
''     variable __FB_BACKEND__ => __FB_BACKEND___
''     variable __FB_BUILD_DATE__ => __FB_BUILD_DATE___
''     variable __FB_DEBUG__ => __FB_DEBUG___
''     variable __FB_ERR__ => __FB_ERR___
''     variable __FB_FPMODE__ => __FB_FPMODE___
''     variable __FB_FPU__ => __FB_FPU___
''     variable __FB_GCC__ => __FB_GCC___
''     variable __FB_LANG__ => __FB_LANG___
''     variable __FB_LINUX__ => __FB_LINUX___
''     variable __FB_MAIN__ => __FB_MAIN___
''     variable __FB_MIN_VERSION__ => __FB_MIN_VERSION___
''     variable __FB_MT__ => __FB_MT___
''     variable __FB_OPTION_BYVAL__ => __FB_OPTION_BYVAL___
''     variable __FB_OPTION_DYNAMIC__ => __FB_OPTION_DYNAMIC___
''     variable __FB_OPTION_ESCAPE__ => __FB_OPTION_ESCAPE___
''     variable __FB_OPTION_EXPLICIT__ => __FB_OPTION_EXPLICIT___
''     variable __FB_OPTION_GOSUB__ => __FB_OPTION_GOSUB___
''     variable __FB_OPTION_PRIVATE__ => __FB_OPTION_PRIVATE___
''     variable __FB_OUT_DLL__ => __FB_OUT_DLL___
''     variable __FB_OUT_EXE__ => __FB_OUT_EXE___
''     variable __FB_OUT_LIB__ => __FB_OUT_LIB___
''     variable __FB_OUT_OBJ__ => __FB_OUT_OBJ___
''     variable __FB_SIGNATURE__ => __FB_SIGNATURE___
''     variable __FB_UNIX__ => __FB_UNIX___
''     variable __FB_VECTORIZE__ => __FB_VECTORIZE___
''     variable __FB_VERSION__ => __FB_VERSION___
''     variable __FB_VER_MAJOR__ => __FB_VER_MAJOR___
''     variable __FB_VER_MINOR__ => __FB_VER_MINOR___
''     variable __FB_VER_PATCH__ => __FB_VER_PATCH___
''     variable __FILE_NQ__ => __FILE_NQ___
''     variable __FILE__ => __FILE___
''     variable __FUNCTION_NQ__ => __FUNCTION_NQ___
''     variable __FUNCTION__ => __FUNCTION___
''     variable __LINE__ => __LINE___
''     variable __PATH__ => __PATH___
''     variable __TIME__ => __TIME___
''     #define integer => integer__
''     enum constant string => string__
''     procedure open => open__
''     #define INT => INT__
''     #define Int => Int___
''     variable base => base__
''     variable window => window__
''     variable windowtitle => windowtitle__
''     struct Width => Width_
''     inside struct Width_ alias "Width":
''         field _ => __
''     typedef type => type_

extern "C"

dim shared ABS_ as long
dim shared ABSTRACT_ as long
dim shared ACCESS_ as long
dim shared ACOS_ as long
dim shared ALIAS_ as long
dim shared ALLOCATE_ as long
dim shared AND_ as long
dim shared ANDALSO_ as long
dim shared ANY_ as long
dim shared APPEND_ as long
dim shared AS_ as long
dim shared ASC_ as long
dim shared ASIN_ as long
dim shared ASM_ as long
dim shared ASSERT_ as long
dim shared ASSERTWARN_ as long
dim shared ATAN2_ as long
dim shared ATN_ as long
dim shared BASE_ as long
dim shared BEEP_ as long
dim shared BIN_ as long
dim shared BINARY_ as long
dim shared BIT_ as long
dim shared BITRESET_ as long
dim shared BITSET_ as long
dim shared BLOAD_ as long
dim shared BSAVE_ as long
dim shared BYREF_ as long
dim shared BYTE_ as long
dim shared BYVAL_ as long
dim shared CALL_ as long
dim shared CALLOCATE_ as long
dim shared CASE_ as long
dim shared CAST_ as long
dim shared CBYTE_ as long
dim shared CDBL_ as long
dim shared CDECL_ as long
dim shared CHAIN_ as long
dim shared CHDIR_ as long
dim shared CHR_ as long
dim shared CINT_ as long
dim shared CIRCLE_ as long
dim shared CLASS_ as long
dim shared CLEAR_ as long
dim shared CLNG_ as long
dim shared CLNGINT_ as long
dim shared CLOSE_ as long
dim shared CLS_ as long
dim shared COLOR_ as long
dim shared COMMAND_ as long
dim shared COMMON_ as long
dim shared CONDBROADCAST_ as long
dim shared CONDCREATE_ as long
dim shared CONDDESTROY_ as long
dim shared CONDSIGNAL_ as long
dim shared CONDWAIT_ as long
dim shared CONST_ as long
dim shared CONSTRUCTOR_ as long
dim shared CONTINUE_ as long
dim shared COS_ as long
dim shared CPTR_ as long
dim shared CSHORT_ as long
dim shared CSIGN_ as long
dim shared CSNG_ as long
dim shared CSRLIN_ as long
dim shared CUBYTE_ as long
dim shared CUINT_ as long
dim shared CULNG_ as long
dim shared CULNGINT_ as long
dim shared CUNSG_ as long
dim shared CURDIR_ as long
dim shared CUSHORT_ as long
dim shared CVD_ as long
dim shared CVI_ as long
dim shared CVL_ as long
dim shared CVLONGINT_ as long
dim shared CVS_ as long
dim shared CVSHORT_ as long
dim shared DATA_ as long
dim shared DATE_ as long
dim shared DEALLOCATE_ as long
dim shared DECLARE_ as long
dim shared DEFBYTE_ as long
dim shared DEFDBL_ as long
dim shared DEFINE_ as long
dim shared DEFINED_ as long
dim shared DEFINT_ as long
dim shared DEFLNG_ as long
dim shared DEFLONGINT_ as long
dim shared DEFSHORT_ as long
dim shared DEFSNG_ as long
dim shared DEFSTR_ as long
dim shared DEFUBYTE_ as long
dim shared DEFUINT_ as long
dim shared DEFULNG_ as long
dim shared DEFULONGINT_ as long
dim shared DEFUSHORT_ as long
dim shared DELETE_ as long
dim shared DESTRUCTOR_ as long
dim shared DIM_ as long
dim shared DIR_ as long
dim shared DO_ as long
dim shared DOUBLE_ as long
dim shared DRAW_ as long
dim shared DYLIBFREE_ as long
dim shared DYLIBLOAD_ as long
dim shared DYLIBSYMBOL_ as long
dim shared DYNAMIC_ as long
dim shared ELSE_ as long
dim shared ELSEIF_ as long
dim shared ENCODING_ as long
dim shared END_ as long
dim shared ENDIF_ as long
dim shared ENDMACRO_ as long
dim shared ENUM_ as long
dim shared ENVIRON_ as long
dim shared EOF_ as long
dim shared EQV_ as long
dim shared ERASE_ as long
dim shared ERFN_ as long
dim shared ERL_ as long
dim shared ERMN_ as long
dim shared ERR_ as long
dim shared ERROR_ as long
dim shared EXEC_ as long
dim shared EXEPATH_ as long
dim shared EXIT_ as long
dim shared EXP_ as long
dim shared EXPLICIT_ as long
dim shared EXPORT_ as long
dim shared EXTENDS_ as long
dim shared EXTERN_ as long
dim shared FIELD_ as long
dim shared FIX_ as long
dim shared FLIP_ as long
dim shared FOR_ as long
dim shared FRAC_ as long
dim shared FRE_ as long
dim shared FREEFILE_ as long
dim shared FUNCTION_ as long
dim shared GET_ as long
dim shared GETJOYSTICK_ as long
dim shared GETKEY_ as long
dim shared GETMOUSE_ as long
dim shared GOSUB_ as long
dim shared GOTO_ as long
dim shared HEX_ as long
dim shared HIBYTE_ as long
dim shared HIWORD_ as long
dim shared IF_ as long
dim shared IFDEF_ as long
dim shared IFNDEF_ as long
dim shared IIF_ as long
dim shared IMAGECONVERTROW_ as long
dim shared IMAGECREATE_ as long
dim shared IMAGEDESTROY_ as long
dim shared IMAGEINFO_ as long
dim shared IMP_ as long
dim shared IMPLEMENTS_ as long
dim shared IMPORT_ as long
dim shared INCLIB_ as long
dim shared INCLUDE_ as long
dim shared INKEY_ as long
dim shared INP_ as long
dim shared INPUT_ as long
dim shared INSTR_ as long
dim shared INSTRREV_ as long
dim shared INT_ as long
dim shared INTEGER_ as long
dim shared IS_ as long
dim shared KILL_ as long
dim shared LANG_ as long
dim shared LBOUND_ as long
dim shared LCASE_ as long
dim shared LEFT_ as long
dim shared LEN_ as long
dim shared LET_ as long
dim shared LIB_ as long
dim shared LIBPATH_ as long
dim shared LINE_ as long
dim shared LOBYTE_ as long
dim shared LOC_ as long
dim shared LOCAL_ as long
dim shared LOCATE_ as long
dim shared LOCK_ as long
dim shared LOF_ as long
dim shared LOG_ as long
dim shared LONG_ as long
dim shared LONGINT_ as long
dim shared LOOP_ as long
dim shared LOWORD_ as long
dim shared LPOS_ as long
dim shared LPRINT_ as long
dim shared LSET_ as long
dim shared LTRIM_ as long
dim shared MACRO_ as long
dim shared MID_ as long
dim shared MKD_ as long
dim shared MKDIR_ as long
dim shared MKI_ as long
dim shared MKL_ as long
dim shared MKLONGINT_ as long
dim shared MKS_ as long
dim shared MKSHORT_ as long
dim shared MOD_ as long
dim shared MULTIKEY_ as long
dim shared MUTEXCREATE_ as long
dim shared MUTEXDESTROY_ as long
dim shared MUTEXLOCK_ as long
dim shared MUTEXUNLOCK_ as long
dim shared NAME_ as long
dim shared NAMESPACE_ as long
dim shared NEW_ as long
dim shared NEXT_ as long
dim shared NOT_ as long
dim shared OBJECT_ as long
dim shared OCT_ as long
dim shared OFFSETOF_ as long
dim shared ON_ as long
dim shared OPEN_ as long
dim shared OPERATOR_ as long
dim shared OPTION_ as long
dim shared OR_ as long
dim shared ORELSE_ as long
dim shared OUT_ as long
dim shared OUTPUT_ as long
dim shared OVERLOAD_ as long
dim shared PAINT_ as long
dim shared PALETTE_ as long
dim shared PASCAL_ as long
dim shared PCOPY_ as long
dim shared PEEK_ as long
dim shared PMAP_ as long
dim shared POINT_ as long
dim shared POINTCOORD_ as long
dim shared POINTER_ as long
dim shared POKE_ as long
dim shared POS_ as long
dim shared PRAGMA_ as long
dim shared PRESERVE_ as long
dim shared PRESET_ as long
dim shared PRINT_ as long
dim shared PRIVATE_ as long
dim shared PROCPTR_ as long
dim shared PROPERTY_ as long
dim shared PROTECTED_ as long
dim shared PSET_ as long
dim shared PTR_ as long
dim shared PUBLIC_ as long
dim shared PUT_ as long
dim shared RANDOM_ as long
dim shared RANDOMIZE_ as long
dim shared READ_ as long
dim shared REALLOCATE_ as long
dim shared REDIM_ as long
dim shared REM_ as long
dim shared RESET_ as long
dim shared RESTORE_ as long
dim shared RESUME_ as long
dim shared RETURN_ as long
dim shared RGB_ as long
dim shared RGBA_ as long
dim shared RIGHT_ as long
dim shared RMDIR_ as long
dim shared RND_ as long
dim shared RSET_ as long
dim shared RTRIM_ as long
dim shared RUN_ as long
dim shared SADD_ as long
dim shared SCOPE_ as long
dim shared SCREEN_ as long
dim shared SCREENCONTROL_ as long
dim shared SCREENCOPY_ as long
dim shared SCREENEVENT_ as long
dim shared SCREENGLPROC_ as long
dim shared SCREENINFO_ as long
dim shared SCREENLIST_ as long
dim shared SCREENLOCK_ as long
dim shared SCREENPTR_ as long
dim shared SCREENRES_ as long
dim shared SCREENSET_ as long
dim shared SCREENSYNC_ as long
dim shared SCREENUNLOCK_ as long
dim shared SEEK_ as long
dim shared SELECT_ as long
dim shared SETDATE_ as long
dim shared SETENVIRON_ as long
dim shared SETMOUSE_ as long
dim shared SETTIME_ as long
dim shared SGN_ as long
dim shared SHARED_ as long
dim shared SHELL_ as long
dim shared SHL_ as long
dim shared SHORT_ as long
dim shared SHR_ as long
dim shared SIN_ as long
dim shared SINGLE_ as long
dim shared SIZEOF_ as long
dim shared SLEEP_ as long
dim shared SPACE_ as long
dim shared SPC_ as long
dim shared SQR_ as long
dim shared STATIC_ as long
dim shared STDCALL_ as long
dim shared STEP_ as long
dim shared STOP_ as long
dim shared STR_ as long
dim shared STRING_ as long
dim shared STRPTR_ as long
dim shared SUB_ as long
dim shared SWAP_ as long
dim shared SYSTEM_ as long
dim shared TAB_ as long
dim shared TAN_ as long
dim shared THEN_ as long
dim shared THREADCALL_ as long
dim shared THREADCREATE_ as long
dim shared THREADWAIT_ as long
dim shared TIME_ as long
dim shared TIMER_ as long
dim shared TO_ as long
dim shared TRIM_ as long
dim shared TYPE_ as long
dim shared TYPEOF_ as long
dim shared UBOUND_ as long
dim shared UBYTE_ as long
dim shared UCASE_ as long
dim shared UINTEGER_ as long
dim shared ULONG_ as long
dim shared ULONGINT_ as long
dim shared UNDEF_ as long
dim shared UNION_ as long
dim shared UNLOCK_ as long
dim shared UNSIGNED_ as long
dim shared UNTIL_ as long
dim shared USHORT_ as long
dim shared USING_ as long
dim shared VAL_ as long
dim shared VALINT_ as long
dim shared VALLNG_ as long
dim shared VALUINT_ as long
dim shared VALULNG_ as long
dim shared VAR_ as long
dim shared VARPTR_ as long
dim shared VA_ARG_ as long
dim shared VA_FIRST_ as long
dim shared VA_NEXT_ as long
dim shared VIEW_ as long
dim shared VIRTUAL_ as long
dim shared WAIT_ as long
dim shared WBIN_ as long
dim shared WCHR_ as long
dim shared WEND_ as long
dim shared WHEX_ as long
dim shared WHILE_ as long
dim shared WIDTH_ as long
dim shared WINDOW_ as long
dim shared WINDOWTITLE_ as long
dim shared WINPUT_ as long
dim shared WITH_ as long
dim shared WOCT_ as long
dim shared WRITE_ as long
dim shared WSPACE_ as long
dim shared WSTR_ as long
dim shared WSTRING_ as long
dim shared XOR_ as long
dim shared ZSTRING_ as long
dim shared __DATE_ISO___ as long
dim shared __DATE___ as long
dim shared __FB_BACKEND___ as long
dim shared __FB_BUILD_DATE___ as long
dim shared __FB_DEBUG___ as long
dim shared __FB_ERR___ as long
dim shared __FB_FPMODE___ as long
dim shared __FB_FPU___ as long
dim shared __FB_GCC___ as long
dim shared __FB_LANG___ as long
dim shared __FB_LINUX___ as long
dim shared __FB_MAIN___ as long
dim shared __FB_MIN_VERSION___ as long
dim shared __FB_MT___ as long
dim shared __FB_OPTION_BYVAL___ as long
dim shared __FB_OPTION_DYNAMIC___ as long
dim shared __FB_OPTION_ESCAPE___ as long
dim shared __FB_OPTION_EXPLICIT___ as long
dim shared __FB_OPTION_GOSUB___ as long
dim shared __FB_OPTION_PRIVATE___ as long
dim shared __FB_OUT_DLL___ as long
dim shared __FB_OUT_EXE___ as long
dim shared __FB_OUT_LIB___ as long
dim shared __FB_OUT_OBJ___ as long
dim shared __FB_SIGNATURE___ as long
dim shared __FB_UNIX___ as long
dim shared __FB_VECTORIZE___ as long
dim shared __FB_VERSION___ as long
dim shared __FB_VER_MAJOR___ as long
dim shared __FB_VER_MINOR___ as long
dim shared __FB_VER_PATCH___ as long
dim shared __FILE_NQ___ as long
dim shared __FILE___ as long
dim shared __FUNCTION_NQ___ as long
dim shared __FUNCTION___ as long
dim shared __LINE___ as long
dim shared __PATH___ as long
dim shared __TIME___ as long

#define integer__

enum
	string__
end enum

declare sub open__ alias "open"()

#define INT__ 1
#define Int___ 2

extern     base__ alias "base" as long
dim shared base__ as long
dim shared window__ as long
extern windowtitle__ alias "windowtitle" as long

type Width_
	as long as
	as long Static
	as long dim
	as long redim
	as long declare
	as long end
	as long type
	as long Union
	as long Enum
	as long Const
	as long rem
	as long Public
	as long Private
	as long Protected
	inT as long
	If as long
	FLOAT as long
	__ as long
end type

type type_ as long

end extern
