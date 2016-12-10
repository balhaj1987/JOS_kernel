// hello, world
#include <inc/lib.h>

void
umain(int argc, char **argv)
{
	cprintf("hello, world\n");
	cprintf("i am environment %08x\n", thisenv->env_id);
	cprintf("  thisenv= %x\n\n",  thisenv);
	cprintf(" binaryname = %x  ,  argc = %x \n\n  ", binaryname, argc  ); 
}
