// @fail @fbfrog -removedefine m
#define m 0x ## G
enum E {
	A = m
};
