/*
 *  arch/mips/mm/fault.c
 *
 *  Copyright (C) 1995, 1996, 1997 by Ralf Baechle
 */
#include <linux/signal.h>
#include <linux/sched.h>
#include <linux/head.h>
#include <linux/kernel.h>
#include <linux/errno.h>
#include <linux/string.h>
#include <linux/types.h>
#include <linux/ptrace.h>
#include <linux/mman.h>
#include <linux/mm.h>
#include <linux/smp.h>
#include <linux/smp_lock.h>

#include <asm/pgtable.h>
#include <asm/mmu_context.h>
#include <asm/system.h>
#include <asm/segment.h>

extern void die_if_kernel(char *, struct pt_regs *, long);

unsigned long asid_cache = ASID_FIRST_VERSION;

/*
 * This routine handles page faults.  It determines the address,
 * and the problem, and then passes it off to one of the appropriate
 * routines.
 */
asmlinkage void do_page_fault(struct pt_regs *regs, unsigned long writeaccess,
			      unsigned long address)
{
	struct vm_area_struct * vma;
	struct task_struct *tsk = current;
	struct mm_struct *mm = tsk->mm;

#if 0
	printk("[%s:%d:%08lx:%ld:%08lx]\n", current->comm, current->pid,
	       address, writeaccess, regs->cp0_epc);
#endif
	down(&mm->mmap_sem);
	vma = find_vma(mm, address);
	if (!vma)
		goto bad_area;
	if (vma->vm_start <= address)
		goto good_area;
	if (!(vma->vm_flags & VM_GROWSDOWN))
		goto bad_area;
	if (expand_stack(vma, address))
		goto bad_area;
/*
 * Ok, we have a good vm_area for this memory access, so
 * we can handle it..
 */
good_area:
	if (writeaccess) {
		if (!(vma->vm_flags & VM_WRITE))
			goto bad_area;
	} else {
		if (!(vma->vm_flags & (VM_READ | VM_EXEC)))
			goto bad_area;
	}
	handle_mm_fault(vma, address, writeaccess);
	up(&mm->mmap_sem);

	return;

/*
 * Something tried to access memory that isn't in our memory map..
 * Fix it, but check if it's kernel or user first..
 */
bad_area:
	up(&mm->mmap_sem);

	if (user_mode(regs)) {
		tsk->tss.cp0_badvaddr = address;
		tsk->tss.error_code = writeaccess;
#if 0
		printk("do_page_fault() #2: sending SIGSEGV to %s for illegal %s\n"
		       "%08lx (epc == %08lx, ra == %08lx)\n",
		       tsk->comm,
		       writeaccess ? "writeaccess to" : "readaccess from",
		       address,
		       (unsigned long) regs->cp0_epc,
		       (unsigned long) regs->regs[31]);
#endif

		current->tss.cp0_badvaddr = address;
		current->tss.error_code = writeaccess;
		force_sig(SIGSEGV, tsk);
		return;
	}

	/*
	 * Oops. The kernel tried to access some bad page. We'll have to
	 * terminate things with extreme prejudice.
	 */
	printk(KERN_ALERT "Unable to handle kernel paging request at virtual "
	       "address %08lx, epc == %08lx, ra == %08lx\n",
	       address, regs->cp0_epc, regs->regs[31]);
	die_if_kernel("Oops", regs, writeaccess);
	do_exit(SIGKILL);
}
