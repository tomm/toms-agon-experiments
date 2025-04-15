	.assume adl=1
	.org $40000
	jp start
	.align $40

	.db "MOS"
	.db 0 ; version
	.db 1 ; ADL

	include "print.asm"

TMR1_CTL: .equ 0x83
PRT_CLK_DIV_4: .equ 0b0000
PRT_CLK_DIV_16: .equ 0b0100
PRT_CLK_DIV_64: .equ 0b1000
PRT_CLK_DIV_256: .equ 0b1100
PRT_MODE_CONTINUOUS: .equ 0b10000
PRT_ENABLE: .equ 0b1
PRT_START: .equ 0b10

PC_DR: .equ 0x9e
PC_DDR: .equ 0x9f
PC_ALT1: .equ 0xa0
PC_ALT2: .equ 0xa1

PD_DR: .equ 0xa2
PD_DDR: .equ 0xa3
PD_ALT1: .equ 0xa4
PD_ALT2: .equ 0xa5

; GPIO usage:
; gpio-c 8 bits colour data
; gpio-d pin 6: vsync
; gpio-d pin 7: hsync

start:
	push iy

	print_asciz "EZ80 GPIO VGA\r\n"

	di
	call setup_gpio
	call start_scanout

	pop iy
	ld hl,0
	ret

setup_gpio:
	; set port c for output
	xor a
	out0 (PC_DDR),a
	out0 (PC_ALT1),a
	out0 (PC_ALT2),a
	out0 (PC_DR),a

	; set port d pin 6&7 to output
	in0 a,(PD_DDR)
	and 0b00111111
	out0 (PD_DDR),a

	in0 a,(PD_ALT1)
	and 0b00111111
	out0 (PD_ALT1),a

	in0 a,(PD_ALT2)
	and 0b00111111
	out0 (PD_ALT2),a

	ret

	in0 a,(PD_DR)
flashloop:
	push af
	ld a,'X'
	rst.lil 0x10
	pop af

	set 6,a
	res 7,a
	out0 (PD_DR),a
	; wait
	ld hl,1000000
	ld de,-1
@@:
	or a
	adc hl,de
	jr nz,@b
	
	res 6,a
	set 7,a
	out0 (PD_DR),a
	; wait
	ld hl,1000000
	ld de,-1
@@:
	or a
	adc hl,de
	jr nz,@b
	jp flashloop

	ret

	macro line_scanout_pixels
		ld b,0b01000000		; end vsync if it's asserted
		call scanout_line_with_pixeldata
	endmacro

	macro line_scanout_empty
		ld b,0b01000000		; end vsync if it's asserted
		call scanout_line_without_pixeldata
	endmacro

	macro line_scanout_empty_vblank
		ld b,0			; vsync on
		call scanout_line_without_pixeldata
	endmacro

	; +0.3 cycles spare
	macro line_scanout_empty_x10
		line_scanout_empty
		nop
		line_scanout_empty
		line_scanout_empty
		nop

		line_scanout_empty
		line_scanout_empty
		nop
		line_scanout_empty
		nop

		line_scanout_empty
		nop
		line_scanout_empty
		nop
		line_scanout_empty

		line_scanout_empty
		nop
	endmacro

	; +0.3 cycles spare
	macro line_scanout_pixels_x10
		line_scanout_pixels
		nop
		line_scanout_pixels
		line_scanout_pixels
		nop

		line_scanout_pixels
		line_scanout_pixels
		nop
		line_scanout_pixels
		nop

		line_scanout_pixels
		nop
		line_scanout_pixels
		nop
		line_scanout_pixels

		line_scanout_pixels
		nop
	endmacro

	macro nop_x5
		nop
		nop
		nop
		nop
		nop
	endmacro

	macro nop_x10
		nop_x5
		nop_x5
	endmacro

	macro nop_x50
		nop_x10
		nop_x10
		nop_x10
		nop_x10
		nop_x10
	endmacro

fb_ptr:	.dl	0

start_scanout:
	; Timings at 18.432 MHz
	; Total scanline: 585.73 cycles (31.778 us)
        ;     hsync pulse: 70.28 cycles ( 3.813 us)
	;     front porch: 35.15 cycles ( 1.907 us)
	;     pixel data: 468.58 cycles (25.422 us)
	;     back porch   11.72 cycles ( 0.636 us)

	; Total lines: 525
	;            2 lines vsync pulse
	;           10 lines front porch
	;          480 lines visible
	;           33 lines back porch

    @loop_scanout:
    	; Load the framebuffer pointer into HL
	; XXX unaccounted for cycles
	ld hl,(fb_ptr)

	; 2 lines of (-ve) vsync pulse.
	line_scanout_empty_vblank
	line_scanout_empty_vblank
	nop
	; 2*0.73 + 1 -> +0.46 cycles spare (XXX not added to 523 line count XXX)

	; now 523 lines with just hsync (no pixel data yet)
	; first 522 lines
	; 100 lines
		; Front porch
		line_scanout_empty_x10
		; Now pixel data scanout (no data yet)
		line_scanout_pixels_x10
		line_scanout_pixels_x10
		nop
		; -0.1 cycles spare
		line_scanout_pixels_x10
		line_scanout_pixels_x10
		line_scanout_pixels_x10
		line_scanout_pixels_x10
		nop
		; 0.1 cycles spare
		line_scanout_pixels_x10
		line_scanout_pixels_x10
		line_scanout_pixels_x10
		nop
		; 0 cycles spare
	; 100 lines
		line_scanout_pixels_x10
		line_scanout_pixels_x10
		line_scanout_pixels_x10
		nop
		; -0.1 cycles spare
		line_scanout_pixels_x10
		line_scanout_pixels_x10
		line_scanout_pixels_x10
		line_scanout_pixels_x10
		nop
		; 0.1 cycles spare
		line_scanout_pixels_x10
		line_scanout_pixels_x10
		line_scanout_pixels_x10
		nop
		; 0 cycles spare
	; 100 lines
		line_scanout_pixels_x10
		line_scanout_pixels_x10
		line_scanout_pixels_x10
		nop
		; -0.1 cycles spare
		line_scanout_pixels_x10
		line_scanout_pixels_x10
		line_scanout_pixels_x10
		line_scanout_pixels_x10
		nop
		; 0.1 cycles spare
		line_scanout_pixels_x10
		line_scanout_pixels_x10
		line_scanout_pixels_x10
		nop
		; 0 cycles spare
	; 100 lines
		line_scanout_pixels_x10
		line_scanout_pixels_x10
		line_scanout_pixels_x10
		nop
		; -0.1 cycles spare
		line_scanout_pixels_x10
		line_scanout_pixels_x10
		line_scanout_pixels_x10
		line_scanout_pixels_x10
		nop
		; 0.1 cycles spare
		line_scanout_pixels_x10
		line_scanout_pixels_x10
		line_scanout_pixels_x10
		nop
		; 0 cycles spare
	; 100 lines
		line_scanout_pixels_x10
		line_scanout_pixels_x10
		line_scanout_pixels_x10
		nop
		; -0.1 cycles spare
		line_scanout_pixels_x10
		line_scanout_pixels_x10
		line_scanout_pixels_x10
		line_scanout_pixels_x10
		nop
		; 0.1 cycles spare
		line_scanout_pixels_x10
		line_scanout_pixels_x10

		; back porch begins here
		line_scanout_empty_x10
		nop
		; 0 cycles spare
	; -> 500 lines done, 23 to go
		line_scanout_empty_x10
		line_scanout_empty_x10
		; +0.6 cycles spare
		line_scanout_empty
		line_scanout_empty
		line_scanout_empty
		; 2.79 cycles spare
		; +0.46 from vsync lines (see above)
		; = 3.25 cycles spare

	; XXX note we have 3.25 cycles spare, but consume 5 here.
	; So final scanout is 1.75 cycles too long
	; This is probably well withing tolerance
	jp @loop_scanout	; 5 cycles

	; 640x480x60hz scanline: 585 cycles (+0.73 cycles spare per scanline)
	; b: sync clear gpio bitfield
scanout_line_without_pixeldata:
	; 11 cycles (horizontal back porch) -> +0.72 spare
	;               ; 2 cycles by setup (sync clear mask into `b`)
	;               ; 7 cycles consumed by 'call'
	nop
	nop

	; 71 cyles (hsync pulse (-ve)) -> +0 spare
	;          (with -ve vsync pulse)
	in0 a,(PD_DR)	; 4 cycles
	and 0b00111111		; 2 cycles
	or b			; 1 cycles
	out0 (PD_DR),a	; 4 cycles
	nop_x50 		; 54 nop cycles
	nop
	nop
	nop
	nop
	or 0b10000000		; 2 cycles (hsync off)
	out0 (PD_DR),a 	; 4 cycles

	; 35 cyles (horizontal front porch) -> +0.15 spare
	xor a			; 1 cycle
	out0 (PC_DR),a	; 4 cycles
	nop_x10			; 30 nop cycles
	nop_x10
	nop_x10

	; 468 cycles (pixel data)  -> +0.73 spare
	nop_x50			; 462 nop cycles
	nop_x50

	nop_x50
	nop_x50

	nop_x50
	nop_x50

	nop_x50
	nop_x50

	nop_x50
	nop_x10
	nop
	nop

	ret		; 6 cycles

scanout_line_with_pixeldata:
	; 11 cycles (horizontal back porch) -> +0.72 spare
	;               ; 2 cycles by setup (sync clear mask into `b`)
	;               ; 7 cycles consumed by 'call'
	nop
	nop

	; 71 cyles (hsync pulse (-ve)) -> +0 spare
	;          (with -ve vsync pulse)
	in0 a,(PD_DR)	; 4 cycles
	and 0b00111111		; 2 cycles
	or b			; 1 cycles
	out0 (PD_DR),a	; 4 cycles
	nop_x50 		; 54 nop cycles
	nop
	nop
	nop
	nop
	or 0b10000000		; 2 cycles (hsync off)
	out0 (PD_DR),a 	; 4 cycles

	; 35 cyles (horizontal front porch) -> +0.15 spare
	xor a			; 1 cycle
	out0 (PC_DR),a	; 4 cycles
	nop_x10			; 16 nop cycles
	nop_x5
	nop

	;;; new shit (14 cycles including 2 initial cycles of otirx)
	ld de,PC_DR		; 4 cycles
	;ld hl,pixeldata		; 4 cycles
	nop
	nop
	nop
	nop
	ld bc,152		; 4 cycles
	otirx			; 2 (+ 3*152)

	; 35 cyles (horizontal front porch) -> +0.15 spare
;;;;;;;;xor a			; 1 cycle
;;;;;;;;out0 (PC_DR),a	; 4 cycles
;;;;;;;;nop_x10		
;;;;;;;;nop_x10		
;;;;;;;;nop
;;;;;;;;nop
;;;;;;;;nop
;;;;;;;;nop
;;;;;;;;ld b,0xff	; 2 cycles
;;;;;;;;out0 (PC_DR),b	; 4 cycles

;;;;;;;;; 468 cycles (pixel data)  -> +0.73 spare
;;;;;;;;nop_x50
;;;;;;;;nop_x50
;;;;;;;;nop_x50
;;;;;;;;nop_x50
;;;;;;;;nop_x50
;;;;;;;;nop_x50
;;;;;;;;nop_x50
;;;;;;;;nop_x50
;;;;;;;;nop_x50		; 450
;;;;;;;;nop_x5
;;;;;;;;nop
;;;;;;;;nop
;;;;;;;;nop
	out0 (PC_DR),a	; 4 cycles clear pixel data
	nop
	nop
	ret		; 6 cycles

pixeldata:
	db 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18
	db 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35
	db 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52
	db 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69
	db 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86
	db 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102
	db 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115
	db 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128
	db 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141
	db 142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154
	db 155
