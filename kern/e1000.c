#include <kern/e1000.h>
#include <kern/pmap.h>
#include <kern/picirq.h>
#include <kern/cpu.h>
#include <kern/env.h>

#include <inc/string.h>
#include <inc/error.h>

// LAB 6: Your driver code here


// we will have to allocate 4 buffers : the first for the tx descriptors and the 2nd for the tx packets, and similar for rcv

// the tx descriptor base address must be 16 bytes aligned and the descriptor total space must be 128 bytes aligned 
// we chose the number of tx descriptors to be 40 (this choice is random except it must satisfy the 128 byte alignment, so it must be a multiple of 8)
// the number of tx descriptors must be multiple iof 8 for alignment purposes, and must not be more than 64 to pass the test, we chose it to be 40

struct tx_desc tx_desc[NTXDESC] __attribute__ ((aligned (16))); 
struct rx_desc rxq[NRXDESC] __attribute__ ((aligned (16)));


// Allocating memory for tx buffer for the packets' data
struct packet tx_pkts_buf[NTXDESC];   // the struct packet is simply an array of characters, with 2048 elements 
struct packet rx_pkts[NRXDESC];       // 


// Base address of memory mapped controller registers
volatile uint32_t *net_reg;  // so that we can access the registers as an array, but bcz each elements will be 32 bit: we divided the registers by 4 

int
pci_nic_attach(struct pci_func *pcif)
{
	pci_func_enable(pcif);  

	// make mapping to the memory mapped I/O, so we can access it like we accesss the virtual memory
	net_reg = mmio_map_region((physaddr_t) pcif->reg_base[0], pcif->reg_size[0]); // // va= mmio (phy addr, size); and it will return the va assigned
	// note the region negotiated are only for mapping the registers and NOT for the packet or descriptor buffers

	cprintf("The NIC Status: %08x\n ", net_reg[2] );  //  This is to make sure we are done the mapping correctly and that we can read from the mapped register address space

	// Transmit initialization,  Trasmitter Descriptor Base Address Register
	net_reg[E1000_TDBAL] = PADDR(tx_desc); // The beginning address of the tx descriptor (must be physica addr)
	//net_reg[E1000_TDBAH] = 0; // only used for 64 bit addressing, its initial default value is 0 

	// TX Desc. Length ==> TDLEN represents the number of bytes allocated for the tx descriptor buffer and must be aligned by 128 bytes  
	net_reg[E1000_TDLEN] = NTXDESC * sizeof(struct tx_desc); // The total size of the tx descriptor [must be 128 bytes aligned]


	////// Although their initial values is zero, but just to make sure ... 
	net_reg[E1000_TDH] = 0;  // The head of the tx descriptor
	net_reg[E1000_TDT] = 0;  // The tail of the tx descriptor

	// Initialize the transmit control register 
	net_reg[E1000_TCTL] |= E1000_TCTL_EN;  //The transmitter is enabled when this bit is set to 1

	// Although not necessarily to work, but it is a good practise... 
	net_reg[E1000_TCTL] |= E1000_TCTL_PSP; // enable Pad Short Packets, Padding makes the packet 64 bytes long. The padding content is data.


//////////////////// Since we are using emulated hardware and virtual netowork, the following commands are not necessary, it would still work wihout them
	/////////////// Note that the initial values of collision registers are 0 which means no retransmission at all 
	//and the initial values of IPG are undefined/uknnown

	// Collision Threshold [bits 4 to 11],  determines the number of re-transmission attempts prior to giving up on the packet. 
	net_reg[E1000_TCTL] |= (0x10) << 4;	// the value chosen 0x10 as specified in the manuale, shifting by 4 bcz this field starts from the 4th bit

	// Collision Distance [bits 12 to 21, Specifies the minimum number of byte times that must elapse for proper CSMA/CD operation. 
	net_reg[E1000_TCTL] |= (0x40) << 12; // the value 0x40 is recommended from the manuale 
		
	//  Inter Packet Gap : A small pause sometimes is required before sending packets, which allows  devices to prepare for the receive of the next packet.
	// IPGR1 should be 2/3 of the IPGR2, since IPGR2 is recommended as 6, we chose IPGR1 to be 4
	net_reg[E1000_TIPG] |= (0xA);		 // IPGR bits are from bit 0 to bit 9
	net_reg[E1000_TIPG] |= (0x4 << 10); // bcz IPGR1 bits are bits 10 -19
	net_reg[E1000_TIPG] |= (0x6 << 20); // bcz IPGR2 bits are bits 20 -29


	// Initializing the tx descriptor buffer 
	int i;
	for (i = 0; i < NTXDESC; i++)
	{
		tx_desc[i].addr = PADDR(&tx_pkts_buf[i]); 	// the packet data that this tx descriptor has info about. // its physical addr bcz it is for the NIC 
		//tx_desc[i].cmd &= ~E1000_TXD_DEXT;	// To select legacy mode operation, bit 29 (TDESC.DEXT) should be set to 0b. 
		tx_desc[i].status |= E1000_TXD_DD;  	// setting the DD bit, 	bcz we used this to indicate whether the descriptor is free or not in the tx function
		// if DD bit is set, it means for the device driver that this descriptor is free and not used by the hardware 					
	}





	///////////////////  Receive Initialization //////////////////////////////

	// setting the MAC address for filtration purposes
	net_reg[E1000_RAL] = 0x12005452;
	net_reg[E1000_RAH] = 0x00005634 | E1000_RAH_AV;  

	net_reg[E1000_RDBAL] = PADDR(&rxq); // This is the base address of the descriptor ring 
	net_reg[E1000_RDBAH] = 0x0; 

	net_reg[E1000_RDLEN] = NRXDESC * sizeof(struct rx_desc);  // The totalsize of the descriptor 

	net_reg[E1000_RDH] = 0; // The head 
	net_reg[E1000_RDT] = NRXDESC - 1; // The tail should point to 1 descriptor beyond the Head per the manuale

	// Initialize the receive descriptors
	for (i = 0; i < NRXDESC; i++)
	 	{
		rxq[i].addr = PADDR(&rx_pkts[i]); 	// set packet buffer addr
		}

	// the Receive Control Register (RCTL)
	net_reg[E1000_RCTL] &= E1000_RCTL_LBM_NO;  // No loop back when we put those 2 bits as zeros 
	net_reg[E1000_RCTL] &= ~E1000_RCTL_BSEX ;  // no size extension, so along with the below line, the buffer size will be 2048 bytes
	net_reg[E1000_RCTL] &= E1000_RCTL_BSIZE_2048; // The receive buffer size will be 2048 bytes as long as BSEX bit is zero 
	net_reg[E1000_RCTL] |= E1000_RCTL_SECRC;  //  strip the cyclic redundancy check which used to detect if the bit is corrupted [simply bcz the grading script us to do it]
	net_reg[E1000_RCTL] &= ~E1000_RCTL_LPE;   // To disable long packets, otherwise we have to take care of using multiple descriptors for one packet 
	net_reg[E1000_RCTL] |= E1000_RCTL_EN;     // Enable the receiving 

	// NOTE:  multicast offset shift (MO)  & Recive minimum threshould RDMTS interrupt, Broadcast Accept mode BAM ar not needed

	return 0;

}
// The arguments passed to this function is addr: the address where the packets to be sent is stored. 
// len : the length of the packet [this length icludes all the header]
// if the return value is negative, it means there is an error
// The errors are: the buffer is full, and the size of the packet is bigger than the packet buffer
// Note that the tail will be used an index for both the descriptor buffer and the packet buffer 

int
nic_transmit(char* pkt_addr, size_t len)
{
	if (len > PKT_BUF_SIZE) //  if the packet is bigger than the packet buffer, return error
		return -1; 

	uint32_t tail_index = net_reg[E1000_TDT];  //The value stored in the descripor tail which is an index to both the tx descriptor buffer and the packet buffer 

	// The NIC sets the DD bit whenever it takes the descriptor if the RS bit in the command register was set
	if (!(tx_desc[tail_index].status & E1000_TXD_DD))  //if the DD bit in the status register is 0, it means the descriptor is used by the HW [means still point to data to be sent]
		return -1;  // this means the circular buffer is full, so the output envi. will try transmitting again after yielding ... 

		memmove((void *) &tx_pkts_buf[tail_index], (void *) pkt_addr, len); // // move the contents of the packet to the packet buffer 

		tx_desc[tail_index].status &= ~E1000_TXD_DD;  // The Hardware will set this bit, so we must reset it to indicate to us that this descriptor is used  
		tx_desc[tail_index].cmd |= E1000_TXD_EOP; 	// This bit says that the end of the packet is in this descriptor/buffer as the packet could be spread across several buffers
		tx_desc[tail_index].cmd |= E1000_TXD_RS;   // (report status bit), We have to set this bit in order to use the DD bit, 
		// as the HW will set the DD bit when it puts the packet in its own FIFO
		tx_desc[tail_index].length = len; // so the hardware will know how long is the packet and how much it needs to copy and send

		// Increment tail index
		net_reg[E1000_TDT] = (tail_index + 1) % NTXDESC; // increment the tail to be an index to the next descriptor/packet buffer

		return 0; // return 0 on success
}



// how to know if the queue is empty? simply when the DD bit is still zero, what would happen? the function would return -1 
// the syscall that have called this function will try again after yielding the cpu 

int
e1000_receive(char* pkt, size_t *length)
{
	size_t tail_idx = (net_reg[E1000_RDT] + 1) % NRXDESC; // so that the tail points to the next packet which has been written by the NIC 
	

	// To make sure the whole packet has received : both DD and EOP bits must be set 
	if ((rxq[tail_idx].status & E1000_RXD_STATUS_DD) == 0)
		return -1;

	if ((rxq[tail_idx].status & E1000_RXD_STATUS_EOP) == 0)
		return -1; 

	*length = rxq[tail_idx].length; // This is the length of the packet, and will be set by the NIC 
	memmove(pkt, &rx_pkts[tail_idx], *length);  // copy the packet from the ring buffer to the address provided as an argument to this function 

	rxq[tail_idx].status = 0x0;   // so the hardware would know that the descritor is free
	//rxq[tail_idx].status &= ~(E1000_RXD_STATUS_DD);   // clear the DD bit, bcz this descriptor is now free/empty after we copied the packet associated with it
	//rxq[tail_idx].status &= ~(E1000_RXD_STATUS_EOP); 

	net_reg[E1000_RDT] = tail_idx; // Now the tail has been increased by 1 , and points to a free descriptor 

	return 0;
}