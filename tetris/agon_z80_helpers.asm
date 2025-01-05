	macro mos_header startfn
			org 0
			jp startfn
			align $40
			db "MOS"
			db 0 ; version
			db 0 ; ADL disabled
	endmacro

	macro putbuf start, end
			ld hl,start
			ld bc,end-start
			xor a
			rst.lis 0x18
	endmacro

	macro push_all
			push af
			push bc
			push de
			push hl
	endmacro

	macro pop_all
			pop hl
			pop de
			pop bc
			pop af
	endmacro

	macro puts msg
			jr @over_str
@str:
			db msg
			db 0
@over_str:
			ld hl,@str
			ld bc,0
			xor a
			rst.lis $18
	endmacro

	macro putc chr
			ld a,chr
			rst.lis $10
	endmacro

	macro col_red
			putc 17
			putc 1
	endmacro

	macro col_green
			putc 17
			putc 2
	endmacro

	macro col_white
			putc 17
			putc 15
	endmacro

	macro setcolor col
			putc 17
			putc col
	endmacro

