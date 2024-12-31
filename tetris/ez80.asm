macro rst.lis num
		db $49 : rst {num}
mend

macro ret.lis
		db $49 : ret
mend

macro lil
		db $5b
mend

macro sis
		db $40
mend

macro call.sis l
		sis : call {l}
mend
