#include "ns.h"

extern  int sys_rcv_packet(char* va, size_t *len);
extern union Nsipc nsipcbuf;

void
input(envid_t ns_envid)
{
	binaryname = "ns_input";

	// LAB 6: Your code here:
	// 	- read a packet from the device driver
	//	- send it to the network server
	// Hint: When you IPC a page to the network server, it will be
	// reading from it for a while, so don't immediately receive
	// another packet in to the same physical page.


	
	char buf[2048];     // temporary buffer to store the data
	int perm = PTE_U | PTE_P | PTE_W;  // permissions 
	size_t len = 2047;

	while(1) 
	{

		int ret;
		while((ret = sys_rcv_packet(buf, &len)) < 0)  // This syscall will read the packet from the ring buffer 
			sys_yield();  // in case the receiver queue is empty (nothing has been received yet or at least the NIC didn't write anything yet )

		//previous page is automatically "page remove"ed
		while ((ret = sys_page_alloc(0, &nsipcbuf, perm)) < 0);

		nsipcbuf.pkt.jp_len = len; // this length will be stored by rx function bcz we passed a pointer, so it is actually the length of the packet. 
		memmove(nsipcbuf.pkt.jp_data, buf, len); // copy the packet to the nsipcbuf structure

		while ((ret = sys_ipc_try_send(ns_envid, NSREQ_INPUT, &nsipcbuf, perm)) < 0); // send the input request to the ns env. [server],
		// so it can forward the packet to the lwip to be processed
	} 
		


}
