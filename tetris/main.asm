		include "ez80.asm"
		include "mos_utils.asm"
		mos_header start

		include "mem.asm"
		include "shape.asm"
		include "board.asm"
		include "platform_agon.asm"
		include "splash.asm"

start:
		lil : push iy

		call plt_init
		call put_logo
		call plt_waitkey
		call plt_gameinit

		xor a
		ld (keystate),a

		ld hl,board
		call board_new

		ld hl,tet
		call new_random_tetromino
		call reset_position

	.gameloop:
		call redraw_board
		call plt_start_timer
		.tickloop:
			call plt_poll
			call handle_controls

			call plt_timer_elapsed
			ld a,l
			cp 60
			jr c,.tickloop

		call move_down

		jr .gameloop

		ld hl,0
		lil : pop iy
		ret.lis

redraw_board:
		ld hl,board
		ld de,tet
		ld bc,(tetpos)
		call board_add_shape

		ld hl,board
		call plt_draw_board

		ld hl,board
		ld de,tet
		ld bc,(tetpos)
		call board_erase_shape
		ret

reset_position:
		ld a,3
		ld (tetpos),a
		xor a
		ld (tetpos+1),a
		ret

move_down:
		ld bc,(tetpos)
		inc b
		push bc
		ld hl,board
		ld de,tet
		call board_shape_collide
		pop bc
		jr c,.hit
		ld (tetpos),bc
		ret
	.hit:
		ld hl,board
		ld de,tet
		ld bc,(tetpos)
		call board_add_shape
		ld hl,tet
		call new_random_tetromino
		call reset_position
		ret

handle_controls:
		xor a
		ld (.didmove),a
		ld hl,(tetpos)
		ld a,(keystate)
		ld e,a
		bit 0,e
		jr z,.nleft
		ld a,l : sub 1 : ld l,a
		ld a,1 : ld (.didmove),a
	.nleft:
		bit 1,e
		jr z,.nright
		ld a,l : add 1 : ld l,a
		ld a,1 : ld (.didmove),a
	.nright:
		bit 2,e
		jr z,.nup
		push de
		push hl
		call try_rotate
		pop hl
		pop de
		jr c,.nup
		ld a,1 : ld (.didmove),a
	.nup:
		bit 3,e
		jr z,.skip
		ld a,h : add 1 : ld h,a
		ld a,1 : ld (.didmove),a
	.skip:
		; is position possible?
		push hl
		ld bc,hl
		ld hl,board
		ld de,tet
		call board_shape_collide
		pop hl
		ret c

		ld a,(.didmove)
		or a
		ret z

		; update position
		ld (tetpos),hl
		call redraw_board

		; wait a little
		ld b,10
		call plt_wait

		ret
	.didmove: ds 1

try_rotate: ; set carry on success
		ld de,.s
		ld hl,tet
		call shape_rot90

		ld hl,board
		ld de,.s
		ld bc,(tetpos)
		call board_shape_collide
		ret c

		ld hl,.s
		ld de,tet
		ld bc,{sizeof}shape_t
		call mem_cpy
		xor a
		ret
	.s:	ds {sizeof}shape_t

new_random_tetromino: ; shape_t(hl)
		ex de,hl
		ld a,r
	.loop:
		sub shape_num_shapes
		cp shape_num_shapes-1
		jr nc,.loop
		ld hl,shape_shapes
		sla a
		add l
		ld l,a
		ld a,0
		adc h
		ld h,a
		ld a,(hl)
		inc hl
		ld h,(hl)
		ld l,a
		call shape_copy
		ret

; keystate bits:
; 0 - left, 1 - right, 2 - up, 3 - down
keystate: db 0
board:	ds {sizeof}board_t
tet:	ds {sizeof}shape_t
tetpos:	ds 2	; x,y
