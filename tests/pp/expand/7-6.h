#ifdef A
	#ifdef B
		#define EXPANDTHIS
	#else
		#define EXPANDTHIS
	#endif
	EXPANDTHIS void f(void);
#else
	EXPANDTHIS void f(void);
#endif