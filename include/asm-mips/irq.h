/*
 * include/asm-mips/irq.h
 *
 * This file is subject to the terms and conditions of the GNU General Public
 * License.  See the file "COPYING" in the main directory of this archive
 * for more details.
 *
 * Copyright (C) 1994 by Waldorf GMBH
 * written by Ralf Baechle
 */
#ifndef _ASM_IRQ_H
#define _ASM_IRQ_H

/*
 * Actually this is a lie but we hide the local device's interrupts ...
 */
#define NR_IRQS 64

#define TIMER_IRQ 0

#if defined(__LANGUAGE_ASSEMBLY__) || defined(__ASSEMBLY__)

#define INC_INTR_COUNT(r1,r2)				\
	.set	push;					\
	.set	noat;					\
	lui	r1,%hi(intr_count);			\
	lw	r2,%lo(intr_count)(r1);			\
	addiu	$1,r2,1;				\
	sw	$1,%lo(intr_count)(r1);			\
	.set	pop

#define DEC_INTR_COUNT(r1,r2)				\
	sw	r2,%lo(intr_count)(r1)

#endif /* defined(__LANGUAGE_ASSEMBLY__) || defined(__ASSEMBLY__) */

#if !(defined(__LANGUAGE_ASSEMBLY__) || defined(__ASSEMBLY__))

struct irqaction;
extern int setup_x86_irq(int irq, struct irqaction * new);
extern void disable_irq(unsigned int);
extern void enable_irq(unsigned int);

extern unsigned int local_irq_count[];

#endif /* !(defined(__LANGUAGE_ASSEMBLY__) || defined(__ASSEMBLY__)) */

#endif /* _ASM_IRQ_H */
