// implement fork from user space

#include <inc/string.h>
#include <inc/lib.h>

// PTE_COW marks copy-on-write page table entries.
// It is one of the bits explicitly allocated to user processes (PTE_AVAIL).
#define PTE_COW		0x800

//
// Custom page fault handler - if faulting page is copy-on-write,
// map in our own private writable copy.
//
static void
pgfault(struct UTrapframe *utf)
{
	void *addr = (void *) utf->utf_fault_va;
	uint32_t err = utf->utf_err;
	int r;

	// Check that the faulting access was (1) a write, and (2) to a
	// copy-on-write page.  If not, panic.
	// Hint:
	//   Use the read-only page table mappings at uvpt
	//   (see <inc/memlayout.h>).


	// LAB 4: Your code here.
	uint32_t pte = uvpt[PGNUM(addr)];

	//if (((err & FEC_WR) != FEC_WR) || ! (pte & PTE_COW) ) 
	//	panic("error in pgfault is not write error or page is not COW.\n",err);



	// Allocate a new page, map it at a temporary location (PFTEMP),
	// copy the data from the old page to the new page, then move the new
	// page to the old page's address.
	// Hint:
	//   You should make three system calls.


	// LAB 4: Your code here.
	addr = ROUNDDOWN(addr, PGSIZE);

	//allocate a physical page, and map it to the temporary address PFTEMP 
	r = sys_page_alloc(0, PFTEMP, PTE_U | PTE_P | PTE_W);
	if (r < 0)
		panic("error in pgfault after returning from sys_page_alloc , error: %e.\n",r);

	// copy data from the faulting address to the temp address 
	memmove(PFTEMP, addr, PGSIZE);

	// now we have 2 physical copies of the same page ... 

	// map the same physical page that is being mapped to the temp address to the faulted address
	r = sys_page_map(0, PFTEMP, 0, addr, PTE_U | PTE_P | PTE_W);
	if (r < 0)
		panic("error in pgfault after returning from sys_page_map , error : %e.\n",r);

	// now we have a new page allocated and mapped to our faulting addresss

	// we don't need the temp address anymore, so just unmap. 
	r = sys_page_unmap(0, PFTEMP);
	if (r < 0)
		panic("error in pgfault after returning from sys_page_unmap , error  : %e.\n",r);
	return; 

}





// Map our virtual page pn (address pn*PGSIZE) into the target envid
// at the same virtual address.  If the page is writable or copy-on-write,
// the new mapping must be created copy-on-write, and then our mapping must be
// marked copy-on-write as well.  (Exercise: Why do we need to mark ours
// copy-on-write again if it was already copy-on-write at the beginning of
// this function?)
//
// Returns: 0 on success, < 0 on error.
// It is also OK to panic on error.

static int
duppage(envid_t envid, unsigned pn)
{
	
	// LAB 4: Your code here.
	int r;
	int perm_w = PTE_P;
	void * va = (void *) ((uint32_t) pn * PGSIZE);
	pte_t pte = uvpt[pn];


			

	if (pte & PTE_SHARE) 
	{
        r = sys_page_map(0, va, envid, va, pte & PTE_SYSCALL);
        if (r < 0)
            panic("duppage : sys_page_map error : %e.\n",r);
    }

    else 
    {

	 if ((pte & PTE_W) || (pte & PTE_COW))
		perm_w |= PTE_COW;  
	else    //if it is not writable page
	{
		r = sys_page_map(0, va, envid, va,  PTE_U |  PTE_P);
		if (r < 0)
			panic("duppage error : when calling sys_page_map  : %e.\n",r);
		return 0; 
	}

	// mapping to the  child
	r = sys_page_map(0, va, envid, va, perm_w | PTE_U |  PTE_P);
	if (r < 0)
		panic("duppage error : when calling sys_page_map  : %e.\n",r);
		
	// mapping to the parent once again

	 
	r = sys_page_map(0, va, 0, va, perm_w | PTE_U |  PTE_P);
	if (r < 0) 
		panic("duppage error: when calling sys_page_map  : %e.\n", r);

}

	return 0;
}





//
// User-level fork with copy-on-write.
// Set up our page fault handler appropriately.
// Create a child.
// Copy our address space and page fault handler setup to the child.
// Then mark the child as runnable and return.
//
// Returns: child's envid to the parent, 0 to the child, < 0 on error.
// It is also OK to panic on error.
//
// Hint:
//   Use uvpd, uvpt, and duppage.
//   Remember to fix "thisenv" in the child process.
//   Neither user exception stack should ever be marked copy-on-write,
//   so you must allocate a new page for the child's user exception stack.
envid_t
fork(void)
{
	// LAB 4: Your code here.
	int r; 
	envid_t envid_ch;
	uintptr_t va;

	set_pgfault_handler(pgfault);

	envid_ch = sys_exofork();  // creating a child
	if (envid_ch < 0)   
		panic("fork : sys_exofork error, %e.\n", envid_ch);

	// sys_exofork() will return 0 for the child 
	if (envid_ch == 0)
		{
			//cprintf(" i am the child but I am still NOT_RUNNABLE, so I am returning  \n");
			thisenv = &envs[ENVX(sys_getenvid())];
			return 0;   // the child is returned
	    }	

	/////////////////////The rest of this is the  parent initialzing the child/////////////////////////////

	 for (va = 0 ; va < USTACKTOP; va += PGSIZE)
	 {
 	   if ((uvpd[PDX(va)] & PTE_P) && (uvpt[PGNUM(va)] & PTE_P) &&   (uvpt[PGNUM(va)] & PTE_U) )     //&& (uvpt[PGNUM(va)] & (PTE_W | PTE_COW)))
    	  duppage(envid_ch, PGNUM(va));
	 }

	// allocate a pge for the exception stack in the child 
	r = sys_page_alloc(envid_ch,  (void *)(UXSTACKTOP-PGSIZE), PTE_U | PTE_P | PTE_W);
	if (r < 0) 
		panic("fork : sys_page_alloc failed. %e.\n",r);


	// setting the child handler 
	r = sys_env_set_pgfault_upcall(envid_ch, thisenv->env_pgfault_upcall);
	if(r < 0) 
		panic(" sys_env_set_pgfault_upcall in fork()   error , %e", r);
	
	// the child is ready to be run now 
	r = sys_env_set_status(envid_ch, ENV_RUNNABLE);
	if(r < 0) 
		panic("sys_env_set_status in fork    error :, %e", r);

	return envid_ch; 
}





int
sfork(void)
{
	panic("sfork not implemented");
	return -E_INVAL;
}


