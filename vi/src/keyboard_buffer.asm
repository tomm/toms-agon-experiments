		.assume	adl = 1	
		.text
		.global _kb_event_handler
		.global _kb_buf_getch

_kb_event_handler:
		; keyboard packet address in `de`. (de+0) = ascii
		push af
		push bc
		push hl
		inc de
		inc de
		inc de
		ld a,(de)		; is keydown?
		dec de
		dec de
		dec de
		or a
		jr z,1f
		ld a,(de)		; ascii
		call nz,kbbuf_append
	1:
		pop hl
		pop bc
		pop af
		ret

_kb_buf_getch:
		call kbbuf_remove	
		ret nz
		jp _kb_buf_getch

kbbuf_append:	; value to append in `a`. set `z` if no space
		push af

		; put `a` at kbbuf_data[kbbuf_end_idx]
		ld hl,kbbuf_data
		ld bc,0
		ld a,(kbbuf_end_idx)
		ld c,a
		add hl,bc

		pop af
		ld (hl),a

		; c := (kbbuf_end_idx+1) & KBBUF_LEN
		inc c
		ld a,KBBUF_LEN
		and c
		ld c,a

		ld a,(kbbuf_start_idx)
		cp c

		; if kbbuf_start_idx==kbbuf_end_idx+1 then no space for appending
		ret z
		
		; otherwise write new kbbuf_end_idx
		ld a,c
		ld (kbbuf_end_idx),a
		ret

kbbuf_remove:	; value removed from fifo in `a`. `z` flag set if no bytes in fifo
		ld bc,0
		ld a,(kbbuf_start_idx)
		ld c,a
		ld a,(kbbuf_end_idx)
		cp c
		ret z

		ld hl,kbbuf_data
		add hl,bc
		ld a,(hl)
		push af

		ld a,(kbbuf_start_idx)
		inc a
		and KBBUF_LEN
		ld (kbbuf_start_idx),a

		pop af
		or a		; clear `z` flag
		ret

KBBUF_LEN: .equ 7		; must be POT-1, and <256
kbbuf_start_idx:	db 0
kbbuf_end_idx: 	db 0
kbbuf_data:	ds KBBUF_LEN+1
