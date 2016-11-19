/* See COPYRIGHT for copyright information. */

#include <inc/mmu.h>
#include <inc/memlayout.h>
#include <inc/trap.h>

#include <kern/picirq.h>


###################################################################
# exceptions/interrupts
###################################################################

/* TRAPHANDLER defines a globally-visible function for handling a trap.
 * It pushes a trap number onto the stack, then jumps to _alltraps.
 * Use TRAPHANDLER for traps where the CPU automatically pushes an error code.
 *
 * You shouldn't call a TRAPHANDLER function from C, but you may
 * need to _declare_ one in C (for instance, to get a function pointer
 * during IDT setup).  You can declare the function with
 *   void NAME();
 * where NAME is the argument passed to TRAPHANDLER.
 */
#define TRAPHANDLER(name, num)						\
	.globl name;		/* define global symbol for 'name' */	\
	.type name, @function;	/* symbol type is function */		\
	.align 2;		/* align function definition */		\
	name:			/* function starts here */		\
	pushl $(num);							\
	jmp _alltraps

/* Use TRAPHANDLER_NOEC for traps where the CPU doesn't push an error code.
 * It pushes a 0 in place of the error code, so the trap frame has the same
 * format in either case.
 */
#define TRAPHANDLER_NOEC(name, num)					\
	.globl name;							\
	.type name, @function;						\
	.align 2;							\
 	name:                               \
   	 pushl $0;                           \
   	 pushl $(num);                           \
    	jmp _alltraps

.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
TRAPHANDLER_NOEC(int0, T_DIVIDE)  // interuupt 0
TRAPHANDLER_NOEC(int1, T_DEBUG)    // interrupt 1 
TRAPHANDLER_NOEC(int2, T_NMI)    // interrupt 2
TRAPHANDLER_NOEC(int3, T_BRKPT)  // interrupt 3  Breakpoint 
TRAPHANDLER_NOEC(int4, T_OFLOW)  // interrupt 4
TRAPHANDLER_NOEC(int5, T_BOUND)  // 5
TRAPHANDLER_NOEC(int6, T_ILLOP) // 6
TRAPHANDLER_NOEC(int7, T_DEVICE)  // 7 
// interrupt 8 have an error code 
TRAPHANDLER(int8, T_DBLFLT)       // interrupt 8
 // interrupt 9 is not defined by recent processors
TRAPHANDLER(int10, T_TSS)  //10
TRAPHANDLER(int11, T_SEGNP)  //11
TRAPHANDLER(int12, T_STACK) //12
TRAPHANDLER(int13, T_GPFLT) //13
TRAPHANDLER(int14, T_PGFLT) //14 
// 15 is reserved 
TRAPHANDLER_NOEC(int16, T_FPERR)   //16
TRAPHANDLER(int17, T_ALIGN) //17  
TRAPHANDLER_NOEC(int18, T_MCHK)      //  18  
TRAPHANDLER_NOEC(int19, T_SIMDERR)  // 19 

TRAPHANDLER_NOEC(int48, T_SYSCALL)   // 48 (error code?)


TRAPHANDLER_NOEC(int32, IRQ_OFFSET+0)  // interuupt 
TRAPHANDLER_NOEC(int33, IRQ_OFFSET+1)    // interrupt 
TRAPHANDLER_NOEC(int34, IRQ_OFFSET+2)    // interrupt 
TRAPHANDLER_NOEC(int35, IRQ_OFFSET+3)  // interrupt
TRAPHANDLER_NOEC(int36, IRQ_OFFSET+4)  // interrupt 
TRAPHANDLER_NOEC(int37, IRQ_OFFSET+5)  // 
TRAPHANDLER_NOEC(int38, IRQ_OFFSET+6) // 
TRAPHANDLER_NOEC(int39, IRQ_OFFSET+7)  // interrupt 
//TRAPHANDLER_NOEC(int37, IRQ_OFFSET+8)  // 
//TRAPHANDLER_NOEC(int38, IRQ_OFFSET+9) // 

/*
 * Lab 3: Your code here for _alltraps
 */

/* before this the ,,  eflags CS, EIP , ...etc and the trap number has been pushed on the stack */ 
//.global _alltraps
_alltraps:
    pushl %ds
    pushl %es

    pushal                 // push the registers 

    movw $GD_KD, %ax
    movw %ax, %ds          // the selectors are 16 bit, right?   %ax or %eax,  %ax then we should use movw not movl
    movw %ax, %es    
      
    pushl %esp
    call trap


