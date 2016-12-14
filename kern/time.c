#include <kern/time.h>
#include <inc/assert.h>

static unsigned int ticks;

void
time_init(void)  //%% called in init.c 
{
	ticks = 0;
}

// This should be called once per timer interrupt.  A timer interrupt
// fires every 10 ms.
void
time_tick(void)
{
	ticks++;
	if (ticks * 10 < ticks)                    
		panic("time_tick: time overflowed");   //%% what is the problem if the timer overflowed??
}

unsigned int
time_msec(void)
{
	return ticks * 10;     //%% this will give us the time elapsed in ms
}
