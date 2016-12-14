#include <inc/lib.h>
#include <kern/e1000.h>

			//char buf11[] = " Lab6 is here ............................... MOha" ; 

void
umain(int argc, char **argv)
{

	/*
	int fd, n, r;
	char buf[512+1];

	binaryname = "icode";

	cprintf("icode startup\n");

	cprintf("icode: open /motd\n");
	if ((fd = open("/motd", O_RDONLY)) < 0)
		panic("icode: open /motd: %e", fd);

	cprintf("icode: read /motd\n");
	while ((n = read(fd, buf, sizeof buf-1)) > 0)
		sys_cputs(buf, n);

	cprintf("icode: close /motd\n");
	close(fd);

	cprintf("icode: spawn /init\n");
	if ((r = spawnl("/init", "init", "initarg1", "initarg2", (char*)0)) < 0)
		panic("icode: spawn /init: %e", r);

	cprintf("icode: exiting\n");*/

		cprintf("icode: BEGINNING \n");
		//int r = nic_tx(buf11, 10) ;
		sys_yield();

		sys_yield();
		sys_yield();
		sys_yield();
		sys_yield();
		sys_yield();
		sys_yield();
		sys_yield();
		sys_yield();
		sys_yield();

		cprintf("icode: Ending \n");


}
