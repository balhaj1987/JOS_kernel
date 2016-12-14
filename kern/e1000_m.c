#include <kern/e1000.h>
#include <kern/pmap.h>
#include <kern/picirq.h>
#include <kern/cpu.h>
#include <kern/env.h>

#include <inc/string.h>
#include <inc/error.h>

// LAB 6: Your driver code here




// we will have to allocate 2 buffers : the first for the tx descriptors and the 2nd for the tx packets

// the tx descriptor base address must be 16 bytes aligned and its total space must be 128 bytes aligned 
// we chose the number of tx descriptors to be 32 (this choice is random except it must satisfy the 128 byte alignment, so it must be a multiple of 8)
// the number of tx descriptors must be multiple iof 8 for alignment purposes, and must not be more than 64 to pass the test, we chose it to be 32 

struct tx_desc tx_desc_buffer[NTXDESC] __attribute__ ((aligned (16)));  // the base address must be 16 byte aligned
struct packet tx_pkt_buffer[NTXDESC];   // allocate a ring buffer to store the data of the transmitted packets


volatile uint32_t *net_reg;



int
pci_nic_attach(struct pci_func *pcif)
{

	pci_func_enable(pcif);
	net_reg = mmio_map_region((physaddr_t) pcif->reg_base[0], pcif->reg_size[0]); // mmio (addr, size); and it will return the va assigned

	cprintf("The NIC Status: %08x\n ", net_reg[2] );  //  This is to make sure we are done the mapping correctly and that we can read from the mapped register address space

	

	net_reg[E1000_TDBAL/4] = PADDR(tx_desc_buffer);  // The beginning address of the tx descriptor (must be physica addr)
	net_reg[E1000_TDBAH/4] =  0x00000000;;  // only used for 64 bit addressing 

	// TDLEN represents the number of bytes allocated for the tx descriptor buffer and must be aligned by 128 bytes 
	net_reg[E1000_TDLEN/4] = NTXDESC * sizeof(struct tx_desc);  // The total size of the tx descriptor [must be 128 bytes aligned]

	net_reg[E1000_TDH/4] =  0x00000000;  // The head of the tx descriptor
	net_reg[E1000_TDT/4] =  0x00000000;  // The tail of the tx descripto



    net_reg[E1000_TCTL/4] |= E1000_TCTL_EN;
	net_reg[E1000_TCTL/4] |= E1000_TCTL_PSP;
	net_reg[E1000_TCTL/4] |= E1000_TCTL_CT;
	net_reg[E1000_TCTL/4] |= E1000_TCTL_COLD;

net_reg[E1000_TIPG/4] |= (0xA << 0);
	net_reg[E1000_TIPG/4] |= (0x8 << 10);
	net_reg[E1000_TIPG/4] |= (0xC << 20);

	// Zero out the whole transmission descriptor queue
	memset(tx_desc_buffer, 0, sizeof(struct tx_desc) * NTXDESC);

/*

	// Initialize the transmit control register 
	net_reg[E1000_TCTL/4] |= E1000_TCTL_EN;   // The transmitter is enabled when this bit is set to 1
	net_reg[E1000_TCTL/4] |= E1000_TCTL_PSP; // enable Pad Short Packets, Padding makes the packet 64 bytes long. The padding content is data. 
	//net_reg[E1000_TCTL] |= E1000_TCTL_CT;  // Collision Threshold [bits 4 to 11],  determines the number of attempts at re-transmission prior to giving up on the packet. 
	net_reg[E1000_TCTL/4] |= (0x10) << 4;  // the value chosen 0x10 as specified in the manuale, shifting by 4 bcz it starts from the 4th bit
	//net_reg[E1000_TCTL] |= E1000_TCTL_COLD;  // Collision Distance [bits 12 to 21, Specifies the minimum number of byte times that must elapse for proper CSMA/CD operation. 
	net_reg[E1000_TCTL/4] |= (0x40) << 12; // the value 0x40 is recommended from the manuale 


	//  Inter Packet Gap 
	// IPGR1 should be 2/3 of the IPGR2, since IPGR2 is recommended as 6, we chose IPGR1 to be 4
	net_reg[E1000_TIPG/4] = 0x0;
	net_reg[E1000_TIPG/4] |= (0x6) << 20; // IPGR2   // bcz IPGR2 bits are bits 20 -29
	net_reg[E1000_TIPG/4] |= (0x4) << 10; // IPGR1   // bcz IPGR1 bits are bits 10 -19
	net_reg[E1000_TIPG/4] |= 0xA; // IPGR bits are from bit 0 to bit 9 

*/

	int i;
	for (i = 0; i < NTXDESC; i++) {
		tx_desc_buffer[i].addr = PADDR(&tx_desc_buffer[i]); 	// set packet buffer addr
		//txq[i].cmd |= E1000_TXD_RS;			// set RS bit
		tx_desc_buffer[i].cmd &= ~E1000_TXD_DEXT;		// set legacy descriptor mode
		tx_desc_buffer[i].status |= E1000_TXD_DD;		// set DD bit, all descriptors
											// are initally free
	}


	
	return 1;
}


// The arguments passed to this function is add, which is the address where the packets to be sent is stored. 
// len : the length of the packet [this length icludes all the header]
// if the return value is negative, it means there is an error
// The errors are: the buffer is fall, and the size of the packet is bigger than the packet buffer
// Note that the tail will be used an index for both the descriptor buffer and the packet buffer 

int nic_tx(const char* addr, int len) 
{
	//cprintf(" I am in nic_tx \n\n\n\n");

	if ( len > PKT_BUF_SIZE) // if the packet is bigger than the packet buffer, return error
		return -1;

	uint32_t tail = net_reg[E1000_TDT/4];   // The value stored in the descripor tail which is an index for both the tx descriptor buffer and the packet buffer 
	cprintf("<<<<<<<<<<<<<<<<<<< tail = %x \n\n", tail);
	//cprintf(" I am in nic_tx  1 \n\n\n\n");

	// The NIC sets the DD bit whenever it takes the descriptor if the RS bit in the command register was set 
	if ( !(tx_desc_buffer[tail].status & E1000_TXD_STAT_DD) ) // if the DD bit in the status register is 1, it means the descriptor is free
		return -1; // this means the circular buffer is full 
	cprintf(" I am in nic_tx  2 \n\n\n\n");

	memmove(&tx_pkt_buffer[tail], addr, len);  // move the contents of the packet to the packet buffer 

	//reset DD bit
	tx_desc_buffer[tail].status &= ~E1000_TXD_STAT_DD;   // Reset the DD bit 
	//set report status bit
	tx_desc_buffer[tail].cmd |= E1000_TXD_CMD_RS ;  // We have to set this bit in order to use the DD bit 
	tx_desc_buffer[tail].cmd |= E1000_TXD_CMD_EOP;  // This bit says that the end of the packet is in this descriptor/buffer as the packet could be spread across several buffers
	tx_desc_buffer[tail].length = len;		  // 

	net_reg[E1000_TDT/4] = (tail + 1) % NTXDESC ; // increment the tail to be an index to the next descriptor/packet buffer
		cprintf("<<<<<<<<<<<<<<<<<<< tail = %x \n\n", tail);

	cprintf(" I am at the end of nic_tx \n\n\n\n");
	
	return 0;

}

