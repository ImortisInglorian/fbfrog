// @fbfrog -whitespace -nonamefixup

__attribute__((warn_unused_result))     void f(void);
__attribute__((__warn_unused_result__)) void f(void);

__attribute__((noreturn))     void f(void);
__attribute__((__noreturn__)) void f(void);

__attribute__((malloc))     void f(void);
__attribute__((__malloc__)) void f(void);

__attribute__((deprecated))     void f(void);
__attribute__((__deprecated__)) void f(void);

__attribute__((deprecated("message")))     void f(void);
__attribute__((__deprecated__("message"))) void f(void);

void *malloc(size_t) __attribute__((  alloc_size  (1)));
void *malloc(size_t) __attribute__((__alloc_size__(1)));
void *calloc(size_t, size_t) __attribute__((  alloc_size  (1, 2)));
void *calloc(size_t, size_t) __attribute__((__alloc_size__(1, 2)));
void *realloc(void *, size_t) __attribute__((  alloc_size  (2)));
void *realloc(void *, size_t) __attribute__((__alloc_size__(2)));

__cdecl                    void f(void);
__attribute__((cdecl))     void f(void);
__attribute__((__cdecl__)) void f(void);

__stdcall                    void f(void);
__attribute__((stdcall))     void f(void);
__attribute__((__stdcall__)) void f(void);


static int before_base_type;
__attribute__((stdcall)) void f(void);

static int behind_base_type;
void __attribute__((stdcall)) f(void);

static int in_nested_declarator;
void (__attribute__((stdcall)) f)(void);

static int at_end_of_declarator;
void f(void) __attribute__((stdcall));
void f(int i __attribute__((deprecated)) = 0);

static int before_extern;
__attribute__((stdcall)) extern void f(void);

static int between_extern_and_base_type;
extern __attribute__((stdcall)) void f(void);

static int in_middle_of_base_type;
const __attribute__((stdcall)) short f(void);

static int all_should_be_stdcall;
__attribute__((stdcall)) void f1(void), f2(void);
void __attribute__((stdcall)) f1(void), f2(void);

static int only_f1_should_be_stdcall;
void (__attribute__((stdcall)) f1)(void), f2(void);
void f1(void) __attribute__((stdcall)), f2(void);

static int only_f2_should_be_stdcall;
void f1(void), __attribute__((stdcall)) f2(void);
void f1(void), (__attribute__((stdcall)) f2)(void);
void f1(void), f2(void) __attribute__((stdcall));

static int all_stdcall_function_pointers;
extern void (__attribute__((stdcall)) *f1)(void);
extern void (* __attribute__((stdcall)) f1)(void);
extern void __attribute__((stdcall)) (*f1)(void);
extern __attribute__((stdcall)) void (*f1)(void);
extern void (*f1)(void) __attribute__((stdcall));

extern int separator1;
    //      function f( byval a as long ) as sub stdcall( byval b as long )
extern int _function_f__byval_a_as_long___as_sub_stdcall__byval_b_as_long;
void (__attribute__((stdcall)) * f(int a))(int b);

extern int separator2;
    //      function f( byval a as long ) as sub stdcall( byval b as long )
extern int _function_f__byval_a_as_long___as_sub_stdcall__byval_b_as_long;
void (* __attribute__((stdcall)) f(int a))(int b);

extern int separator3;
    //      function f stdcall( byval a as long ) as sub( byval b as long )
extern int _function_f_stdcall__byval_a_as_long___as_sub__byval_b_as_long;
__attribute__((stdcall)) void (*f(int a))(int b);

extern int separator4;
    //      function f stdcall( byval a as long ) as sub( byval b as long )
extern int _function_f_stdcall__byval_a_as_long___as_sub__byval_b_as_long;
void __attribute__((stdcall)) (*f(int a))(int b);

extern int separator5;
    //      function f stdcall( byval a as long ) as sub( byval b as long )
extern int _function_f_stdcall__byval_a_as_long___as_sub__byval_b_as_long;
void (*f(int a))(int b) __attribute__((stdcall));

extern int separator6;
    //      function f stdcall( byval a as long ) as function( byval b as long ) as sub( byval c as long )
extern int _function_f_stdcall__byval_a_as_long___as_function__byval_b_as_long___as_sub__byval_c_as_long;
__attribute__((stdcall)) void (*(*f(int a))(int b))(int c);

extern int separator7;
    //      function f stdcall( byval a as long ) as function( byval b as long ) as sub( byval c as long )
extern int _function_f_stdcall__byval_a_as_long___as_function__byval_b_as_long___as_sub__byval_c_as_long;
void __attribute__((stdcall)) (*(*f(int a))(int b))(int c);

extern int separator8;
    //      function f stdcall( byval a as long ) as function( byval b as long ) as sub( byval c as long )
extern int _function_f_stdcall__byval_a_as_long___as_function__byval_b_as_long___as_sub__byval_c_as_long;
void (*(*f(int a))(int b))(int c) __attribute__((stdcall));

extern int separator9;
    //      function f( byval a as long ) as function( byval b as long ) as sub stdcall( byval c as long )
extern int _function_f__byval_a_as_long___as_function__byval_b_as_long___as_sub_stdcall__byval_c_as_long;
void (__attribute__((stdcall)) *(*f(int a))(int b))(int c);

extern int separator10;
    //      function f( byval a as long ) as function stdcall( byval b as long ) as sub( byval c as long )
extern int _function_f__byval_a_as_long___as_function_stdcall__byval_b_as_long___as_sub__byval_c_as_long;
void (*(__attribute__((stdcall)) *f(int a))(int b))(int c);

extern int separator11;
    //     p as function stdcall( byval a as long ) as sub( byval b as long )
extern int p_as_function_stdcall__byval_a_as_long___as_sub__byval_b_as_long;
extern __attribute__((stdcall)) void (*(*p)(int a))(int b);
extern void (*(__attribute__((stdcall)) *p)(int a))(int b);
extern void (*(*p)(int a))(int b) __attribute__((stdcall));

extern int separator12;
    //     p as function( byval a as long ) as sub stdcall( byval b as long )
extern int p_as_function__byval_a_as_long___as_sub_stdcall__byval_b_as_long;
extern void (__attribute__((stdcall)) *(*p)(int a))(int b);

extern int separator13;
    //      sub f stdcall( )
extern int _sub_f_stdcall;
void   (__attribute__((stdcall)) f)  (void);
void  ((__attribute__((stdcall)) f)) (void);
void (((__attribute__((stdcall)) f)))(void);

extern int separator14;
    //      function f stdcall( ) as sub( )
extern int _function_f_stdcall____as_sub;
void (*  (__attribute__((stdcall)) f)  (void))(void);
void (* ((__attribute__((stdcall)) f)) (void))(void);
void (*(((__attribute__((stdcall)) f)))(void))(void);

extern int separator15;
    //     p as sub stdcall( )
extern int p_as_sub_stdcall;
extern void (  __attribute__((stdcall))    *p     )(void);
extern void (  __attribute__((stdcall))   (*p)    )(void);
extern void (  __attribute__((stdcall))  ((*p))   )(void);
extern void (  __attribute__((stdcall)) (((*p)))  )(void);
extern void ( (__attribute__((stdcall))    *p   ) )(void);
extern void ( (__attribute__((stdcall))   (*p)  ) )(void);
extern void ( (__attribute__((stdcall))  ((*p)) ) )(void);
extern void ( (__attribute__((stdcall)) (((*p)))) )(void);
extern void (((__attribute__((stdcall))    *p   )))(void);
extern void (((__attribute__((stdcall))   (*p)  )))(void);
extern void (((__attribute__((stdcall))  ((*p)) )))(void);
extern void (((__attribute__((stdcall)) (((*p))))))(void);
extern void (  __attribute__((stdcall))    *(p)     )(void);
extern void (  __attribute__((stdcall))   (*(p))    )(void);
extern void (  __attribute__((stdcall))  ((*(p)))   )(void);
extern void (  __attribute__((stdcall)) (((*(p))))  )(void);
extern void ( (__attribute__((stdcall))    *(p)   ) )(void);
extern void ( (__attribute__((stdcall))   (*(p))  ) )(void);
extern void ( (__attribute__((stdcall))  ((*(p))) ) )(void);
extern void ( (__attribute__((stdcall)) (((*(p))))) )(void);
extern void (((__attribute__((stdcall))    *(p)   )))(void);
extern void (((__attribute__((stdcall))   (*(p))  )))(void);
extern void (((__attribute__((stdcall))  ((*(p))) )))(void);
extern void (((__attribute__((stdcall)) (((*(p)))))))(void);

// Lots of cdecl procedures to get fbfrog to generate Extern "C" instead of Extern "Windows"
void f(void);
void f(void);
void f(void);
void f(void);
void f(void);
void f(void);
void f(void);
void f(void);
void f(void);
void f(void);
void f(void);
void f(void);
void f(void);
void f(void);
void f(void);
void f(void);
void f(void);
void f(void);
void f(void);
void f(void);
void f(void);
void f(void);
void f(void);
void f(void);
void f(void);
void f(void);
void f(void);
void f(void);
void f(void);
void f(void);

struct __attribute__((packed)) A1 { short a; int b; };
struct __attribute__((__packed__)) A2 { short a; int b; };
struct A3 { short a; int b; } __attribute__((packed));
struct __attribute__((packed)) A4 { short a; int b; } A4_;
struct A5 { short a; int b; } __attribute__((packed)) A5_;

typedef struct __attribute__((packed)) B1 { short a; int b; } UDT4;
typedef struct B2 { short a; int b; } __attribute__((packed)) UDT5;
typedef struct B3 { short a; int b; } __attribute__((packed)) (*PFUDT6)(void);

// stdcall here is wrong, and should be ignored
typedef struct C1 { short a; int b; }                         __attribute__((stdcall)) (*PFC1)(void);
typedef struct C2 { short a; int b; } __attribute__((packed)) __attribute__((stdcall)) (*PFC2)(void);
typedef struct C3 { short a; int b; } __attribute__((packed, stdcall))                 (*PFC3)(void);
typedef struct C4 { short a; int b; }                         __attribute__((stdcall)) FC4(void);
typedef struct C5 { short a; int b; } __attribute__((packed)) __attribute__((stdcall)) FC5(void);
typedef struct C6 { short a; int b; } __attribute__((packed, stdcall))                 FC6(void);
        struct D1 { short a; int b; }                         __attribute__((stdcall)) (*PFD1)(void);
        struct D2 { short a; int b; } __attribute__((packed)) __attribute__((stdcall)) (*PFD2)(void);
        struct D3 { short a; int b; } __attribute__((packed, stdcall))                 (*PFD3)(void);
        struct D4 { short a; int b; }                         __attribute__((stdcall)) FD4(void);
        struct D5 { short a; int b; } __attribute__((packed)) __attribute__((stdcall)) FD5(void);
        struct D6 { short a; int b; } __attribute__((packed, stdcall))                 FD6(void);

__extension__ typedef signed long long myint64;

extern const volatile int *a;
