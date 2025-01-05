sizeof_Shape:	equ	17
Shape_sz:		equ 0
Shape_tiles:	equ 1

shape_copy:	; src(hl), dest(de)
		ld bc,sizeof_Shape
		ldir
		ret

shape_rot90: ; src(hl), dest(de)
		push ix
		push iy

		ld ix,@rot4x4map
		ld a,(hl)	; get sz
		or a
		jp z, @is4x4
		ld ix,@rot3x3map
@is4x4:
		; copy sz byte
		ld a,(hl)
		ld (de),a
		inc hl
		inc de
		ex de,hl
		ld b,16
@loop:
		push bc
			ld b,0
			ld c,(ix+0)
			push hl
				ld a,(de)
				add hl,bc
				ld (hl),a
			pop hl
		pop bc
		inc de
		inc ix
		djnz @loop

		pop iy
		pop ix
		ret
@rot3x3map:
		db 2,6,10,3
		db 1,5,9,7
		db 0,4,8,11
		db 12,13,14,15
@rot4x4map:
		db 3,7,11,15
		db 2,6,10,14
		db 1,5,9,13
		db 0,4,8,12

shape_num_shapes: equ 7
shape_shapes:
	dw @shape0
	dw @shape1
	dw @shape2
	dw @shape3
	dw @shape4
	dw @shape5
	dw @shape6
@shape0:
	db 0
	db "    "
	db " 00 "
	db " 00 "
	db "    "
@shape1:
	db 0
	db " 1  "
	db " 1  "
	db " 1  "
	db " 1  "
@shape2:
	db 1
	db " 2  "
	db " 2  "
	db " 22 "
	db "    "
@shape3:
	db 1
	db " 3  "
	db "333 "
	db "    "
	db "    "
@shape4:
	db 1
	db " 4  "
	db " 4  "
	db "44  "
	db "    "
@shape5:
	db 1
	db " 5  "
	db "55  "
	db "5   "
	db "    "
@shape6:
	db 1
	db " 6  "
	db " 66 "
	db "  6 "
	db "    "
