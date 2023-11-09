	section	.text,"ax",@progbits
	assume	adl = 1

	public _fast_vdu
_fast_vdu:
	push ix
	ld ix, 0
	add ix, sp

	push hl
	push de
	push bc

	; data pointer
	ld	hl, (ix + 6)
	; length
	ld	bc, (ix + 9)

	call uart0_fast_write

	pop bc
	pop de
	pop hl
	pop ix
	ret

uart0_fast_write: ; hl=data, bc=len
	; do we have >= 16 bytes to send?
	push hl

	ld hl,-16
	or a
	adc hl,bc
	jr nc,.write_lt_16

	; write 16 bytes
	push hl
	pop bc ; bc -= 16
	pop hl ; restore hl (data)

	; wait for uart0 fifo to be empty
	; fifo is 16 bytes long, so we can write all 16 bytes without waiting
.not_ready:
	in0 a,(0xc5)  ; UART0_LSR
	and 0x60      ; either TEMT or THRE (fifo empty, but transmit shift register can be active)
	jr z, .not_ready

	; fill the uart0 fifo with 16 bytes
	ld a, (hl)
	inc hl
	out0 (0xc0), a

	ld a, (hl)
	inc hl
	out0 (0xc0), a

	ld a, (hl)
	inc hl
	out0 (0xc0), a

	ld a, (hl)
	inc hl
	out0 (0xc0), a

	ld a, (hl)
	inc hl
	out0 (0xc0), a

	ld a, (hl)
	inc hl
	out0 (0xc0), a

	ld a, (hl)
	inc hl
	out0 (0xc0), a

	ld a, (hl)
	inc hl
	out0 (0xc0), a

	ld a, (hl)
	inc hl
	out0 (0xc0), a

	ld a, (hl)
	inc hl
	out0 (0xc0), a

	ld a, (hl)
	inc hl
	out0 (0xc0), a

	ld a, (hl)
	inc hl
	out0 (0xc0), a

	ld a, (hl)
	inc hl
	out0 (0xc0), a

	ld a, (hl)
	inc hl
	out0 (0xc0), a

	ld a, (hl)
	inc hl
	out0 (0xc0), a

	ld a, (hl)
	inc hl
	out0 (0xc0), a

	jr uart0_fast_write
	
	; write the final <16 bytee
.write_lt_16:
	pop hl

.not_ready2: ; wait for uart0 fifo to be empty
	in0 a,(0xc5)  ; UART0_LSR
	and 0x60      ; either TEMT or THRE (fifo empty, but transmit shift register can be active)
	jr z, .not_ready2

	ld b, c ; len fits in 8 bits now (is <16)
	ld a, b
	or a
	jr z, .done

.loop_lt_16:
	ld a, (hl)
	inc hl
	out0 (0xc0), a
	djnz .loop_lt_16
.done:
	ret
