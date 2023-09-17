	section	.text,"ax",@progbits
	assume	adl = 1

	public _vblank_handler
_vblank_handler:
	di
	push af
	IN0	a,(0x9a)
	OR	2
	OUT0	(0x9a),a
	push bc
	push de
	push hl
	push ix
	push iy

	; in C code
	call _on_vblank

	pop iy
	pop ix
	pop hl
	pop de
	pop bc
	pop af
	ei
	reti.lil

	extern _on_vblank
