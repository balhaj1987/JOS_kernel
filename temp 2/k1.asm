
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 56 00 00 00       	call   f0100094 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 0c             	sub    $0xc,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	53                   	push   %ebx
f010004b:	68 20 1a 10 f0       	push   $0xf0101a20
f0100050:	e8 f4 09 00 00       	call   f0100a49 <cprintf>
	if (x > 0)
f0100055:	83 c4 10             	add    $0x10,%esp
f0100058:	85 db                	test   %ebx,%ebx
f010005a:	7e 11                	jle    f010006d <test_backtrace+0x2d>
		test_backtrace(x-1);
f010005c:	83 ec 0c             	sub    $0xc,%esp
f010005f:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100062:	50                   	push   %eax
f0100063:	e8 d8 ff ff ff       	call   f0100040 <test_backtrace>
f0100068:	83 c4 10             	add    $0x10,%esp
f010006b:	eb 11                	jmp    f010007e <test_backtrace+0x3e>
	else
		mon_backtrace(10, 0, 0);
f010006d:	83 ec 04             	sub    $0x4,%esp
f0100070:	6a 00                	push   $0x0
f0100072:	6a 00                	push   $0x0
f0100074:	6a 0a                	push   $0xa
f0100076:	e8 fc 06 00 00       	call   f0100777 <mon_backtrace>
f010007b:	83 c4 10             	add    $0x10,%esp
	cprintf("leaving test_backtrace %d\n", x);
f010007e:	83 ec 08             	sub    $0x8,%esp
f0100081:	53                   	push   %ebx
f0100082:	68 3c 1a 10 f0       	push   $0xf0101a3c
f0100087:	e8 bd 09 00 00       	call   f0100a49 <cprintf>
}
f010008c:	83 c4 10             	add    $0x10,%esp
f010008f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100092:	c9                   	leave  
f0100093:	c3                   	ret    

f0100094 <i386_init>:

void
i386_init(void)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f010009a:	b8 44 29 11 f0       	mov    $0xf0112944,%eax
f010009f:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000a4:	50                   	push   %eax
f01000a5:	6a 00                	push   $0x0
f01000a7:	68 00 23 11 f0       	push   $0xf0112300
f01000ac:	e8 c2 14 00 00       	call   f0101573 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b1:	e8 8f 04 00 00       	call   f0100545 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000b6:	83 c4 08             	add    $0x8,%esp
f01000b9:	68 ac 1a 00 00       	push   $0x1aac
f01000be:	68 57 1a 10 f0       	push   $0xf0101a57
f01000c3:	e8 81 09 00 00       	call   f0100a49 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000c8:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000cf:	e8 6c ff ff ff       	call   f0100040 <test_backtrace>
f01000d4:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000d7:	83 ec 0c             	sub    $0xc,%esp
f01000da:	6a 00                	push   $0x0
f01000dc:	e8 fb 07 00 00       	call   f01008dc <monitor>
f01000e1:	83 c4 10             	add    $0x10,%esp
f01000e4:	eb f1                	jmp    f01000d7 <i386_init+0x43>

f01000e6 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000e6:	55                   	push   %ebp
f01000e7:	89 e5                	mov    %esp,%ebp
f01000e9:	56                   	push   %esi
f01000ea:	53                   	push   %ebx
f01000eb:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000ee:	83 3d 40 29 11 f0 00 	cmpl   $0x0,0xf0112940
f01000f5:	75 37                	jne    f010012e <_panic+0x48>
		goto dead;
	panicstr = fmt;
f01000f7:	89 35 40 29 11 f0    	mov    %esi,0xf0112940

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000fd:	fa                   	cli    
f01000fe:	fc                   	cld    

	va_start(ap, fmt);
f01000ff:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100102:	83 ec 04             	sub    $0x4,%esp
f0100105:	ff 75 0c             	pushl  0xc(%ebp)
f0100108:	ff 75 08             	pushl  0x8(%ebp)
f010010b:	68 72 1a 10 f0       	push   $0xf0101a72
f0100110:	e8 34 09 00 00       	call   f0100a49 <cprintf>
	vcprintf(fmt, ap);
f0100115:	83 c4 08             	add    $0x8,%esp
f0100118:	53                   	push   %ebx
f0100119:	56                   	push   %esi
f010011a:	e8 04 09 00 00       	call   f0100a23 <vcprintf>
	cprintf("\n");
f010011f:	c7 04 24 ae 1a 10 f0 	movl   $0xf0101aae,(%esp)
f0100126:	e8 1e 09 00 00       	call   f0100a49 <cprintf>
	va_end(ap);
f010012b:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010012e:	83 ec 0c             	sub    $0xc,%esp
f0100131:	6a 00                	push   $0x0
f0100133:	e8 a4 07 00 00       	call   f01008dc <monitor>
f0100138:	83 c4 10             	add    $0x10,%esp
f010013b:	eb f1                	jmp    f010012e <_panic+0x48>

f010013d <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010013d:	55                   	push   %ebp
f010013e:	89 e5                	mov    %esp,%ebp
f0100140:	53                   	push   %ebx
f0100141:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100144:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100147:	ff 75 0c             	pushl  0xc(%ebp)
f010014a:	ff 75 08             	pushl  0x8(%ebp)
f010014d:	68 8a 1a 10 f0       	push   $0xf0101a8a
f0100152:	e8 f2 08 00 00       	call   f0100a49 <cprintf>
	vcprintf(fmt, ap);
f0100157:	83 c4 08             	add    $0x8,%esp
f010015a:	53                   	push   %ebx
f010015b:	ff 75 10             	pushl  0x10(%ebp)
f010015e:	e8 c0 08 00 00       	call   f0100a23 <vcprintf>
	cprintf("\n");
f0100163:	c7 04 24 ae 1a 10 f0 	movl   $0xf0101aae,(%esp)
f010016a:	e8 da 08 00 00       	call   f0100a49 <cprintf>
	va_end(ap);
}
f010016f:	83 c4 10             	add    $0x10,%esp
f0100172:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100175:	c9                   	leave  
f0100176:	c3                   	ret    

f0100177 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100177:	55                   	push   %ebp
f0100178:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010017a:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010017f:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100180:	a8 01                	test   $0x1,%al
f0100182:	74 0b                	je     f010018f <serial_proc_data+0x18>
f0100184:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100189:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010018a:	0f b6 c0             	movzbl %al,%eax
f010018d:	eb 05                	jmp    f0100194 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f010018f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100194:	5d                   	pop    %ebp
f0100195:	c3                   	ret    

f0100196 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100196:	55                   	push   %ebp
f0100197:	89 e5                	mov    %esp,%ebp
f0100199:	53                   	push   %ebx
f010019a:	83 ec 04             	sub    $0x4,%esp
f010019d:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f010019f:	eb 2b                	jmp    f01001cc <cons_intr+0x36>
		if (c == 0)
f01001a1:	85 c0                	test   %eax,%eax
f01001a3:	74 27                	je     f01001cc <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f01001a5:	8b 0d 24 25 11 f0    	mov    0xf0112524,%ecx
f01001ab:	8d 51 01             	lea    0x1(%ecx),%edx
f01001ae:	89 15 24 25 11 f0    	mov    %edx,0xf0112524
f01001b4:	88 81 20 23 11 f0    	mov    %al,-0xfeedce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f01001ba:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01001c0:	75 0a                	jne    f01001cc <cons_intr+0x36>
			cons.wpos = 0;
f01001c2:	c7 05 24 25 11 f0 00 	movl   $0x0,0xf0112524
f01001c9:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001cc:	ff d3                	call   *%ebx
f01001ce:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001d1:	75 ce                	jne    f01001a1 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001d3:	83 c4 04             	add    $0x4,%esp
f01001d6:	5b                   	pop    %ebx
f01001d7:	5d                   	pop    %ebp
f01001d8:	c3                   	ret    

f01001d9 <kbd_proc_data>:
f01001d9:	ba 64 00 00 00       	mov    $0x64,%edx
f01001de:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01001df:	a8 01                	test   $0x1,%al
f01001e1:	0f 84 f0 00 00 00    	je     f01002d7 <kbd_proc_data+0xfe>
f01001e7:	ba 60 00 00 00       	mov    $0x60,%edx
f01001ec:	ec                   	in     (%dx),%al
f01001ed:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001ef:	3c e0                	cmp    $0xe0,%al
f01001f1:	75 0d                	jne    f0100200 <kbd_proc_data+0x27>
		// E0 escape character
		shift |= E0ESC;
f01001f3:	83 0d 00 23 11 f0 40 	orl    $0x40,0xf0112300
		return 0;
f01001fa:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001ff:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100200:	55                   	push   %ebp
f0100201:	89 e5                	mov    %esp,%ebp
f0100203:	53                   	push   %ebx
f0100204:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f0100207:	84 c0                	test   %al,%al
f0100209:	79 36                	jns    f0100241 <kbd_proc_data+0x68>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f010020b:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100211:	89 cb                	mov    %ecx,%ebx
f0100213:	83 e3 40             	and    $0x40,%ebx
f0100216:	83 e0 7f             	and    $0x7f,%eax
f0100219:	85 db                	test   %ebx,%ebx
f010021b:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f010021e:	0f b6 d2             	movzbl %dl,%edx
f0100221:	0f b6 82 00 1c 10 f0 	movzbl -0xfefe400(%edx),%eax
f0100228:	83 c8 40             	or     $0x40,%eax
f010022b:	0f b6 c0             	movzbl %al,%eax
f010022e:	f7 d0                	not    %eax
f0100230:	21 c8                	and    %ecx,%eax
f0100232:	a3 00 23 11 f0       	mov    %eax,0xf0112300
		return 0;
f0100237:	b8 00 00 00 00       	mov    $0x0,%eax
f010023c:	e9 9e 00 00 00       	jmp    f01002df <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f0100241:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100247:	f6 c1 40             	test   $0x40,%cl
f010024a:	74 0e                	je     f010025a <kbd_proc_data+0x81>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f010024c:	83 c8 80             	or     $0xffffff80,%eax
f010024f:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100251:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100254:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
	}

	shift |= shiftcode[data];
f010025a:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f010025d:	0f b6 82 00 1c 10 f0 	movzbl -0xfefe400(%edx),%eax
f0100264:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
f010026a:	0f b6 8a 00 1b 10 f0 	movzbl -0xfefe500(%edx),%ecx
f0100271:	31 c8                	xor    %ecx,%eax
f0100273:	a3 00 23 11 f0       	mov    %eax,0xf0112300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100278:	89 c1                	mov    %eax,%ecx
f010027a:	83 e1 03             	and    $0x3,%ecx
f010027d:	8b 0c 8d e0 1a 10 f0 	mov    -0xfefe520(,%ecx,4),%ecx
f0100284:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100288:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f010028b:	a8 08                	test   $0x8,%al
f010028d:	74 1b                	je     f01002aa <kbd_proc_data+0xd1>
		if ('a' <= c && c <= 'z')
f010028f:	89 da                	mov    %ebx,%edx
f0100291:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100294:	83 f9 19             	cmp    $0x19,%ecx
f0100297:	77 05                	ja     f010029e <kbd_proc_data+0xc5>
			c += 'A' - 'a';
f0100299:	83 eb 20             	sub    $0x20,%ebx
f010029c:	eb 0c                	jmp    f01002aa <kbd_proc_data+0xd1>
		else if ('A' <= c && c <= 'Z')
f010029e:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002a1:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01002a4:	83 fa 19             	cmp    $0x19,%edx
f01002a7:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002aa:	f7 d0                	not    %eax
f01002ac:	a8 06                	test   $0x6,%al
f01002ae:	75 2d                	jne    f01002dd <kbd_proc_data+0x104>
f01002b0:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002b6:	75 25                	jne    f01002dd <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f01002b8:	83 ec 0c             	sub    $0xc,%esp
f01002bb:	68 a4 1a 10 f0       	push   $0xf0101aa4
f01002c0:	e8 84 07 00 00       	call   f0100a49 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002c5:	ba 92 00 00 00       	mov    $0x92,%edx
f01002ca:	b8 03 00 00 00       	mov    $0x3,%eax
f01002cf:	ee                   	out    %al,(%dx)
f01002d0:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002d3:	89 d8                	mov    %ebx,%eax
f01002d5:	eb 08                	jmp    f01002df <kbd_proc_data+0x106>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01002d7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002dc:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002dd:	89 d8                	mov    %ebx,%eax
}
f01002df:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01002e2:	c9                   	leave  
f01002e3:	c3                   	ret    

f01002e4 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002e4:	55                   	push   %ebp
f01002e5:	89 e5                	mov    %esp,%ebp
f01002e7:	57                   	push   %edi
f01002e8:	56                   	push   %esi
f01002e9:	53                   	push   %ebx
f01002ea:	83 ec 1c             	sub    $0x1c,%esp
f01002ed:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002ef:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002f4:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002f9:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002fe:	eb 09                	jmp    f0100309 <cons_putc+0x25>
f0100300:	89 ca                	mov    %ecx,%edx
f0100302:	ec                   	in     (%dx),%al
f0100303:	ec                   	in     (%dx),%al
f0100304:	ec                   	in     (%dx),%al
f0100305:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f0100306:	83 c3 01             	add    $0x1,%ebx
f0100309:	89 f2                	mov    %esi,%edx
f010030b:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010030c:	a8 20                	test   $0x20,%al
f010030e:	75 08                	jne    f0100318 <cons_putc+0x34>
f0100310:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100316:	7e e8                	jle    f0100300 <cons_putc+0x1c>
f0100318:	89 f8                	mov    %edi,%eax
f010031a:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010031d:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100322:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100323:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100328:	be 79 03 00 00       	mov    $0x379,%esi
f010032d:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100332:	eb 09                	jmp    f010033d <cons_putc+0x59>
f0100334:	89 ca                	mov    %ecx,%edx
f0100336:	ec                   	in     (%dx),%al
f0100337:	ec                   	in     (%dx),%al
f0100338:	ec                   	in     (%dx),%al
f0100339:	ec                   	in     (%dx),%al
f010033a:	83 c3 01             	add    $0x1,%ebx
f010033d:	89 f2                	mov    %esi,%edx
f010033f:	ec                   	in     (%dx),%al
f0100340:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100346:	7f 04                	jg     f010034c <cons_putc+0x68>
f0100348:	84 c0                	test   %al,%al
f010034a:	79 e8                	jns    f0100334 <cons_putc+0x50>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010034c:	ba 78 03 00 00       	mov    $0x378,%edx
f0100351:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100355:	ee                   	out    %al,(%dx)
f0100356:	ba 7a 03 00 00       	mov    $0x37a,%edx
f010035b:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100360:	ee                   	out    %al,(%dx)
f0100361:	b8 08 00 00 00       	mov    $0x8,%eax
f0100366:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100367:	89 fa                	mov    %edi,%edx
f0100369:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f010036f:	89 f8                	mov    %edi,%eax
f0100371:	80 cc 07             	or     $0x7,%ah
f0100374:	85 d2                	test   %edx,%edx
f0100376:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100379:	89 f8                	mov    %edi,%eax
f010037b:	0f b6 c0             	movzbl %al,%eax
f010037e:	83 f8 09             	cmp    $0x9,%eax
f0100381:	74 74                	je     f01003f7 <cons_putc+0x113>
f0100383:	83 f8 09             	cmp    $0x9,%eax
f0100386:	7f 0a                	jg     f0100392 <cons_putc+0xae>
f0100388:	83 f8 08             	cmp    $0x8,%eax
f010038b:	74 14                	je     f01003a1 <cons_putc+0xbd>
f010038d:	e9 99 00 00 00       	jmp    f010042b <cons_putc+0x147>
f0100392:	83 f8 0a             	cmp    $0xa,%eax
f0100395:	74 3a                	je     f01003d1 <cons_putc+0xed>
f0100397:	83 f8 0d             	cmp    $0xd,%eax
f010039a:	74 3d                	je     f01003d9 <cons_putc+0xf5>
f010039c:	e9 8a 00 00 00       	jmp    f010042b <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f01003a1:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003a8:	66 85 c0             	test   %ax,%ax
f01003ab:	0f 84 e6 00 00 00    	je     f0100497 <cons_putc+0x1b3>
			crt_pos--;
f01003b1:	83 e8 01             	sub    $0x1,%eax
f01003b4:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003ba:	0f b7 c0             	movzwl %ax,%eax
f01003bd:	66 81 e7 00 ff       	and    $0xff00,%di
f01003c2:	83 cf 20             	or     $0x20,%edi
f01003c5:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f01003cb:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003cf:	eb 78                	jmp    f0100449 <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003d1:	66 83 05 28 25 11 f0 	addw   $0x50,0xf0112528
f01003d8:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003d9:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003e0:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003e6:	c1 e8 16             	shr    $0x16,%eax
f01003e9:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003ec:	c1 e0 04             	shl    $0x4,%eax
f01003ef:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
f01003f5:	eb 52                	jmp    f0100449 <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f01003f7:	b8 20 00 00 00       	mov    $0x20,%eax
f01003fc:	e8 e3 fe ff ff       	call   f01002e4 <cons_putc>
		cons_putc(' ');
f0100401:	b8 20 00 00 00       	mov    $0x20,%eax
f0100406:	e8 d9 fe ff ff       	call   f01002e4 <cons_putc>
		cons_putc(' ');
f010040b:	b8 20 00 00 00       	mov    $0x20,%eax
f0100410:	e8 cf fe ff ff       	call   f01002e4 <cons_putc>
		cons_putc(' ');
f0100415:	b8 20 00 00 00       	mov    $0x20,%eax
f010041a:	e8 c5 fe ff ff       	call   f01002e4 <cons_putc>
		cons_putc(' ');
f010041f:	b8 20 00 00 00       	mov    $0x20,%eax
f0100424:	e8 bb fe ff ff       	call   f01002e4 <cons_putc>
f0100429:	eb 1e                	jmp    f0100449 <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f010042b:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f0100432:	8d 50 01             	lea    0x1(%eax),%edx
f0100435:	66 89 15 28 25 11 f0 	mov    %dx,0xf0112528
f010043c:	0f b7 c0             	movzwl %ax,%eax
f010043f:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100445:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100449:	66 81 3d 28 25 11 f0 	cmpw   $0x7cf,0xf0112528
f0100450:	cf 07 
f0100452:	76 43                	jbe    f0100497 <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100454:	a1 2c 25 11 f0       	mov    0xf011252c,%eax
f0100459:	83 ec 04             	sub    $0x4,%esp
f010045c:	68 00 0f 00 00       	push   $0xf00
f0100461:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100467:	52                   	push   %edx
f0100468:	50                   	push   %eax
f0100469:	e8 52 11 00 00       	call   f01015c0 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010046e:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100474:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f010047a:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100480:	83 c4 10             	add    $0x10,%esp
f0100483:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100488:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010048b:	39 d0                	cmp    %edx,%eax
f010048d:	75 f4                	jne    f0100483 <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010048f:	66 83 2d 28 25 11 f0 	subw   $0x50,0xf0112528
f0100496:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100497:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f010049d:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004a2:	89 ca                	mov    %ecx,%edx
f01004a4:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004a5:	0f b7 1d 28 25 11 f0 	movzwl 0xf0112528,%ebx
f01004ac:	8d 71 01             	lea    0x1(%ecx),%esi
f01004af:	89 d8                	mov    %ebx,%eax
f01004b1:	66 c1 e8 08          	shr    $0x8,%ax
f01004b5:	89 f2                	mov    %esi,%edx
f01004b7:	ee                   	out    %al,(%dx)
f01004b8:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004bd:	89 ca                	mov    %ecx,%edx
f01004bf:	ee                   	out    %al,(%dx)
f01004c0:	89 d8                	mov    %ebx,%eax
f01004c2:	89 f2                	mov    %esi,%edx
f01004c4:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004c5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01004c8:	5b                   	pop    %ebx
f01004c9:	5e                   	pop    %esi
f01004ca:	5f                   	pop    %edi
f01004cb:	5d                   	pop    %ebp
f01004cc:	c3                   	ret    

f01004cd <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004cd:	80 3d 34 25 11 f0 00 	cmpb   $0x0,0xf0112534
f01004d4:	74 11                	je     f01004e7 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004d6:	55                   	push   %ebp
f01004d7:	89 e5                	mov    %esp,%ebp
f01004d9:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004dc:	b8 77 01 10 f0       	mov    $0xf0100177,%eax
f01004e1:	e8 b0 fc ff ff       	call   f0100196 <cons_intr>
}
f01004e6:	c9                   	leave  
f01004e7:	f3 c3                	repz ret 

f01004e9 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004e9:	55                   	push   %ebp
f01004ea:	89 e5                	mov    %esp,%ebp
f01004ec:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004ef:	b8 d9 01 10 f0       	mov    $0xf01001d9,%eax
f01004f4:	e8 9d fc ff ff       	call   f0100196 <cons_intr>
}
f01004f9:	c9                   	leave  
f01004fa:	c3                   	ret    

f01004fb <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004fb:	55                   	push   %ebp
f01004fc:	89 e5                	mov    %esp,%ebp
f01004fe:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f0100501:	e8 c7 ff ff ff       	call   f01004cd <serial_intr>
	kbd_intr();
f0100506:	e8 de ff ff ff       	call   f01004e9 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f010050b:	a1 20 25 11 f0       	mov    0xf0112520,%eax
f0100510:	3b 05 24 25 11 f0    	cmp    0xf0112524,%eax
f0100516:	74 26                	je     f010053e <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100518:	8d 50 01             	lea    0x1(%eax),%edx
f010051b:	89 15 20 25 11 f0    	mov    %edx,0xf0112520
f0100521:	0f b6 88 20 23 11 f0 	movzbl -0xfeedce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100528:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f010052a:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100530:	75 11                	jne    f0100543 <cons_getc+0x48>
			cons.rpos = 0;
f0100532:	c7 05 20 25 11 f0 00 	movl   $0x0,0xf0112520
f0100539:	00 00 00 
f010053c:	eb 05                	jmp    f0100543 <cons_getc+0x48>
		return c;
	}
	return 0;
f010053e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100543:	c9                   	leave  
f0100544:	c3                   	ret    

f0100545 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100545:	55                   	push   %ebp
f0100546:	89 e5                	mov    %esp,%ebp
f0100548:	57                   	push   %edi
f0100549:	56                   	push   %esi
f010054a:	53                   	push   %ebx
f010054b:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f010054e:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100555:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010055c:	5a a5 
	if (*cp != 0xA55A) {
f010055e:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100565:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100569:	74 11                	je     f010057c <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010056b:	c7 05 30 25 11 f0 b4 	movl   $0x3b4,0xf0112530
f0100572:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100575:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f010057a:	eb 16                	jmp    f0100592 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010057c:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100583:	c7 05 30 25 11 f0 d4 	movl   $0x3d4,0xf0112530
f010058a:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010058d:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100592:	8b 3d 30 25 11 f0    	mov    0xf0112530,%edi
f0100598:	b8 0e 00 00 00       	mov    $0xe,%eax
f010059d:	89 fa                	mov    %edi,%edx
f010059f:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005a0:	8d 5f 01             	lea    0x1(%edi),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005a3:	89 da                	mov    %ebx,%edx
f01005a5:	ec                   	in     (%dx),%al
f01005a6:	0f b6 c8             	movzbl %al,%ecx
f01005a9:	c1 e1 08             	shl    $0x8,%ecx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005ac:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005b1:	89 fa                	mov    %edi,%edx
f01005b3:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005b4:	89 da                	mov    %ebx,%edx
f01005b6:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005b7:	89 35 2c 25 11 f0    	mov    %esi,0xf011252c
	crt_pos = pos;
f01005bd:	0f b6 c0             	movzbl %al,%eax
f01005c0:	09 c8                	or     %ecx,%eax
f01005c2:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005c8:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005cd:	b8 00 00 00 00       	mov    $0x0,%eax
f01005d2:	89 f2                	mov    %esi,%edx
f01005d4:	ee                   	out    %al,(%dx)
f01005d5:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005da:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005df:	ee                   	out    %al,(%dx)
f01005e0:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005e5:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005ea:	89 da                	mov    %ebx,%edx
f01005ec:	ee                   	out    %al,(%dx)
f01005ed:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005f2:	b8 00 00 00 00       	mov    $0x0,%eax
f01005f7:	ee                   	out    %al,(%dx)
f01005f8:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005fd:	b8 03 00 00 00       	mov    $0x3,%eax
f0100602:	ee                   	out    %al,(%dx)
f0100603:	ba fc 03 00 00       	mov    $0x3fc,%edx
f0100608:	b8 00 00 00 00       	mov    $0x0,%eax
f010060d:	ee                   	out    %al,(%dx)
f010060e:	ba f9 03 00 00       	mov    $0x3f9,%edx
f0100613:	b8 01 00 00 00       	mov    $0x1,%eax
f0100618:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100619:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010061e:	ec                   	in     (%dx),%al
f010061f:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100621:	3c ff                	cmp    $0xff,%al
f0100623:	0f 95 05 34 25 11 f0 	setne  0xf0112534
f010062a:	89 f2                	mov    %esi,%edx
f010062c:	ec                   	in     (%dx),%al
f010062d:	89 da                	mov    %ebx,%edx
f010062f:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100630:	80 f9 ff             	cmp    $0xff,%cl
f0100633:	75 10                	jne    f0100645 <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f0100635:	83 ec 0c             	sub    $0xc,%esp
f0100638:	68 b0 1a 10 f0       	push   $0xf0101ab0
f010063d:	e8 07 04 00 00       	call   f0100a49 <cprintf>
f0100642:	83 c4 10             	add    $0x10,%esp
}
f0100645:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100648:	5b                   	pop    %ebx
f0100649:	5e                   	pop    %esi
f010064a:	5f                   	pop    %edi
f010064b:	5d                   	pop    %ebp
f010064c:	c3                   	ret    

f010064d <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010064d:	55                   	push   %ebp
f010064e:	89 e5                	mov    %esp,%ebp
f0100650:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100653:	8b 45 08             	mov    0x8(%ebp),%eax
f0100656:	e8 89 fc ff ff       	call   f01002e4 <cons_putc>
}
f010065b:	c9                   	leave  
f010065c:	c3                   	ret    

f010065d <getchar>:

int
getchar(void)
{
f010065d:	55                   	push   %ebp
f010065e:	89 e5                	mov    %esp,%ebp
f0100660:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100663:	e8 93 fe ff ff       	call   f01004fb <cons_getc>
f0100668:	85 c0                	test   %eax,%eax
f010066a:	74 f7                	je     f0100663 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010066c:	c9                   	leave  
f010066d:	c3                   	ret    

f010066e <iscons>:

int
iscons(int fdnum)
{
f010066e:	55                   	push   %ebp
f010066f:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100671:	b8 01 00 00 00       	mov    $0x1,%eax
f0100676:	5d                   	pop    %ebp
f0100677:	c3                   	ret    

f0100678 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100678:	55                   	push   %ebp
f0100679:	89 e5                	mov    %esp,%ebp
f010067b:	83 ec 0c             	sub    $0xc,%esp
	int i;
	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010067e:	68 00 1d 10 f0       	push   $0xf0101d00
f0100683:	68 1e 1d 10 f0       	push   $0xf0101d1e
f0100688:	68 23 1d 10 f0       	push   $0xf0101d23
f010068d:	e8 b7 03 00 00       	call   f0100a49 <cprintf>
f0100692:	83 c4 0c             	add    $0xc,%esp
f0100695:	68 f8 1d 10 f0       	push   $0xf0101df8
f010069a:	68 2c 1d 10 f0       	push   $0xf0101d2c
f010069f:	68 23 1d 10 f0       	push   $0xf0101d23
f01006a4:	e8 a0 03 00 00       	call   f0100a49 <cprintf>
f01006a9:	83 c4 0c             	add    $0xc,%esp
f01006ac:	68 35 1d 10 f0       	push   $0xf0101d35
f01006b1:	68 42 1d 10 f0       	push   $0xf0101d42
f01006b6:	68 23 1d 10 f0       	push   $0xf0101d23
f01006bb:	e8 89 03 00 00       	call   f0100a49 <cprintf>
	return 0;
}
f01006c0:	b8 00 00 00 00       	mov    $0x0,%eax
f01006c5:	c9                   	leave  
f01006c6:	c3                   	ret    

f01006c7 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006c7:	55                   	push   %ebp
f01006c8:	89 e5                	mov    %esp,%ebp
f01006ca:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006cd:	68 4c 1d 10 f0       	push   $0xf0101d4c
f01006d2:	e8 72 03 00 00       	call   f0100a49 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006d7:	83 c4 08             	add    $0x8,%esp
f01006da:	68 0c 00 10 00       	push   $0x10000c
f01006df:	68 20 1e 10 f0       	push   $0xf0101e20
f01006e4:	e8 60 03 00 00       	call   f0100a49 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006e9:	83 c4 0c             	add    $0xc,%esp
f01006ec:	68 0c 00 10 00       	push   $0x10000c
f01006f1:	68 0c 00 10 f0       	push   $0xf010000c
f01006f6:	68 48 1e 10 f0       	push   $0xf0101e48
f01006fb:	e8 49 03 00 00       	call   f0100a49 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100700:	83 c4 0c             	add    $0xc,%esp
f0100703:	68 01 1a 10 00       	push   $0x101a01
f0100708:	68 01 1a 10 f0       	push   $0xf0101a01
f010070d:	68 6c 1e 10 f0       	push   $0xf0101e6c
f0100712:	e8 32 03 00 00       	call   f0100a49 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100717:	83 c4 0c             	add    $0xc,%esp
f010071a:	68 00 23 11 00       	push   $0x112300
f010071f:	68 00 23 11 f0       	push   $0xf0112300
f0100724:	68 90 1e 10 f0       	push   $0xf0101e90
f0100729:	e8 1b 03 00 00       	call   f0100a49 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010072e:	83 c4 0c             	add    $0xc,%esp
f0100731:	68 44 29 11 00       	push   $0x112944
f0100736:	68 44 29 11 f0       	push   $0xf0112944
f010073b:	68 b4 1e 10 f0       	push   $0xf0101eb4
f0100740:	e8 04 03 00 00       	call   f0100a49 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100745:	b8 43 2d 11 f0       	mov    $0xf0112d43,%eax
f010074a:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010074f:	83 c4 08             	add    $0x8,%esp
f0100752:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f0100757:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010075d:	85 c0                	test   %eax,%eax
f010075f:	0f 48 c2             	cmovs  %edx,%eax
f0100762:	c1 f8 0a             	sar    $0xa,%eax
f0100765:	50                   	push   %eax
f0100766:	68 d8 1e 10 f0       	push   $0xf0101ed8
f010076b:	e8 d9 02 00 00       	call   f0100a49 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100770:	b8 00 00 00 00       	mov    $0x0,%eax
f0100775:	c9                   	leave  
f0100776:	c3                   	ret    

f0100777 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100777:	55                   	push   %ebp
f0100778:	89 e5                	mov    %esp,%ebp
f010077a:	57                   	push   %edi
f010077b:	56                   	push   %esi
f010077c:	53                   	push   %ebx
f010077d:	83 ec 2c             	sub    $0x2c,%esp
	uint32_t ebpr;

	uint32_t *temp;
        uint32_t *ptr1;
        uintptr_t address;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebpr));
f0100780:	89 ee                	mov    %ebp,%esi
	{
	
	address = *(ptr+1);
        
	ptr1 = (uint32_t*) *ptr;
        debuginfo_eip(address, &i);
f0100782:	8d 7d d0             	lea    -0x30(%ebp),%edi
        uintptr_t address;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebpr));
	struct Eipdebuginfo i;	
                uint32_t *ptr = (uint32_t*)ebpr ;
      
	while(*ptr!=0)
f0100785:	e9 3b 01 00 00       	jmp    f01008c5 <mon_backtrace+0x14e>
	{
	
	address = *(ptr+1);
        
	ptr1 = (uint32_t*) *ptr;
        debuginfo_eip(address, &i);
f010078a:	83 ec 08             	sub    $0x8,%esp
f010078d:	57                   	push   %edi
f010078e:	ff 76 04             	pushl  0x4(%esi)
f0100791:	e8 bd 03 00 00       	call   f0100b53 <debuginfo_eip>
                 	cprintf("EBP :%08x  ,EIP %08x  ,args:  %08x ,  %08x,   %08x ,   %08x,   %08x \n",*ptr,*(ptr+1),*(ptr1+2),*(ptr1+3), *(ptr1+4), *(ptr1+5), *(ptr1+6));
f0100796:	ff 73 18             	pushl  0x18(%ebx)
f0100799:	ff 73 14             	pushl  0x14(%ebx)
f010079c:	ff 73 10             	pushl  0x10(%ebx)
f010079f:	ff 73 0c             	pushl  0xc(%ebx)
f01007a2:	ff 73 08             	pushl  0x8(%ebx)
f01007a5:	ff 76 04             	pushl  0x4(%esi)
f01007a8:	ff 36                	pushl  (%esi)
f01007aa:	68 04 1f 10 f0       	push   $0xf0101f04
f01007af:	e8 95 02 00 00       	call   f0100a49 <cprintf>


      switch(i.eip_fn_narg) {
f01007b4:	83 c4 30             	add    $0x30,%esp
f01007b7:	83 7d e4 04          	cmpl   $0x4,-0x1c(%ebp)
f01007bb:	0f 87 9e 00 00 00    	ja     f010085f <mon_backtrace+0xe8>
f01007c1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01007c4:	ff 24 85 a0 20 10 f0 	jmp    *-0xfefdf60(,%eax,4)
         
       case 0: 
    	     cprintf("EBP :%08x  ,EIP %08x  ,args:  non \n",*ptr,*(ptr+1));
f01007cb:	83 ec 04             	sub    $0x4,%esp
f01007ce:	ff 76 04             	pushl  0x4(%esi)
f01007d1:	ff 36                	pushl  (%esi)
f01007d3:	68 4c 1f 10 f0       	push   $0xf0101f4c
f01007d8:	e8 6c 02 00 00       	call   f0100a49 <cprintf>
       break; 
f01007dd:	83 c4 10             	add    $0x10,%esp
f01007e0:	e9 9b 00 00 00       	jmp    f0100880 <mon_backtrace+0x109>


         case 1:
               	cprintf("EBP :%08x  ,EIP %08x  ,args:  %08x \n",*ptr,*(ptr+1),*(ptr1+2));
f01007e5:	ff 73 08             	pushl  0x8(%ebx)
f01007e8:	ff 76 04             	pushl  0x4(%esi)
f01007eb:	ff 36                	pushl  (%esi)
f01007ed:	68 70 1f 10 f0       	push   $0xf0101f70
f01007f2:	e8 52 02 00 00       	call   f0100a49 <cprintf>
         break;
f01007f7:	83 c4 10             	add    $0x10,%esp
f01007fa:	e9 81 00 00 00       	jmp    f0100880 <mon_backtrace+0x109>


        case 2:
               	cprintf("EBP :%08x  ,EIP %08x  ,args:  %08x ,  %08x \n",*ptr,*(ptr+1),*(ptr1+2),*(ptr1+3));
f01007ff:	83 ec 0c             	sub    $0xc,%esp
f0100802:	ff 73 0c             	pushl  0xc(%ebx)
f0100805:	ff 73 08             	pushl  0x8(%ebx)
f0100808:	ff 76 04             	pushl  0x4(%esi)
f010080b:	ff 36                	pushl  (%esi)
f010080d:	68 98 1f 10 f0       	push   $0xf0101f98
f0100812:	e8 32 02 00 00       	call   f0100a49 <cprintf>
         break;
f0100817:	83 c4 20             	add    $0x20,%esp
f010081a:	eb 64                	jmp    f0100880 <mon_backtrace+0x109>


         case 3:
               	cprintf("EBP :%08x  ,EIP %08x  ,args:  %08x ,  %08x,   %08x \n",*ptr,*(ptr+1),*(ptr1+2),*(ptr1+3), *(ptr1+4));
f010081c:	83 ec 08             	sub    $0x8,%esp
f010081f:	ff 73 10             	pushl  0x10(%ebx)
f0100822:	ff 73 0c             	pushl  0xc(%ebx)
f0100825:	ff 73 08             	pushl  0x8(%ebx)
f0100828:	ff 76 04             	pushl  0x4(%esi)
f010082b:	ff 36                	pushl  (%esi)
f010082d:	68 c8 1f 10 f0       	push   $0xf0101fc8
f0100832:	e8 12 02 00 00       	call   f0100a49 <cprintf>
         break;
f0100837:	83 c4 20             	add    $0x20,%esp
f010083a:	eb 44                	jmp    f0100880 <mon_backtrace+0x109>



         case 4:
               	cprintf("EBP :%08x  ,EIP %08x  ,args:  %08x ,  %08x,   %08x ,   %08x \n",*ptr,*(ptr+1),*(ptr1+2),*(ptr1+3), *(ptr1+4), *(ptr1+5));
f010083c:	83 ec 04             	sub    $0x4,%esp
f010083f:	ff 73 14             	pushl  0x14(%ebx)
f0100842:	ff 73 10             	pushl  0x10(%ebx)
f0100845:	ff 73 0c             	pushl  0xc(%ebx)
f0100848:	ff 73 08             	pushl  0x8(%ebx)
f010084b:	ff 76 04             	pushl  0x4(%esi)
f010084e:	ff 36                	pushl  (%esi)
f0100850:	68 00 20 10 f0       	push   $0xf0102000
f0100855:	e8 ef 01 00 00       	call   f0100a49 <cprintf>
         break;
f010085a:	83 c4 20             	add    $0x20,%esp
f010085d:	eb 21                	jmp    f0100880 <mon_backtrace+0x109>



       default: //5 or more
               	cprintf("EBP :%08x  ,EIP %08x  ,args:  %08x ,  %08x,   %08x ,   %08x,   %08x \n",*ptr,*(ptr+1),*(ptr1+2),*(ptr1+3), *(ptr1+4), *(ptr1+5), *(ptr1+6));
f010085f:	ff 73 18             	pushl  0x18(%ebx)
f0100862:	ff 73 14             	pushl  0x14(%ebx)
f0100865:	ff 73 10             	pushl  0x10(%ebx)
f0100868:	ff 73 0c             	pushl  0xc(%ebx)
f010086b:	ff 73 08             	pushl  0x8(%ebx)
f010086e:	ff 76 04             	pushl  0x4(%esi)
f0100871:	ff 36                	pushl  (%esi)
f0100873:	68 04 1f 10 f0       	push   $0xf0101f04
f0100878:	e8 cc 01 00 00       	call   f0100a49 <cprintf>
         break;
f010087d:	83 c4 20             	add    $0x20,%esp

        }      

	temp = ptr;
	ptr = (uint32_t*) *temp;
f0100880:	8b 36                	mov    (%esi),%esi

            
         cprintf("Source File : %s    ", i.eip_file);
f0100882:	83 ec 08             	sub    $0x8,%esp
f0100885:	ff 75 d0             	pushl  -0x30(%ebp)
f0100888:	68 65 1d 10 f0       	push   $0xf0101d65
f010088d:	e8 b7 01 00 00       	call   f0100a49 <cprintf>
         cprintf("Line# : %d    ", i.eip_line);
f0100892:	83 c4 08             	add    $0x8,%esp
f0100895:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100898:	68 7a 1d 10 f0       	push   $0xf0101d7a
f010089d:	e8 a7 01 00 00       	call   f0100a49 <cprintf>
         cprintf("Func Name   : %s  ", i.eip_fn_name);
f01008a2:	83 c4 08             	add    $0x8,%esp
f01008a5:	ff 75 d8             	pushl  -0x28(%ebp)
f01008a8:	68 89 1d 10 f0       	push   $0xf0101d89
f01008ad:	e8 97 01 00 00       	call   f0100a49 <cprintf>
         cprintf("number of arguments  : %d \n\n ", i.eip_fn_narg);    
f01008b2:	83 c4 08             	add    $0x8,%esp
f01008b5:	ff 75 e4             	pushl  -0x1c(%ebp)
f01008b8:	68 9c 1d 10 f0       	push   $0xf0101d9c
f01008bd:	e8 87 01 00 00       	call   f0100a49 <cprintf>
f01008c2:	83 c4 10             	add    $0x10,%esp
        uintptr_t address;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebpr));
	struct Eipdebuginfo i;	
                uint32_t *ptr = (uint32_t*)ebpr ;
      
	while(*ptr!=0)
f01008c5:	8b 1e                	mov    (%esi),%ebx
f01008c7:	85 db                	test   %ebx,%ebx
f01008c9:	0f 85 bb fe ff ff    	jne    f010078a <mon_backtrace+0x13>
	}	

		      

	return 0;
}
f01008cf:	b8 00 00 00 00       	mov    $0x0,%eax
f01008d4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008d7:	5b                   	pop    %ebx
f01008d8:	5e                   	pop    %esi
f01008d9:	5f                   	pop    %edi
f01008da:	5d                   	pop    %ebp
f01008db:	c3                   	ret    

f01008dc <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01008dc:	55                   	push   %ebp
f01008dd:	89 e5                	mov    %esp,%ebp
f01008df:	57                   	push   %edi
f01008e0:	56                   	push   %esi
f01008e1:	53                   	push   %ebx
f01008e2:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01008e5:	68 40 20 10 f0       	push   $0xf0102040
f01008ea:	e8 5a 01 00 00       	call   f0100a49 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01008ef:	c7 04 24 64 20 10 f0 	movl   $0xf0102064,(%esp)
f01008f6:	e8 4e 01 00 00       	call   f0100a49 <cprintf>
f01008fb:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01008fe:	83 ec 0c             	sub    $0xc,%esp
f0100901:	68 ba 1d 10 f0       	push   $0xf0101dba
f0100906:	e8 11 0a 00 00       	call   f010131c <readline>
f010090b:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f010090d:	83 c4 10             	add    $0x10,%esp
f0100910:	85 c0                	test   %eax,%eax
f0100912:	74 ea                	je     f01008fe <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100914:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f010091b:	be 00 00 00 00       	mov    $0x0,%esi
f0100920:	eb 0a                	jmp    f010092c <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100922:	c6 03 00             	movb   $0x0,(%ebx)
f0100925:	89 f7                	mov    %esi,%edi
f0100927:	8d 5b 01             	lea    0x1(%ebx),%ebx
f010092a:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f010092c:	0f b6 03             	movzbl (%ebx),%eax
f010092f:	84 c0                	test   %al,%al
f0100931:	74 63                	je     f0100996 <monitor+0xba>
f0100933:	83 ec 08             	sub    $0x8,%esp
f0100936:	0f be c0             	movsbl %al,%eax
f0100939:	50                   	push   %eax
f010093a:	68 be 1d 10 f0       	push   $0xf0101dbe
f010093f:	e8 f2 0b 00 00       	call   f0101536 <strchr>
f0100944:	83 c4 10             	add    $0x10,%esp
f0100947:	85 c0                	test   %eax,%eax
f0100949:	75 d7                	jne    f0100922 <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f010094b:	80 3b 00             	cmpb   $0x0,(%ebx)
f010094e:	74 46                	je     f0100996 <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100950:	83 fe 0f             	cmp    $0xf,%esi
f0100953:	75 14                	jne    f0100969 <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100955:	83 ec 08             	sub    $0x8,%esp
f0100958:	6a 10                	push   $0x10
f010095a:	68 c3 1d 10 f0       	push   $0xf0101dc3
f010095f:	e8 e5 00 00 00       	call   f0100a49 <cprintf>
f0100964:	83 c4 10             	add    $0x10,%esp
f0100967:	eb 95                	jmp    f01008fe <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f0100969:	8d 7e 01             	lea    0x1(%esi),%edi
f010096c:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100970:	eb 03                	jmp    f0100975 <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100972:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100975:	0f b6 03             	movzbl (%ebx),%eax
f0100978:	84 c0                	test   %al,%al
f010097a:	74 ae                	je     f010092a <monitor+0x4e>
f010097c:	83 ec 08             	sub    $0x8,%esp
f010097f:	0f be c0             	movsbl %al,%eax
f0100982:	50                   	push   %eax
f0100983:	68 be 1d 10 f0       	push   $0xf0101dbe
f0100988:	e8 a9 0b 00 00       	call   f0101536 <strchr>
f010098d:	83 c4 10             	add    $0x10,%esp
f0100990:	85 c0                	test   %eax,%eax
f0100992:	74 de                	je     f0100972 <monitor+0x96>
f0100994:	eb 94                	jmp    f010092a <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f0100996:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f010099d:	00 

	// Lookup and invoke the command
	if (argc == 0)
f010099e:	85 f6                	test   %esi,%esi
f01009a0:	0f 84 58 ff ff ff    	je     f01008fe <monitor+0x22>
f01009a6:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01009ab:	83 ec 08             	sub    $0x8,%esp
f01009ae:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01009b1:	ff 34 85 c0 20 10 f0 	pushl  -0xfefdf40(,%eax,4)
f01009b8:	ff 75 a8             	pushl  -0x58(%ebp)
f01009bb:	e8 18 0b 00 00       	call   f01014d8 <strcmp>
f01009c0:	83 c4 10             	add    $0x10,%esp
f01009c3:	85 c0                	test   %eax,%eax
f01009c5:	75 21                	jne    f01009e8 <monitor+0x10c>
			return commands[i].func(argc, argv, tf);
f01009c7:	83 ec 04             	sub    $0x4,%esp
f01009ca:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01009cd:	ff 75 08             	pushl  0x8(%ebp)
f01009d0:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01009d3:	52                   	push   %edx
f01009d4:	56                   	push   %esi
f01009d5:	ff 14 85 c8 20 10 f0 	call   *-0xfefdf38(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01009dc:	83 c4 10             	add    $0x10,%esp
f01009df:	85 c0                	test   %eax,%eax
f01009e1:	78 25                	js     f0100a08 <monitor+0x12c>
f01009e3:	e9 16 ff ff ff       	jmp    f01008fe <monitor+0x22>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f01009e8:	83 c3 01             	add    $0x1,%ebx
f01009eb:	83 fb 03             	cmp    $0x3,%ebx
f01009ee:	75 bb                	jne    f01009ab <monitor+0xcf>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01009f0:	83 ec 08             	sub    $0x8,%esp
f01009f3:	ff 75 a8             	pushl  -0x58(%ebp)
f01009f6:	68 e0 1d 10 f0       	push   $0xf0101de0
f01009fb:	e8 49 00 00 00       	call   f0100a49 <cprintf>
f0100a00:	83 c4 10             	add    $0x10,%esp
f0100a03:	e9 f6 fe ff ff       	jmp    f01008fe <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100a08:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a0b:	5b                   	pop    %ebx
f0100a0c:	5e                   	pop    %esi
f0100a0d:	5f                   	pop    %edi
f0100a0e:	5d                   	pop    %ebp
f0100a0f:	c3                   	ret    

f0100a10 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100a10:	55                   	push   %ebp
f0100a11:	89 e5                	mov    %esp,%ebp
f0100a13:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0100a16:	ff 75 08             	pushl  0x8(%ebp)
f0100a19:	e8 2f fc ff ff       	call   f010064d <cputchar>
	*cnt++;
}
f0100a1e:	83 c4 10             	add    $0x10,%esp
f0100a21:	c9                   	leave  
f0100a22:	c3                   	ret    

f0100a23 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100a23:	55                   	push   %ebp
f0100a24:	89 e5                	mov    %esp,%ebp
f0100a26:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0100a29:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100a30:	ff 75 0c             	pushl  0xc(%ebp)
f0100a33:	ff 75 08             	pushl  0x8(%ebp)
f0100a36:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100a39:	50                   	push   %eax
f0100a3a:	68 10 0a 10 f0       	push   $0xf0100a10
f0100a3f:	e8 0a 04 00 00       	call   f0100e4e <vprintfmt>
	return cnt;
}
f0100a44:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100a47:	c9                   	leave  
f0100a48:	c3                   	ret    

f0100a49 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100a49:	55                   	push   %ebp
f0100a4a:	89 e5                	mov    %esp,%ebp
f0100a4c:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100a4f:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100a52:	50                   	push   %eax
f0100a53:	ff 75 08             	pushl  0x8(%ebp)
f0100a56:	e8 c8 ff ff ff       	call   f0100a23 <vcprintf>
	va_end(ap);

	return cnt;
}
f0100a5b:	c9                   	leave  
f0100a5c:	c3                   	ret    

f0100a5d <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100a5d:	55                   	push   %ebp
f0100a5e:	89 e5                	mov    %esp,%ebp
f0100a60:	57                   	push   %edi
f0100a61:	56                   	push   %esi
f0100a62:	53                   	push   %ebx
f0100a63:	83 ec 14             	sub    $0x14,%esp
f0100a66:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100a69:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100a6c:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100a6f:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100a72:	8b 1a                	mov    (%edx),%ebx
f0100a74:	8b 01                	mov    (%ecx),%eax
f0100a76:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a79:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0100a80:	eb 7f                	jmp    f0100b01 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0100a82:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100a85:	01 d8                	add    %ebx,%eax
f0100a87:	89 c6                	mov    %eax,%esi
f0100a89:	c1 ee 1f             	shr    $0x1f,%esi
f0100a8c:	01 c6                	add    %eax,%esi
f0100a8e:	d1 fe                	sar    %esi
f0100a90:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0100a93:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100a96:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0100a99:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a9b:	eb 03                	jmp    f0100aa0 <stab_binsearch+0x43>
			m--;
f0100a9d:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100aa0:	39 c3                	cmp    %eax,%ebx
f0100aa2:	7f 0d                	jg     f0100ab1 <stab_binsearch+0x54>
f0100aa4:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0100aa8:	83 ea 0c             	sub    $0xc,%edx
f0100aab:	39 f9                	cmp    %edi,%ecx
f0100aad:	75 ee                	jne    f0100a9d <stab_binsearch+0x40>
f0100aaf:	eb 05                	jmp    f0100ab6 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100ab1:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f0100ab4:	eb 4b                	jmp    f0100b01 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100ab6:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100ab9:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100abc:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100ac0:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100ac3:	76 11                	jbe    f0100ad6 <stab_binsearch+0x79>
			*region_left = m;
f0100ac5:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100ac8:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0100aca:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100acd:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100ad4:	eb 2b                	jmp    f0100b01 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100ad6:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100ad9:	73 14                	jae    f0100aef <stab_binsearch+0x92>
			*region_right = m - 1;
f0100adb:	83 e8 01             	sub    $0x1,%eax
f0100ade:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100ae1:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100ae4:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100ae6:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100aed:	eb 12                	jmp    f0100b01 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100aef:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100af2:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0100af4:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100af8:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100afa:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100b01:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100b04:	0f 8e 78 ff ff ff    	jle    f0100a82 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100b0a:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100b0e:	75 0f                	jne    f0100b1f <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0100b10:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b13:	8b 00                	mov    (%eax),%eax
f0100b15:	83 e8 01             	sub    $0x1,%eax
f0100b18:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100b1b:	89 06                	mov    %eax,(%esi)
f0100b1d:	eb 2c                	jmp    f0100b4b <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b1f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b22:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100b24:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100b27:	8b 0e                	mov    (%esi),%ecx
f0100b29:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100b2c:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0100b2f:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b32:	eb 03                	jmp    f0100b37 <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100b34:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b37:	39 c8                	cmp    %ecx,%eax
f0100b39:	7e 0b                	jle    f0100b46 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f0100b3b:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0100b3f:	83 ea 0c             	sub    $0xc,%edx
f0100b42:	39 df                	cmp    %ebx,%edi
f0100b44:	75 ee                	jne    f0100b34 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100b46:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100b49:	89 06                	mov    %eax,(%esi)
	}
}
f0100b4b:	83 c4 14             	add    $0x14,%esp
f0100b4e:	5b                   	pop    %ebx
f0100b4f:	5e                   	pop    %esi
f0100b50:	5f                   	pop    %edi
f0100b51:	5d                   	pop    %ebp
f0100b52:	c3                   	ret    

f0100b53 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100b53:	55                   	push   %ebp
f0100b54:	89 e5                	mov    %esp,%ebp
f0100b56:	57                   	push   %edi
f0100b57:	56                   	push   %esi
f0100b58:	53                   	push   %ebx
f0100b59:	83 ec 3c             	sub    $0x3c,%esp
f0100b5c:	8b 75 08             	mov    0x8(%ebp),%esi
f0100b5f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100b62:	c7 03 e4 20 10 f0    	movl   $0xf01020e4,(%ebx)
	info->eip_line = 0;
f0100b68:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100b6f:	c7 43 08 e4 20 10 f0 	movl   $0xf01020e4,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100b76:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100b7d:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100b80:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100b87:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100b8d:	76 11                	jbe    f0100ba0 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b8f:	b8 62 76 10 f0       	mov    $0xf0107662,%eax
f0100b94:	3d 69 5d 10 f0       	cmp    $0xf0105d69,%eax
f0100b99:	77 1c                	ja     f0100bb7 <debuginfo_eip+0x64>
f0100b9b:	e9 a3 01 00 00       	jmp    f0100d43 <debuginfo_eip+0x1f0>
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
        
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100ba0:	83 ec 04             	sub    $0x4,%esp
f0100ba3:	68 ee 20 10 f0       	push   $0xf01020ee
f0100ba8:	68 86 00 00 00       	push   $0x86
f0100bad:	68 fb 20 10 f0       	push   $0xf01020fb
f0100bb2:	e8 2f f5 ff ff       	call   f01000e6 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100bb7:	80 3d 61 76 10 f0 00 	cmpb   $0x0,0xf0107661
f0100bbe:	0f 85 86 01 00 00    	jne    f0100d4a <debuginfo_eip+0x1f7>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100bc4:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100bcb:	b8 68 5d 10 f0       	mov    $0xf0105d68,%eax
f0100bd0:	2d 30 23 10 f0       	sub    $0xf0102330,%eax
f0100bd5:	c1 f8 02             	sar    $0x2,%eax
f0100bd8:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100bde:	83 e8 01             	sub    $0x1,%eax
f0100be1:	89 45 e0             	mov    %eax,-0x20(%ebp)

	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100be4:	83 ec 08             	sub    $0x8,%esp
f0100be7:	56                   	push   %esi
f0100be8:	6a 64                	push   $0x64
f0100bea:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100bed:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100bf0:	b8 30 23 10 f0       	mov    $0xf0102330,%eax
f0100bf5:	e8 63 fe ff ff       	call   f0100a5d <stab_binsearch>
	if (lfile == 0)
f0100bfa:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100bfd:	83 c4 10             	add    $0x10,%esp
f0100c00:	85 c0                	test   %eax,%eax
f0100c02:	0f 84 49 01 00 00    	je     f0100d51 <debuginfo_eip+0x1fe>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100c08:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100c0b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c0e:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100c11:	83 ec 08             	sub    $0x8,%esp
f0100c14:	56                   	push   %esi
f0100c15:	6a 24                	push   $0x24
f0100c17:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100c1a:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100c1d:	b8 30 23 10 f0       	mov    $0xf0102330,%eax
f0100c22:	e8 36 fe ff ff       	call   f0100a5d <stab_binsearch>

	if (lfun <= rfun) {
f0100c27:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100c2a:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100c2d:	83 c4 10             	add    $0x10,%esp
f0100c30:	39 d0                	cmp    %edx,%eax
f0100c32:	7f 40                	jg     f0100c74 <debuginfo_eip+0x121>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.


		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100c34:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0100c37:	c1 e1 02             	shl    $0x2,%ecx
f0100c3a:	8d b9 30 23 10 f0    	lea    -0xfefdcd0(%ecx),%edi
f0100c40:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0100c43:	8b b9 30 23 10 f0    	mov    -0xfefdcd0(%ecx),%edi
f0100c49:	b9 62 76 10 f0       	mov    $0xf0107662,%ecx
f0100c4e:	81 e9 69 5d 10 f0    	sub    $0xf0105d69,%ecx
f0100c54:	39 cf                	cmp    %ecx,%edi
f0100c56:	73 09                	jae    f0100c61 <debuginfo_eip+0x10e>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100c58:	81 c7 69 5d 10 f0    	add    $0xf0105d69,%edi
f0100c5e:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100c61:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100c64:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100c67:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100c6a:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100c6c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100c6f:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100c72:	eb 0f                	jmp    f0100c83 <debuginfo_eip+0x130>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.


		info->eip_fn_addr = addr;
f0100c74:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100c77:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c7a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100c7d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c80:	89 45 d0             	mov    %eax,-0x30(%ebp)

	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100c83:	83 ec 08             	sub    $0x8,%esp
f0100c86:	6a 3a                	push   $0x3a
f0100c88:	ff 73 08             	pushl  0x8(%ebx)
f0100c8b:	e8 c7 08 00 00       	call   f0101557 <strfind>
f0100c90:	2b 43 08             	sub    0x8(%ebx),%eax
f0100c93:	89 43 0c             	mov    %eax,0xc(%ebx)
          

 //////////////////////////////////////////////////////

        
	stab_binsearch(stabs, &lline, &rline, N_SLINE	, addr);
f0100c96:	83 c4 08             	add    $0x8,%esp
f0100c99:	56                   	push   %esi
f0100c9a:	6a 44                	push   $0x44
f0100c9c:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100c9f:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100ca2:	b8 30 23 10 f0       	mov    $0xf0102330,%eax
f0100ca7:	e8 b1 fd ff ff       	call   f0100a5d <stab_binsearch>
         
        info->eip_line = stabs[lline].n_value;
f0100cac:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0100caf:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0100cb2:	8d 04 85 30 23 10 f0 	lea    -0xfefdcd0(,%eax,4),%eax
f0100cb9:	8b 48 08             	mov    0x8(%eax),%ecx
f0100cbc:	89 4b 04             	mov    %ecx,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100cbf:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100cc2:	83 c4 10             	add    $0x10,%esp
f0100cc5:	eb 06                	jmp    f0100ccd <debuginfo_eip+0x17a>
f0100cc7:	83 ea 01             	sub    $0x1,%edx
f0100cca:	83 e8 0c             	sub    $0xc,%eax
f0100ccd:	39 d6                	cmp    %edx,%esi
f0100ccf:	7f 34                	jg     f0100d05 <debuginfo_eip+0x1b2>
	       && stabs[lline].n_type != N_SOL
f0100cd1:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0100cd5:	80 f9 84             	cmp    $0x84,%cl
f0100cd8:	74 0b                	je     f0100ce5 <debuginfo_eip+0x192>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100cda:	80 f9 64             	cmp    $0x64,%cl
f0100cdd:	75 e8                	jne    f0100cc7 <debuginfo_eip+0x174>
f0100cdf:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100ce3:	74 e2                	je     f0100cc7 <debuginfo_eip+0x174>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100ce5:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0100ce8:	8b 14 85 30 23 10 f0 	mov    -0xfefdcd0(,%eax,4),%edx
f0100cef:	b8 62 76 10 f0       	mov    $0xf0107662,%eax
f0100cf4:	2d 69 5d 10 f0       	sub    $0xf0105d69,%eax
f0100cf9:	39 c2                	cmp    %eax,%edx
f0100cfb:	73 08                	jae    f0100d05 <debuginfo_eip+0x1b2>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100cfd:	81 c2 69 5d 10 f0    	add    $0xf0105d69,%edx
f0100d03:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100d05:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100d08:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100d0b:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100d10:	39 f2                	cmp    %esi,%edx
f0100d12:	7d 49                	jge    f0100d5d <debuginfo_eip+0x20a>
		for (lline = lfun + 1;
f0100d14:	83 c2 01             	add    $0x1,%edx
f0100d17:	89 d0                	mov    %edx,%eax
f0100d19:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0100d1c:	8d 14 95 30 23 10 f0 	lea    -0xfefdcd0(,%edx,4),%edx
f0100d23:	eb 04                	jmp    f0100d29 <debuginfo_eip+0x1d6>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100d25:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100d29:	39 c6                	cmp    %eax,%esi
f0100d2b:	7e 2b                	jle    f0100d58 <debuginfo_eip+0x205>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100d2d:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0100d31:	83 c0 01             	add    $0x1,%eax
f0100d34:	83 c2 0c             	add    $0xc,%edx
f0100d37:	80 f9 a0             	cmp    $0xa0,%cl
f0100d3a:	74 e9                	je     f0100d25 <debuginfo_eip+0x1d2>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100d3c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d41:	eb 1a                	jmp    f0100d5d <debuginfo_eip+0x20a>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100d43:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d48:	eb 13                	jmp    f0100d5d <debuginfo_eip+0x20a>
f0100d4a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d4f:	eb 0c                	jmp    f0100d5d <debuginfo_eip+0x20a>
	lfile = 0;
	rfile = (stab_end - stabs) - 1;

	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100d51:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d56:	eb 05                	jmp    f0100d5d <debuginfo_eip+0x20a>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100d58:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100d5d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100d60:	5b                   	pop    %ebx
f0100d61:	5e                   	pop    %esi
f0100d62:	5f                   	pop    %edi
f0100d63:	5d                   	pop    %ebp
f0100d64:	c3                   	ret    

f0100d65 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100d65:	55                   	push   %ebp
f0100d66:	89 e5                	mov    %esp,%ebp
f0100d68:	57                   	push   %edi
f0100d69:	56                   	push   %esi
f0100d6a:	53                   	push   %ebx
f0100d6b:	83 ec 1c             	sub    $0x1c,%esp
f0100d6e:	89 c7                	mov    %eax,%edi
f0100d70:	89 d6                	mov    %edx,%esi
f0100d72:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d75:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100d78:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100d7b:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100d7e:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0100d81:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100d86:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100d89:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0100d8c:	39 d3                	cmp    %edx,%ebx
f0100d8e:	72 05                	jb     f0100d95 <printnum+0x30>
f0100d90:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100d93:	77 45                	ja     f0100dda <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100d95:	83 ec 0c             	sub    $0xc,%esp
f0100d98:	ff 75 18             	pushl  0x18(%ebp)
f0100d9b:	8b 45 14             	mov    0x14(%ebp),%eax
f0100d9e:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100da1:	53                   	push   %ebx
f0100da2:	ff 75 10             	pushl  0x10(%ebp)
f0100da5:	83 ec 08             	sub    $0x8,%esp
f0100da8:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100dab:	ff 75 e0             	pushl  -0x20(%ebp)
f0100dae:	ff 75 dc             	pushl  -0x24(%ebp)
f0100db1:	ff 75 d8             	pushl  -0x28(%ebp)
f0100db4:	e8 c7 09 00 00       	call   f0101780 <__udivdi3>
f0100db9:	83 c4 18             	add    $0x18,%esp
f0100dbc:	52                   	push   %edx
f0100dbd:	50                   	push   %eax
f0100dbe:	89 f2                	mov    %esi,%edx
f0100dc0:	89 f8                	mov    %edi,%eax
f0100dc2:	e8 9e ff ff ff       	call   f0100d65 <printnum>
f0100dc7:	83 c4 20             	add    $0x20,%esp
f0100dca:	eb 18                	jmp    f0100de4 <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100dcc:	83 ec 08             	sub    $0x8,%esp
f0100dcf:	56                   	push   %esi
f0100dd0:	ff 75 18             	pushl  0x18(%ebp)
f0100dd3:	ff d7                	call   *%edi
f0100dd5:	83 c4 10             	add    $0x10,%esp
f0100dd8:	eb 03                	jmp    f0100ddd <printnum+0x78>
f0100dda:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100ddd:	83 eb 01             	sub    $0x1,%ebx
f0100de0:	85 db                	test   %ebx,%ebx
f0100de2:	7f e8                	jg     f0100dcc <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100de4:	83 ec 08             	sub    $0x8,%esp
f0100de7:	56                   	push   %esi
f0100de8:	83 ec 04             	sub    $0x4,%esp
f0100deb:	ff 75 e4             	pushl  -0x1c(%ebp)
f0100dee:	ff 75 e0             	pushl  -0x20(%ebp)
f0100df1:	ff 75 dc             	pushl  -0x24(%ebp)
f0100df4:	ff 75 d8             	pushl  -0x28(%ebp)
f0100df7:	e8 b4 0a 00 00       	call   f01018b0 <__umoddi3>
f0100dfc:	83 c4 14             	add    $0x14,%esp
f0100dff:	0f be 80 09 21 10 f0 	movsbl -0xfefdef7(%eax),%eax
f0100e06:	50                   	push   %eax
f0100e07:	ff d7                	call   *%edi
}
f0100e09:	83 c4 10             	add    $0x10,%esp
f0100e0c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e0f:	5b                   	pop    %ebx
f0100e10:	5e                   	pop    %esi
f0100e11:	5f                   	pop    %edi
f0100e12:	5d                   	pop    %ebp
f0100e13:	c3                   	ret    

f0100e14 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100e14:	55                   	push   %ebp
f0100e15:	89 e5                	mov    %esp,%ebp
f0100e17:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100e1a:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100e1e:	8b 10                	mov    (%eax),%edx
f0100e20:	3b 50 04             	cmp    0x4(%eax),%edx
f0100e23:	73 0a                	jae    f0100e2f <sprintputch+0x1b>
		*b->buf++ = ch;
f0100e25:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100e28:	89 08                	mov    %ecx,(%eax)
f0100e2a:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e2d:	88 02                	mov    %al,(%edx)
}
f0100e2f:	5d                   	pop    %ebp
f0100e30:	c3                   	ret    

f0100e31 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100e31:	55                   	push   %ebp
f0100e32:	89 e5                	mov    %esp,%ebp
f0100e34:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100e37:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100e3a:	50                   	push   %eax
f0100e3b:	ff 75 10             	pushl  0x10(%ebp)
f0100e3e:	ff 75 0c             	pushl  0xc(%ebp)
f0100e41:	ff 75 08             	pushl  0x8(%ebp)
f0100e44:	e8 05 00 00 00       	call   f0100e4e <vprintfmt>
	va_end(ap);
}
f0100e49:	83 c4 10             	add    $0x10,%esp
f0100e4c:	c9                   	leave  
f0100e4d:	c3                   	ret    

f0100e4e <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100e4e:	55                   	push   %ebp
f0100e4f:	89 e5                	mov    %esp,%ebp
f0100e51:	57                   	push   %edi
f0100e52:	56                   	push   %esi
f0100e53:	53                   	push   %ebx
f0100e54:	83 ec 2c             	sub    $0x2c,%esp
f0100e57:	8b 75 08             	mov    0x8(%ebp),%esi
f0100e5a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100e5d:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100e60:	eb 12                	jmp    f0100e74 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100e62:	85 c0                	test   %eax,%eax
f0100e64:	0f 84 42 04 00 00    	je     f01012ac <vprintfmt+0x45e>
				return;
			putch(ch, putdat);
f0100e6a:	83 ec 08             	sub    $0x8,%esp
f0100e6d:	53                   	push   %ebx
f0100e6e:	50                   	push   %eax
f0100e6f:	ff d6                	call   *%esi
f0100e71:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100e74:	83 c7 01             	add    $0x1,%edi
f0100e77:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100e7b:	83 f8 25             	cmp    $0x25,%eax
f0100e7e:	75 e2                	jne    f0100e62 <vprintfmt+0x14>
f0100e80:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0100e84:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100e8b:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100e92:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0100e99:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100e9e:	eb 07                	jmp    f0100ea7 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ea0:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100ea3:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ea7:	8d 47 01             	lea    0x1(%edi),%eax
f0100eaa:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100ead:	0f b6 07             	movzbl (%edi),%eax
f0100eb0:	0f b6 d0             	movzbl %al,%edx
f0100eb3:	83 e8 23             	sub    $0x23,%eax
f0100eb6:	3c 55                	cmp    $0x55,%al
f0100eb8:	0f 87 d3 03 00 00    	ja     f0101291 <vprintfmt+0x443>
f0100ebe:	0f b6 c0             	movzbl %al,%eax
f0100ec1:	ff 24 85 a0 21 10 f0 	jmp    *-0xfefde60(,%eax,4)
f0100ec8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100ecb:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100ecf:	eb d6                	jmp    f0100ea7 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ed1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100ed4:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ed9:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100edc:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100edf:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0100ee3:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0100ee6:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0100ee9:	83 f9 09             	cmp    $0x9,%ecx
f0100eec:	77 3f                	ja     f0100f2d <vprintfmt+0xdf>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100eee:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100ef1:	eb e9                	jmp    f0100edc <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100ef3:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ef6:	8b 00                	mov    (%eax),%eax
f0100ef8:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100efb:	8b 45 14             	mov    0x14(%ebp),%eax
f0100efe:	8d 40 04             	lea    0x4(%eax),%eax
f0100f01:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f04:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100f07:	eb 2a                	jmp    f0100f33 <vprintfmt+0xe5>
f0100f09:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100f0c:	85 c0                	test   %eax,%eax
f0100f0e:	ba 00 00 00 00       	mov    $0x0,%edx
f0100f13:	0f 49 d0             	cmovns %eax,%edx
f0100f16:	89 55 e0             	mov    %edx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f19:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100f1c:	eb 89                	jmp    f0100ea7 <vprintfmt+0x59>
f0100f1e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100f21:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100f28:	e9 7a ff ff ff       	jmp    f0100ea7 <vprintfmt+0x59>
f0100f2d:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100f30:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0100f33:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100f37:	0f 89 6a ff ff ff    	jns    f0100ea7 <vprintfmt+0x59>
				width = precision, precision = -1;
f0100f3d:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100f40:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100f43:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100f4a:	e9 58 ff ff ff       	jmp    f0100ea7 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100f4f:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f52:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100f55:	e9 4d ff ff ff       	jmp    f0100ea7 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100f5a:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f5d:	8d 78 04             	lea    0x4(%eax),%edi
f0100f60:	83 ec 08             	sub    $0x8,%esp
f0100f63:	53                   	push   %ebx
f0100f64:	ff 30                	pushl  (%eax)
f0100f66:	ff d6                	call   *%esi
			break;
f0100f68:	83 c4 10             	add    $0x10,%esp
			lflag++;
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100f6b:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f6e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0100f71:	e9 fe fe ff ff       	jmp    f0100e74 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100f76:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f79:	8d 78 04             	lea    0x4(%eax),%edi
f0100f7c:	8b 00                	mov    (%eax),%eax
f0100f7e:	99                   	cltd   
f0100f7f:	31 d0                	xor    %edx,%eax
f0100f81:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100f83:	83 f8 07             	cmp    $0x7,%eax
f0100f86:	7f 0b                	jg     f0100f93 <vprintfmt+0x145>
f0100f88:	8b 14 85 00 23 10 f0 	mov    -0xfefdd00(,%eax,4),%edx
f0100f8f:	85 d2                	test   %edx,%edx
f0100f91:	75 1b                	jne    f0100fae <vprintfmt+0x160>
				printfmt(putch, putdat, "error %d", err);
f0100f93:	50                   	push   %eax
f0100f94:	68 21 21 10 f0       	push   $0xf0102121
f0100f99:	53                   	push   %ebx
f0100f9a:	56                   	push   %esi
f0100f9b:	e8 91 fe ff ff       	call   f0100e31 <printfmt>
f0100fa0:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100fa3:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fa6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0100fa9:	e9 c6 fe ff ff       	jmp    f0100e74 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0100fae:	52                   	push   %edx
f0100faf:	68 2a 21 10 f0       	push   $0xf010212a
f0100fb4:	53                   	push   %ebx
f0100fb5:	56                   	push   %esi
f0100fb6:	e8 76 fe ff ff       	call   f0100e31 <printfmt>
f0100fbb:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100fbe:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fc1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100fc4:	e9 ab fe ff ff       	jmp    f0100e74 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100fc9:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fcc:	83 c0 04             	add    $0x4,%eax
f0100fcf:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100fd2:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fd5:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0100fd7:	85 ff                	test   %edi,%edi
f0100fd9:	b8 1a 21 10 f0       	mov    $0xf010211a,%eax
f0100fde:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0100fe1:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100fe5:	0f 8e 94 00 00 00    	jle    f010107f <vprintfmt+0x231>
f0100feb:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0100fef:	0f 84 98 00 00 00    	je     f010108d <vprintfmt+0x23f>
				for (width -= strnlen(p, precision); width > 0; width--)
f0100ff5:	83 ec 08             	sub    $0x8,%esp
f0100ff8:	ff 75 d0             	pushl  -0x30(%ebp)
f0100ffb:	57                   	push   %edi
f0100ffc:	e8 0c 04 00 00       	call   f010140d <strnlen>
f0101001:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0101004:	29 c1                	sub    %eax,%ecx
f0101006:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f0101009:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f010100c:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0101010:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101013:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0101016:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101018:	eb 0f                	jmp    f0101029 <vprintfmt+0x1db>
					putch(padc, putdat);
f010101a:	83 ec 08             	sub    $0x8,%esp
f010101d:	53                   	push   %ebx
f010101e:	ff 75 e0             	pushl  -0x20(%ebp)
f0101021:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101023:	83 ef 01             	sub    $0x1,%edi
f0101026:	83 c4 10             	add    $0x10,%esp
f0101029:	85 ff                	test   %edi,%edi
f010102b:	7f ed                	jg     f010101a <vprintfmt+0x1cc>
f010102d:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101030:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0101033:	85 c9                	test   %ecx,%ecx
f0101035:	b8 00 00 00 00       	mov    $0x0,%eax
f010103a:	0f 49 c1             	cmovns %ecx,%eax
f010103d:	29 c1                	sub    %eax,%ecx
f010103f:	89 75 08             	mov    %esi,0x8(%ebp)
f0101042:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101045:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101048:	89 cb                	mov    %ecx,%ebx
f010104a:	eb 4d                	jmp    f0101099 <vprintfmt+0x24b>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f010104c:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0101050:	74 1b                	je     f010106d <vprintfmt+0x21f>
f0101052:	0f be c0             	movsbl %al,%eax
f0101055:	83 e8 20             	sub    $0x20,%eax
f0101058:	83 f8 5e             	cmp    $0x5e,%eax
f010105b:	76 10                	jbe    f010106d <vprintfmt+0x21f>
					putch('?', putdat);
f010105d:	83 ec 08             	sub    $0x8,%esp
f0101060:	ff 75 0c             	pushl  0xc(%ebp)
f0101063:	6a 3f                	push   $0x3f
f0101065:	ff 55 08             	call   *0x8(%ebp)
f0101068:	83 c4 10             	add    $0x10,%esp
f010106b:	eb 0d                	jmp    f010107a <vprintfmt+0x22c>
				else
					putch(ch, putdat);
f010106d:	83 ec 08             	sub    $0x8,%esp
f0101070:	ff 75 0c             	pushl  0xc(%ebp)
f0101073:	52                   	push   %edx
f0101074:	ff 55 08             	call   *0x8(%ebp)
f0101077:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010107a:	83 eb 01             	sub    $0x1,%ebx
f010107d:	eb 1a                	jmp    f0101099 <vprintfmt+0x24b>
f010107f:	89 75 08             	mov    %esi,0x8(%ebp)
f0101082:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101085:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101088:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010108b:	eb 0c                	jmp    f0101099 <vprintfmt+0x24b>
f010108d:	89 75 08             	mov    %esi,0x8(%ebp)
f0101090:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101093:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101096:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0101099:	83 c7 01             	add    $0x1,%edi
f010109c:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01010a0:	0f be d0             	movsbl %al,%edx
f01010a3:	85 d2                	test   %edx,%edx
f01010a5:	74 23                	je     f01010ca <vprintfmt+0x27c>
f01010a7:	85 f6                	test   %esi,%esi
f01010a9:	78 a1                	js     f010104c <vprintfmt+0x1fe>
f01010ab:	83 ee 01             	sub    $0x1,%esi
f01010ae:	79 9c                	jns    f010104c <vprintfmt+0x1fe>
f01010b0:	89 df                	mov    %ebx,%edi
f01010b2:	8b 75 08             	mov    0x8(%ebp),%esi
f01010b5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01010b8:	eb 18                	jmp    f01010d2 <vprintfmt+0x284>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01010ba:	83 ec 08             	sub    $0x8,%esp
f01010bd:	53                   	push   %ebx
f01010be:	6a 20                	push   $0x20
f01010c0:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01010c2:	83 ef 01             	sub    $0x1,%edi
f01010c5:	83 c4 10             	add    $0x10,%esp
f01010c8:	eb 08                	jmp    f01010d2 <vprintfmt+0x284>
f01010ca:	89 df                	mov    %ebx,%edi
f01010cc:	8b 75 08             	mov    0x8(%ebp),%esi
f01010cf:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01010d2:	85 ff                	test   %edi,%edi
f01010d4:	7f e4                	jg     f01010ba <vprintfmt+0x26c>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01010d6:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01010d9:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01010dc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01010df:	e9 90 fd ff ff       	jmp    f0100e74 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01010e4:	83 f9 01             	cmp    $0x1,%ecx
f01010e7:	7e 19                	jle    f0101102 <vprintfmt+0x2b4>
		return va_arg(*ap, long long);
f01010e9:	8b 45 14             	mov    0x14(%ebp),%eax
f01010ec:	8b 50 04             	mov    0x4(%eax),%edx
f01010ef:	8b 00                	mov    (%eax),%eax
f01010f1:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01010f4:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01010f7:	8b 45 14             	mov    0x14(%ebp),%eax
f01010fa:	8d 40 08             	lea    0x8(%eax),%eax
f01010fd:	89 45 14             	mov    %eax,0x14(%ebp)
f0101100:	eb 38                	jmp    f010113a <vprintfmt+0x2ec>
	else if (lflag)
f0101102:	85 c9                	test   %ecx,%ecx
f0101104:	74 1b                	je     f0101121 <vprintfmt+0x2d3>
		return va_arg(*ap, long);
f0101106:	8b 45 14             	mov    0x14(%ebp),%eax
f0101109:	8b 00                	mov    (%eax),%eax
f010110b:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010110e:	89 c1                	mov    %eax,%ecx
f0101110:	c1 f9 1f             	sar    $0x1f,%ecx
f0101113:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0101116:	8b 45 14             	mov    0x14(%ebp),%eax
f0101119:	8d 40 04             	lea    0x4(%eax),%eax
f010111c:	89 45 14             	mov    %eax,0x14(%ebp)
f010111f:	eb 19                	jmp    f010113a <vprintfmt+0x2ec>
	else
		return va_arg(*ap, int);
f0101121:	8b 45 14             	mov    0x14(%ebp),%eax
f0101124:	8b 00                	mov    (%eax),%eax
f0101126:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101129:	89 c1                	mov    %eax,%ecx
f010112b:	c1 f9 1f             	sar    $0x1f,%ecx
f010112e:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0101131:	8b 45 14             	mov    0x14(%ebp),%eax
f0101134:	8d 40 04             	lea    0x4(%eax),%eax
f0101137:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f010113a:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010113d:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0101140:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101145:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101149:	0f 89 0e 01 00 00    	jns    f010125d <vprintfmt+0x40f>
				putch('-', putdat);
f010114f:	83 ec 08             	sub    $0x8,%esp
f0101152:	53                   	push   %ebx
f0101153:	6a 2d                	push   $0x2d
f0101155:	ff d6                	call   *%esi
				num = -(long long) num;
f0101157:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010115a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010115d:	f7 da                	neg    %edx
f010115f:	83 d1 00             	adc    $0x0,%ecx
f0101162:	f7 d9                	neg    %ecx
f0101164:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0101167:	b8 0a 00 00 00       	mov    $0xa,%eax
f010116c:	e9 ec 00 00 00       	jmp    f010125d <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101171:	83 f9 01             	cmp    $0x1,%ecx
f0101174:	7e 18                	jle    f010118e <vprintfmt+0x340>
		return va_arg(*ap, unsigned long long);
f0101176:	8b 45 14             	mov    0x14(%ebp),%eax
f0101179:	8b 10                	mov    (%eax),%edx
f010117b:	8b 48 04             	mov    0x4(%eax),%ecx
f010117e:	8d 40 08             	lea    0x8(%eax),%eax
f0101181:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f0101184:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101189:	e9 cf 00 00 00       	jmp    f010125d <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f010118e:	85 c9                	test   %ecx,%ecx
f0101190:	74 1a                	je     f01011ac <vprintfmt+0x35e>
		return va_arg(*ap, unsigned long);
f0101192:	8b 45 14             	mov    0x14(%ebp),%eax
f0101195:	8b 10                	mov    (%eax),%edx
f0101197:	b9 00 00 00 00       	mov    $0x0,%ecx
f010119c:	8d 40 04             	lea    0x4(%eax),%eax
f010119f:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f01011a2:	b8 0a 00 00 00       	mov    $0xa,%eax
f01011a7:	e9 b1 00 00 00       	jmp    f010125d <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f01011ac:	8b 45 14             	mov    0x14(%ebp),%eax
f01011af:	8b 10                	mov    (%eax),%edx
f01011b1:	b9 00 00 00 00       	mov    $0x0,%ecx
f01011b6:	8d 40 04             	lea    0x4(%eax),%eax
f01011b9:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f01011bc:	b8 0a 00 00 00       	mov    $0xa,%eax
f01011c1:	e9 97 00 00 00       	jmp    f010125d <vprintfmt+0x40f>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f01011c6:	83 ec 08             	sub    $0x8,%esp
f01011c9:	53                   	push   %ebx
f01011ca:	6a 58                	push   $0x58
f01011cc:	ff d6                	call   *%esi
			putch('X', putdat);
f01011ce:	83 c4 08             	add    $0x8,%esp
f01011d1:	53                   	push   %ebx
f01011d2:	6a 58                	push   $0x58
f01011d4:	ff d6                	call   *%esi
			putch('X', putdat);
f01011d6:	83 c4 08             	add    $0x8,%esp
f01011d9:	53                   	push   %ebx
f01011da:	6a 58                	push   $0x58
f01011dc:	ff d6                	call   *%esi
			break;
f01011de:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01011e1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f01011e4:	e9 8b fc ff ff       	jmp    f0100e74 <vprintfmt+0x26>

		// pointer
		case 'p':
			putch('0', putdat);
f01011e9:	83 ec 08             	sub    $0x8,%esp
f01011ec:	53                   	push   %ebx
f01011ed:	6a 30                	push   $0x30
f01011ef:	ff d6                	call   *%esi
			putch('x', putdat);
f01011f1:	83 c4 08             	add    $0x8,%esp
f01011f4:	53                   	push   %ebx
f01011f5:	6a 78                	push   $0x78
f01011f7:	ff d6                	call   *%esi
			num = (unsigned long long)
f01011f9:	8b 45 14             	mov    0x14(%ebp),%eax
f01011fc:	8b 10                	mov    (%eax),%edx
f01011fe:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0101203:	83 c4 10             	add    $0x10,%esp
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0101206:	8d 40 04             	lea    0x4(%eax),%eax
f0101209:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010120c:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0101211:	eb 4a                	jmp    f010125d <vprintfmt+0x40f>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101213:	83 f9 01             	cmp    $0x1,%ecx
f0101216:	7e 15                	jle    f010122d <vprintfmt+0x3df>
		return va_arg(*ap, unsigned long long);
f0101218:	8b 45 14             	mov    0x14(%ebp),%eax
f010121b:	8b 10                	mov    (%eax),%edx
f010121d:	8b 48 04             	mov    0x4(%eax),%ecx
f0101220:	8d 40 08             	lea    0x8(%eax),%eax
f0101223:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0101226:	b8 10 00 00 00       	mov    $0x10,%eax
f010122b:	eb 30                	jmp    f010125d <vprintfmt+0x40f>
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
f010122d:	85 c9                	test   %ecx,%ecx
f010122f:	74 17                	je     f0101248 <vprintfmt+0x3fa>
		return va_arg(*ap, unsigned long);
f0101231:	8b 45 14             	mov    0x14(%ebp),%eax
f0101234:	8b 10                	mov    (%eax),%edx
f0101236:	b9 00 00 00 00       	mov    $0x0,%ecx
f010123b:	8d 40 04             	lea    0x4(%eax),%eax
f010123e:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0101241:	b8 10 00 00 00       	mov    $0x10,%eax
f0101246:	eb 15                	jmp    f010125d <vprintfmt+0x40f>
	if (lflag >= 2)
		return va_arg(*ap, unsigned long long);
	else if (lflag)
		return va_arg(*ap, unsigned long);
	else
		return va_arg(*ap, unsigned int);
f0101248:	8b 45 14             	mov    0x14(%ebp),%eax
f010124b:	8b 10                	mov    (%eax),%edx
f010124d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101252:	8d 40 04             	lea    0x4(%eax),%eax
f0101255:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f0101258:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f010125d:	83 ec 0c             	sub    $0xc,%esp
f0101260:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0101264:	57                   	push   %edi
f0101265:	ff 75 e0             	pushl  -0x20(%ebp)
f0101268:	50                   	push   %eax
f0101269:	51                   	push   %ecx
f010126a:	52                   	push   %edx
f010126b:	89 da                	mov    %ebx,%edx
f010126d:	89 f0                	mov    %esi,%eax
f010126f:	e8 f1 fa ff ff       	call   f0100d65 <printnum>
			break;
f0101274:	83 c4 20             	add    $0x20,%esp
f0101277:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010127a:	e9 f5 fb ff ff       	jmp    f0100e74 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010127f:	83 ec 08             	sub    $0x8,%esp
f0101282:	53                   	push   %ebx
f0101283:	52                   	push   %edx
f0101284:	ff d6                	call   *%esi
			break;
f0101286:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101289:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f010128c:	e9 e3 fb ff ff       	jmp    f0100e74 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101291:	83 ec 08             	sub    $0x8,%esp
f0101294:	53                   	push   %ebx
f0101295:	6a 25                	push   $0x25
f0101297:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101299:	83 c4 10             	add    $0x10,%esp
f010129c:	eb 03                	jmp    f01012a1 <vprintfmt+0x453>
f010129e:	83 ef 01             	sub    $0x1,%edi
f01012a1:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f01012a5:	75 f7                	jne    f010129e <vprintfmt+0x450>
f01012a7:	e9 c8 fb ff ff       	jmp    f0100e74 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f01012ac:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01012af:	5b                   	pop    %ebx
f01012b0:	5e                   	pop    %esi
f01012b1:	5f                   	pop    %edi
f01012b2:	5d                   	pop    %ebp
f01012b3:	c3                   	ret    

f01012b4 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01012b4:	55                   	push   %ebp
f01012b5:	89 e5                	mov    %esp,%ebp
f01012b7:	83 ec 18             	sub    $0x18,%esp
f01012ba:	8b 45 08             	mov    0x8(%ebp),%eax
f01012bd:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01012c0:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01012c3:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01012c7:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01012ca:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01012d1:	85 c0                	test   %eax,%eax
f01012d3:	74 26                	je     f01012fb <vsnprintf+0x47>
f01012d5:	85 d2                	test   %edx,%edx
f01012d7:	7e 22                	jle    f01012fb <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01012d9:	ff 75 14             	pushl  0x14(%ebp)
f01012dc:	ff 75 10             	pushl  0x10(%ebp)
f01012df:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01012e2:	50                   	push   %eax
f01012e3:	68 14 0e 10 f0       	push   $0xf0100e14
f01012e8:	e8 61 fb ff ff       	call   f0100e4e <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01012ed:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01012f0:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01012f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01012f6:	83 c4 10             	add    $0x10,%esp
f01012f9:	eb 05                	jmp    f0101300 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01012fb:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0101300:	c9                   	leave  
f0101301:	c3                   	ret    

f0101302 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101302:	55                   	push   %ebp
f0101303:	89 e5                	mov    %esp,%ebp
f0101305:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101308:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f010130b:	50                   	push   %eax
f010130c:	ff 75 10             	pushl  0x10(%ebp)
f010130f:	ff 75 0c             	pushl  0xc(%ebp)
f0101312:	ff 75 08             	pushl  0x8(%ebp)
f0101315:	e8 9a ff ff ff       	call   f01012b4 <vsnprintf>
	va_end(ap);

	return rc;
}
f010131a:	c9                   	leave  
f010131b:	c3                   	ret    

f010131c <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f010131c:	55                   	push   %ebp
f010131d:	89 e5                	mov    %esp,%ebp
f010131f:	57                   	push   %edi
f0101320:	56                   	push   %esi
f0101321:	53                   	push   %ebx
f0101322:	83 ec 0c             	sub    $0xc,%esp
f0101325:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0101328:	85 c0                	test   %eax,%eax
f010132a:	74 11                	je     f010133d <readline+0x21>
		cprintf("%s", prompt);
f010132c:	83 ec 08             	sub    $0x8,%esp
f010132f:	50                   	push   %eax
f0101330:	68 2a 21 10 f0       	push   $0xf010212a
f0101335:	e8 0f f7 ff ff       	call   f0100a49 <cprintf>
f010133a:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f010133d:	83 ec 0c             	sub    $0xc,%esp
f0101340:	6a 00                	push   $0x0
f0101342:	e8 27 f3 ff ff       	call   f010066e <iscons>
f0101347:	89 c7                	mov    %eax,%edi
f0101349:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010134c:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101351:	e8 07 f3 ff ff       	call   f010065d <getchar>
f0101356:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0101358:	85 c0                	test   %eax,%eax
f010135a:	79 18                	jns    f0101374 <readline+0x58>
			cprintf("read error: %e\n", c);
f010135c:	83 ec 08             	sub    $0x8,%esp
f010135f:	50                   	push   %eax
f0101360:	68 20 23 10 f0       	push   $0xf0102320
f0101365:	e8 df f6 ff ff       	call   f0100a49 <cprintf>
			return NULL;
f010136a:	83 c4 10             	add    $0x10,%esp
f010136d:	b8 00 00 00 00       	mov    $0x0,%eax
f0101372:	eb 79                	jmp    f01013ed <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101374:	83 f8 08             	cmp    $0x8,%eax
f0101377:	0f 94 c2             	sete   %dl
f010137a:	83 f8 7f             	cmp    $0x7f,%eax
f010137d:	0f 94 c0             	sete   %al
f0101380:	08 c2                	or     %al,%dl
f0101382:	74 1a                	je     f010139e <readline+0x82>
f0101384:	85 f6                	test   %esi,%esi
f0101386:	7e 16                	jle    f010139e <readline+0x82>
			if (echoing)
f0101388:	85 ff                	test   %edi,%edi
f010138a:	74 0d                	je     f0101399 <readline+0x7d>
				cputchar('\b');
f010138c:	83 ec 0c             	sub    $0xc,%esp
f010138f:	6a 08                	push   $0x8
f0101391:	e8 b7 f2 ff ff       	call   f010064d <cputchar>
f0101396:	83 c4 10             	add    $0x10,%esp
			i--;
f0101399:	83 ee 01             	sub    $0x1,%esi
f010139c:	eb b3                	jmp    f0101351 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f010139e:	83 fb 1f             	cmp    $0x1f,%ebx
f01013a1:	7e 23                	jle    f01013c6 <readline+0xaa>
f01013a3:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01013a9:	7f 1b                	jg     f01013c6 <readline+0xaa>
			if (echoing)
f01013ab:	85 ff                	test   %edi,%edi
f01013ad:	74 0c                	je     f01013bb <readline+0x9f>
				cputchar(c);
f01013af:	83 ec 0c             	sub    $0xc,%esp
f01013b2:	53                   	push   %ebx
f01013b3:	e8 95 f2 ff ff       	call   f010064d <cputchar>
f01013b8:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f01013bb:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f01013c1:	8d 76 01             	lea    0x1(%esi),%esi
f01013c4:	eb 8b                	jmp    f0101351 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f01013c6:	83 fb 0a             	cmp    $0xa,%ebx
f01013c9:	74 05                	je     f01013d0 <readline+0xb4>
f01013cb:	83 fb 0d             	cmp    $0xd,%ebx
f01013ce:	75 81                	jne    f0101351 <readline+0x35>
			if (echoing)
f01013d0:	85 ff                	test   %edi,%edi
f01013d2:	74 0d                	je     f01013e1 <readline+0xc5>
				cputchar('\n');
f01013d4:	83 ec 0c             	sub    $0xc,%esp
f01013d7:	6a 0a                	push   $0xa
f01013d9:	e8 6f f2 ff ff       	call   f010064d <cputchar>
f01013de:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f01013e1:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f01013e8:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f01013ed:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01013f0:	5b                   	pop    %ebx
f01013f1:	5e                   	pop    %esi
f01013f2:	5f                   	pop    %edi
f01013f3:	5d                   	pop    %ebp
f01013f4:	c3                   	ret    

f01013f5 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01013f5:	55                   	push   %ebp
f01013f6:	89 e5                	mov    %esp,%ebp
f01013f8:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01013fb:	b8 00 00 00 00       	mov    $0x0,%eax
f0101400:	eb 03                	jmp    f0101405 <strlen+0x10>
		n++;
f0101402:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101405:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101409:	75 f7                	jne    f0101402 <strlen+0xd>
		n++;
	return n;
}
f010140b:	5d                   	pop    %ebp
f010140c:	c3                   	ret    

f010140d <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010140d:	55                   	push   %ebp
f010140e:	89 e5                	mov    %esp,%ebp
f0101410:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101413:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101416:	ba 00 00 00 00       	mov    $0x0,%edx
f010141b:	eb 03                	jmp    f0101420 <strnlen+0x13>
		n++;
f010141d:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101420:	39 c2                	cmp    %eax,%edx
f0101422:	74 08                	je     f010142c <strnlen+0x1f>
f0101424:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0101428:	75 f3                	jne    f010141d <strnlen+0x10>
f010142a:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f010142c:	5d                   	pop    %ebp
f010142d:	c3                   	ret    

f010142e <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010142e:	55                   	push   %ebp
f010142f:	89 e5                	mov    %esp,%ebp
f0101431:	53                   	push   %ebx
f0101432:	8b 45 08             	mov    0x8(%ebp),%eax
f0101435:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101438:	89 c2                	mov    %eax,%edx
f010143a:	83 c2 01             	add    $0x1,%edx
f010143d:	83 c1 01             	add    $0x1,%ecx
f0101440:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0101444:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101447:	84 db                	test   %bl,%bl
f0101449:	75 ef                	jne    f010143a <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f010144b:	5b                   	pop    %ebx
f010144c:	5d                   	pop    %ebp
f010144d:	c3                   	ret    

f010144e <strcat>:

char *
strcat(char *dst, const char *src)
{
f010144e:	55                   	push   %ebp
f010144f:	89 e5                	mov    %esp,%ebp
f0101451:	53                   	push   %ebx
f0101452:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101455:	53                   	push   %ebx
f0101456:	e8 9a ff ff ff       	call   f01013f5 <strlen>
f010145b:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f010145e:	ff 75 0c             	pushl  0xc(%ebp)
f0101461:	01 d8                	add    %ebx,%eax
f0101463:	50                   	push   %eax
f0101464:	e8 c5 ff ff ff       	call   f010142e <strcpy>
	return dst;
}
f0101469:	89 d8                	mov    %ebx,%eax
f010146b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010146e:	c9                   	leave  
f010146f:	c3                   	ret    

f0101470 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101470:	55                   	push   %ebp
f0101471:	89 e5                	mov    %esp,%ebp
f0101473:	56                   	push   %esi
f0101474:	53                   	push   %ebx
f0101475:	8b 75 08             	mov    0x8(%ebp),%esi
f0101478:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010147b:	89 f3                	mov    %esi,%ebx
f010147d:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101480:	89 f2                	mov    %esi,%edx
f0101482:	eb 0f                	jmp    f0101493 <strncpy+0x23>
		*dst++ = *src;
f0101484:	83 c2 01             	add    $0x1,%edx
f0101487:	0f b6 01             	movzbl (%ecx),%eax
f010148a:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010148d:	80 39 01             	cmpb   $0x1,(%ecx)
f0101490:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101493:	39 da                	cmp    %ebx,%edx
f0101495:	75 ed                	jne    f0101484 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101497:	89 f0                	mov    %esi,%eax
f0101499:	5b                   	pop    %ebx
f010149a:	5e                   	pop    %esi
f010149b:	5d                   	pop    %ebp
f010149c:	c3                   	ret    

f010149d <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010149d:	55                   	push   %ebp
f010149e:	89 e5                	mov    %esp,%ebp
f01014a0:	56                   	push   %esi
f01014a1:	53                   	push   %ebx
f01014a2:	8b 75 08             	mov    0x8(%ebp),%esi
f01014a5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01014a8:	8b 55 10             	mov    0x10(%ebp),%edx
f01014ab:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01014ad:	85 d2                	test   %edx,%edx
f01014af:	74 21                	je     f01014d2 <strlcpy+0x35>
f01014b1:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f01014b5:	89 f2                	mov    %esi,%edx
f01014b7:	eb 09                	jmp    f01014c2 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01014b9:	83 c2 01             	add    $0x1,%edx
f01014bc:	83 c1 01             	add    $0x1,%ecx
f01014bf:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01014c2:	39 c2                	cmp    %eax,%edx
f01014c4:	74 09                	je     f01014cf <strlcpy+0x32>
f01014c6:	0f b6 19             	movzbl (%ecx),%ebx
f01014c9:	84 db                	test   %bl,%bl
f01014cb:	75 ec                	jne    f01014b9 <strlcpy+0x1c>
f01014cd:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f01014cf:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01014d2:	29 f0                	sub    %esi,%eax
}
f01014d4:	5b                   	pop    %ebx
f01014d5:	5e                   	pop    %esi
f01014d6:	5d                   	pop    %ebp
f01014d7:	c3                   	ret    

f01014d8 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01014d8:	55                   	push   %ebp
f01014d9:	89 e5                	mov    %esp,%ebp
f01014db:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01014de:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01014e1:	eb 06                	jmp    f01014e9 <strcmp+0x11>
		p++, q++;
f01014e3:	83 c1 01             	add    $0x1,%ecx
f01014e6:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01014e9:	0f b6 01             	movzbl (%ecx),%eax
f01014ec:	84 c0                	test   %al,%al
f01014ee:	74 04                	je     f01014f4 <strcmp+0x1c>
f01014f0:	3a 02                	cmp    (%edx),%al
f01014f2:	74 ef                	je     f01014e3 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01014f4:	0f b6 c0             	movzbl %al,%eax
f01014f7:	0f b6 12             	movzbl (%edx),%edx
f01014fa:	29 d0                	sub    %edx,%eax
}
f01014fc:	5d                   	pop    %ebp
f01014fd:	c3                   	ret    

f01014fe <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01014fe:	55                   	push   %ebp
f01014ff:	89 e5                	mov    %esp,%ebp
f0101501:	53                   	push   %ebx
f0101502:	8b 45 08             	mov    0x8(%ebp),%eax
f0101505:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101508:	89 c3                	mov    %eax,%ebx
f010150a:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f010150d:	eb 06                	jmp    f0101515 <strncmp+0x17>
		n--, p++, q++;
f010150f:	83 c0 01             	add    $0x1,%eax
f0101512:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101515:	39 d8                	cmp    %ebx,%eax
f0101517:	74 15                	je     f010152e <strncmp+0x30>
f0101519:	0f b6 08             	movzbl (%eax),%ecx
f010151c:	84 c9                	test   %cl,%cl
f010151e:	74 04                	je     f0101524 <strncmp+0x26>
f0101520:	3a 0a                	cmp    (%edx),%cl
f0101522:	74 eb                	je     f010150f <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101524:	0f b6 00             	movzbl (%eax),%eax
f0101527:	0f b6 12             	movzbl (%edx),%edx
f010152a:	29 d0                	sub    %edx,%eax
f010152c:	eb 05                	jmp    f0101533 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f010152e:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101533:	5b                   	pop    %ebx
f0101534:	5d                   	pop    %ebp
f0101535:	c3                   	ret    

f0101536 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101536:	55                   	push   %ebp
f0101537:	89 e5                	mov    %esp,%ebp
f0101539:	8b 45 08             	mov    0x8(%ebp),%eax
f010153c:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101540:	eb 07                	jmp    f0101549 <strchr+0x13>
		if (*s == c)
f0101542:	38 ca                	cmp    %cl,%dl
f0101544:	74 0f                	je     f0101555 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101546:	83 c0 01             	add    $0x1,%eax
f0101549:	0f b6 10             	movzbl (%eax),%edx
f010154c:	84 d2                	test   %dl,%dl
f010154e:	75 f2                	jne    f0101542 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0101550:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101555:	5d                   	pop    %ebp
f0101556:	c3                   	ret    

f0101557 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101557:	55                   	push   %ebp
f0101558:	89 e5                	mov    %esp,%ebp
f010155a:	8b 45 08             	mov    0x8(%ebp),%eax
f010155d:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101561:	eb 03                	jmp    f0101566 <strfind+0xf>
f0101563:	83 c0 01             	add    $0x1,%eax
f0101566:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0101569:	38 ca                	cmp    %cl,%dl
f010156b:	74 04                	je     f0101571 <strfind+0x1a>
f010156d:	84 d2                	test   %dl,%dl
f010156f:	75 f2                	jne    f0101563 <strfind+0xc>
			break;
	return (char *) s;
}
f0101571:	5d                   	pop    %ebp
f0101572:	c3                   	ret    

f0101573 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101573:	55                   	push   %ebp
f0101574:	89 e5                	mov    %esp,%ebp
f0101576:	57                   	push   %edi
f0101577:	56                   	push   %esi
f0101578:	53                   	push   %ebx
f0101579:	8b 7d 08             	mov    0x8(%ebp),%edi
f010157c:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010157f:	85 c9                	test   %ecx,%ecx
f0101581:	74 36                	je     f01015b9 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101583:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101589:	75 28                	jne    f01015b3 <memset+0x40>
f010158b:	f6 c1 03             	test   $0x3,%cl
f010158e:	75 23                	jne    f01015b3 <memset+0x40>
		c &= 0xFF;
f0101590:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101594:	89 d3                	mov    %edx,%ebx
f0101596:	c1 e3 08             	shl    $0x8,%ebx
f0101599:	89 d6                	mov    %edx,%esi
f010159b:	c1 e6 18             	shl    $0x18,%esi
f010159e:	89 d0                	mov    %edx,%eax
f01015a0:	c1 e0 10             	shl    $0x10,%eax
f01015a3:	09 f0                	or     %esi,%eax
f01015a5:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f01015a7:	89 d8                	mov    %ebx,%eax
f01015a9:	09 d0                	or     %edx,%eax
f01015ab:	c1 e9 02             	shr    $0x2,%ecx
f01015ae:	fc                   	cld    
f01015af:	f3 ab                	rep stos %eax,%es:(%edi)
f01015b1:	eb 06                	jmp    f01015b9 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01015b3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01015b6:	fc                   	cld    
f01015b7:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01015b9:	89 f8                	mov    %edi,%eax
f01015bb:	5b                   	pop    %ebx
f01015bc:	5e                   	pop    %esi
f01015bd:	5f                   	pop    %edi
f01015be:	5d                   	pop    %ebp
f01015bf:	c3                   	ret    

f01015c0 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01015c0:	55                   	push   %ebp
f01015c1:	89 e5                	mov    %esp,%ebp
f01015c3:	57                   	push   %edi
f01015c4:	56                   	push   %esi
f01015c5:	8b 45 08             	mov    0x8(%ebp),%eax
f01015c8:	8b 75 0c             	mov    0xc(%ebp),%esi
f01015cb:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01015ce:	39 c6                	cmp    %eax,%esi
f01015d0:	73 35                	jae    f0101607 <memmove+0x47>
f01015d2:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01015d5:	39 d0                	cmp    %edx,%eax
f01015d7:	73 2e                	jae    f0101607 <memmove+0x47>
		s += n;
		d += n;
f01015d9:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01015dc:	89 d6                	mov    %edx,%esi
f01015de:	09 fe                	or     %edi,%esi
f01015e0:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01015e6:	75 13                	jne    f01015fb <memmove+0x3b>
f01015e8:	f6 c1 03             	test   $0x3,%cl
f01015eb:	75 0e                	jne    f01015fb <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f01015ed:	83 ef 04             	sub    $0x4,%edi
f01015f0:	8d 72 fc             	lea    -0x4(%edx),%esi
f01015f3:	c1 e9 02             	shr    $0x2,%ecx
f01015f6:	fd                   	std    
f01015f7:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01015f9:	eb 09                	jmp    f0101604 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01015fb:	83 ef 01             	sub    $0x1,%edi
f01015fe:	8d 72 ff             	lea    -0x1(%edx),%esi
f0101601:	fd                   	std    
f0101602:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101604:	fc                   	cld    
f0101605:	eb 1d                	jmp    f0101624 <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101607:	89 f2                	mov    %esi,%edx
f0101609:	09 c2                	or     %eax,%edx
f010160b:	f6 c2 03             	test   $0x3,%dl
f010160e:	75 0f                	jne    f010161f <memmove+0x5f>
f0101610:	f6 c1 03             	test   $0x3,%cl
f0101613:	75 0a                	jne    f010161f <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f0101615:	c1 e9 02             	shr    $0x2,%ecx
f0101618:	89 c7                	mov    %eax,%edi
f010161a:	fc                   	cld    
f010161b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010161d:	eb 05                	jmp    f0101624 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010161f:	89 c7                	mov    %eax,%edi
f0101621:	fc                   	cld    
f0101622:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101624:	5e                   	pop    %esi
f0101625:	5f                   	pop    %edi
f0101626:	5d                   	pop    %ebp
f0101627:	c3                   	ret    

f0101628 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0101628:	55                   	push   %ebp
f0101629:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f010162b:	ff 75 10             	pushl  0x10(%ebp)
f010162e:	ff 75 0c             	pushl  0xc(%ebp)
f0101631:	ff 75 08             	pushl  0x8(%ebp)
f0101634:	e8 87 ff ff ff       	call   f01015c0 <memmove>
}
f0101639:	c9                   	leave  
f010163a:	c3                   	ret    

f010163b <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010163b:	55                   	push   %ebp
f010163c:	89 e5                	mov    %esp,%ebp
f010163e:	56                   	push   %esi
f010163f:	53                   	push   %ebx
f0101640:	8b 45 08             	mov    0x8(%ebp),%eax
f0101643:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101646:	89 c6                	mov    %eax,%esi
f0101648:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010164b:	eb 1a                	jmp    f0101667 <memcmp+0x2c>
		if (*s1 != *s2)
f010164d:	0f b6 08             	movzbl (%eax),%ecx
f0101650:	0f b6 1a             	movzbl (%edx),%ebx
f0101653:	38 d9                	cmp    %bl,%cl
f0101655:	74 0a                	je     f0101661 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0101657:	0f b6 c1             	movzbl %cl,%eax
f010165a:	0f b6 db             	movzbl %bl,%ebx
f010165d:	29 d8                	sub    %ebx,%eax
f010165f:	eb 0f                	jmp    f0101670 <memcmp+0x35>
		s1++, s2++;
f0101661:	83 c0 01             	add    $0x1,%eax
f0101664:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101667:	39 f0                	cmp    %esi,%eax
f0101669:	75 e2                	jne    f010164d <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010166b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101670:	5b                   	pop    %ebx
f0101671:	5e                   	pop    %esi
f0101672:	5d                   	pop    %ebp
f0101673:	c3                   	ret    

f0101674 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101674:	55                   	push   %ebp
f0101675:	89 e5                	mov    %esp,%ebp
f0101677:	53                   	push   %ebx
f0101678:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f010167b:	89 c1                	mov    %eax,%ecx
f010167d:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f0101680:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101684:	eb 0a                	jmp    f0101690 <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101686:	0f b6 10             	movzbl (%eax),%edx
f0101689:	39 da                	cmp    %ebx,%edx
f010168b:	74 07                	je     f0101694 <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010168d:	83 c0 01             	add    $0x1,%eax
f0101690:	39 c8                	cmp    %ecx,%eax
f0101692:	72 f2                	jb     f0101686 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101694:	5b                   	pop    %ebx
f0101695:	5d                   	pop    %ebp
f0101696:	c3                   	ret    

f0101697 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101697:	55                   	push   %ebp
f0101698:	89 e5                	mov    %esp,%ebp
f010169a:	57                   	push   %edi
f010169b:	56                   	push   %esi
f010169c:	53                   	push   %ebx
f010169d:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01016a0:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01016a3:	eb 03                	jmp    f01016a8 <strtol+0x11>
		s++;
f01016a5:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01016a8:	0f b6 01             	movzbl (%ecx),%eax
f01016ab:	3c 20                	cmp    $0x20,%al
f01016ad:	74 f6                	je     f01016a5 <strtol+0xe>
f01016af:	3c 09                	cmp    $0x9,%al
f01016b1:	74 f2                	je     f01016a5 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01016b3:	3c 2b                	cmp    $0x2b,%al
f01016b5:	75 0a                	jne    f01016c1 <strtol+0x2a>
		s++;
f01016b7:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01016ba:	bf 00 00 00 00       	mov    $0x0,%edi
f01016bf:	eb 11                	jmp    f01016d2 <strtol+0x3b>
f01016c1:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01016c6:	3c 2d                	cmp    $0x2d,%al
f01016c8:	75 08                	jne    f01016d2 <strtol+0x3b>
		s++, neg = 1;
f01016ca:	83 c1 01             	add    $0x1,%ecx
f01016cd:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01016d2:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01016d8:	75 15                	jne    f01016ef <strtol+0x58>
f01016da:	80 39 30             	cmpb   $0x30,(%ecx)
f01016dd:	75 10                	jne    f01016ef <strtol+0x58>
f01016df:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01016e3:	75 7c                	jne    f0101761 <strtol+0xca>
		s += 2, base = 16;
f01016e5:	83 c1 02             	add    $0x2,%ecx
f01016e8:	bb 10 00 00 00       	mov    $0x10,%ebx
f01016ed:	eb 16                	jmp    f0101705 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f01016ef:	85 db                	test   %ebx,%ebx
f01016f1:	75 12                	jne    f0101705 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01016f3:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01016f8:	80 39 30             	cmpb   $0x30,(%ecx)
f01016fb:	75 08                	jne    f0101705 <strtol+0x6e>
		s++, base = 8;
f01016fd:	83 c1 01             	add    $0x1,%ecx
f0101700:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0101705:	b8 00 00 00 00       	mov    $0x0,%eax
f010170a:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f010170d:	0f b6 11             	movzbl (%ecx),%edx
f0101710:	8d 72 d0             	lea    -0x30(%edx),%esi
f0101713:	89 f3                	mov    %esi,%ebx
f0101715:	80 fb 09             	cmp    $0x9,%bl
f0101718:	77 08                	ja     f0101722 <strtol+0x8b>
			dig = *s - '0';
f010171a:	0f be d2             	movsbl %dl,%edx
f010171d:	83 ea 30             	sub    $0x30,%edx
f0101720:	eb 22                	jmp    f0101744 <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f0101722:	8d 72 9f             	lea    -0x61(%edx),%esi
f0101725:	89 f3                	mov    %esi,%ebx
f0101727:	80 fb 19             	cmp    $0x19,%bl
f010172a:	77 08                	ja     f0101734 <strtol+0x9d>
			dig = *s - 'a' + 10;
f010172c:	0f be d2             	movsbl %dl,%edx
f010172f:	83 ea 57             	sub    $0x57,%edx
f0101732:	eb 10                	jmp    f0101744 <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f0101734:	8d 72 bf             	lea    -0x41(%edx),%esi
f0101737:	89 f3                	mov    %esi,%ebx
f0101739:	80 fb 19             	cmp    $0x19,%bl
f010173c:	77 16                	ja     f0101754 <strtol+0xbd>
			dig = *s - 'A' + 10;
f010173e:	0f be d2             	movsbl %dl,%edx
f0101741:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0101744:	3b 55 10             	cmp    0x10(%ebp),%edx
f0101747:	7d 0b                	jge    f0101754 <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f0101749:	83 c1 01             	add    $0x1,%ecx
f010174c:	0f af 45 10          	imul   0x10(%ebp),%eax
f0101750:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0101752:	eb b9                	jmp    f010170d <strtol+0x76>

	if (endptr)
f0101754:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101758:	74 0d                	je     f0101767 <strtol+0xd0>
		*endptr = (char *) s;
f010175a:	8b 75 0c             	mov    0xc(%ebp),%esi
f010175d:	89 0e                	mov    %ecx,(%esi)
f010175f:	eb 06                	jmp    f0101767 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101761:	85 db                	test   %ebx,%ebx
f0101763:	74 98                	je     f01016fd <strtol+0x66>
f0101765:	eb 9e                	jmp    f0101705 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f0101767:	89 c2                	mov    %eax,%edx
f0101769:	f7 da                	neg    %edx
f010176b:	85 ff                	test   %edi,%edi
f010176d:	0f 45 c2             	cmovne %edx,%eax
}
f0101770:	5b                   	pop    %ebx
f0101771:	5e                   	pop    %esi
f0101772:	5f                   	pop    %edi
f0101773:	5d                   	pop    %ebp
f0101774:	c3                   	ret    
f0101775:	66 90                	xchg   %ax,%ax
f0101777:	66 90                	xchg   %ax,%ax
f0101779:	66 90                	xchg   %ax,%ax
f010177b:	66 90                	xchg   %ax,%ax
f010177d:	66 90                	xchg   %ax,%ax
f010177f:	90                   	nop

f0101780 <__udivdi3>:
f0101780:	55                   	push   %ebp
f0101781:	57                   	push   %edi
f0101782:	56                   	push   %esi
f0101783:	53                   	push   %ebx
f0101784:	83 ec 1c             	sub    $0x1c,%esp
f0101787:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010178b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010178f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0101793:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101797:	85 f6                	test   %esi,%esi
f0101799:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010179d:	89 ca                	mov    %ecx,%edx
f010179f:	89 f8                	mov    %edi,%eax
f01017a1:	75 3d                	jne    f01017e0 <__udivdi3+0x60>
f01017a3:	39 cf                	cmp    %ecx,%edi
f01017a5:	0f 87 c5 00 00 00    	ja     f0101870 <__udivdi3+0xf0>
f01017ab:	85 ff                	test   %edi,%edi
f01017ad:	89 fd                	mov    %edi,%ebp
f01017af:	75 0b                	jne    f01017bc <__udivdi3+0x3c>
f01017b1:	b8 01 00 00 00       	mov    $0x1,%eax
f01017b6:	31 d2                	xor    %edx,%edx
f01017b8:	f7 f7                	div    %edi
f01017ba:	89 c5                	mov    %eax,%ebp
f01017bc:	89 c8                	mov    %ecx,%eax
f01017be:	31 d2                	xor    %edx,%edx
f01017c0:	f7 f5                	div    %ebp
f01017c2:	89 c1                	mov    %eax,%ecx
f01017c4:	89 d8                	mov    %ebx,%eax
f01017c6:	89 cf                	mov    %ecx,%edi
f01017c8:	f7 f5                	div    %ebp
f01017ca:	89 c3                	mov    %eax,%ebx
f01017cc:	89 d8                	mov    %ebx,%eax
f01017ce:	89 fa                	mov    %edi,%edx
f01017d0:	83 c4 1c             	add    $0x1c,%esp
f01017d3:	5b                   	pop    %ebx
f01017d4:	5e                   	pop    %esi
f01017d5:	5f                   	pop    %edi
f01017d6:	5d                   	pop    %ebp
f01017d7:	c3                   	ret    
f01017d8:	90                   	nop
f01017d9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01017e0:	39 ce                	cmp    %ecx,%esi
f01017e2:	77 74                	ja     f0101858 <__udivdi3+0xd8>
f01017e4:	0f bd fe             	bsr    %esi,%edi
f01017e7:	83 f7 1f             	xor    $0x1f,%edi
f01017ea:	0f 84 98 00 00 00    	je     f0101888 <__udivdi3+0x108>
f01017f0:	bb 20 00 00 00       	mov    $0x20,%ebx
f01017f5:	89 f9                	mov    %edi,%ecx
f01017f7:	89 c5                	mov    %eax,%ebp
f01017f9:	29 fb                	sub    %edi,%ebx
f01017fb:	d3 e6                	shl    %cl,%esi
f01017fd:	89 d9                	mov    %ebx,%ecx
f01017ff:	d3 ed                	shr    %cl,%ebp
f0101801:	89 f9                	mov    %edi,%ecx
f0101803:	d3 e0                	shl    %cl,%eax
f0101805:	09 ee                	or     %ebp,%esi
f0101807:	89 d9                	mov    %ebx,%ecx
f0101809:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010180d:	89 d5                	mov    %edx,%ebp
f010180f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101813:	d3 ed                	shr    %cl,%ebp
f0101815:	89 f9                	mov    %edi,%ecx
f0101817:	d3 e2                	shl    %cl,%edx
f0101819:	89 d9                	mov    %ebx,%ecx
f010181b:	d3 e8                	shr    %cl,%eax
f010181d:	09 c2                	or     %eax,%edx
f010181f:	89 d0                	mov    %edx,%eax
f0101821:	89 ea                	mov    %ebp,%edx
f0101823:	f7 f6                	div    %esi
f0101825:	89 d5                	mov    %edx,%ebp
f0101827:	89 c3                	mov    %eax,%ebx
f0101829:	f7 64 24 0c          	mull   0xc(%esp)
f010182d:	39 d5                	cmp    %edx,%ebp
f010182f:	72 10                	jb     f0101841 <__udivdi3+0xc1>
f0101831:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101835:	89 f9                	mov    %edi,%ecx
f0101837:	d3 e6                	shl    %cl,%esi
f0101839:	39 c6                	cmp    %eax,%esi
f010183b:	73 07                	jae    f0101844 <__udivdi3+0xc4>
f010183d:	39 d5                	cmp    %edx,%ebp
f010183f:	75 03                	jne    f0101844 <__udivdi3+0xc4>
f0101841:	83 eb 01             	sub    $0x1,%ebx
f0101844:	31 ff                	xor    %edi,%edi
f0101846:	89 d8                	mov    %ebx,%eax
f0101848:	89 fa                	mov    %edi,%edx
f010184a:	83 c4 1c             	add    $0x1c,%esp
f010184d:	5b                   	pop    %ebx
f010184e:	5e                   	pop    %esi
f010184f:	5f                   	pop    %edi
f0101850:	5d                   	pop    %ebp
f0101851:	c3                   	ret    
f0101852:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101858:	31 ff                	xor    %edi,%edi
f010185a:	31 db                	xor    %ebx,%ebx
f010185c:	89 d8                	mov    %ebx,%eax
f010185e:	89 fa                	mov    %edi,%edx
f0101860:	83 c4 1c             	add    $0x1c,%esp
f0101863:	5b                   	pop    %ebx
f0101864:	5e                   	pop    %esi
f0101865:	5f                   	pop    %edi
f0101866:	5d                   	pop    %ebp
f0101867:	c3                   	ret    
f0101868:	90                   	nop
f0101869:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101870:	89 d8                	mov    %ebx,%eax
f0101872:	f7 f7                	div    %edi
f0101874:	31 ff                	xor    %edi,%edi
f0101876:	89 c3                	mov    %eax,%ebx
f0101878:	89 d8                	mov    %ebx,%eax
f010187a:	89 fa                	mov    %edi,%edx
f010187c:	83 c4 1c             	add    $0x1c,%esp
f010187f:	5b                   	pop    %ebx
f0101880:	5e                   	pop    %esi
f0101881:	5f                   	pop    %edi
f0101882:	5d                   	pop    %ebp
f0101883:	c3                   	ret    
f0101884:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101888:	39 ce                	cmp    %ecx,%esi
f010188a:	72 0c                	jb     f0101898 <__udivdi3+0x118>
f010188c:	31 db                	xor    %ebx,%ebx
f010188e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0101892:	0f 87 34 ff ff ff    	ja     f01017cc <__udivdi3+0x4c>
f0101898:	bb 01 00 00 00       	mov    $0x1,%ebx
f010189d:	e9 2a ff ff ff       	jmp    f01017cc <__udivdi3+0x4c>
f01018a2:	66 90                	xchg   %ax,%ax
f01018a4:	66 90                	xchg   %ax,%ax
f01018a6:	66 90                	xchg   %ax,%ax
f01018a8:	66 90                	xchg   %ax,%ax
f01018aa:	66 90                	xchg   %ax,%ax
f01018ac:	66 90                	xchg   %ax,%ax
f01018ae:	66 90                	xchg   %ax,%ax

f01018b0 <__umoddi3>:
f01018b0:	55                   	push   %ebp
f01018b1:	57                   	push   %edi
f01018b2:	56                   	push   %esi
f01018b3:	53                   	push   %ebx
f01018b4:	83 ec 1c             	sub    $0x1c,%esp
f01018b7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01018bb:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01018bf:	8b 74 24 34          	mov    0x34(%esp),%esi
f01018c3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01018c7:	85 d2                	test   %edx,%edx
f01018c9:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01018cd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01018d1:	89 f3                	mov    %esi,%ebx
f01018d3:	89 3c 24             	mov    %edi,(%esp)
f01018d6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01018da:	75 1c                	jne    f01018f8 <__umoddi3+0x48>
f01018dc:	39 f7                	cmp    %esi,%edi
f01018de:	76 50                	jbe    f0101930 <__umoddi3+0x80>
f01018e0:	89 c8                	mov    %ecx,%eax
f01018e2:	89 f2                	mov    %esi,%edx
f01018e4:	f7 f7                	div    %edi
f01018e6:	89 d0                	mov    %edx,%eax
f01018e8:	31 d2                	xor    %edx,%edx
f01018ea:	83 c4 1c             	add    $0x1c,%esp
f01018ed:	5b                   	pop    %ebx
f01018ee:	5e                   	pop    %esi
f01018ef:	5f                   	pop    %edi
f01018f0:	5d                   	pop    %ebp
f01018f1:	c3                   	ret    
f01018f2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01018f8:	39 f2                	cmp    %esi,%edx
f01018fa:	89 d0                	mov    %edx,%eax
f01018fc:	77 52                	ja     f0101950 <__umoddi3+0xa0>
f01018fe:	0f bd ea             	bsr    %edx,%ebp
f0101901:	83 f5 1f             	xor    $0x1f,%ebp
f0101904:	75 5a                	jne    f0101960 <__umoddi3+0xb0>
f0101906:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010190a:	0f 82 e0 00 00 00    	jb     f01019f0 <__umoddi3+0x140>
f0101910:	39 0c 24             	cmp    %ecx,(%esp)
f0101913:	0f 86 d7 00 00 00    	jbe    f01019f0 <__umoddi3+0x140>
f0101919:	8b 44 24 08          	mov    0x8(%esp),%eax
f010191d:	8b 54 24 04          	mov    0x4(%esp),%edx
f0101921:	83 c4 1c             	add    $0x1c,%esp
f0101924:	5b                   	pop    %ebx
f0101925:	5e                   	pop    %esi
f0101926:	5f                   	pop    %edi
f0101927:	5d                   	pop    %ebp
f0101928:	c3                   	ret    
f0101929:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101930:	85 ff                	test   %edi,%edi
f0101932:	89 fd                	mov    %edi,%ebp
f0101934:	75 0b                	jne    f0101941 <__umoddi3+0x91>
f0101936:	b8 01 00 00 00       	mov    $0x1,%eax
f010193b:	31 d2                	xor    %edx,%edx
f010193d:	f7 f7                	div    %edi
f010193f:	89 c5                	mov    %eax,%ebp
f0101941:	89 f0                	mov    %esi,%eax
f0101943:	31 d2                	xor    %edx,%edx
f0101945:	f7 f5                	div    %ebp
f0101947:	89 c8                	mov    %ecx,%eax
f0101949:	f7 f5                	div    %ebp
f010194b:	89 d0                	mov    %edx,%eax
f010194d:	eb 99                	jmp    f01018e8 <__umoddi3+0x38>
f010194f:	90                   	nop
f0101950:	89 c8                	mov    %ecx,%eax
f0101952:	89 f2                	mov    %esi,%edx
f0101954:	83 c4 1c             	add    $0x1c,%esp
f0101957:	5b                   	pop    %ebx
f0101958:	5e                   	pop    %esi
f0101959:	5f                   	pop    %edi
f010195a:	5d                   	pop    %ebp
f010195b:	c3                   	ret    
f010195c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101960:	8b 34 24             	mov    (%esp),%esi
f0101963:	bf 20 00 00 00       	mov    $0x20,%edi
f0101968:	89 e9                	mov    %ebp,%ecx
f010196a:	29 ef                	sub    %ebp,%edi
f010196c:	d3 e0                	shl    %cl,%eax
f010196e:	89 f9                	mov    %edi,%ecx
f0101970:	89 f2                	mov    %esi,%edx
f0101972:	d3 ea                	shr    %cl,%edx
f0101974:	89 e9                	mov    %ebp,%ecx
f0101976:	09 c2                	or     %eax,%edx
f0101978:	89 d8                	mov    %ebx,%eax
f010197a:	89 14 24             	mov    %edx,(%esp)
f010197d:	89 f2                	mov    %esi,%edx
f010197f:	d3 e2                	shl    %cl,%edx
f0101981:	89 f9                	mov    %edi,%ecx
f0101983:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101987:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010198b:	d3 e8                	shr    %cl,%eax
f010198d:	89 e9                	mov    %ebp,%ecx
f010198f:	89 c6                	mov    %eax,%esi
f0101991:	d3 e3                	shl    %cl,%ebx
f0101993:	89 f9                	mov    %edi,%ecx
f0101995:	89 d0                	mov    %edx,%eax
f0101997:	d3 e8                	shr    %cl,%eax
f0101999:	89 e9                	mov    %ebp,%ecx
f010199b:	09 d8                	or     %ebx,%eax
f010199d:	89 d3                	mov    %edx,%ebx
f010199f:	89 f2                	mov    %esi,%edx
f01019a1:	f7 34 24             	divl   (%esp)
f01019a4:	89 d6                	mov    %edx,%esi
f01019a6:	d3 e3                	shl    %cl,%ebx
f01019a8:	f7 64 24 04          	mull   0x4(%esp)
f01019ac:	39 d6                	cmp    %edx,%esi
f01019ae:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01019b2:	89 d1                	mov    %edx,%ecx
f01019b4:	89 c3                	mov    %eax,%ebx
f01019b6:	72 08                	jb     f01019c0 <__umoddi3+0x110>
f01019b8:	75 11                	jne    f01019cb <__umoddi3+0x11b>
f01019ba:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01019be:	73 0b                	jae    f01019cb <__umoddi3+0x11b>
f01019c0:	2b 44 24 04          	sub    0x4(%esp),%eax
f01019c4:	1b 14 24             	sbb    (%esp),%edx
f01019c7:	89 d1                	mov    %edx,%ecx
f01019c9:	89 c3                	mov    %eax,%ebx
f01019cb:	8b 54 24 08          	mov    0x8(%esp),%edx
f01019cf:	29 da                	sub    %ebx,%edx
f01019d1:	19 ce                	sbb    %ecx,%esi
f01019d3:	89 f9                	mov    %edi,%ecx
f01019d5:	89 f0                	mov    %esi,%eax
f01019d7:	d3 e0                	shl    %cl,%eax
f01019d9:	89 e9                	mov    %ebp,%ecx
f01019db:	d3 ea                	shr    %cl,%edx
f01019dd:	89 e9                	mov    %ebp,%ecx
f01019df:	d3 ee                	shr    %cl,%esi
f01019e1:	09 d0                	or     %edx,%eax
f01019e3:	89 f2                	mov    %esi,%edx
f01019e5:	83 c4 1c             	add    $0x1c,%esp
f01019e8:	5b                   	pop    %ebx
f01019e9:	5e                   	pop    %esi
f01019ea:	5f                   	pop    %edi
f01019eb:	5d                   	pop    %ebp
f01019ec:	c3                   	ret    
f01019ed:	8d 76 00             	lea    0x0(%esi),%esi
f01019f0:	29 f9                	sub    %edi,%ecx
f01019f2:	19 d6                	sbb    %edx,%esi
f01019f4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01019f8:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01019fc:	e9 18 ff ff ff       	jmp    f0101919 <__umoddi3+0x69>
