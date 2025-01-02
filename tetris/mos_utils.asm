dummy=RASM_VERSION+SYNCHRO:dummy=0; just use this shit to get rid of warning

macro mos_header startfn
		org 0
		jp {startfn}
		align $40
		db "MOS"
		db 0 ; version
		db 0 ; ADL disabled
mend

macro putbuf start,end
		ld hl,{start}
		ld bc,{end}-{start}
		xor a
		rst.lis 0x18
mend

macro puts msg
		jr @over_msg	
	@msg:
		db {msg}
		db 0
	@over_msg:
		ld hl,@msg
		ld bc,0
		xor a
		rst.lis $18
mend

macro putc chr
		ld a,{chr}
		rst.lis $10
mend

macro col_red
		putc 17 : putc 1
mend

macro col_green
		putc 17 : putc 2
mend

macro col_white
		putc 17 : putc 15
mend
