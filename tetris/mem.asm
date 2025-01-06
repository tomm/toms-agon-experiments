mem_cmp: ; obj1(hl), obj2(de), len(bc) -> carry set if neq
		ld a,c
		or b
		jr z,@eq

		ld a,(de)
		cp (hl)
		jr nz,@neq
		inc de
		inc hl
		dec bc
		jr mem_cmp
	@eq:
		xor a
		ret
	@neq:
		xor a
		ccf
		ret

mem_cpy: ; src(hl), dest(de), len(bc)
		ld a,b
		or c
		ret z
		ldir
		ret

mem_set: ; dest(hl), value(a), count(bc)
		; count == 0?
		ld e,a
		ld a,b
		or c
		ret z

		; count == 1?
		ld (hl),e
		dec bc
		ld a,b
		or c
		ret z

		ld d,h
		ld e,l
		inc de

		ldir
		ret
