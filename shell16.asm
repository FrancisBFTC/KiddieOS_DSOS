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

; VARIAVEIS PARA ROLAGEM DO EDITOR
CursorRaw 	db 5
CursorCol 	db 12
LimitCursorBeginX 	db 0
LimitCursorFinalY 	db 22

; VARIAVEIS DE ACESSO DE PASTAS
CounterAccess 	db 0x0001
Quant 			db 0
CmdWrite 		db 0
QuantDirs 		db 0

; STRINGS DE COMANDOS
SaveAddressString 	dw 0x0000

; BUFFER DE TECLAS E ARGUMENTOS
BufferKeys 	times 60 db 0
BufferArgs 	times 60 db 0

StatusArg 		db 0
CounterChars	db 0

SavePointerArgs 	dw 0x0000

; INTERFACE INICIAL DO SHELL
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
	
; IMPRIME INFORMAÇÕES DO SHELL
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
	call 	Cursor.CheckToRollEditor
	mov 	bx, word[CounterAccess]
	add 	dl, bl
	add 	dl, 3
	cmp 	byte[Quant], 0
	jna 	Print_Access
	inc 	dl
Print_Access:
	mov 	byte[LimitCursorBeginX], dl
	mov 	si, LetterDisk
	call 	Print_String
	mov 	si, FolderAccess
	call 	Print_String
	mov 	si, SymbolCommands
	call 	Print_String
	
	; Set Cursor Shape
	call 	Show_Cursor
	call 	VerifyToWrite
	cmp 	byte[CmdWrite], 1
	je 		Shell_Editor2
	
; IMPLEMENTAÇÃO DA CLI (COMMAND LINE INTERFACE)
Shell_Editor:
	mov 	di, BufferKeys
	mov 	word[SaveAddressString], di
	call 	Reset_Buffer
	Shell_Editor2:
		mov 	byte[CmdWrite], 0
		mov 	di, BufferArgs
		mov 	word[SavePointerArgs], di
		call 	Reset_Buffer
		mov 	di, BufferKeys
		mov 	si, Vector.CMD_Names
		push 	di
		mov 	di, word[SaveAddressString]
		Start:
			mov 	ah, 00h
			int 	16h
			cmp 	al, 0x08
			je 		CheckBackspace
			cmp 	al, 0x0D
			je 		Shell_Interpreter
			cmp 	al, 0x1B
			je 		List_Commands
			cmp 	ah, 0x3B
			je 		ChangeLayout1
			cmp 	ah, 0x3C
			je 		ChangeLayout2
			cmp 	ah, 0x3D
			je 		ChangeLayout3
			cmp 	ah, 0x3E
			je 		ChangeLayout4
			cmp 	ah, 0x3F
			je 		ChangeLayout5
			cmp 	ah, 0x40
			je 		ChangeLayout3
			cmp 	ah, 0x50
			je 		RollEditorToUp
			cmp 	ah, 0x48
			je 		RollEditorToDown
			cmp 	al, 0x20
			je		AltStatusArg
			jmp 	SaveChar
		AltStatusArg:
			mov 	byte[StatusArg], 1
			mov 	ah, 0eh
			int 	10h
			push 	di
			push 	ds
			pop 	es
			mov 	di, word[SavePointerArgs]
			stosb
			mov 	word[SavePointerArgs], di
			pop 	di
			jmp 	SaveReturn
		SaveChar:
			mov 	ah, 0eh
			int 	10h
			push 	di
			push 	ds
			pop 	es
			mov 	di, word[SavePointerArgs]
			stosb
			mov 	word[SavePointerArgs], di
			pop 	di
			mov 	bl, al
			cmp 	bl, "."
			je 		CreateSpaceFile
			cmp 	bl, "/"
			je 		IncQuantDirs
			cmp 	bl, 0x60
			ja 		Conversion2
			cmp 	bl, 0x40
			ja 		Conversion1
			cmp 	bl, 0x29
			ja 		ConvertNumber
			jmp 	SaveReturn
			
		IncQuantDirs:
			inc 	byte[QuantDirs]
			
		SaveReturn:
			stosb
			cmp 	byte[StatusArg], 1
			jne 	Start
			inc 	byte[CounterChars]
			jmp 	Start
	
; FUNCIONALIDADES DA CLI	
	CheckBackspace:
		call 	Get_Cursor
		cmp 	dl, byte[LimitCursorBeginX]
		je 		Start
		dec 	word[SavePointerArgs]
		dec 	di
		; call 	EraseSpaceFile
		mov 	byte[di], 0
		mov 	ah, 0eh
		int 	10h
		mov 	al, [di]
		int 	10h
		mov 	al, 0x08
		int 	10h
		cmp 	byte[StatusArg], 1
		jne 	Start
		dec 	byte[CounterChars]
		jmp 	Start
	
	Shell_Interpreter:
		jmp 	Start
	
	List_Commands:
		jmp 	Start
		
	ChangeLayout1:
		jmp 	Start
		
	ChangeLayout2:
		jmp 	Start
		
	ChangeLayout3:
		jmp 	Start
		
	ChangeLayout4:
		jmp 	Start
		
	ChangeLayout5:
		jmp 	Start
		
	RollEditorToUp:
		mov 	ah, 06h
		call 	RollingEditor
		jmp 	Start
		
	RollEditorToDown:
		mov 	ah, 07h
		call 	RollingEditor
		jmp 	Start
			
	CreateSpaceFile:
		jmp 	Start
		
	EraseSpaceFile:
		jmp 	Start
		
	Conversion1:
		jmp 	Start
		
	Conversion2:
		jmp 	Start
		
	ConvertNumber:
		jmp 	Start


VerifyToWrite:
	cmp 	byte[CmdWrite], 1
	jne 	RetWrite
	mov 	si, word[SaveAddressString]
	call 	Print_String
	mov 	word[SaveAddressString], di
RetWrite:
	ret
	
Cursor.CheckToRollEditor:
	pusha
	mov 	dh, byte[CursorRaw]
	cmp 	dh, byte[LimitCursorFinalY]
	ja 		RollEditor
	mov 	dl, byte[CursorCol]
	call 	Move_Cursor
	jmp 	RetCheck
RollEditor:
	mov 	ah, 06h
	call 	RollingEditor
	mov 	dh, byte[LimitCursorFinalY]
	mov 	byte[CursorRaw], dh
	mov 	dl, byte[CursorCol]
	call 	Move_Cursor
RetCheck:
	popa
	mov 	dl, byte[CursorCol]
ret

RollingEditor:
	pusha
	mov 	al, 1
	mov 	bh, [Backeditor_Color]
	mov 	cx, 0x050C
	mov 	dx, 0x1643
	int 	10h
	popa
ret

Reset_Buffer:
	pusha
	mov 	cx, 60
	Reset:
		mov 	byte[di], 0
		inc 	di
		loop 	Reset
	popa
ret
		
		
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
		
		
		