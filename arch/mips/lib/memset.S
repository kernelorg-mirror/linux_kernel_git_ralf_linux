/*
 * include/asm-mips/types.h
 *
 * This file is subject to the terms and conditions of the GNU General Public
 * License.  See the file "COPYING" in the main directory of this archive
 * for more details.
 *
 * Copyright (C) 1998 by Ralf Baechle
 *
 * $Id: memset.S,v 1.1 1998/04/14 22:28:36 ralf Exp $
 */
#include <asm/asm.h>
#include <asm/regdef.h>

#define F_FILL64(dst, offset, val)				\
	sw	val, (offset + 0x00)(dst);			\
	sw	val, (offset + 0x04)(dst);			\
	sw	val, (offset + 0x08)(dst);			\
	sw	val, (offset + 0x0c)(dst);			\
	sw	val, (offset + 0x10)(dst);			\
	sw	val, (offset + 0x14)(dst);			\
	sw	val, (offset + 0x18)(dst);			\
	sw	val, (offset + 0x1c)(dst);			\
	sw	val, (offset + 0x20)(dst);			\
	sw	val, (offset + 0x24)(dst);			\
	sw	val, (offset + 0x28)(dst);			\
	sw	val, (offset + 0x2c)(dst);			\
	sw	val, (offset + 0x30)(dst);			\
	sw	val, (offset + 0x34)(dst);			\
	sw	val, (offset + 0x38)(dst);			\
	sw	val, (offset + 0x3c)(dst)

#define R_FILL64(dst, offset, val)				\
	sw	val, (offset + 0x3c)(dst);			\
	sw	val, (offset + 0x38)(dst);			\
	sw	val, (offset + 0x34)(dst);			\
	sw	val, (offset + 0x30)(dst);			\
	sw	val, (offset + 0x2c)(dst);			\
	sw	val, (offset + 0x28)(dst);			\
	sw	val, (offset + 0x24)(dst);			\
	sw	val, (offset + 0x20)(dst);			\
	sw	val, (offset + 0x1c)(dst);			\
	sw	val, (offset + 0x18)(dst);			\
	sw	val, (offset + 0x14)(dst);			\
	sw	val, (offset + 0x10)(dst);			\
	sw	val, (offset + 0x0c)(dst);			\
	sw	val, (offset + 0x08)(dst);			\
	sw	val, (offset + 0x04)(dst);			\
	sw	val, (offset + 0x00)(dst)

/*
 * memset(void *s, int c, size_t n)
 *
 * a0: start of area to clear
 * a1: char to fill with
 * a2: size of area to clear
 */
	.set	noreorder
LEAF(memset)
	sltiu	t0, a2, 12				# very small region?
	bnez	t0, small_memset
	 move	v0, a0					# result

	 andi	a1, 0xff				# spread fillword
	sll	t0, a1, 8
	or	a1, t0
	sll	t0, a1, 16
	or	a1, t0

	andi	t0, a0, 3				# aligned?
	beqz	t0, 1f
	 nop

	usw	a1, (a0)				# make dword aligned
	usw	a1, 4(a0)

	addiu	t0, a0, 7				# alignment in bytes
	ori	t0, 7
	xori	t0, 7
	subu	t0, a0

	addu	a0, t0					# word align ptr
	subu	a2, t0					# correct size

1:
	ori	t0, a2, 0x3f				# full blocks
	xori	t0, 0x3f
	beqz	t0, memset_partial			# no block to fill
	 addu	t0, a0

	.set	reorder
1:	addiu	a0, 64
	F_FILL64(a0, -64, a1)
	bne	t0, a0, 1b
	.set	noreorder

memset_partial:
	la	t0, 2f					# where to start
	andi	t1, a2, 0x3c
	subu	t0, t1
	jr	t0
	 nop

	R_FILL64(a0, 0, a1)
2:	addu	a0, t1					# dest ptr
	andi	a2, 3					# 0 <= n <= 3 to go

small_memset:
	beqz	a2, 2f
	 addu	t1, a0, a2

1:	addiu	a0, 1					# fill bytewise
	bne	t1, a0, 1b
	 sb	a1, -1(a0)

2:	jr	ra					# done
	 nop
	END(memset)
