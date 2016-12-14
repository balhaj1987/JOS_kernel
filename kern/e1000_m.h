#ifndef JOS_KERN_E1000_H
#define JOS_KERN_E1000_H

#include <kern/pci.h>
#include <inc/types.h>

#define VENDOR_ID 0x8086
#define DEVICE_ID 0x100E  // should it be E capital?
#define PKT_SIZE 2048
#define NTXDESC 32



#define NRXDESC 128

#define NELEM_MTA 128

#define PKT_BUF_SIZE 2048

#define E1000_NUM_MAC_WORDS 3



int pci_nic_attach(struct pci_func *pcif);
int nic_tx(const char* addr, int len);


// each transmit descriptor is 16 bytes
struct tx_desc
{
	uint64_t addr;
	uint16_t length;
	uint8_t cso;
	uint8_t cmd;
	uint8_t status;
	uint8_t css;
	uint16_t special;
};



// Packet buffer
struct packet
{
	uint8_t buf[PKT_SIZE];

};   

#define E1000_TXD_DEXT	0x20 /* bit 5 in CMD section */
#define E1000_TXD_RS	0x8 /* bit 3 in CMD section */
#define E1000_TXD_DD	0x1 /* bit 0 in STATUS section */
#define E1000_TXD_EOP	0x1 /* bit 0 of CMD section */


#define E1000_TDBAL    0x03800  /* TX Descriptor Base Address Low - RW */
#define E1000_TDBAH    0x03804  /* TX Descriptor Base Address High - RW */
#define E1000_TDLEN    0x03808  /* TX Descriptor Length - RW */
#define E1000_TDH      0x03810  /* TX Descriptor Head - RW */
#define E1000_TDT      0x03818  /* TX Descripotr Tail - RW */
#define E1000_TIDV     0x03820  /* TX Interrupt Delay Value - RW */
#define E1000_TXDCTL   0x03828  /* TX Descriptor Control - RW */
#define E1000_TADV     0x0382C  /* TX Interrupt Absolute Delay Val - RW */
#define E1000_TSPMT    0x03830  /* TCP Segmentation PAD & Min Threshold - RW */
#define E1000_TARC0    0x03840  /* TX Arbitration Count (0) */



/* Transmit Control */
#define E1000_TCTL     0x00400  /* TX Control - RW */

#define E1000_TCTL_EN     0x00000002    /* enable tx */
#define E1000_TCTL_PSP    0x00000008    /* pad short packets */
#define E1000_TCTL_CT     0x00000ff0    /* collision threshold */
#define E1000_TCTL_COLD   0x003ff000    /* collision distance */

#define E1000_TIPG     0x00410  /* TX Inter-packet gap -RW */



#define E1000_TXD_CMD_EOP    0x01000000 /* End of Packet */

#define E1000_TXD_CMD_RS     0x08000000 /* Report Status */

#define E1000_TXD_STAT_DD    0x00000001 /* Descriptor Done */



#endif	// JOS_KERN_E1000_H
