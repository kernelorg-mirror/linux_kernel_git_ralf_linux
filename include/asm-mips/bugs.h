/*
 *  include/asm-mips/bugs.h
 *
 *  Copyright (C) 1995  Waldorf Electronics
 *  Copyright (C) 1997  Ralf Baechle
 *
 * $Id: bugs.h,v 1.1.1.1 1999/04/06 10:39:19 vladimir Exp $
 */
#include <asm/bootinfo.h>

/*
 * This is included by init/main.c to check for architecture-dependent bugs.
 *
 * Needs:
 *	void check_bugs(void);
 */


static inline void check_wait(void)
{
	printk("Checking for 'wait' instruction... ");
	switch(mips_cputype) {
	case CPU_R3081:
	case CPU_R3081E:
		wait_available = r3081_wait;
		printk(" available.\n");
		break;
	case CPU_R4200: 
	case CPU_R4300: 
	case CPU_R4600: 
	case CPU_R4640: 
	case CPU_R4650: 
	case CPU_R4700: 
	case CPU_R5000: 
	case CPU_NEVADA:
		wait_available = r4k_wait;
		printk(" available.\n");
		break;
	default:
		printk(" unavailable.\n");
		break;
	}
}

static void check_bugs(void)
{
	check_wait();
}
