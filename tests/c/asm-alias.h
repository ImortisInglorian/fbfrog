extern int a asm("b");
extern int a __asm("b");
extern int a __asm__("b");

void f1(void) __asm("f2");
