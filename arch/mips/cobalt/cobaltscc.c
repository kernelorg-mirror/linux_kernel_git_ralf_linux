/*
 * Filename: cobaltscc.c
 * 
 * Description: Functions for supporting and testing serial I/O
 * 
 * Author(s): Timothy Stonis
 * 
 * Copyright 1997, Cobalt Microserver, Inc.
 *
 * $Id: cobaltscc.c,v 1.1 1997/10/23 22:25:41 ralf Exp $
 */
#include "z8530.h"
#include "diagdefs.h"
#include "serial.h"

/*
 * Function prototypes
 */
void InitSerialPort(unsigned char *);
void RegisterDelay(void);
void InitScc(void);

/*
 * Function: RegisterDelay
 *
 * Description: A little delay since the SCC can't handle quick consecutive 
 *              accesses
 * In: none
 * Out: none
 */
void RegisterDelay(void)
{
	register int ctr;
  
	for(ctr=0;ctr<0x40;ctr++);
}

/*
 * Function: SccInit
 *
 * Description: Initialize all the SCC registers for 19200 baud, asynchronous,
 *		8 bit, 1 stop bit, no parity communication (Channel A)
 *
 * In: none
 *
 * Out: none
 */
void InitScc(void)
{
	/* Force hardware reset */
	Write8530(kSCC_ChanA | kSCC_Command, R9 | NULLCODE);
	RegisterDelay();
	Write8530(kSCC_ChanA, FHWRES);
	RegisterDelay();
  
	/* x32 clock, 1 stop bit, no parity */
	Write8530(kSCC_ChanA | kSCC_Command, R4 | NULLCODE);
	RegisterDelay();
	Write8530(kSCC_ChanA, X16CLK | SB1);
	RegisterDelay();
  
	/* Rx 8 bits, Rx disabled */
	Write8530(kSCC_ChanA | kSCC_Command, R3 | NULLCODE);
	RegisterDelay();
	Write8530(kSCC_ChanA, Rx8);
	RegisterDelay();
   
	/* Tx 8 bits, DTR, RTS, Tx off */
	Write8530(kSCC_ChanA | kSCC_Command, R5 | NULLCODE);
	RegisterDelay();
	Write8530(kSCC_ChanA, Tx8 | DTR | RTS);
	RegisterDelay();

	/* Int. Disabled */
	Write8530(kSCC_ChanA | kSCC_Command, R9 | NULLCODE);
	RegisterDelay();
	Write8530(kSCC_ChanA, 0x0);
	RegisterDelay();

	/* NRZ */
	Write8530(kSCC_ChanA | kSCC_Command, R10 | NULLCODE);
	RegisterDelay();
	Write8530(kSCC_ChanA, NRZ);
	RegisterDelay();

	/* Tx & Rx = BRG out, TRxC = BRG out */
	Write8530(kSCC_ChanA | kSCC_Command, R11 | NULLCODE);
	RegisterDelay();
	Write8530(kSCC_ChanA, TCBR | RCBR | TRxCBR | TRxCOI); 
	RegisterDelay();

	/* Time constant = 0x01 */
	Write8530(kSCC_ChanA | kSCC_Command, R12 | NULLCODE);
	RegisterDelay();
	Write8530(kSCC_ChanA, kSCC_115200 ); 
	RegisterDelay();

	/* Time constant high = 0x00 */
	Write8530(kSCC_ChanA | kSCC_Command, R13 | NULLCODE);
	RegisterDelay();
	Write8530(kSCC_ChanA, 0x00); 
	RegisterDelay();

	/* BRG in = ~RTxC, BRG off, loopback */
	Write8530(kSCC_ChanA | kSCC_Command, R14 | NULLCODE);
	RegisterDelay();
	Write8530(kSCC_ChanA, LOOPBAK | BRSRC); 
	RegisterDelay();
}

/*
 * Function: EnableScc
 *
 * Description: Enable transmit and receive on SCC Channel A
 * In: none
 * Out: none
 */
void EnableScc(void)
{
	/* Enable BRG */
	Write8530(kSCC_ChanA | kSCC_Command, R14 | NULLCODE);
	RegisterDelay();
	Write8530(kSCC_ChanA, BRENABL | BRSRC);
	RegisterDelay();
  
	/* Rx enable (Rx 8 bits) */
	Write8530(kSCC_ChanA | kSCC_Command, R3 | NULLCODE);
	RegisterDelay();
	Write8530(kSCC_ChanA, RxENABLE | Rx8);
	RegisterDelay();

	/* Tx enable (Tx8, DTR, RTS) */
	Write8530(kSCC_ChanA | kSCC_Command, R5 | NULLCODE);
	RegisterDelay();
	Write8530(kSCC_ChanA, TxENAB | Tx8 | DTR | RTS); 
	RegisterDelay();
}

/*
 * Function: SccOutb
 *
 * Description: Write a byte to the SCC (Channel A) and blink LED
 * In: Byte to send
 * Out: none
 */
void SccOutb(unsigned char byte)
{
	/* LED on.. */
	Write8530(kSCC_ChanB | kSCC_Command, R5);
	RegisterDelay();
	Write8530(kSCC_ChanB | kSCC_Command, RTS);
	RegisterDelay();
 
	while ((Read8530(kSCC_ChanA) & Tx_BUF_EMP) == 0)
		RegisterDelay();
 
	Write8530(kSCC_ChanA | kSCC_Direct, byte);
	RegisterDelay();
 
	/* LED off.. */
	Write8530(kSCC_ChanB | kSCC_Command, R9);
	RegisterDelay();
	Write8530(kSCC_ChanB | kSCC_Command, CHRB);
	RegisterDelay();
}

/*
 * Function: SccInb
 *
 * Description: Read a byte from the SCC (Channel A)
 * In: Byte to send
 * Out: none
 */
void SccInb(unsigned char *byte)
{
	while ((Read8530(kSCC_ChanA) & Rx_CH_AV) == 0)
		RegisterDelay();
 
	*byte = Read8530(kSCC_ChanA | kSCC_Direct);
	RegisterDelay();
}

/*
 * Function: SccWrite
 *
 * Description: Write a null terminated string to the SCC 
 * In: C string
 * Out: none
 */
void SccWrite(const unsigned char *string)
{
	while((*string) != 0) { 
		if (*string == 10)
			SccOutb((unsigned char) 13);
		SccOutb(*(string++));
	}
}

/*
 * Function: InitSerialPort
 *
 * Description: Initialize the SCC and spit out the header message 
 * In: Header message
 * Out: none
 */
void InitSerialPort(unsigned char *msg)
{
	InitScc();
	EnableScc();
	SccWrite(msg);
}

/*
 * Function: SccInbTimeout
 *
 * Description: Read a byte from the SCC (Channel A) with timeout
 * In: Byte to send
 * Out: Timeout status
 */
unsigned char SccInbTimeout(unsigned char *byte, unsigned long timeout)
{
	unsigned long ctr = 0;

	while ((Read8530(kSCC_ChanA) & Rx_CH_AV) == 0) {
		RegisterDelay();
		if ((ctr++) > timeout)
			return 0xFF;
	}

	*byte = Read8530(kSCC_ChanA | kSCC_Direct);
	RegisterDelay();
 
	return 0;
}
