		include "ez80.asm"
		include "agon_z80_helpers.asm"
		mos_header start

		include "mem.asm"
		include "shape.asm"
		include "board.asm"

start:
		lil : push iy
		puts "Running tests\r\n"

		call test_shape
		jp c, .failed

		call test_board
		jp c, .failed

		col_green
		puts "\r\n\r\nPassed!\r\n"
		col_white
		jr .exit
	.failed:
		col_red
		puts "\r\n\r\nFailed.\r\n"
		col_white
	.exit
		ld hl,0
		lil : pop iy
		ret.lis

test_board:
		puts "\r\ntest_board "

		; does a new board look right?
		ld hl,.b
		call board_new
		ld hl,.b
		ld de,.c
		ld bc,{sizeof}board_t
		call mem_cmp
		ret c
		putc '.'

		; test board bounds
		ld b,0 : ld c,0 : call board_bounds
		jp c,.fail
		ld b,0 : ld c,board_width-1 : call board_bounds
		jp c,.fail
		ld b,0 : ld c,board_width : call board_bounds
		jp nc,.fail
		ld b,board_height : ld c,0 : call board_bounds
		jp nc,.fail

		; add a shape to the board (ie stick it there)
		ld de,.s : ld hl,(shape_shapes+4)
		call shape_copy
		ld hl,.b : ld de,.s : ld c,0 : ld b,0
		call board_add_shape

		; does that look right?
		ld c,0 : ld b,0 : ld hl,.b : call board_get : cp ' '
		jp nz,.fail
		ld c,1 : ld b,0 : ld hl,.b : call board_get : cp '#'
		jp nz,.fail
		ld c,2 : ld b,0 : ld hl,.b : call board_get : cp ' '
		jp nz,.fail

		; now draw somewhere offset
		ld hl,.b : ld de,.s : ld c,board_width-2 : ld b,board_height-2
		call board_add_shape
		ld c,board_width-1 : ld b,board_height-2 : ld hl,.b : call board_get : cp '#'
		jp nz,.fail

		; draw the board to screen
		putc 13 : putc 10
		ld hl,.b
		ld b,board_height
	.loopy:
		push bc
		ld b,board_width
		.loopx
			ld a,(hl)
			inc hl
			rst.lis 0x10
			djnz .loopx
		putc 13 : putc 10
		pop bc
		djnz .loopy
		puts "----------\r\n"

		; test collisions
		ld hl,.b : ld de,.s : ld c,0 : ld b,0
		call board_shape_collide
		jr nc,.fail
		ld hl,.b : ld de,.s : ld c,1 : ld b,0
		call board_shape_collide
		jr nc,.fail
		ld hl,.b : ld de,.s : ld c,2 : ld b,0
		call board_shape_collide
		jr c,.fail
		ld hl,.b : ld de,.s : ld c,1 : ld b,1
		call board_shape_collide
		jr nc,.fail
		ld hl,.b : ld de,.s : ld c,1 : ld b,3
		call board_shape_collide
		jr c,.fail
		
		xor a
		ret
	.fail:
		xor a
		ccf
		ret
	.s  ds {sizeof}shape_t
	.b:	ds {sizeof}board_t
	.c: db "          "
		db "          "
		db "          "
		db "          "
		db "          "
		db "          "
		db "          "
		db "          "
		db "          "
		db "          "
		db "          "
		db "          "
		db "          "
		db "          "
		db "          "
		db "          "
		db "          "
		db "          "
		db "          "
		db "          "
		db "          "
		db "          "
		db "          "
		db "          "

test_shape:
		puts "\r\ntest_shape "
		ld de,.s : ld hl,(shape_shapes+4)
		call shape_copy

		; did shape_copy work?
		ld de,.s : ld hl,(shape_shapes+4) : ld bc,{sizeof}shape_t
		call mem_cmp
		ret c
		putc '.'

		; test 3x3 shape rotation
		ld hl,.s : ld de,.t
		call shape_rot90
		ld de,.t : ld hl,.u : ld bc,{sizeof}shape_t
		call mem_cmp
		ret c
		putc '.'

		; test 4x4 shape rotation
		ld de,.s : ld hl,(shape_shapes+2)
		call shape_copy
		ld hl,.s : ld de,.t
		call shape_rot90
		ld de,.t : ld hl,.v : ld bc,{sizeof}shape_t
		call mem_cmp
		ret c
		putc '.'
		
		xor a
		ret
	.s: ds {sizeof}shape_t
	.t: ds {sizeof}shape_t
	.u: db 1
		db "    "
		db "### "
		db "#   "
		db "    "
	.v: db 0
		db "    "
		db "####"
		db "    "
		db "    "
