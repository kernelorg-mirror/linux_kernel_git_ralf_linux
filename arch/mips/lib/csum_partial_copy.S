/*
 * This file is subject to the terms and conditions of the GNU General Public
 * License.  See the file "COPYING" in the main directory of this archive
 * for more details.
 *
 * Copyright (C) 1998 Ralf Baechle
 *
 * $Id: csum_partial_copy.S,v 1.1 1998/04/14 22:32:24 ralf Exp $
 */
#include <asm/asm.h>
#include <asm/regdef.h>

#define ADDC(sum,reg)			\
	addu	sum, reg;		\
	sltu	v1, sum, reg;		\
	addu	sum, v1

/* ascending order, destination aligned  */
#define CSUM_BIGCHUNK(src, dst, offset, sum, t0, t1, t2, t3) \
	lw	t0, (offset + 0x00)(src); \
	lw	t1, (offset + 0x04)(src); \
	lw	t2, (offset + 0x08)(src); \
	lw	t3, (offset + 0x0c)(src); \
	ADDC(sum, t0);                    \
	ADDC(sum, t1);                    \
	ADDC(sum, t2);                    \
	ADDC(sum, t3);                    \
	sw	t0, (offset + 0x00)(dst); \
	sw	t1, (offset + 0x04)(dst); \
	sw	t2, (offset + 0x08)(dst); \
	sw	t3, (offset + 0x0c)(dst); \
	lw	t0, (offset + 0x10)(src); \
	lw	t1, (offset + 0x14)(src); \
	lw	t2, (offset + 0x18)(src); \
	lw	t3, (offset + 0x1c)(src); \
	ADDC(sum, t0);                    \
	ADDC(sum, t1);                    \
	ADDC(sum, t2);                    \
	ADDC(sum, t3);                    \
	sw	t0, (offset + 0x10)(dst); \
	sw	t1, (offset + 0x14)(dst); \
	sw	t2, (offset + 0x18)(dst); \
	sw	t3, (offset + 0x1c)(dst)

/* ascending order, destination unaligned  */
#define UCSUM_BIGCHUNK(src, dst, offset, sum, t0, t1, t2, t3) \
	lw	t0, (offset + 0x00)(src); \
	lw	t1, (offset + 0x04)(src); \
	lw	t2, (offset + 0x08)(src); \
	lw	t3, (offset + 0x0c)(src); \
	ADDC(sum, t0);                    \
	ADDC(sum, t1);                    \
	ADDC(sum, t2);                    \
	ADDC(sum, t3);                    \
	usw	t0, (offset + 0x00)(dst); \
	usw	t1, (offset + 0x04)(dst); \
	usw	t2, (offset + 0x08)(dst); \
	usw	t3, (offset + 0x0c)(dst); \
	lw	t0, (offset + 0x10)(src); \
	lw	t1, (offset + 0x14)(src); \
	lw	t2, (offset + 0x18)(src); \
	lw	t3, (offset + 0x1c)(src); \
	ADDC(sum, t0);                    \
	ADDC(sum, t1);                    \
	ADDC(sum, t2);                    \
	ADDC(sum, t3);                    \
	usw	t0, (offset + 0x10)(dst); \
	usw	t1, (offset + 0x14)(dst); \
	usw	t2, (offset + 0x18)(dst); \
	usw	t3, (offset + 0x1c)(dst)

#
# a0: source address
# a1: destination address
# a2: length of the area to checksum
# a3: partial checksum
#

#define src a0
#define dest a1
#define sum v0

	.text
	.set	noreorder

/* unknown src/dst alignment and < 8 bytes to go  */
small_csumcpy:
	move	a2, t2

	andi	t0, a2, 4
	beqz	t0, 1f
	 andi	t0, a2, 2

	/* Still a full word to go  */
	ulw	t1, (src)
	addiu	src, 4
	usw	t1, (dest)
	addiu	dest, 4
	ADDC(sum, t1)

1:	move	t1, zero
	beqz	t0, 1f
	 andi	t0, a2, 1

	/* Still a halfword to go  */
	ulhu	t1, (src)
	addiu	src, 2
	ush	t1, (dest)
	addiu	dest, 2

1:	beqz	t0, 1f
	 sll	t1, t1, 16

	lbu	t2, (src)
	 nop
	sb	t2, (dest)

#ifdef __MIPSEB__
	sll	t2, t2, 8
#endif
	or	t1, t2

1:	ADDC(sum, t1)

	/* fold checksum */
	sll	v1, sum, 16
	addu	sum, v1
	sltu	v1, sum, v1
	srl	sum, sum, 16
	addu	sum, v1

	/* odd buffer alignment? */
	beqz	t7, 1f
	 nop
	sll	v1, sum, 8
	srl	sum, sum, 8
	or	sum, v1
	andi	sum, 0xffff
1:
	.set	reorder
	/* Add the passed partial csum.  */
	ADDC(sum, a3)
	jr	ra
	.set	noreorder

/* ------------------------------------------------------------------------- */

	.align	5
LEAF(csum_partial_copy)
 move sum, zero
 move t7, zero
	xor	t0, dest, src
	andi	t0, t0, 0x3
	beqz	t0, can_align
	 sltiu	t8, a2, 0x8

	b	memcpy_u_src			# bad alignment
	 move	t2, a2

can_align:
	bnez	t8, small_csumcpy		# < 8 bytes to copy
	 move	t2, a2

	beqz	a2, out
	 andi	t7, src, 0x1			# odd buffer?

hword_align:
	beqz	t7, word_align
	 andi	t8, src, 0x2

	lbu	t0, (src)
	subu	a2, a2, 0x1
	sb	t0, (dest)
#ifdef __MIPSEL__
	sll	t0, t0, 8
#endif
	ADDC(sum, t0)
	addu	src, src, 0x1
	addu	dest, dest, 0x1
	andi	t8, src, 0x2

word_align:
	beqz	t8, dword_align
	 sltiu	t8, a2, 56

	lhu	t0, (src)
	subu	a2, a2, 0x2
	sh	t0, (dest)
	ADDC(sum, t0)
	sltiu	t8, a2, 56
	addu	dest, dest, 0x2
	addu	src, src, 0x2

dword_align:
	bnez	t8, do_end_words
	 move	t8, a2

	andi	t8, src, 0x4
	beqz	t8, qword_align
	 andi	t8, src, 0x8

	lw	t0, 0x00(src)
	subu	a2, a2, 0x4
	ADDC(sum, t0)
	sw	t0, 0x00(dest)
	addu	src, src, 0x4
	addu	dest, dest, 0x4
	andi	t8, src, 0x8

qword_align:
	beqz	t8, oword_align
	 andi	t8, src, 0x10

	lw	t0, 0x00(src)
	lw	t1, 0x04(src)
	subu	a2, a2, 0x8
	ADDC(sum, t0)
	ADDC(sum, t1)
	sw	t0, 0x00(dest)
	addu	src, src, 0x8
	sw	t1, 0x04(dest)
	andi	t8, src, 0x10
	addu	dest, dest, 0x8

oword_align:
	beqz	t8, begin_movement
	 srl	t8, a2, 0x7

	lw	t3, 0x08(src)			# assumes subblock ordering
	lw	t4, 0x0c(src)
	lw	t0, 0x00(src)
	lw	t1, 0x04(src)
	ADDC(sum, t3)
	ADDC(sum, t4)
	ADDC(sum, t0)
	ADDC(sum, t1)
	sw	t3, 0x08(dest)
	subu	a2, a2, 0x10
	sw	t4, 0x0c(dest)
	addu	src, src, 0x10
	sw	t0, 0x00(dest)
	srl	t8, a2, 0x7
	addu	dest, dest, 0x10
	sw	t1, -0x0c(dest)

begin_movement:
	beqz	t8, 0f
	 andi	t2, a2, 0x40

move_128bytes:
	CSUM_BIGCHUNK(src, dest, 0x00, sum, t0, t1, t3, t4)
	CSUM_BIGCHUNK(src, dest, 0x20, sum, t0, t1, t3, t4)
	CSUM_BIGCHUNK(src, dest, 0x40, sum, t0, t1, t3, t4)
	CSUM_BIGCHUNK(src, dest, 0x60, sum, t0, t1, t3, t4)
	subu	t8, t8, 0x01
	addu	src, src, 0x80
	bnez	t8, move_128bytes
	 addu	dest, dest, 0x80

0:
	beqz	t2, 1f
	 andi	t2, a2, 0x20

move_64bytes:
	CSUM_BIGCHUNK(src, dest, 0x00, sum, t0, t1, t3, t4)
	CSUM_BIGCHUNK(src, dest, 0x20, sum, t0, t1, t3, t4)
	addu	src, src, 0x40
	addu	dest, dest, 0x40

1:
	beqz	t2, do_end_words
	 andi	t8, a2, 0x1c

move_32bytes:
	CSUM_BIGCHUNK(src, dest, 0x00, sum, t0, t1, t3, t4)
	andi	t8, a2, 0x1c
	addu	src, src, 0x20
	addu	dest, dest, 0x20

do_end_words:
	beqz	t8, maybe_end_cruft
	 srl	t8, t8, 0x2

end_words:
	lw	t0, (src)
	subu	t8, t8, 0x1
	ADDC(sum, t0)
	sw	t0, (dest)
	addu	src, src, 0x4
	bnez	t8, end_words
	 addu	dest, dest, 0x4

maybe_end_cruft:
	andi	t2, a2, 0x3

small_memcpy:
 j small_csumcpy; move a2, t2
	beqz	t2, out
	 move	a2, t2

end_bytes:
	lb	t0, (src)
	subu	a2, a2, 0x1
	sb	t0, (dest)
	addu	src, src, 0x1
	bnez	a2, end_bytes
	 addu	dest, dest, 0x1

out:
	jr	ra
	 move	v0, sum

/* ------------------------------------------------------------------------- */

/* Bad, bad.  At least try to align the source  */

memcpy_u_src:
	bnez	t8, small_memcpy		# < 8 bytes?
	 move	t2, a2

	beqz	a2, out
	 andi	t7, src, 0x1			# odd alignment?

u_hword_align:
	beqz	t7, u_word_align
	 andi	t8, src, 0x2

	lbu	t0, (src)
	subu	a2, a2, 0x1
	sb	t0, (dest)
#ifdef __MIPSEL__
	sll	t0, t0, 8
#endif
	ADDC(sum, t0)
	addu	src, src, 0x1
	addu	dest, dest, 0x1
	andi	t8, src, 0x2

u_word_align:
	beqz	t8, u_dword_align
	 sltiu	t8, a2, 56

	lhu	t0, (src)
	subu	a2, a2, 0x2
	ush	t0, (dest)
	ADDC(sum, t0)
	sltiu	t8, a2, 56
	addu	dest, dest, 0x2
	addu	src, src, 0x2

u_dword_align:
	bnez	t8, u_do_end_words
	 move	t8, a2

	andi	t8, src, 0x4
	beqz	t8, u_qword_align
	 andi	t8, src, 0x8

	lw	t0, 0x00(src)
	subu	a2, a2, 0x4
	ADDC(sum, t0)
	usw	t0, 0x00(dest)
	addu	src, src, 0x4
	addu	dest, dest, 0x4
	andi	t8, src, 0x8

u_qword_align:
	beqz	t8, u_oword_align
	 andi	t8, src, 0x10

	lw	t0, 0x00(src)
	lw	t1, 0x04(src)
	subu	a2, a2, 0x8
	ADDC(sum, t0)
	ADDC(sum, t1)
	usw	t0, 0x00(dest)
	addu	src, src, 0x8
	usw	t1, 0x04(dest)
	andi	t8, src, 0x10
	addu	dest, dest, 0x8

u_oword_align:
	beqz	t8, u_begin_movement
	 srl	t8, a2, 0x7

	lw	t3, 0x08(src)			# assumes subblock ordering
	lw	t4, 0x0c(src)
	lw	t0, 0x00(src)
	lw	t1, 0x04(src)
	ADDC(sum, t3)
	ADDC(sum, t4)
	ADDC(sum, t0)
	ADDC(sum, t1)
	usw	t3, 0x08(dest)
	subu	a2, a2, 0x10
	usw	t4, 0x0c(dest)
	addu	src, src, 0x10
	usw	t0, 0x00(dest)
	srl	t8, a2, 0x7
	addu	dest, dest, 0x10
	usw	t1, -0x0c(dest)

u_begin_movement:
	beqz	t8, 0f
	 andi	t2, a2, 0x40

u_move_128bytes:
	UCSUM_BIGCHUNK(src, dest, 0x00, sum, t0, t1, t3, t4)
	UCSUM_BIGCHUNK(src, dest, 0x20, sum, t0, t1, t3, t4)
	UCSUM_BIGCHUNK(src, dest, 0x40, sum, t0, t1, t3, t4)
	UCSUM_BIGCHUNK(src, dest, 0x60, sum, t0, t1, t3, t4)
	subu	t8, t8, 0x01
	addu	src, src, 0x80
	bnez	t8, u_move_128bytes
	 addu	dest, dest, 0x80

0:
	beqz	t2, 1f
	 andi	t2, a2, 0x20

u_move_64bytes:
	UCSUM_BIGCHUNK(src, dest, 0x00, sum, t0, t1, t3, t4)
	UCSUM_BIGCHUNK(src, dest, 0x20, sum, t0, t1, t3, t4)
	addu	src, src, 0x40
	addu	dest, dest, 0x40

1:
	beqz	t2, u_do_end_words
	 andi	t8, a2, 0x1c

u_move_32bytes:
	UCSUM_BIGCHUNK(src, dest, 0x00, sum, t0, t1, t3, t4)
	andi	t8, a2, 0x1c
	addu	src, src, 0x20
	addu	dest, dest, 0x20

u_do_end_words:
	beqz	t8, u_maybe_end_cruft
	 srl	t8, t8, 0x2

u_end_words:
	lw	t0, 0x00(src)
	subu	t8, t8, 0x1
	ADDC(sum, t0)
	usw	t0, 0x00(dest)
	addu	src, src, 0x4
	bnez	t8, u_end_words
	 addu	dest, dest, 0x4

u_maybe_end_cruft:
	andi	t2, a2, 0x3

u_cannot_optimize:
 j small_csumcpy; move a2, t2
	beqz	t2, out
	 move	a2, t2

u_end_bytes:
	lb	t0, (src)
	subu	a2, a2, 0x1
	sb	t0, (dest)
	addu	src, src, 0x1
	bnez	a2, u_end_bytes
	 addu	dest, dest, 0x1

	jr	ra
	 move	v0, sum
	END(csum_partial_copy)
