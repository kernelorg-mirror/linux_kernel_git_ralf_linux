/*
 * r4k_switch.S: R4xx0 specific task switching code for the O32 ABI.
 *
 * Copyright (C) 1994, 1995, 1996 by Ralf Baechle and Andreas Busse
 *
 * Multi-cpu abstraction and macros for easier reading:
 * Copyright (C) 1996 David S. Miller (dm@engr.sgi.com)
 */
#include <asm/asm.h>
#include <asm/bootinfo.h>
#include <asm/cachectl.h>
#include <asm/fpregdef.h>
#include <asm/mipsconfig.h>
#include <asm/mipsregs.h>
#include <asm/page.h>
#include <asm/pgtable.h>
#include <asm/processor.h>
#include <asm/regdef.h>
#include <asm/stackframe.h>

#include <asm/asmmacro.h>

#define FPU_SAVE_16DOUBLE(thread, tmp) \
	cfc1	tmp,  fcr31;                    \
	sdc1	$f0,  (THREAD_FPU + 0x000)(thread); \
	sdc1	$f2,  (THREAD_FPU + 0x010)(thread); \
	sdc1	$f4,  (THREAD_FPU + 0x020)(thread); \
	sdc1	$f6,  (THREAD_FPU + 0x030)(thread); \
	sdc1	$f8,  (THREAD_FPU + 0x040)(thread); \
	sdc1	$f10, (THREAD_FPU + 0x050)(thread); \
	sdc1	$f12, (THREAD_FPU + 0x060)(thread); \
	sdc1	$f14, (THREAD_FPU + 0x070)(thread); \
	sdc1	$f16, (THREAD_FPU + 0x080)(thread); \
	sdc1	$f18, (THREAD_FPU + 0x090)(thread); \
	sdc1	$f20, (THREAD_FPU + 0x0a0)(thread); \
	sdc1	$f22, (THREAD_FPU + 0x0b0)(thread); \
	sdc1	$f24, (THREAD_FPU + 0x0c0)(thread); \
	sdc1	$f26, (THREAD_FPU + 0x0d0)(thread); \
	sdc1	$f28, (THREAD_FPU + 0x0e0)(thread); \
	sdc1	$f30, (THREAD_FPU + 0x0f0)(thread); \
	sw	tmp,  (THREAD_FPU + 0x100)(thread);

#define FPU_RESTORE_16DOUBLE(thread, tmp) \
	lw	tmp,  (THREAD_FPU + 0x100)(thread); \
	ldc1	$f0,  (THREAD_FPU + 0x000)(thread); \
	ldc1	$f2,  (THREAD_FPU + 0x010)(thread); \
	ldc1	$f4,  (THREAD_FPU + 0x020)(thread); \
	ldc1	$f6,  (THREAD_FPU + 0x030)(thread); \
	ldc1	$f8,  (THREAD_FPU + 0x040)(thread); \
	ldc1	$f10, (THREAD_FPU + 0x050)(thread); \
	ldc1	$f12, (THREAD_FPU + 0x060)(thread); \
	ldc1	$f14, (THREAD_FPU + 0x070)(thread); \
	ldc1	$f16, (THREAD_FPU + 0x080)(thread); \
	ldc1	$f18, (THREAD_FPU + 0x090)(thread); \
	ldc1	$f20, (THREAD_FPU + 0x0a0)(thread); \
	ldc1	$f22, (THREAD_FPU + 0x0b0)(thread); \
	ldc1	$f24, (THREAD_FPU + 0x0c0)(thread); \
	ldc1	$f26, (THREAD_FPU + 0x0d0)(thread); \
	ldc1	$f28, (THREAD_FPU + 0x0e0)(thread); \
	ldc1	$f30, (THREAD_FPU + 0x0f0)(thread); \
	ctc1	tmp,  fcr31;

	.set	noreorder
	.set	mips3
	.align	5
	LEAF(r4xx0_resume)
	lui	t5, %hi(current_set)
	lw	t0, %lo(current_set)(t5)
	mfc0	t1, CP0_STATUS
	nop
	sw	t1, THREAD_STATUS(t0)
	ori	t2, t1, 0x1f
	xori	t2, t2, 0x1e
	mtc0	t2, CP0_STATUS
	CPU_SAVE_NONSCRATCH(t0)
	sll	t2, t1, 2		# Save floating point state
	bgez	t2, 2f
	 sw	ra, THREAD_REG31(t0)
	FPU_SAVE_16DOUBLE(t0, t1)	# clobbers t1
2:
	sw	a0, %lo(current_set)(t5)
	lw	a3, TASK_MM(a0)
	lw	a2, THREAD_STATUS(a0)
	lw	a3, MM_CONTEXT(a3)
	ori	t1, a2, 1		# restore fpu, pipeline magic
	andi	a3, a3, 0xff
	xori	t1, t1, 1
	mtc0	a3, CP0_ENTRYHI
	mtc0	t1, CP0_STATUS
	sll	t0, a2, 2
	bgez	t0, 2f
	 FPU_RESTORE_16DOUBLE(a0, t0)	# clobbers t0
2:
	CPU_RESTORE_NONSCRATCH(a0)
	lw	t0, THREAD_KSP(a0)
	sw	t0, kernelsp
	jr	ra
	 mtc0	a2, CP0_STATUS
	END(r4xx0_resume)
