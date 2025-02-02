	.assume adl=1
	.org $40000
	jp start
	.align $40

	.db "MOS"
	.db 0 ; version
	.db 1 ; ADL enabled (24-bit addressing)

	macro puts_hl
		ld bc,0
		xor a
		rst.lil 0x18
	endmacro

	macro putc char
		ld a,char
		rst.lil 0x10
	endmacro

start:
	push ix
	push iy

	ld hl, hello
	puts_hl

	call setup_kb_handler

	; loop until escape is pressed
	ld hl,esc_pressed
	ld (hl),0
	xor a
@loop:
	cp (hl)
	jr z,@loop

	; remove the handler before exit
	call clear_kb_handler

	ld hl, 0
	pop iy
	pop ix
	ret

clear_kb_handler:
	ld hl,0
	ld c,0
	ld a,0x1d        ; mos_setkbvector
	rst.lil 0x8
	ret

setup_kb_handler:
	ld hl,@on_keyboard_event
	ld c,0		 ; c=0 means 24-bit handler pointer in hl (c=1 means 16-bit pointer)
	ld a,0x1d        ; mos_setkbvector
	rst.lil 0x8
	ret

@on_keyboard_event:
	push bc
	push hl
	push ix

	; VDP keyboard packet in de. Get into ix for easy access
	push de
	pop ix

	ld a,(ix+0)	   ; ascii code
	call print_hexbyte

	ld a,(ix+1)	   ; modifier keys
	call print_hexbyte

	ld a,(ix+2)	   ; fabgl vkey
	call print_hexbyte

	ld a,(ix+3)	   ; is key down?
	call print_hexbyte

	putc 13
	putc 10

	; flag exit on pressing escape
	ld a,(ix+2)	   ; fabgl vkey
	cp 0x7d
	jr nz,@f
	ld a,1
	ld (esc_pressed),a
@@:
	pop ix
	pop hl
	pop bc
	ret

print_hexbyte:
	push af
	srl a
	srl a
	srl a
	srl a
	; print high nibble
	call @print_hexnibble
	pop af
	and $f
	; print low nibble
	call @print_hexnibble
	; indent
	ld b,8
	ld a,' '
@@:	rst.lil $10
	djnz @b
	ret
@print_hexnibble:
	add a, 48
	cp 58
	jr c, @f
	add a, 7
@@:	rst.lil $10
	ret

hello:
	.db "Custom kbvector demo - escape to exit\r\n"
	.db "ASCII     MODS      VDP-VKEY  IS-DOWN?\r\n",0

esc_pressed:
	.db 0
