// test user-level fault handler -- alloc pages to fix faults

#include <inc/lib.h>

void
handler(struct UTrapframe *utf)
{
	int r;
	void *addr = (void*)utf->utf_fault_va;
	cprintf("we r in handler in faultalloc\n\n");
	cprintf("fault %x\n", addr);
	if ((r = sys_page_alloc(0, ROUNDDOWN(addr, PGSIZE),
				PTE_P|PTE_U|PTE_W)) < 0)
		panic("allocating at %x in page fault handler: %e", addr, r);
	snprintf((char*) addr, 100, "this string was faulted in at %x", addr);
}

void
umain(int argc, char **argv)
{
	set_pgfault_handler(handler);
	cprintf(" here\n\n\n");
	cprintf("%s\n", (char*)0xDeadBeef);
	cprintf("%s\n", (char*)0xCafeBffe);
}
