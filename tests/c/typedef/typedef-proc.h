typedef int T1(int i);
T1 f11;
T1 f12;
T1 f13;
int x1N(int i);

// Calling convention must be preserved
typedef __attribute__((stdcall)) void T2(void);
T2 f2;
__attribute__((stdcall)) void x2(void);

// Multiple parameters
typedef void T3(int a, short b, float c, double);
T3 f3;
void x3(int a, short b, float c, double);

// Typedefs should be processed recursively
typedef T1 T4;
T4 f4;
int x4(int i);

// Should expand into pointers too (it becomes a function pointer)
static T1 *p1;
static T1 **p2;
static T1 ***p3;
typedef T1 *p4;
void p5(T1 *param);

// CONSTs should be preserved when expanding
static T1 * const c1;
static T1 * * const c2;
static T1 * const * c3;
static T1 * const * const c4;

// cv-qualifiers on function types should be ignored
T1 const qualified1;
static T1 const *qualified2;
static T1 const * const qualified3;
