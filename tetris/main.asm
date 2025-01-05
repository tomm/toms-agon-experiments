		.cpu ez80
		.assume adl=0	

		org 0
header:
		jp start
		align $40
		db "MOS"
		db 0 ; version
		db 0 ; ADL disabled

		; platform-specific agon stuff using ez80 instructions (in Z80 mode)
		include "agon_z80_helpers.asm"
		include "platform_agon.asm"
		include "splash.asm"

start:
		push.lil ix
		push.lil iy
		call main
		ld hl,0
		pop.lil iy
		pop.lil ix
		ret.lis

		; game core, in Z80-only
		.cpu z80
		include "mem.asm"
		include "consts.asm"
		include "shape.asm"
		include "board.asm"
		include "variables.asm"
		include "game.asm"

main:
		call plt_init
		call do_splash
		call plt_waitkey
		call plt_gameinit

		call start_game

		ret
