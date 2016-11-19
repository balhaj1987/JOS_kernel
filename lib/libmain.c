// Called from entry.S to get us going.
// entry.S already took care of defining envs, pages, uvpd, and uvpt.

#include <inc/lib.h>

extern void umain(int argc, char **argv);

const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	 unsigned envid_u = sys_getenvid();
	 thisenv = &envs[ENVX(envid_u)];

	//cprintf(" envid_u = %x  /////  ENVX(envid_u) = %x  //// envs[ENVX(envid_u)] = %x  //// &envs[2] = %x  /////// thisenv = %x \n\n" , envid_u, ENVX(envid_u), envs[2], &envs[2], thisenv);
	// save the name of the program so that panic() can use it
	if (argc > 0)
		binaryname = argv[0];
	//cprintf(" binaryname = %x  ,  argc = %x \n\n  ", *binaryname, argc  ); 
	// call user main routine
	umain(argc, argv);

	// exit gracefully
	exit();
}

