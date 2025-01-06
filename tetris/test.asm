		.assume adl=0

		org 0
header:
		jp start
		align $40
		db "MOS"
		db 0 ; version
		db 0 ; ADL disabled

		include "agon_z80_helpers.asm"
		include "mem.asm"
		include "shape.asm"
		include "board.asm"

		.cpu ez80
start:
		push.lil iy
		puts "Running tests\r\n"

		call test_shape
		jp c, @failed

		call test_board
		jp c, @failed

		col_green
		puts "\r\n\r\nPassed!\r\n"
		col_white
		jr @exit
	@failed:
		col_red
		puts "\r\n\r\nFailed.\r\n"
		col_white
	@exit:
		ld hl,0
		pop.lil iy
		ret.lis

test_board:
		puts "\r\ntest_board "

		; does a new board look right?
		ld hl,@_b
		call board_new
		ld hl,@_b
		ld de,@_c
		ld bc,sizeof_Shape
		call mem_cmp
		ret c
		putc '.'

		; test board bounds
		ld b,0
		ld c,0
		call board_bounds
		jp c,@fail
		ld b,0
		ld c,board_width-1
		call board_bounds
		jp c,@fail
		ld b,0
		ld c,board_width
		call board_bounds
		jp nc,@fail
		ld b,board_height
		ld c,0
		call board_bounds
		jp nc,@fail
		putc '.'

		; add a shape to the board (ie stick it there)
		ld de,@_s
		ld hl,(shape_shapes+4)
		call shape_copy
		ld hl,@_b
		ld de,@_s
		ld c,0
		ld b,0
		call board_add_shape

		; does that look right?
		ld c,0
		ld b,0
		ld hl,@_b
		call board_get
		cp ' '
		jp nz,@fail
		ld c,1
		ld b,0
		ld hl,@_b
		call board_get
		cp '2'
		jp nz,@fail
		ld c,2
		ld b,0
		ld hl,@_b
		call board_get
		cp ' '
		jp nz,@fail
		putc '.'

		; now draw somewhere offset
		ld hl,@_b
		ld de,@_s
		ld c,board_width-2
		ld b,board_height-2
		call board_add_shape
		ld c,board_width-1
		ld b,board_height-2
		ld hl,@_b
		call board_get
		cp '2'
		jp nz,@fail
		putc '.'

		; draw the board to screen
		putc 13
		putc 10
		ld hl,@_b
		ld b,board_height
	@loopy:
		push bc
		ld b,board_width
	@loopx:
			ld a,(hl)
			inc hl
			rst.lis 0x10
			djnz @loopx
		putc 13
		putc 10
		pop bc
		djnz @loopy
		puts "----------\r\n"

		; test collisions
		ld hl,@_b
		ld de,@_s
		ld c,0
		ld b,0
		call board_shape_collide
		jr nc,@fail
		ld hl,@_b
		ld de,@_s
		ld c,1
		ld b,0
		call board_shape_collide
		jr nc,@fail
		ld hl,@_b
		ld de,@_s
		ld c,2
		ld b,0
		call board_shape_collide
		jr c,@fail
		ld hl,@_b
		ld de,@_s
		ld c,1
		ld b,1
		call board_shape_collide
		jr nc,@fail
		ld hl,@_b
		ld de,@_s
		ld c,1
		ld b,3
		call board_shape_collide
		jr c,@fail
		
		xor a
		ret
	@fail:
		xor a
		ccf
		ret
	@_s:		ds sizeof_Shape
	@_b:		ds sizeof_Board
	@_c: 	db "          "
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
		ld de,@_s
		ld hl,(shape_shapes+4)
		call shape_copy

		; did shape_copy work?
		ld de,@_s
		ld hl,(shape_shapes+4)
		ld bc,sizeof_Shape
		call mem_cmp
		ret c
		putc '.'

		; test 3x3 shape rotation
		ld hl,@_s
		ld de,@_t
		call shape_rot90
		ld de,@_t
		ld hl,@_u
		ld bc,sizeof_Shape
		out (0x10),a
		call mem_cmp
		ret c
		putc '.'

		; test 4x4 shape rotation
		ld de,@_s
		ld hl,(shape_shapes+2)
		call shape_copy
		ld hl,@_s
		ld de,@_t
		call shape_rot90
		ld de,@_t
		ld hl,@_v
		ld bc,sizeof_Shape
		call mem_cmp
		ret c
		putc '.'
		
		xor a
		ret
	@_s: ds sizeof_Shape
	@_t: ds sizeof_Shape
	@_u: db 1
		db "    "
		db "222 "
		db "2   "
		db "    "
	@_v: db 0
		db "    "
		db "1111"
		db "    "
		db "    "
