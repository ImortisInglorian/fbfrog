// @fail @fbfrog -removedefine m
#define m 0 ## 8
enum E {
	A = m
};
