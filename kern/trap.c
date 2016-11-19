#include <inc/mmu.h>
#include <inc/x86.h>
#include <inc/assert.h>

#include <kern/pmap.h>
#include <kern/trap.h>
#include <kern/console.h>
#include <kern/monitor.h>
#include <kern/env.h>
#include <kern/syscall.h>
#include <kern/sched.h>
#include <kern/kclock.h>
#include <kern/picirq.h>
#include <kern/cpu.h>
#include <kern/spinlock.h>



// declaring the handlers used in entry_trap.S
    void int0 ();
    void int1 ();
    void int2 ();
    void int3 ();
    void int4 ();
    void int5 ();
    void int6 ();
    void int7 ();
    void int8 ();
    void int9 ();
    void int10 ();
    void int11 ();
    void int12 ();
    void int13 ();
    void int14 ();
    void int15 ();
    void int16 ();
    void int17 ();
    void int18 ();
    void int19 ();
    void int48 ();

    void int32 ();
    void int33 ();
    void int34();
    void int35 ();
    void int36 ();
    void int37 ();
    void int38 ();
    void int39 ();
   



static struct Taskstate ts;

/* For debugging, so print_trapframe can distinguish between printing
 * a saved trapframe and printing the current trapframe and print some
 * additional information in the latter case.
 */
static struct Trapframe *last_tf;

/* Interrupt descriptor table.  (Must be built at run time because
 * shifted function addresses can't be represented in relocation records.)
 */
struct Gatedesc idt[256] = { { 0 } };     
struct Pseudodesc idt_pd = {       
	sizeof(idt) - 1, (uint32_t) idt
};


static const char *trapname(int trapno)
{
	static const char * const excnames[] = {
		"Divide error",
		"Debug",
		"Non-Maskable Interrupt",
		"Breakpoint",
		"Overflow",
		"BOUND Range Exceeded",
		"Invalid Opcode",
		"Device Not Available",
		"Double Fault",
		"Coprocessor Segment Overrun",
		"Invalid TSS",
		"Segment Not Present",
		"Stack Fault",
		"General Protection",
		"Page Fault",
		"(unknown trap)",
		"x87 FPU Floating-Point Error",
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
		return excnames[trapno];
	if (trapno == T_SYSCALL)
		return "System call";
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
		return "Hardware Interrupt";
	return "(unknown trap)";
}


void
trap_init(void)
{
	extern struct Segdesc gdt[];
	//extern struct Gatedesc idt []; 
	//cprintf(" excnames[2] = %s \n", trapname(2)) ;  // the size is 8 

	// LAB 3: Your code here.
    SETGATE(idt[0], 0, GD_KT, int0, 0);
    SETGATE(idt[1], 0, GD_KT, int1, 0);
    SETGATE(idt[2], 0, GD_KT, int2, 0);
    SETGATE(idt[3], 0, GD_KT, int3, 3);  // breakpoint

    SETGATE(idt[4], 0, GD_KT, int4, 0);
    SETGATE(idt[5], 0, GD_KT, int5, 0);
    SETGATE(idt[6], 0, GD_KT, int6, 0);
    SETGATE(idt[7], 0, GD_KT, int7, 0);
    SETGATE(idt[8], 0, GD_KT, int8, 0);
    //SETGATE(idt[9], 0, GD_KT, int9, 0);

    SETGATE(idt[10], 0, GD_KT, int10, 0);
    SETGATE(idt[11], 0, GD_KT, int11, 0);
    SETGATE(idt[12], 0, GD_KT, int12, 0);
    SETGATE(idt[13], 0, GD_KT, int13, 0);
    SETGATE(idt[14], 0, GD_KT, int14, 0);
 //   SETGATE(idt[15], 0, GD_KT, int15, 0);

    SETGATE(idt[16], 0, GD_KT, int16, 0);
    SETGATE(idt[17], 0, GD_KT, int17, 0);
    SETGATE(idt[18], 0, GD_KT, int18, 0);
    SETGATE(idt[19], 0, GD_KT, int19, 0);
    SETGATE(idt[48], 0, GD_KT, int48, 3);   // system call

    SETGATE(idt[32], 0, GD_KT, int32, 0);
    SETGATE(idt[33], 0, GD_KT, int33, 0);
    SETGATE(idt[34], 0, GD_KT, int34, 0);
    SETGATE(idt[35], 0, GD_KT, int35, 0);

    SETGATE(idt[36], 0, GD_KT, int36, 0);
    SETGATE(idt[37], 0, GD_KT, int37, 0);
    SETGATE(idt[38], 0, GD_KT, int38, 0);
    SETGATE(idt[39], 0, GD_KT, int39, 0);
	// Per-CPU setup 
	trap_init_percpu();
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
	// The example code here sets up the Task State Segment (TSS) and
	// the TSS descriptor for CPU 0. But it is incorrect if we are
	// running on other CPUs because each CPU has its own kernel stack.
	// Fix the code so that it works for all CPUs.
	//
	// Hints:
	//   - The macro "thiscpu" always refers to the current CPU's
	//     struct CpuInfo;
	//   - The ID of the current CPU is given by cpunum() or
	//     thiscpu->cpu_id;
	//   - Use "thiscpu->cpu_ts" as the TSS for the current CPU,
	//     rather than the global "ts" variable;
	//   - Use gdt[(GD_TSS0 >> 3) + i] for CPU i's TSS descriptor;
	//   - You mapped the per-CPU kernel stacks in mem_init_mp()
	//
	// ltr sets a 'busy' flag in the TSS selector, so if you
	// accidentally load the same TSS on more than one CPU, you'll
	// get a triple fault.  If you set up an individual CPU's TSS
	// wrong, you may not get a fault until you try to return from
	// user space on that CPU.
	//

	// "thiscpu" always refers to the current CPU's	struct CpuInfo;
	// The ID of the current CPU ( 0, 1, 2 ..) is given by cpunum() or   thiscpu->cpu_id;
	// "thiscpu->cpu_ts :: points to the TSS structure of the current cpu
	
	// LAB 4: Your code here:

	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	 thiscpu->cpu_ts.ts_esp0 = KSTACKTOP - (thiscpu->cpu_id)*(KSTKSIZE + KSTKGAP);
 	 thiscpu->cpu_ts.ts_ss0 = GD_KD;
	//cprintf("thiscpu->cpu_ts= %x \n", &thiscpu->cpu_ts); 
	// Initialize the TSS slot of the gdt.

	// SEG16( type, base, lim, dpl)
	// STS_T32A   = 9 which is available TSS
	gdt[(GD_TSS0 >> 3) + thiscpu->cpu_id] = SEG16(STS_T32A,        (uint32_t) (&thiscpu->cpu_ts),     sizeof(struct Taskstate) - 1 ,      0);

	gdt[(GD_TSS0 >> 3) + thiscpu->cpu_id].sd_s = 0;   // means it is for system
	
	// Load the TSS selector (like other segment selectors, the
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0  + (thiscpu->cpu_id << 3) );


	// Load the IDT
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
		cprintf("  cr2  0x%08x\n", rcr2());
	cprintf("  err  0x%08x", tf->tf_err);
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
	cprintf("  eip  0x%08x\n", tf->tf_eip);
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
	if ((tf->tf_cs & 3) != 0) {
		cprintf("  esp  0x%08x\n", tf->tf_esp);
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
	}
}

void
print_regs(struct PushRegs *regs)
{
	cprintf("  edi  0x%08x\n", regs->reg_edi);
	cprintf("  esi  0x%08x\n", regs->reg_esi);
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
	cprintf("  edx  0x%08x\n", regs->reg_edx);
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
	cprintf("  eax  0x%08x\n", regs->reg_eax);
}

static void
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	 if (tf->tf_trapno == T_PGFLT) 
	   {
        	page_fault_handler(tf);
        	return;
 	   }

	 if (tf->tf_trapno == T_BRKPT) 
	   {
        	monitor(tf);
        	return;
	   }
 

	if (tf->tf_trapno == T_SYSCALL) 
	{	
		tf->tf_regs.reg_eax =   syscall(tf->tf_regs.reg_eax,    tf->tf_regs.reg_edx,    tf->tf_regs.reg_ecx,    tf->tf_regs.reg_ebx,    tf->tf_regs.reg_edi,    tf->tf_regs.reg_esi);
        	return; 
	}

	// Handle spurious interrupts
	// The hardware sometimes raises these because of noise on the
	// IRQ line or other reasons. We don't care.
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {
		cprintf("Spurious interrupt on irq 7\n");
		print_trapframe(tf);
		return;
	}

	// Handle clock interrupts. Don't forget to acknowledge the
	// interrupt using lapic_eoi() before calling the scheduler!
	// LAB 4: Your code here.

	if (tf->tf_trapno == IRQ_OFFSET + IRQ_TIMER) 
	{
		lapic_eoi();
		//cprintf(" A Timer interrupt has been received \n");
		sched_yield();
		return;
	}
	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
	if (tf->tf_cs == GD_KT)
		panic("unhandled trap in kernel");
	else {
		cprintf("the env will be destroyed by trap_dispatch bcz it asked for an invalid interrupt \n"); 
		env_destroy(curenv);
		return;
	     }

}

void
trap(struct Trapframe *tf)
{
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");

	// Halt the CPU if some other CPU has called panic()
	extern char *panicstr;
	if (panicstr)
		asm volatile("hlt");

	// Re-acqurie the big kernel lock if we were halted in
	// sched_yield()
	if (xchg(&thiscpu->cpu_status, CPU_STARTED) == CPU_HALTED)
		lock_kernel();
	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));

//<<<<<<< HEAD
	//if ((tf->tf_cs & 3) == 3) {
//=======
	//cprintf("Incoming TRAP frame at %p and trap_num %s\n", tf, trapname(tf->tf_trapno));
	//cprintf("  b4 curenv->env_status = %d \n" , curenv->env_status);
	if ((tf->tf_cs & 3) == 3) 
	{
//>>>>>>> lab3
		// Trapped from user mode.
		// Acquire the big kernel lock before doing any
		// serious kernel work.
		// LAB 4: Your code here.
		lock_kernel();
		assert(curenv);

		// Garbage collect if current enviroment is a zombie
		if (curenv->env_status == ENV_DYING) {
			env_free(curenv);
			curenv = NULL;
			sched_yield();
		}

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

//<<<<<<< HEAD
	// If we made it to this point, then no other environment was
	// scheduled, so we should return to the current environment
	// if doing so makes sense.
	if (curenv && curenv->env_status == ENV_RUNNING)
		env_run(curenv);
	else
		sched_yield();
//=======
	// Return to the current environment, which should be running.
	//cprintf(" curenv && curenv->env_status = %d \n" , curenv && curenv->env_status);
	//cprintf(" curenv  = %d \n" , curenv);
	//cprintf("  curenv->env_status = %d \n" , curenv->env_status);
	assert(curenv && curenv->env_status == ENV_RUNNING);
	env_run(curenv);
//>>>>>>> lab3
}
//}


void
page_fault_handler(struct Trapframe *tf)
{
	uint32_t fault_va;

	// Read processor's CR2 register to find the faulting address
	fault_va = rcr2();

	// Handle kernel-mode page faults.
	//cprintf(" page_fault_handler() \n" ); 
	// LAB 3: Your code here.
	if ((tf->tf_cs & 3) == 0) 
		{
		print_trapframe(tf);
		panic(" a page fault in the kernel");
		}
	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Call the environment's page fault upcall, if one exists.  Set up a
	// page fault stack frame on the user exception stack (below
	// UXSTACKTOP), then branch to curenv->env_pgfault_upcall.
	//
	// The page fault upcall might cause another page fault, in which case
	// we branch to the page fault upcall recursively, pushing another
	// page fault stack frame on top of the user exception stack.
	//
	// The trap handler needs one word of scratch space at the top of the
	// trap-time stack in order to return.  In the non-recursive case, we
	// don't have to worry about this because the top of the regular user
	// stack is free.  In the recursive case, this means we have to leave
	// an extra word between the current top of the exception stack and
	// the new stack frame because the exception stack _is_ the trap-time
	// stack.
	//
	// If there's no page fault upcall, 
	//the environment didn't allocate a page for its exception stack or can't write to it, 
	//or the exception stack overflows, then destroy the environment that caused the fault.

	// Note that the grade script assumes you will first check for the page
	// fault upcall and print the "user fault va" message below if there is
	// none.  The remaining three checks can be combined into a single test.
	//
	// Hints:
	//   user_mem_assert() and env_run() are useful here.
	//   To change what the user environment runs, modify 'curenv->env_tf'
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.
	   struct UTrapframe *utrapframe;


	if ( (!curenv->env_pgfault_upcall) || (USTACKTOP < tf->tf_esp && tf->tf_esp < UXSTACKTOP - PGSIZE)  )
	{
		// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",  curenv->env_id,   fault_va, tf->tf_eip);
	print_trapframe(tf);
		cprintf(" the env wil be destroyed in page_fault_handler() \n" ); 
	env_destroy(curenv);
	}
	

	//cprintf("[%08x] user fault va %08x ip %08x\n",  curenv->env_id,   fault_va, tf->tf_eip);
	//print_trapframe(tf);


	

	if (tf->tf_esp < UXSTACKTOP   &&  tf->tf_esp >= UXSTACKTOP-PGSIZE)  //already in the exception stack
		utrapframe = (struct UTrapframe *) (tf->tf_esp - sizeof (struct UTrapframe) - 4);

	else 
		utrapframe = (struct UTrapframe *) (UXSTACKTOP - sizeof (struct UTrapframe));
	
	user_mem_assert(curenv, (void *)(utrapframe), sizeof(struct UTrapframe), PTE_W | PTE_U | PTE_P);

		
	utrapframe->utf_regs = tf->tf_regs;
	utrapframe->utf_eip = tf->tf_eip;
	utrapframe->utf_err = tf->tf_err;
	utrapframe->utf_esp = tf->tf_esp;
	utrapframe->utf_fault_va = fault_va;
	utrapframe->utf_eflags = tf->tf_eflags;


	tf->tf_eip = (uintptr_t)curenv->env_pgfault_upcall;
	tf->tf_esp = (uintptr_t)utrapframe; 
 	env_run(curenv);

	
}

