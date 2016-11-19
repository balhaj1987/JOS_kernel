// Fork a binary tree of processes and display their structure.

#include <inc/lib.h>

#define DEPTH 3

void forktree(const char *cur);

void
forkchild(const char *cur, char branch)
{
	//cprintf(" at the start of forkchild by cur %c  and branch %c \n", *cur, branch);

	char nxt[DEPTH+1];

	if (strlen(cur) >= DEPTH)
		return;

	snprintf(nxt, DEPTH+1, "%s%c", cur, branch);
	if (fork() == 0) {
		//cprintf(" i am the child %x\n \n", sys_getenvid() );

		forktree(nxt);
		exit();
	}
}

void
forktree(const char *cur)
{
	cprintf("%04x: I am '%s'\n", sys_getenvid(), cur);

	forkchild(cur, '0');
	//cprintf(" in middle of forktree \n");

	forkchild(cur, '1');
}

void
umain(int argc, char **argv)
{
	//cprintf(" umain \n");
	forktree("");
}

