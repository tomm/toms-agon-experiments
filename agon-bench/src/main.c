#include <stdio.h>
#include <stdint.h>
#include <mos_api.h>
#include <agon/vdp_vdu.h>

typedef void (*vblank_handler_t)();

volatile int32_t count = 0;

// vblank.asm
extern void vblank_handler();
extern void fast_vdu(uint8_t *data, int len);
// misc.asm
extern uint8_t getsysvar_gp(void);
extern void delay_1sec(void);

// called from vblank_handler
void on_vblank()
{
	count++;
}

static void vdu_gp(uint8_t msg)
{
	putch(23); // Send a general poll packet
	putch(0);
	putch(0x80);
	putch(msg);
}

#define AGON_CLK 18.432f

#define PUSH_ALL "\tpush af\n" \
	         "\tpush bc\n" \
		 "\tpush de\n" \
		 "\tpush hl\n" \
		 "\tpush ix\n" \
		 "\tpush iy\n"
#define POP_ALL "\tpop iy\n" \
	        "\tpop ix\n" \
	        "\tpop hl\n" \
	        "\tpop de\n" \
	        "\tpop bc\n" \
	        "\tpop af\n"

int main() {
	// mode 0: make sure we have a 60hz mode for timing
	putch(22); putch(0);

	printf("Agon Bench 1.04\n");
	printf("===============\n\n");
	vblank_handler_t old_handler = mos_setintvector(0x32, &vblank_handler);

	{
		for (count=-1; count; ) {} // clear counter and let current frame finish
		delay_1sec(); // should really be 1 second if 18.432MHz cpu
		delay_1sec();
		printf("ez80 frequency:                      %.3f MHz\n", 2 * AGON_CLK * 60.0f / count);
	}
	printf("\n");

	{
		for (count=-1; count; ) {} // clear counter and let current frame finish
		int iters = 0;
		while (count < 60) {
			asm(PUSH_ALL
			"	ld a,0x8\n"
			"	rst.lil 0x8\n"
				POP_ALL
			);
			iters++;
		}
		printf("Syscalls per second                  %d MOS calls (%.2f x Agon Light)\n", iters, (float)iters / 77478.0f);
	}
	printf("\n");

	{
		for (count=-1; count; ) {} // clear counter and let current frame finish
		for (int j=0; j<10; j++) {
			uint8_t i=0;
			while (i<255) {
				vdu_gp(i);
				while (getsysvar_gp() != i) {}
				i++;
			}
		}
		float elapsed = (float)count / 60.0f;
		printf("ez80 <-> VDP round-trips per second  %.0f\n", 2550.0f / elapsed);
		printf("ez80 <-> VDP round-trip latency      %.2f ms\n", 1000.0f * elapsed / 2550.0f);
	}


	{
		for (count=-1; count; ) {} // clear counter and let current frame finish
		// load 64KiB of junk into the vdp
		vdp_load_bitmap(128, 128, (uint32_t*)0x40000);
		float elapsed = (float)count / 60.0f;
		printf("ez80 to VDP                          %.2f KiB/sec (%.2f KBit/sec)\n", 64.0f / elapsed, 8.0f*64.0f / elapsed);
	}

	{
		for (count=-1; count; ) {} // clear counter and let current frame finish
		// load 64KiB of junk into the vdp
		putch(23); putch(27); putch(1);
		putch(128); putch(0);
		putch(128); putch(0);
		fast_vdu((uint8_t*)0x40000, 65536);
		float elapsed = (float)count / 60.0f;
		printf("ez80 to VDP (fast_vdu)               %.2f KiB/sec (%.2f KBit/sec)\n", 64.0f / elapsed, 8.0f*64.0f / elapsed);
	}
	printf("\n");
	
	mos_del("agon-bench.tmp");
	{
		for (count=-1; count; ) {} // clear counter and let current frame finish
		mos_save("agon-bench.tmp", 0xa0000, 65536);
		float elapsed = (float)count / 60.0f;
		printf("SDCard write                         %.2f KiB/sec\n", 64.0f / elapsed);
	}
	{
		for (count=-1; count; ) {} // clear counter and let current frame finish
		mos_load("agon-bench.tmp", 0xa0000, 65536);
		float elapsed = (float)count / 60.0f;
		printf("SDCard read                          %.2f KiB/sec\n", 64.0f / elapsed);
	}
	mos_del("agon-bench.tmp");
	
	mos_setintvector(0x32, old_handler);

	return 0;
}
