/*
 * memcpy.S: MIPS optimized memcpy based upon SparcLinux code.
 *
 *  Copyright (C) 1995 Linus Torvalds
 *  Copyright (C) 1996 David S. Miller, Eddie C. Dost
 *  Copyright (C) 1998 Ralf Baechle
 *
 * derived from:
 *	e-mail between David and Eddie.
 *
 * $Id: memcpy.S,v 1.2 1998/04/12 01:25:04 ralf Exp $
 */
#include <asm/asm.h>
#include <asm/regdef.h>

#define MOVE_BIGCHUNK(src, dst, offset, t0, t1, t2, t3, t4, t5) \
	lw	t0, (offset + 0x18)(src); \
	lw	t1, (offset + 0x1c)(src); \
	sw	t0, (offset + 0x18)(dst); \
	lw	t2, (offset + 0x10)(src); \
	sw	t1, (offset + 0x1c)(dst); \
	lw	t3, (offset + 0x14)(src); \
	sw	t2, (offset + 0x10)(dst); \
	lw	t4, (offset + 0x08)(src); \
	sw	t3, (offset + 0x14)(dst); \
	lw	t5, (offset + 0x0c)(src); \
	sw	t4, (offset + 0x08)(dst); \
	lw	t0, (offset + 0x00)(src); \
	sw	t5, (offset + 0x0c)(dst); \
	lw	t1, (offset + 0x04)(src); \
	sw	t0, (offset + 0x00)(dst); \
	sw	t1, (offset + 0x04)(dst); \

	.text
	.set	noreorder
	.set	noat

	.align	5
LEAF(memcpy)					/* a0=dst a1=src a2=len */
	xor	t0, a0, a1
	andi	t0, t0, 0x3
	move	t7, a0
	beqz	t0, can_align
	 sltiu	t8, a2, 0x8

	b	memcpy_u_src			# bad alignment
	 move	t2, a2

can_align:
	bnez	t8, small_memcpy		# < 8 bytes to copy
	 move	t2, a2

	beqz	a2, out
	 andi	t8, a1, 0x1

hword_align:
	beqz	t8, word_align
	 andi	t8, a1, 0x2

	lb	t0, (a1)
	subu	a2, a2, 0x1
	sb	t0, (a0)
	addu	a1, a1, 0x1
	addu	a0, a0, 0x1
	andi	t8, a1, 0x2

word_align:
	beqz	t8, dword_align
	 sltiu	t8, a2, 56
	
	lh	t0, (a1)
	subu	a2, a2, 0x2
	sh	t0, (a0)
	sltiu	t8, a2, 56
	addu	a0, a0, 0x2
	addu	a1, a1, 0x2

dword_align:
	bnez	t8, do_end_words
	 move	t8, a2

	andi	t8, a1, 0x4
	beqz	t8, qword_align
	 andi	t8, a1, 0x8

	lw	t0, 0x00(a1)
	subu	a2, a2, 0x4
	sw	t0, 0x00(a0)
	addu	a1, a1, 0x4
	addu	a0, a0, 0x4
	andi	t8, a1, 0x8

qword_align:
	beqz	t8, oword_align
	 andi	t8, a1, 0x10

	lw	t0, 0x00(a1)
	lw	t1, 0x04(a1)
	subu	a2, a2, 0x8
	sw	t0, 0x00(a0)
	addu	a1, a1, 0x8
	sw	t1, 0x04(a0)
	andi	t8, a1, 0x10
	addu	a0, a0, 0x8

oword_align:
	beqz	t8, begin_movement
	 srl	t8, a2, 0x7

	lw	t3, 0x08(a1)			# assumes subblock ordering
	lw	t4, 0x0c(a1)
	lw	t0, 0x00(a1)
	lw	t1, 0x04(a1)
	sw	t3, 0x08(a0)
	subu	a2, a2, 0x10
	sw	t4, 0x0c(a0)
	addu	a1, a1, 0x10
	sw	t0, 0x00(a0)
	srl	t8, a2, 0x7
	addu	a0, a0, 0x10
	sw	t1, -0x0c(a0)

begin_movement:
	beqz	t8, 0f
	 andi	t2, a2, 0x40

move_128bytes:
	MOVE_BIGCHUNK(a1, a0, 0x00, t0, t1, t3, t4, t5, t6)
	MOVE_BIGCHUNK(a1, a0, 0x20, t0, t1, t3, t4, t5, t6)
	MOVE_BIGCHUNK(a1, a0, 0x40, t0, t1, t3, t4, t5, t6)
	MOVE_BIGCHUNK(a1, a0, 0x60, t0, t1, t3, t4, t5, t6)
	subu	t8, t8, 0x01
	addu	a1, a1, 0x80
	bnez	t8, move_128bytes
	 addu	a0, a0, 0x80

0:
	beqz	t2, 1f
	 andi	t2, a2, 0x20

move_64bytes:
	MOVE_BIGCHUNK(a1, a0, 0x00, t0, t1, t3, t4, t5, t6)
	MOVE_BIGCHUNK(a1, a0, 0x20, t0, t1, t3, t4, t5, t6)
	addu	a1, a1, 0x40
	addu	a0, a0, 0x40

1:
	beqz	t2, do_end_words
	 andi	t8, a2, 0x1c

move_32bytes:
	MOVE_BIGCHUNK(a1, a0, 0x00, t0, t1, t3, t4, t5, t6)
	andi	t8, a2, 0x1c
	addu	a1, a1, 0x20
	addu	a0, a0, 0x20

do_end_words:
	beqz	t8, maybe_end_cruft
	 srl	t8, t8, 0x2

end_words:
	lw	t0, (a1)
	subu	t8, t8, 0x1
	sw	t0, (a0)
	addu	a1, a1, 0x4
	bnez	t8, end_words
	 addu	a0, a0, 0x4

maybe_end_cruft:
	andi	t2, a2, 0x3

small_memcpy:
	beqz	t2, out
	 move	a2, t2

end_bytes:
	lb	t0, (a1)
	subu	a2, a2, 0x1
	sb	t0, (a0)
	addu	a1, a1, 0x1
	bnez	a2, end_bytes
	 addu	a0, a0, 0x1

out:
	jr	ra
	 move	v0, t7

/* ------------------------------------------------------------------------- */

#define UMOVE_BIGCHUNK(src, dst, offset, t0, t1, t2, t3, t4, t5) \
	lw	t0, (offset + 0x18)(src); \
	lw	t1, (offset + 0x1c)(src); \
	usw	t0, (offset + 0x18)(dst); \
	lw	t2, (offset + 0x10)(src); \
	usw	t1, (offset + 0x1c)(dst); \
	lw	t3, (offset + 0x14)(src); \
	usw	t2, (offset + 0x10)(dst); \
	lw	t4, (offset + 0x08)(src); \
	usw	t3, (offset + 0x14)(dst); \
	lw	t5, (offset + 0x0c)(src); \
	usw	t4, (offset + 0x08)(dst); \
	lw	t0, (offset + 0x00)(src); \
	usw	t5, (offset + 0x0c)(dst); \
	lw	t1, (offset + 0x04)(src); \
	usw	t0, (offset + 0x00)(dst); \
	usw	t1, (offset + 0x04)(dst); \

/* Bad, bad.  At least try to align the source  */

memcpy_u_src:
	bnez	t8, small_memcpy		# < 8 bytes?
	 move	t2, a2

	addiu	t0, a1, 7			# t0: how much to align
	ori	t0, 7
	xori	t0, 7
	subu	t0, a1

	ulw	t1, (a1)			# dword alignment
	ulw	t2, 4(a1)
	usw	t1, (a0)
	usw	t2, 4(a0)

	addu	a1, t0				# src
	addu	a0, t0				# dst
	subu	a2, t0				# len

	sltiu	t8, a2, 56
	bnez	t8, u_do_end_words
	 andi	t8, a2, 0x3c

	andi	t8, a1, 8			# now qword aligned?

u_qword_align:
	beqz	t8, u_oword_align
	 andi	t8, a1, 0x10

	lw	t0, 0x00(a1)
	lw	t1, 0x04(a1)
	subu	a2, a2, 0x8
	usw	t0, 0x00(a0)
	addu	a1, a1, 0x8
	usw	t1, 0x04(a0)
	andi	t8, a1, 0x10
	addu	a0, a0, 0x8

u_oword_align:
	beqz	t8, u_begin_movement
	 srl	t8, a2, 0x7

	lw	t3, 0x08(a1)			# assumes subblock ordering
	lw	t4, 0x0c(a1)
	lw	t0, 0x00(a1)
	lw	t1, 0x04(a1)
	usw	t3, 0x08(a0)
	subu	a2, a2, 0x10
	usw	t4, 0x0c(a0)
	addu	a1, a1, 0x10
	usw	t0, 0x00(a0)
	srl	t8, a2, 0x7
	addu	a0, a0, 0x10
	usw	t1, -0x0c(a0)

u_begin_movement:
	beqz	t8, 0f
	 andi	t2, a2, 0x40

u_move_128bytes:
	UMOVE_BIGCHUNK(a1, a0, 0x00, t0, t1, t3, t4, t5, t6)
	UMOVE_BIGCHUNK(a1, a0, 0x20, t0, t1, t3, t4, t5, t6)
	UMOVE_BIGCHUNK(a1, a0, 0x40, t0, t1, t3, t4, t5, t6)
	UMOVE_BIGCHUNK(a1, a0, 0x60, t0, t1, t3, t4, t5, t6)
	subu	t8, t8, 0x01
	addu	a1, a1, 0x80
	bnez	t8, u_move_128bytes
	 addu	a0, a0, 0x80

0:
	beqz	t2, 1f
	 andi	t2, a2, 0x20

u_move_64bytes:
	UMOVE_BIGCHUNK(a1, a0, 0x00, t0, t1, t3, t4, t5, t6)
	UMOVE_BIGCHUNK(a1, a0, 0x20, t0, t1, t3, t4, t5, t6)
	addu	a1, a1, 0x40
	addu	a0, a0, 0x40

1:
	beqz	t2, u_do_end_words
	 andi	t8, a2, 0x1c

u_move_32bytes:
	UMOVE_BIGCHUNK(a1, a0, 0x00, t0, t1, t3, t4, t5, t6)
	andi	t8, a2, 0x1c
	addu	a1, a1, 0x20
	addu	a0, a0, 0x20

u_do_end_words:
	beqz	t8, u_maybe_end_cruft
	 srl	t8, t8, 0x2

u_end_words:
	lw	t0, 0x00(a1)
	subu	t8, t8, 0x1
	usw	t0, 0x00(a0)
	addu	a1, a1, 0x4
	bnez	t8, u_end_words
	 addu	a0, a0, 0x4

u_maybe_end_cruft:
	andi	t2, a2, 0x3

u_cannot_optimize:
	beqz	t2, out
	 move	a2, t2

u_end_bytes:
	lb	t0, (a1)
	subu	a2, a2, 0x1
	sb	t0, (a0)
	addu	a1, a1, 0x1
	bnez	a2, u_end_bytes
	 addu	a0, a0, 0x1

	jr	ra
	 move	v0, t7
	END(memcpy)

/*
 * Just for the correctness of things.  The backwards case is still
 * unoptimized.
 */
LEAF(memmove)
	j	memcpy;nop
	sltu	t0, a0, a1			# dst < src -> memcpy
	bnez	t0, memcpy
	 addu	v0, a0, a2
	beqz	a2, 2f				# len != 0 -> done
	 sltu	t0, v0, a1			# dst + len < src -> non-
	bnez	t0, memcpy			# overlapping, can use memcpy
	addu	v1, a1, a2

	/* Ok, really have to use this ...  */
1:	lb	t2, (v1)			# copy backwards
	subu	t1, 1
	sb	t2, (v0)
	bne	t0, a0, 1b
	 subu	t0, 1

2:	jr	ra
	 nop					# return dst ptr
	END(memmove)
