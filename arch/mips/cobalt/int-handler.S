/*
 * arch/mips/cobalt/int-handler.S
 *
 * $Id: int-handler.S,v 1.1 1997/10/23 22:25:42 ralf Exp $
 */
#include <asm/asm.h>
#include <asm/mipsconfig.h>
#include <asm/mipsregs.h>
#include <asm/cobalt.h>
#include <asm/irq.h>
#include <asm/regdef.h>
#include <asm/stackframe.h>

/*
 * cobalt_handle_int: Interrupt handler for the twenty-seven board.
 */
		.align	5
		.set	noreorder
		NESTED(cobalt_handle_int, PT_SIZE, ra)
		.set	noat
		SAVE_ALL
		REG_S	sp,PT_OR2(sp)
		CLI
		.set	at
		mfc0	t0,CP0_CAUSE
		mfc0	t1,CP0_STATUS
		and	t0,t1
		/* Such a kind of cascade is optimal for R5000 */
		andi	t1,t0,CAUSEF_IP2
		bnez	t1,ll_galileo_irq
		 andi	t1,t0,CAUSEF_IP4
		bnez	t1,ll_ethernet_irq
		 andi	t1,t0,CAUSEF_IP6
		bnez	t1,ll_via_irq
		 andi	t1,t0,CAUSEF_IP3
		bnez	t1,ll_scc_irq
		 andi	t1,t0,CAUSEF_IP5
		bnez	t1,ll_scsi_irq
		 nop
		/* wrong alarm ... */
		j	spurious_interrupt
		 nop
		END(cobalt_handle_int)

		.align	5
		.set	reorder
ll_galileo_irq:	move	a0,sp
		INC_INTR_COUNT(s1,s2)
		jal	galileo_irq
		DEC_INTR_COUNT(s1,s2)
		j	ret_from_irq

ll_via_irq:	move	a0,sp
		INC_INTR_COUNT(s1,s2)
		jal	via_irq
		DEC_INTR_COUNT(s1,s2)
		j	ret_from_irq

		.align	5
ll_ethernet_irq:
		INC_INTR_COUNT(s1,s2)
		mfc0	s0,CP0_STATUS		# mask interrupt
		ori	t0,s0,STATUSF_IP4
		xori	t0,STATUSF_IP4
		mtc0	t0,CP0_STATUS
		li	a0,COBALT_ETHERNET_IRQ
		move	a1,sp
		jal     do_IRQ
		mtc0	s0,CP0_STATUS
		DEC_INTR_COUNT(s1,s2)
		j	ret_from_irq

		.align	5
ll_scc_irq:	li	a0,COBALT_SCC_IRQ
		INC_INTR_COUNT(s1,s2)
		move	a1,sp
		jal     do_IRQ
		DEC_INTR_COUNT(s1,s2)
		j	ret_from_irq

		.align	5
ll_scsi_irq:	li	a0,COBALT_SCSI_IRQ
		INC_INTR_COUNT(s1,s2)
		move	a1,sp
		jal     do_IRQ
		DEC_INTR_COUNT(s1,s2)
		j	ret_from_irq
