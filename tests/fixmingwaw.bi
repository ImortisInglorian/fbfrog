#pragma once

#ifdef UNICODE
	#define __MINGW_NAME_AW(s) s##W
	#define __MINGW_NAME_AW_EXT(func, ext) func##W##ext
	#define __MINGW_NAME_UAW(func) func##_W
	#define __MINGW_NAME_UAW_EXT(func, ext) func##_W_##ext
	#define CreateWindowEx CreateWindowExW
	#define SendMessage SendMessageW
	#define Function1 Function1W123
	#define Function2 Function2_W
	#define Function3 Function3_W_123
#else
	#define __MINGW_NAME_AW(s) s##A
	#define __MINGW_NAME_AW_EXT(func, ext) func##A##ext
	#define __MINGW_NAME_UAW(func) func##_A
	#define __MINGW_NAME_UAW_EXT(func, ext) func##_A_##ext
	#define CreateWindowEx CreateWindowExA
	#define SendMessage SendMessageA
	#define Function1 Function1A123
	#define Function2 Function2_A
	#define Function3 Function3_A_123
#endif

#define CONST1A 1
#define CONST1W 2

#ifdef UNICODE
	#define CONST1 CONST1W
#else
	#define CONST1 CONST1A
#endif