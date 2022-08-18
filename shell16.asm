%INCLUDE "Hardware/memory.lib"
%INCLUDE "Hardware/kernel.lib"
[BITS SYSTEM]
[ORG SHELL16]


jmp 	Os_Shell_Setup


; VARIAVEIS DE CORES PADRÕES
Background_Color 	db 0001_1111b	; Blue_White
Borderpanel_Color 	db 0010_1111b 	; Green_White
Backeditor_Color 	db 0000_1111b	; Black_White
Backpanel_Color 	db 0111_0000b 	; Gray_Black

; VARIAVEIS DE POSIÇÕES DE TEXTOS
SavePositionRight 	dw 0x0000
SavePositionLeft 	dw 0x0000

; VARIAVEIS DE SELEÇÃO
CounterList 	db 0
Selection 		db 0


Os_Shell_Setup:
	Back_Blue_Screen:
		mov 	bh, [Background_Color]
		mov 	cx, 0x0000
		mov 	dx, 0x1950 		; DH = 25, DL = 80
		call 	Create_Panel
	Back_Black_Editor:
		mov 	bh, [Backeditor_Color]
		mov 	cx, 0x050C 		; CH = 05, DL = 12
		mov 	dx, 0x1643 		; DH = 22, DL = 67
		call 	Create_Panel
	Back_Green_Left:
		mov 	bh, [Borderpanel_Color]
		mov 	cx, 0x0400 		; CH = 04, CL = 00
		mov 	dx, 0x160B 		; DH = 22, DL = 11
		call 	Create_Panel
	Back_Green_Right:
		mov 	bh, [Borderpanel_Color]
		mov 	cx, 0x0444 		; CH = 04, CL = 68
		mov 	dx, 0x164F 		; DH = 22, DL = 79
		call 	Create_Panel
	Back_White_Left:
		mov 	bh, [Backpanel_Color]
		mov 	cx, 0x0500 		; CH = 05, CL = 00
		mov 	dx, 0x160A 		; DH = 22, DL = 10
		call 	Create_Panel
	List_Commands_Panel:
		mov 	word[SavePositionLeft], cx
		
		; TODO: Listar comandos no painel esquerdo
		; na próxima aula
		
	Back_White_Right:
		mov 	bh, [Backpanel_Color]
		mov 	cx, 0x0545 		; CH = 05, CL = 69
		mov 	dx, 0x164F 		; DH = 22, DL = 79
		call 	Create_Panel
		mov 	word[SavePositionRight], cx
	Back_Bottom_Green:
		mov 	bh, [Background_Color]
		mov 	cx, 0x1800 		; CH = 24, CL = 00
		mov 	dx, 0x1950 		; DH = 25, CL = 80
		call 	Create_Panel
		jmp 	$
		
		
		