#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <mos_api.h>
#include <agon/vdp_vdu.h>

typedef void (*vblank_handler_t)();

/* Pointer to sysvar_time. Gets +=2 at a 60Hz freq */
int24_t * volatile pCount;

// misc.asm
extern uint8_t getsysvar_gp(void);
extern void delay_1sec(void);

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

#define WAIT_VBLANK() \
	for (setCount(-2); getCount(); ) {}

inline void setCount(int24_t c) {
	*pCount = (c<<1);
}

inline int24_t getCount(void) {
	return (*pCount)>>1;
}

int main() {
	// mode 0: make sure we have a 60hz mode for timing
	putch(22); putch(0);

	/* Get pointer to sysvar_time */
	asm volatile(
	"	push af\n"
	"	push ix\n"
	"	ld a,8  /* mos_sysvar call */ \n"
	"	rst.lil 8\n"
	"	ld (_pCount),ix\n"
	"	pop ix\n"
	"	pop af\n"
	);

	printf("Agon Bench 1.05\n");
	printf("===============\n\n");

	{
		WAIT_VBLANK();
		delay_1sec(); // should really be 1 second if 18.432MHz cpu
		delay_1sec();
		printf("ez80 frequency:                      %.3f MHz\n", 2 * AGON_CLK * 60.0f / getCount());
	}
	printf("\n");

	{
		WAIT_VBLANK();
		int iters = 0;
		while (getCount() < 60) {
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
		WAIT_VBLANK();
		for (int j=0; j<10; j++) {
			uint8_t i=0;
			while (i<255) {
				vdu_gp(i);
				while (getsysvar_gp() != i) {}
				i++;
			}
		}
		float elapsed = (float)getCount() / 60.0f;
		printf("ez80 <-> VDP round-trips per second  %.0f\n", 2550.0f / elapsed);
		printf("ez80 <-> VDP round-trip latency      %.2f ms\n", 1000.0f * elapsed / 2550.0f);
	}


	{
		WAIT_VBLANK();
		// load 64KiB of junk into the vdp
		vdp_load_bitmap(128, 128, (uint32_t*)0x40000);
		float elapsed = (float)getCount() / 60.0f;
		printf("ez80 to VDP                          %.2f KiB/sec (%.2f KBit/sec)\n", 64.0f / elapsed, 8.0f*64.0f / elapsed);
	}

	printf("\n");

	char *buf = malloc(65536);
	
	mos_del("agon-bench.tmp");
	{
		WAIT_VBLANK();
		mos_save("agon-bench.tmp", buf, 65536);
		float elapsed = (float)getCount() / 60.0f;
		printf("SDCard write                         %.2f KiB/sec\n", 64.0f / elapsed);
	}
	{
		WAIT_VBLANK();
		mos_load("agon-bench.tmp", buf, 65536);
		float elapsed = (float)getCount() / 60.0f;
		printf("SDCard read                          %.2f KiB/sec\n", 64.0f / elapsed);
	}
	free(buf);
	mos_del("agon-bench.tmp");
	
	return 0;
}
