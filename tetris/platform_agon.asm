sysvar_keyascii equ 5

draw_tile: ; tile(a) -> does vdu to set tile color
		ld b,'0'
		sub b
		ld b,a
		add b
		add b
		ld d,0
		ld e,a
		ld hl,.tile
		add hl,de
		ld a,(hl)
		inc hl
		push af
		; bg
		putc 17
		ld a,(hl)
		rst.lis 0x10
		; fg
		putc 17
		inc hl
		ld a,(hl)
		rst.lis 0x10
		; draw tile
		pop af
		rst.lis 0x10
		ret
	.tile: ; tile,bg,fg (using agon 64-col palette)
		db '#',129,9	; red
		db '#',130,10	; green
		db '#',131,11	; yellow
		db '#',140,20	; blue
		db '#',133,13	; magenta
		db '#',134,14	; cyan
		db '#',182,58	; orange
		db '#',136,7	; grey - the 'clearing row' tile

print_hex_a:
    push af
    push bc
    push de
    push hl
    ld b, a

    ; output high nibble as ascii hex
    srl a
    srl a
    srl a
    srl a
    ld de,.hex_chr
    ld hl,0
    ld l,a
    add hl,de
    ld a,(hl)
    rst.lis $10

    ; output low nibble as ascii hex
    ld a, b
    and $f
    ld de,.hex_chr
    ld hl,0
    ld l,a
    add hl,de
    ld a,(hl)
    rst.lis $10

    pop hl
    pop de
    pop bc
    pop af
    ret

	.hex_chr:
		db "0123456789ABCDEF"

print_hex_hl:
		ld a,h
		call print_hex_a
		ld a,l
		call print_hex_a
		ret

plt_draw_score: ; score(hl)
		setcolor 128
		setcolor 15
		putc 31 : putc 30 : putc 3		; cursor_to(10,3)
		call print_hex_hl
		ret

plt_draw_board: ; board(hl)
		; draw the board to screen
		putc 31 : putc 10 : putc 3		; cursor_to(10,3)
		; don't draw top 2 rows
		ld de,board_width
		add hl,de
		add hl,de
		ld b,board_height-2
	.loopy:
		push bc
		ld b,board_width
		setcolor 129
		putc '='
		setcolor 130
		setcolor 15
		.loopx
			ld a,(hl)
			inc hl
			cp ' '
			push_all
			jr z,.isspace
			call draw_tile
			jr .ok
			.isspace:
			setcolor 128
			setcolor 15
			putc ' '
			.ok:
			pop_all
			djnz .loopx
		setcolor 15
		setcolor 129
		putc '='
		; move to next row
		ld b,board_width+2
	.wipe_loop:
		putc 8
		djnz .wipe_loop
		putc 10
		pop bc
		djnz .loopy
		setcolor 129
		puts "============\r\n"
		ret

plt_poll:
		ret

plt_waitkey: ; -> ascii key(a)
		ld a,(last_ascii_keydown)
		or a
		jp z,plt_waitkey
		push af
		xor a : ld (last_ascii_keydown),a
		pop af
		ret

sysvar_ptr:
		ds 2
		db 0xb
timer_start:	ds 2

get_sysvar: ; sysvar offset (a) -> value (a)
		; icky. assume segment 0x4
		lil : ld hl,(sysvar_ptr) : db 0x4
		add l
		ld l,a
		ld a,h
		adc 0
		ld h,a
		lil : ld a,(hl)
		ret

set_sysvar: ; sysvar offset (a), value (b)
		; icky. assume segment 0x4
		lil : ld hl,(sysvar_ptr) : db 0x4
		add l
		ld l,a
		ld a,h
		adc 0
		ld h,a
		lil : ld (hl),b
		ret

gettime:	; -> centiseconds (de)
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

		putbuf tileset,tileset.end
		ret

tileset:
		db 23,'#',0xff,0x81,0x81,0x81,0x81,0x81,0x81,0xff
		db 23,'=',0xff,0x44,0x44,0x44,0xff,0x22,0x22,0x22
tileset.end:

last_ascii_keydown: ds 1

plt_init:
		xor a
		ld (last_ascii_keydown),a

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
		ld b,(ix+0)		; ascii code
		ld c,(ix+1)		; modifier keys
		ld e,(ix+2)		; fabgl vkey code
		ld d,(ix+3)		; is key down?
		call.sis .on_keyboard_event_z80

		pop ix
		pop hl
		pop bc
		ret

	.on_keyboard_event_z80:
		ld a,d	
		or a
		jr z, .notKeyDown
		ld a,b
		ld (last_ascii_keydown),a
	.notKeyDown

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
