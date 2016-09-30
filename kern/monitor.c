// Simple command-line kernel monitor useful for
// controlling the kernel and exploring the system interactively.

#include <inc/stdio.h>
#include <inc/string.h>
#include <inc/memlayout.h>
#include <inc/assert.h>
#include <inc/x86.h>

#include <kern/console.h>
#include <kern/monitor.h>
#include <kern/kdebug.h>
#include <kern/trap.h>

#define CMDBUF_SIZE	80	// enough for one VGA text line


struct Command {
	const char *name;
	const char *desc;
	// return -1 to force monitor to exit
	int (*func)(int argc, char** argv, struct Trapframe* tf);
};

static struct Command commands[] = {
	{ "help", "Display this list of commands", mon_help },
	{ "kerninfo", "Display information about the kernel", mon_kerninfo },
        { "backtrace", "Provides the backtrace",    mon_backtrace},
};
#define NCOMMANDS (sizeof(commands)/sizeof(commands[0]))

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;
	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	uint32_t ebpr;

	uint32_t *temp;
        uint32_t *ptr1;
        uintptr_t address;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebpr));
	struct Eipdebuginfo i;	
                uint32_t *ptr = (uint32_t*)ebpr ;
      
	while(*ptr!=0)
	{
	
	address = *(ptr+1);
        
	ptr1 = (uint32_t*) *ptr;
        debuginfo_eip(address, &i);
                 	cprintf("EBP :%08x  ,EIP %08x  ,args:  %08x ,  %08x,   %08x ,   %08x,   %08x \n",*ptr,*(ptr+1),*(ptr1+2),*(ptr1+3), *(ptr1+4), *(ptr1+5), *(ptr1+6));


      switch(i.eip_fn_narg) {
         
       case 0: 
    	     cprintf("EBP :%08x  ,EIP %08x  ,args:  non \n",*ptr,*(ptr+1));
       break; 


         case 1:
               	cprintf("EBP :%08x  ,EIP %08x  ,args:  %08x \n",*ptr,*(ptr+1),*(ptr1+2));
         break;


        case 2:
               	cprintf("EBP :%08x  ,EIP %08x  ,args:  %08x ,  %08x \n",*ptr,*(ptr+1),*(ptr1+2),*(ptr1+3));
         break;


         case 3:
               	cprintf("EBP :%08x  ,EIP %08x  ,args:  %08x ,  %08x,   %08x \n",*ptr,*(ptr+1),*(ptr1+2),*(ptr1+3), *(ptr1+4));
         break;



         case 4:
               	cprintf("EBP :%08x  ,EIP %08x  ,args:  %08x ,  %08x,   %08x ,   %08x \n",*ptr,*(ptr+1),*(ptr1+2),*(ptr1+3), *(ptr1+4), *(ptr1+5));
         break;



       default: //5 or more
               	cprintf("EBP :%08x  ,EIP %08x  ,args:  %08x ,  %08x,   %08x ,   %08x,   %08x \n",*ptr,*(ptr+1),*(ptr1+2),*(ptr1+3), *(ptr1+4), *(ptr1+5), *(ptr1+6));
         break;

        }      

	temp = ptr;
	ptr = (uint32_t*) *temp;

            
         cprintf("Source File : %s    ", i.eip_file);
         cprintf("Line# : %d    ", i.eip_line);
         cprintf("Func Name   : %s  ", i.eip_fn_name);
         cprintf("number of arguments  : %d \n\n ", i.eip_fn_narg);    
    
	}	

		      

	return 0;
}


/***** Kernel monitor command interpreter *****/

#define WHITESPACE "\t\r\n "
#define MAXARGS 16

static int
runcmd(char *buf, struct Trapframe *tf)
{
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
		if (*buf == 0)
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
	}
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
	return 0;
}

void
monitor(struct Trapframe *tf)
{
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
	cprintf("Type 'help' for a list of commands.\n");

	if (tf != NULL)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
