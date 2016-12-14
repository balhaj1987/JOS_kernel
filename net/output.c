#include "ns.h"
#include <inc/syscall.h>
//#include <kern/syscall.h>

extern int  sys_send_packet(const char* va, int len) ;

extern union Nsipc nsipcbuf;

void
output(envid_t ns_envid)
{
	binaryname = "ns_output";

	// LAB 6: Your code here:
	// 	- read a packet from the network server
	//	- send the packet to the device driver
		int ret;

	// This should be run in forever loop and keep waiting for packets from the lwip which will put in the buffer for the nic to send
	while(1) 
	{
		ret = sys_ipc_recv(&nsipcbuf);  // to receive data from the lwip

		if ((thisenv->env_ipc_from != ns_envid) || (thisenv->env_ipc_value != NSREQ_OUTPUT)) 
			continue; // skip! don't send this packet bcz it is not SEND request or it is not from ns env. 

		while((ret = sys_send_packet(nsipcbuf.pkt.jp_data, nsipcbuf.pkt.jp_len)) < 0) // this syscall will simply call nic_transmit()
				sys_yield();// This will be executed if the circular buffer is full
		//nsipcbuf.pkt.jp_data : The address where the packet is stored 
		//nsipcbuf.pkt.jp_len  : The length of the packet
	}

}
