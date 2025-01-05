; keystate bits:
; 0 - left, 1 - right, 2 - up, 3 - down
keystate: 	db 0
moved_down: db 0
score:  	ds 2
board:		ds sizeof_Board
tet:		ds sizeof_Shape
tetpos:		ds 2	; x,y
