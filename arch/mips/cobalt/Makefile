#
# Makefile for the Cobalt micro systems family specific parts of the kernel
#
# Note! Dependencies are done automagically by 'make dep', which also
# removes any old dependencies. DON'T put your own dependencies here
# unless it's something special (ie not a .c file).
#
# $Id: Makefile,v 1.2 2002/11/19 03:17:59 ralf Exp $
#

.S.s:
	$(CPP) $(CFLAGS) -D__ASSEMBLY__ $< -o $*.s
.S.o:
	$(CC) $(CFLAGS) -D__ASSEMBLY__ -c $< -o $*.o

all: cobalt.o
O_TARGET := cobalt.o
O_OBJS	 := cobaltscc.o hw-access.o int-handler.o pci.o reset.o setup.o via.o

int-handler.o: int-handler.S

clean:

include $(TOPDIR)/Rules.make
