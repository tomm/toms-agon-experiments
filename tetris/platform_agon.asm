sysvar_keyascii equ 5

plt_draw_board: ; board(hl)
		; draw the board to screen
		putc 31 : putc 0 : putc 0		; cursor_to(0,0)
		ld b,board_height
	.loopy:
		push bc
		ld b,board_width
		putc '|'
		.loopx
			ld a,(hl)
			inc hl
			rst.lis 0x10
			djnz .loopx
		putc '|'
		putc 13 : putc 10
		pop bc
		djnz .loopy
		puts "------------\r\n"
		ret

plt_poll:
		ret

plt_waitkey:
		ld a,sysvar_keyascii
		call get_sysvar
		or a
		jp z,plt_waitkey
		ret

sysvar_ptr:
		ds 2
		db 0xb
timer_start:	ds 2

get_sysvar: ; sysvar offset (a) -> value (a)
		lil : ld hl,(sysvar_ptr) : db 0x4
		add l
		ld l,a
		ld a,h
		adc 0
		ld h,a
		lil : ld a,(hl)
		ret

gettime:	; -> centiseconds (de)
		; icky. assume segment 0x4
		lil : ld hl,(sysvar_ptr) : db 0x4
		lil : ld e,(hl)
		lil : inc hl
		lil : ld d,(hl)
		ret
		

plt_start_timer:
		call gettime
		ld (timer_start),de
		ret

plt_timer_elapsed: ; -> elapsed vblanks (hl)
		call gettime
		ld hl,(timer_start)
		ex de,hl
		xor a
		sbc hl,de
		ret

plt_wait:	; vblanks to wait (b)
		sla b
		call gettime
		ld a,e
		add b
		ld l,a
		ld a,d
		adc 0
		ld h,a
		; hl is end time
		push hl
	.loop:
		call gettime
		pop hl
		push hl
		xor a
		sbc hl,de
		jr nc,.loop
		pop hl
		ret

plt_gameinit:
		; mode 8
		putc 22 : putc 8
		; hide cursor
		putc 23 : putc 1 : putc 0
		ret


plt_init:
		ld a,8
		rst.lis 8
		ld (sysvar_ptr),ix

		ld hl,.on_keyboard_event
		ld c,1
		ld a,0x1d		; mos_setkbvector
		rst.lis 0x8
		ret

	; called in ADL mode
	.on_keyboard_event
		push bc
		push hl
		push ix
		push de
		pop ix

		ld e,(ix+2)		; fabgl vkey code
		ld d,(ix+3)		; is key down?

		call.sis .on_keyboard_event_z80
		pop ix
		pop hl
		pop bc
		ret

	.on_keyboard_event_z80:
		ld b,0
		ld a,e
		cp 154			; left
		jr nz,.notl
		ld b,1
		jr .skip
	.notl:
		cp 156			; right
		jr nz,.notr
		ld b,2
		jr .skip
	.notr:
		cp 150			; up
		jr nz,.notu
		ld b,4
		jr .skip
	.notu:
		cp 152			; down
		jr nz,.skip
		ld b,8
		jr .skip
	.skip:
		ld a,d
		or a
		jr z,.keyup
		ld a,(keystate)
		or b
		ld (keystate),a
		ret.lis
	.keyup:
		ld a,b : cpl : ld b,a
		ld a,(keystate)
		and b
		ld (keystate),a
		ret.lis
