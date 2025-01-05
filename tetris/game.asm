start_game:
		xor a
		ld (keystate),a

		ld hl,board
		call board_new

		ld hl,tet
		call new_random_tetromino
		call reset_position
		call reset_score

@gameloop:
		call redraw_board
		call handle_completed_rows
		call plt_start_timer
		; clear the 'player chose to move down' flag
		xor a
		ld (moved_down),a

@tickloop:
			call plt_poll
			call handle_controls

			ld a,(moved_down)
			or a
			jr nz,@exit_tick_moved_down

			call plt_timer_elapsed
			ld a,l
			cp GAME_TURNTIME
			jr c,@tickloop

		call move_down
@exit_tick_moved_down:
		jr @gameloop
		ret ; exit @gameloop

reset_score:
		ld hl,0
		ld (score),hl
		ret

increment_score:
		ld hl,(score)
		inc hl
		ld (score),hl
		ret

handle_completed_rows:
		xor a
		ld (@did_complete_row),a
		ld b,board_height
@scan_rows_loop:
		ld a,b
		or a
		jr z,@done_scanning
		dec b
		push bc
		call @is_row_complete
		pop bc
		jr nc,@scan_rows_loop
		; row is complete
		push bc
			call increment_score
			ld hl,board
			ld c,0
			call board_get
			ld b,board_width
			ld a,'7'	; '7': the 'clearing row' tile
@mark_row_loop:
			ld (hl),a
			inc hl
			djnz @mark_row_loop
		pop bc
		ld a,1
		ld (@did_complete_row),a
		jr @scan_rows_loop
@done_scanning:
		ld a,(@did_complete_row)
		or a
		ret z
		call redraw_board
		ld b,15
		call plt_wait
		call @remove_complete_rows
		call redraw_board
		ret

@is_row_complete: ; row(b) -> set carry flag if complete
			ld hl,board
			ld c,0
			call board_get
			ld b,board_width
			ld a,' '
@test_row_complete_loop:
			cp (hl)
			jr z,@not_complete
			inc hl
			djnz @test_row_complete_loop
			xor a
			scf
			ret
@not_complete:
			xor a
			ret
	
@remove_complete_rows:
			ld b,board_height
@scan_rows_loop2:
			ld a,b
			or a
			ret z
			dec b

			push bc
			call @is_row_complete
			pop bc
			jr nc,@scan_rows_loop2
			; row is complete. shuffle down board
			push bc
				ld h,0
				ld l,b
				ld d,h
				ld e,l
				add hl,hl
				add hl,hl
				add hl,hl	; row*8
				add hl,de
				add hl,de				; row*10
				ld b,h
				ld c,l
				ld hl,board+10
				add hl,bc
				ld d,h
				ld e,l
				dec de
				ld hl,board
				add hl,bc
				dec hl
				lddr
			pop bc
			; rescan same row, since stuff has been shuffled down
			inc b
			jr @scan_rows_loop2
			ret
@did_complete_row: ds 1

redraw_board:
		ld hl,board
		ld de,tet
		ld bc,(tetpos)
		call board_add_shape

		ld hl,board
		call plt_draw_board
		ld hl,(score)
		call plt_draw_score

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
		jr c,@hit
		ld (tetpos),bc
		ret
@hit:
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
		ld (@didmove),a
		ld hl,(tetpos)
		ld a,(keystate)
		ld e,a
		bit 0,e
		jr z,@nleft
		ld a,l
		sub 1
		ld l,a
		ld a,1
		ld (@didmove),a
@nleft:
		bit 1,e
		jr z,@nright
		ld a,l
		add 1
		ld l,a
		ld a,1
		ld (@didmove),a
@nright:
		bit 2,e
		jr z,@nup
		push de
		push hl
		call try_rotate
		pop hl
		pop de
		jr c,@nup
		ld a,1
		ld (@didmove),a
@nup:
		bit 3,e
		jr z,@skip
		call move_down
		ld a,1
		ld (moved_down),a
		call redraw_board
		; wait a little
		ld b,DELAY_MOVEDOWN
		call plt_wait
		ret
@skip:
		; is position possible?
		push hl
		ld b,h
		ld c,l
		ld hl,board
		ld de,tet
		call board_shape_collide
		pop hl
		ret c

		ld a,(@didmove)
		or a
		ret z

		; update position
		ld (tetpos),hl
		call redraw_board

		; wait a little
		ld b,8
		call plt_wait

		ret
@didmove: ds 1

try_rotate: ; set carry on success
		ld de,@s
		ld hl,tet
		call shape_rot90

		ld hl,board
		ld de,@s
		ld bc,(tetpos)
		call board_shape_collide
		ret c

		ld hl,@s
		ld de,tet
		ld bc,sizeof_Shape
		call mem_cpy
		xor a
		ret
@s:	ds sizeof_Shape

new_random_tetromino: ; shape_t(hl)
		ex de,hl
		ld a,r
@loop:
		sub shape_num_shapes
		cp shape_num_shapes
		jr nc,@loop
		ld hl,shape_shapes
		sla a
		add a,l
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

