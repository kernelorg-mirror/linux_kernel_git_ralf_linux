/*
 * This file is subject to the terms and conditions of the GNU General Public
 * License.  See the file "COPYING" in the main directory of this archive
 * for more details.
 *
 * Cobalt Qube specific PCI support.
 *
 * $Id: pci.c,v 1.1 1997/10/23 22:25:43 ralf Exp $
 */

#include <linux/config.h>
#include <linux/types.h>
#include <linux/bios32.h>
#include <linux/pci.h>
#include <asm/cobalt.h>
#include <asm/pci.h>
 
#undef PCI_DEBUG 

#ifdef CONFIG_PCI

static unsigned long
qube_pcibios_fixup(unsigned long mem_start, unsigned long mem_end)
{
        /*
         * Now tell the SCSI device that we expect an interrupt at
         * IRQ 7 and not the default 0.
         */
        pcibios_write_config_byte(0, 0x08<<3, PCI_INTERRUPT_LINE,
                                  COBALT_SCSI_IRQ);

        /*
         * Now tell the Ethernet device that we expect an interrupt at
         * IRQ 13 and not the default 189.
         */
        pcibios_write_config_byte(0, 0x07<<3, PCI_INTERRUPT_LINE,
                                  COBALT_ETHERNET_IRQ);
	return mem_start;  /* 911 SN: */
}

static int
pci_range_ck(unsigned char bus, unsigned char dev) 
{
	if ((bus == 0) && ( (dev==0) || ((dev>6) && (dev <=9))) )
		return 0;  /* OK device number  */

	return -1;  /* NOT ok device number */
}

/* 911 this func needs more work */
static void *
pci_get_addr (unsigned char dev, unsigned char fun, unsigned char offset)
{
	void *addr;

	*((unsigned long *) 0xB4000CF8) = 
		0x80000000 | (dev << 11) | (fun << 8) | offset ;

	addr = (void *)0xb4000cfc;

#ifdef PCI_DEBUG	
        printk("pci_get_addr: returning pci_addr 0x%lx\n", addr);
#endif
        return addr;
}
	

static int
qube_pcibios_read_config_dword (unsigned char bus, unsigned char dev,
                                unsigned char offset, unsigned int *val)
{
	unsigned long _val;
	unsigned long *ptr;
	unsigned char fun = dev&0x07;
	dev >>= 3;
#ifdef PCI_DEBUG	
	printk("PCI Read config dword[%d.%d.%x] = ", bus, dev, offset);
#endif	
	if (pci_range_ck(bus, dev))
	{
		*val = 0xFFFFFFFF;
		return PCIBIOS_DEVICE_NOT_FOUND;
	} else
	{
		ptr = (unsigned long *)pci_get_addr(dev, fun, offset);
#ifdef PCI_DEBUG	
		printk("[%x] ", ptr);
#endif		
		_val = (*ptr);
	}
#ifdef PCI_DEBUG	
	printk("%x\n", _val);
#endif	
	*val = _val;
	return PCIBIOS_SUCCESSFUL;
}

static int
qube_pcibios_read_config_word (unsigned char bus, unsigned char dev,
                             unsigned char offset, unsigned short *val)
{
	unsigned long _val;
	unsigned long *ptr;
	unsigned char fun = dev&0x07;
	dev >>= 3;
#ifdef PCI_DEBUG	
	printk("PCI Read config word[%d.%d.%x] = ", bus, dev, offset);
#endif	
	if (pci_range_ck(bus, dev))
	{
		*val = (unsigned char) -1;
		return PCIBIOS_DEVICE_NOT_FOUND;
	} else
	{
		ptr = (unsigned long *)pci_get_addr(dev, fun, offset);
#ifdef PCI_DEBUG	
		printk("[%x] ", ptr);
#endif		
		_val = (*ptr);
	}
#ifdef PCI_DEBUG	
	printk("%x\n", _val);
#endif		
	*val = ( ( offset & 0x02) ? (unsigned short) (_val >> 16) : (unsigned short)
		_val);
	return PCIBIOS_SUCCESSFUL;
}

static int
qube_pcibios_read_config_byte (unsigned char bus, unsigned char dev,
                               unsigned char offset, unsigned char *val)
{
	unsigned char _val;
	volatile unsigned char *ptr;
	unsigned char fun = dev&0x07;
	dev >>= 3;
#ifdef PCI_DEBUG	
	printk("PCI Read config byte[%d.%d.%x] = ", bus, dev, offset);
#endif		
	if (pci_range_ck(bus, dev))
	{
		*val = (unsigned char) -1;
		return PCIBIOS_DEVICE_NOT_FOUND;
	} else
	{
		ptr = (unsigned char *)pci_get_addr(dev, fun, offset); 
#ifdef PCI_DEBUG	
		printk("[%x] ", ptr);
#endif		
		_val = *ptr;
	}
#ifdef PCI_DEBUG	
	printk("%x\n", _val);
#endif
	*val = _val;
	return PCIBIOS_SUCCESSFUL;
}

static int
qube_pcibios_write_config_dword (unsigned char bus, unsigned char dev,
                                 unsigned char offset, unsigned int val)
{
	unsigned long _val;
	unsigned long *ptr;
	unsigned char fun = dev & 0x07;
	dev >>= 3;
	_val = (val);
#ifdef PCI_DEBUG	
	printk("PCI Write config dword[%d.%d.%x] = %x\n", bus, dev, offset, _val);
#endif		
	if (pci_range_ck(bus, dev))
	{
		return PCIBIOS_DEVICE_NOT_FOUND;
	} else
	{
		ptr = (unsigned long *)pci_get_addr(dev, fun, offset);
		*ptr = _val;
	}
	return PCIBIOS_SUCCESSFUL;
}

static int
qube_pcibios_write_config_word (unsigned char bus, unsigned char dev,
                                unsigned char offset, unsigned short val)
{
	unsigned short _val;
	unsigned short *ptr;
	unsigned char fun = dev&0x07;
	dev >>= 3;
	_val = (val);
#ifdef PCI_DEBUG	
	printk("PCI Write config word[%d.%d.%x] = %x\n", bus, dev, offset, _val);
#endif		
	if (pci_range_ck(bus, dev))
	{
		return PCIBIOS_DEVICE_NOT_FOUND;
	} else
	{
		ptr = (unsigned short *)pci_get_addr(dev, fun, offset);
		*ptr = _val;
	}
	return PCIBIOS_SUCCESSFUL;
}

static int
qube_pcibios_write_config_byte (unsigned char bus, unsigned char dev,
                                unsigned char offset, unsigned char val)
{
	unsigned char _val;
	unsigned char *ptr;
	unsigned char fun = dev&0x07;
	dev >>= 3;
	_val = val;
#ifdef PCI_DEBUG	
	printk("PCI Write config byte[%d.%d.%x] = %x\n", bus, dev, offset, _val);
#endif		
	if (pci_range_ck(bus, dev))
	{
		return PCIBIOS_DEVICE_NOT_FOUND;
	} else
	{
		ptr = (unsigned char *)pci_get_addr(dev, fun, offset);
		*ptr = _val;
	}
	return PCIBIOS_SUCCESSFUL;
}


#if 0
/*SN: 911 This routine needs to be modified */
static int
qube_pcibios_find_device (unsigned short vendor, unsigned short device_id,
                          unsigned short index, unsigned char *bus,
                          unsigned char *dev)
{
	unsigned int w, desired = (device_id << 16) | vendor;
	int devnr;

	if (vendor == 0xffff) {
		return PCIBIOS_BAD_VENDOR_ID;
	}

	/* 911 REMOVE IMMEDIATELY!! */
//	*bus = 0;
//	*dev = 11;
//	return PCIBIOS_SUCCESSFUL;
	/* 911 REMOVE IMMEDIATELY!! */

	for (devnr = 0;  devnr < 10;  devnr++)
	{
		qube_pcibios_read_config_dword(0, devnr<<3, PCI_VENDOR_ID, &w);
		if (w == desired) {
			if (index == 0) {
				*bus = 0;
				*dev = devnr<<3;
				return PCIBIOS_SUCCESSFUL;
			}
			--index;
		}
	}
	return PCIBIOS_DEVICE_NOT_FOUND;
}

/*SN: 911 This routine needs to be modified */
static int
qube_pcibios_find_class (unsigned int class_code, unsigned short index, 
                         unsigned char *bus, unsigned char *dev)
{
	int dev_nr, class, indx;
	indx = 0;
#ifdef PCI_DEBUG	
	printk("pcibios_find_class - class: %x, index: %x", class_code, index);
#endif	
	for (dev_nr = 0;  dev_nr < 9;  dev_nr++)
	{
		pcibios_read_config_dword(0, dev_nr<<3, PCI_CLASS_REVISION, &class);
		if ((class>>8) == class_code)
		{
			if (index == indx)
			{
				*bus = 0;
				*dev = dev_nr<<3;
#ifdef PCI_DEBUG
	printk(" - device: %x\n", dev_nr);
#endif	
				return (0);
			}
			indx++;
		}
	}
#ifdef PCI_DEBUG
	printk(" - not found\n");
#endif	
	return PCIBIOS_DEVICE_NOT_FOUND;
}
#endif

struct pci_ops qube_pci_ops = {
	qube_pcibios_fixup,
	qube_pcibios_read_config_byte,
	qube_pcibios_read_config_word,
	qube_pcibios_read_config_dword,
	qube_pcibios_write_config_byte,
	qube_pcibios_write_config_word,
	qube_pcibios_write_config_dword
};

#endif /* CONFIG_PCI */
