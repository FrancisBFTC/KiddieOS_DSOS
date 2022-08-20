%INCLUDE "Hardware/memory.lib"
%INCLUDE "Hardware/kernel.lib"
%INCLUDE "Hardware/info.lib"
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
		mov 	dx, cx
		mov 	byte[CounterList], 0
		mov 	byte[Selection], ch
		mov 	cx, COUNT_COMMANDS
		mov 	si, Vector.CMD_Names
		call 	Write_Info
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
	
Print_Labels:
	mov 	dx, 0x011E 	 ; DH = 01, DL = 30
	call 	Move_Cursor
	mov 	si, NameSystem
	call 	Print_String
Prt_Cmd:
	mov 	dx, 0x0400
	call 	Move_Cursor
	mov 	si, CommandsStr
	call 	Print_String
Prt_Info:
	mov 	dx, 0x0445
	call 	Move_Cursor
	mov 	si, InfoStr
	call 	Print_String
Prt_Help:
	mov 	dx, 0x1701
	mov 	cx, 2
	mov 	si, HelpStr
	call 	Write_Info
Cursor_Commands:
	; TODO: Regras de verificação de Cursor
	mov 	dx, 0x050C
	call 	Move_Cursor
Print_Access:
	; TODO: Salvar limite de Cursor
	mov 	si, LetterDisk
	call 	Print_String
	mov 	si, FolderAccess
	call 	Print_String
	mov 	si, SymbolCommands
	call 	Print_String
	jmp 	$
	
	; TODO: Preparação para Editor do Shell
		
		
NameSystem 	db "KiddieOS Shell ",VERSION,0
CommandsStr db "Commands",0
InfoStr 	db "Information",0
HelpStr:
	db 	"KEY COMMANDS -> ESC : Goto Commands/Editor | UP/DOWN : Select Command |",0
	db  "ENTER : Choose Command | F1,F2,F3,F4,F5,F6 : Update Layouts",0

LetterDisk		db "K:",0
FolderAccess:
	db '\'
	times 150 db 0
SymbolCommands	db ">",0 		


Vector:

	.CMD_Names:
		db "exit"	,0,	"reboot" ,0,	"start"	,0,	"bpb"		,0,	"lf"	,0
		db "clean" 	,0, "read" 	 ,0,	"cd" 	,0, "assign"	,0, "help"  ,0
		db "fat" 	,0, "hex"	 ,0,	"disk"  ,0
	
	.CMD_Funcs:
		times 	13	DW 	0x0000
		COUNT_COMMANDS EQU 	($ - .CMD_Funcs) / 2
		
		
		