board_width=10
board_height=24

struct board_t
		tiles ds board_width*board_height
endstruct

board_new:  ; dest(hl)
		ld a,' '
		ld bc,{sizeof}board_t
		call mem_set
		ret

board_get: ; board(hl), x(c), y(b) -> tile(a), &tile(hl)
		; a = y*10 + x
		ld a,b
		sla b
		sla b
		sla b
		sla a
		add b
		add c

		add l
		ld l,a
		ld a,h
		adc 0
		ld h,a
		ld a,(hl)
		ret

board_set: ; board(hl), x(c), y(b), value(a)
		push af
		call board_get
		pop af
		ld (hl),a
		ret

board_bounds: ; x(c), y(b) -> carry flag set if out of bounds
		ld a,c
		cp board_width
		jr nc,.oob
		ld a,b
		cp board_height
		jr nc,.oob
		xor a
		ret
	.oob:
		xor a
		ccf
		ret

; A shape landed. Write it to the board
board_add_shape: ; board(hl), shape(de), offset_x(c), offset_y(b)
		push ix
		ld ix,bc
		; skip shape sz byte
		inc de

		repeat 4
			repeat 4
				push bc
				call board_bounds
				pop bc
				jr c,@oob

				; tile from shape
				ld a,(de)
				cp ' '
				jr z,@oob

				push hl
				push bc
				call board_set
				pop bc
				pop hl
			@oob:
				inc de
				inc c
			rend
			ld a,c : sub 4 : ld c,a
			inc b
		rend

		pop ix
		ret

board_erase_shape: ; board(hl), shape(de), offset_x(c), offset_y(b)
		push ix
		ld ix,bc
		; skip shape sz byte
		inc de

		repeat 4
			repeat 4
				push bc
				call board_bounds
				pop bc
				jr c,@oob

				; tile from shape
				ld a,(de)
				cp ' '
				jr z,@oob
				ld a,' '

				push hl
				push bc
				call board_set
				pop bc
				pop hl
			@oob:
				inc de
				inc c
			rend
			ld a,c : sub 4 : ld c,a
			inc b
		rend

		pop ix
		ret

board_shape_collide:  ; board(hl), shape(de), offset_x(c), offset_y(b) -> carry set if collides
		push ix
		ld ix,bc
		; skip shape sz byte
		inc de

		repeat 4
			repeat 4
				; tile from shape
				ld a,(de)
				cp ' '
				jr z,@skip

				; shape tile is out of bounds on board. consider this a collision
				push bc
				call board_bounds
				pop bc
				jp c,_board_shape_collide_collision

				push hl
				push bc
				call board_get
				pop bc
				pop hl

				cp ' '
				jp nz,_board_shape_collide_collision
			@skip:
				inc de
				inc c
			rend
			ld a,c : sub 4 : ld c,a
			inc b
		rend
		pop ix
		xor a
		ret
	_board_shape_collide_collision:
		pop ix
		xor a
		ccf
		ret
