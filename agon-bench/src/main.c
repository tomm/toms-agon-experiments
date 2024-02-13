#include <stdio.h>
#include <stdint.h>
#include <mos_api.h>
#include <agon/vdp_vdu.h>

typedef void (*vblank_handler_t)();

volatile int32_t count = 0;

// vblank.asm
extern void vblank_handler();
extern void fast_vdu(uint8_t *data, int len);

// called from vblank_handler
void on_vblank()
{
	count++;
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
	printf("Agon Bench 1.03\n");
	printf("===============\n\n");
	vblank_handler_t old_handler = mos_setintvector(0x32, &vblank_handler);

	{
		for (count=-1; count; ) {} // clear counter and let current frame finish
		int iters = 0;
		while (count < 60) {
			iters++;
		}
		printf("%d C loop iters per second (%.3f MHz ez80 equivalent)\n", iters, AGON_CLK * (float)iters / 292668.0f);
	}
	{
		for (count=-1; count; ) {} // clear counter and let current frame finish
		int iters = 0;
		while (count < 60) {
			asm("	mlt bc\n"
				:::"bc");
			iters++;
		}
		printf("%d C loop mlt iters per second (%.3f MHz ez80 equivalent)\n", iters, AGON_CLK * (float)iters / 236407.0f);
	}
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
		printf("%d MOS calls (%.2f x Agon Light)\n", iters, (float)iters / 77478.0f);
	}
	{
		for (count=-1; count; ) {} // clear counter and let current frame finish
		// load 64KiB of junk into the vdp
		vdp_load_bitmap(128, 128, (uint32_t*)0x40000);
		float elapsed = (float)count / 60.0f;
		printf("%.2f seconds to upload 64KiB to VDP (%.2f KiB/sec, %.2f KBit/sec)\n", elapsed, 64.0f / elapsed, 8.0f*64.0f / elapsed);
	}
	{
		for (count=-1; count; ) {} // clear counter and let current frame finish
		// load 64KiB of junk into the vdp
		putch(23); putch(27); putch(1);
		putch(128); putch(0);
		putch(128); putch(0);
		fast_vdu((uint8_t*)0x40000, 65536);
		float elapsed = (float)count / 60.0f;
		printf("%.2f seconds to upload 64KiB to VDP with fast_vdu() (%.2f KiB/sec, %.2f KBit/sec)\n", elapsed, 64.0f / elapsed, 8.0f*64.0f / elapsed);
	}
	
	
	mos_setintvector(0x32, old_handler);

	return 0;
}
