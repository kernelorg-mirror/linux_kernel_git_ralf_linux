/*
 * Copyright (C) 2000, 2004  Maciej W. Rozycki
 * Copyright (C) 2003 Ralf Baechle
 *
 * This file is subject to the terms and conditions of the GNU General Public
 * License.  See the file "COPYING" in the main directory of this archive
 * for more details.
 */
#ifndef __ASM_DIV64_H
#define __ASM_DIV64_H

#include <asm-generic/div64.h>

#if BITS_PER_LONG == 32

#include <asm/compiler.h>

/*
 * No traps on overflows for any of these...
 */

#define do_div64_32(res, high, low, base) ({ \
	unsigned long __quot, __mod; \
	unsigned long __cf, __tmp, __tmp2, __i; \
	\
	__asm__(".set	push\n\t" \
		".set	noat\n\t" \
		".set	noreorder\n\t" \
		"move	%2, $0\n\t" \
		"move	%3, $0\n\t" \
		"b	1f\n\t" \
		" li	%4, 0x21\n" \
		"0:\n\t" \
		"sll	$1, %0, 0x1\n\t" \
		"srl	%3, %0, 0x1f\n\t" \
		"or	%0, $1, %5\n\t" \
		"sll	%1, %1, 0x1\n\t" \
		"sll	%2, %2, 0x1\n" \
		"1:\n\t" \
		"bnez	%3, 2f\n\t" \
		" sltu	%5, %0, %z6\n\t" \
		"bnez	%5, 3f\n" \
		"2:\n\t" \
		" addiu	%4, %4, -1\n\t" \
		"subu	%0, %0, %z6\n\t" \
		"addiu	%2, %2, 1\n" \
		"3:\n\t" \
		"bnez	%4, 0b\n\t" \
		" srl	%5, %1, 0x1f\n\t" \
		".set	pop" \
		: "=&r" (__mod), "=&r" (__tmp), "=&r" (__quot), "=&r" (__cf), \
		  "=&r" (__i), "=&r" (__tmp2) \
		: "Jr" (base), "0" (high), "1" (low)); \
	\
	(res) = __quot; \
	__mod; })

#endif /* BITS_PER_LONG == 32 */

#if BITS_PER_LONG == 64

/*
 * No traps on overflows for any of these...
 */

/*
 * Don't use this one in new code
 */
#define do_div64_32(res, high, low, base) ({ \
	unsigned int __quot, __mod; \
	unsigned long __div; \
	unsigned int __low, __high, __base; \
	\
	__high = (high); \
	__low = (low); \
	__div = __high; \
	__div = __div << 32 | __low; \
	__base = (base); \
	\
	__mod = __div % __base; \
	__div = __div / __base; \
	\
	__quot = __div; \
	(res) = __quot; \
	__mod; })

#define __div64_32(n, base)						\
({									\
	unsigned long __cf, __tmp, __tmp2, __i;				\
	unsigned long __quot32, __mod32;				\
	unsigned long __high, __low;					\
	unsigned long long __n;						\
									\
	__high = *__n >> 32;						\
	__low = __n;							\
	__asm__(							\
	"	.set	push					\n"	\
	"	.set	noat					\n"	\
	"	.set	noreorder				\n"	\
	"	move	%2, $0					\n"	\
	"	move	%3, $0					\n"	\
	"	b	1f					\n"	\
	"	 li	%4, 0x21				\n"	\
	"0:							\n"	\
	"	sll	$1, %0, 0x1				\n"	\
	"	srl	%3, %0, 0x1f				\n"	\
	"	or	%0, $1, %5				\n"	\
	"	sll	%1, %1, 0x1				\n"	\
	"	sll	%2, %2, 0x1				\n"	\
	"1:							\n"	\
	"	bnez	%3, 2f					\n"	\
	"	 sltu	%5, %0, %z6				\n"	\
	"	bnez	%5, 3f					\n"	\
	"2:							\n"	\
	"	 addiu	%4, %4, -1				\n"	\
	"	subu	%0, %0, %z6				\n"	\
	"	addiu	%2, %2, 1				\n"	\
	"3:							\n"	\
	"	bnez	%4, 0b\n\t"					\
	"	 srl	%5, %1, 0x1f\n\t"				\
	"	.set	pop"						\
	: "=&r" (__mod32), "=&r" (__tmp),				\
	  "=&r" (__quot32), "=&r" (__cf),				\
	  "=&r" (__i), "=&r" (__tmp2)					\
	: "Jr" (base), "0" (__high), "1" (__low));			\
									\
	(__n) = __quot32;						\
	__mod32;							\
})

#endif /* BITS_PER_LONG == 64 */

#endif /* __ASM_DIV64_H */
