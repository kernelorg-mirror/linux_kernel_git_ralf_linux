/* $Id: time.c,v 1.1 1997/10/23 22:26:44 ralf Exp $
 * time.c: Extracting time information from ARCS prom.
 *
 * Copyright (C) 1996 David S. Miller (dm@engr.sgi.com)
 */

#include <asm/sgialib.h>

struct linux_tinfo *prom_gettinfo(void)
{
	return romvec->get_tinfo();
}

unsigned long prom_getrtime(void)
{
	return romvec->get_rtime();
}
