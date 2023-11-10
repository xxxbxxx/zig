
// includes commented out to make sure the symbols come from the precompiled header.
//#include "includeA.h"
//#include "includeB.h"

#ifndef A_INCLUDED
#error "pch not included"
#endif
#ifndef B_INCLUDED
#error "pch not included"
#endif

int main(int argc, char *argv[])
{
	real a = 0.123;

	if (argc > 1) {
		fprintf(stdout, "abs(%g)=%g\n", a, abs(a));
	}

	return EXIT_SUCCESS;
}
