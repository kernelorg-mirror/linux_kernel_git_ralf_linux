/*
 *  Reset a Cobalt Qube.
 *
 * $Id: reset.c,v 1.1 1997/10/23 22:25:43 ralf Exp $
 */
#include <linux/sched.h>
#include <linux/mm.h>
#include <asm/io.h>
#include <asm/pgtable.h>
#include <asm/processor.h>
#include <asm/reboot.h>
#include <asm/system.h>

void cobalt_machine_restart(char *command)
{
	*(volatile char *)0xbc000000 = 0x0f;

	/*
	 * Ouch, we're still alive ... This time we take the silver bullet ...
	 * ... and find that we leave the hardware in a state in which the
	 * kernel in the flush locks up somewhen during of after the PCI
	 * detection stuff.
	 */
	set_cp0_status((ST0_BEV | ST0_ERL), (ST0_BEV | ST0_ERL));
	set_cp0_config(CONFIG_CM_CMASK, CONFIG_CM_UNCACHED);
	flush_cache_all();
	write_32bit_cp0_register(CP0_WIRED, 0);
	__asm__ __volatile__(
		"jr\t%0"
		:
		: "r" (0xbfc00000));
}

void cobalt_machine_halt(void)
{
	/* Save some power ... */
	cli();
	while(1)
		if(wait_available)
			__asm__ __volatile__(
				".set\tnoreorder\n\t"
				".set\tmips3\n\t"
				"wait\n\t"
				".set\tmips0\n\t"
				".set\treorder");
}

/*
 * This triggers the luser mode device driver for the power switch ;-)
 */
void cobalt_machine_power_off(void)
{
	printk("You can switch the machine off now.\n");
	cobalt_machine_halt();
}
