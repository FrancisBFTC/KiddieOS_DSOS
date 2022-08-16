%INCLUDE "Hardware/memory.lib"
[BITS SYSTEM]
[ORG KERNEL]

OS_VECTOR_JUMP:
	jmp 	OSMain				; 0000h (Chamado pela VBR)
	jmp 	Print_Name_File		; 0003h
	jmp 	Print_Hexa_Value16  ; 0006h
	jmp 	Print_Hexa_Value8	; 0009h
	jmp 	Print_String 		; 000Ch
	jmp 	Break_Line			; 000Fh
	jmp 	Create_Panel 		; 0012h
	jmp 	Clear_Screen 		; 0015h
	jmp 	Move_Cursor 		; 0018h
	jmp 	Get_Cursor 			; 001Bh
	jmp 	Show_Cursor 		; 001Eh
	jmp 	Hide_Cursor 		; 0021h
	jmp 	Kernel_Menu 		; 0024h
	jmp 	Write_Info 			; 0027h
	jmp 	WMANAGER_INIT 		; 002Ah
	jmp 	Print_Hexa_Value32  ; 002Dh
	jmp 	Print_Dec_Value32 	; 0030h
	jmp 	Print_Fat_Date 		; 0033h
	jmp 	Print_Fat_Time 		; 0036h
	jmp 	END					; 0039h

; _____________________________________________
; Directives and Inclusions ___________________

%INCLUDE "Hardware/monitor.lib"
%INCLUDE "Hardware/disk.lib"
%INCLUDE "Hardware/serial.lib"
%INCLUDE "Hardware/keyboard.lib"
%INCLUDE "Hardware/fontswriter.lib"
%INCLUDE "Hardware/win16.lib"


; _____________________________________________

VetorHexa 	db "0123456789ABCDEF",0
VetorDec 	db "0123456789",0
Zero 		db 0
CursorPos   dw 0

Vector  	dd 16,14,12, 13, 1, 5, 3, 8, 11, 9, 6, 4, 2, 10, 7   ; Vetor Exemplo 3 de tamanho 14
AlgSort 	db 13,10,"++++ RADIXSORT ++++",13,10,13,10,0


; _____________________________________________
; Starting the System _________________________

OSMain:
	cld
	mov 	ax, 0x0800
	mov 	ds, ax
	mov 	es, ax
	mov 	fs, ax
	mov 	gs, ax
	cli 
	mov 	ax, 0x07D0
	mov 	ss, ax
	mov 	sp, 0xFFFF
	sti
	
	; Configura Modo de Texto (80x20)
	mov 	ah, 00h
	mov 	al, 03h
	int 	10h
	
	; Limpa a tela
	mov 	ax, 03h
	int 	10h
	
Kernel_Menu:
	call 	Hide_Cursor
	
	Back_Blue_Screen:
		mov 	bh, 0001_1111b 	; Blue_White
		mov 	cx, 0x0000 		; CH = 0, CL = 0
		mov 	dx, 0x1950 		; DH = 25, DL = 80
		call 	Create_Panel
		
	Dialog_Panel:
		mov 	bh, 0100_1111b  ; Red_White
		mov 	cx, 0x0818 		; CH = 08, CL = 24
		mov 	dx, 0x1038 		; DH = 16, DL = 56
		call 	Create_Panel
		mov 	bh, 0111_0000b  ; White_Black
		mov 	cx, 0x0919 		; CH = 09, CL = 25
		mov 	dx, 0x0F37 		; CH = 15, DL = 55
		call 	Create_Panel
		
	Dialog_Options:
		add 	ch, 2
		add 	cl, 1
		mov 	dx, cx
		mov 	byte[Counter],0
		mov 	byte[Selection],ch
		mov 	bh, 0100_1111b 		; Red_White
		call 	Select_Event
		mov 	word[CursorPos], dx
	Write_Options:
		mov 	dx, word[CursorPos]
		push 	cx
		mov 	cx, QUANT_OPTIONS
		mov 	si, Options_Menu
		call 	Write_Info
		pop 	cx
		jmp 	Select_Options
		
		QUANT_OPTIONS  	EQU 	3
		Options_Menu:
			Option1 	db "Textual Mode    (Shell16.osf)",0
			Option2 	db "Graphical Mode  (winmng.osf)",0
			Option3 	db "System Information",0
			Counter 	db 0
			Selection 	db 0
			Systems 	dw SHELL16_INIT, WMANAGER_INIT, SYSTEM_INFORMATION
		
	Select_Options:
		mov 	ah, 00h
		int 	0x16
		cmp 	ah, 0x50
		je 		IncSelection
		cmp 	ah, 0x48
		je 		DecSelection
		cmp 	al, 0x0D
		je 		RunSelection
		jmp 	Select_Options
		
	RunSelection:
		xor		bx, bx
		mov 	bl, byte[Counter]
		shl 	bx, 1
		jmp 	WORD[Systems + bx]
		
	IncSelection:
		cmp 	byte[Counter], QUANT_OPTIONS-1
		jne 	IncNow
		mov 	byte[Counter], 0
		call 	Erase_Select
		sub 	ch, QUANT_OPTIONS-1
		call 	Focus_Select
		jmp 	Write_Options
	IncNow:
		inc 	byte[Counter]
		call 	Erase_Select
		inc 	ch
		call 	Focus_Select
		jmp 	Write_Options
		
	DecSelection:
		cmp 	byte[Counter], 0
		jne 	DecNow
		mov 	byte[Counter], QUANT_OPTIONS-1
		call 	Erase_Select
		add 	ch, QUANT_OPTIONS-1
		call 	Focus_Select
		jmp 	Write_Options
	DecNow:
		dec 	byte[Counter]
		call 	Erase_Select
		dec 	ch
		call 	Focus_Select
		jmp 	Write_Options
		
		
	Erase_Select:
		mov 	ch, byte[Selection]
		mov 	dh, ch
		mov 	bh, 0111_0000b
		call 	Select_Event
		mov 	ch, byte[Selection]
	ret
	
	Focus_Select:
		mov 	dh, ch
		mov 	byte[Selection], ch
		mov 	bh, 0100_1111b
		call 	Select_Event
	ret
		
	Select_Event:
		push 	dx
		add 	dl, 28
		call 	Create_Panel
		pop 	dx
	ret
		
SYSTEM_INFORMATION:
	mov 	bh, 0010_1111b 	; Green_White
	mov 	cx, 0x0616 		; CH = 06,CL = 22
	mov 	dx, 0x133A 		; DH = 19, DL = 58
	call 	Create_Panel
	mov 	bh, 0111_1010b  ; white_green
	mov 	cx, 0x0717 		; CH = 07, CL = 23
	mov 	dx, 0x1239 		; DH = 18, DL, 57
	call 	Create_Panel
	inc 	ch 				; CH = 08
	inc 	cl 				; CL = 18
	mov 	dx, cx
	mov 	cx, 10
	mov 	si, Informations
	call 	Write_Info
	mov 	ah, 00h
	int 	16h
	jmp 	Back_Blue_Screen
	
	Informations:
		System_Name 	db "System Name  : KiddieOS",0
		Version 		db "Version      : v1.2.0",0
		Author 			db "Author:      : Francis",0
		Arquitecture 	db "Arquitecture : 16-bit (x86)",0
		FileSystem 		db "File System  : FAT16",0
		RunningFile 	db "Running File : kernel.osf",0
		GUIVersion 		db "GUI Version  : Window 2.0",0
		SourceCode 		db "Source Code  : Assembly x86",0
		Lang 			db "Language     : English (US)",0
		DateTime 		db "Date/Time    : 11/08/2022 18:35",0
	
	
SHELL16_INIT:
	mov 	si, string2
	call 	Print_String
	mov 	ah, 00h
	int 	16h
	jmp 	Back_Blue_Screen

string2 db "Shell16 Init",0

WMANAGER_INIT: 
	mov 	si, string3
	call 	Print_String
	mov 	ah, 00h
	int 	16h
	jmp 	Back_Blue_Screen

string3 db "Wmanager Init",0
	

; _____________________________________________
	
; _____________________________________________
; Kernel Functions ____________________________


;GraficInterface:
	;__LoadInterface
	
;	mov word[PositionX], 100
;	mov word[PositionY], 10
;	mov word[W_Width], 120
;	mov word[W_Height], 120
;	mov cx, _WALL
	
;	mov byte[CountField], -1
;	mov byte[QuantTab], 0
	
;Start:
;	WallPaper cx, SCREEN_WIDTH, SCREEN_HEIGHT, 40, 20
;	Window3D MOVABLE, word[PositionX], word[PositionY], word[W_Width], word[W_Height]
;cmp al, 2
;je Start

Print_Fat_Time:
	pusha
	mov 	bx, ax
	xor 	eax, eax
	mov 	ax, bx
	and 	ax, (11111b << 11)
	shr 	ax, 11
	cmp 	al, 10
	jnb 	NoTimeZero1
	push 	ax
	mov 	ax, 0x0E30
	int 	0x10
	pop 	ax
NoTimeZero1:
	call 	Print_Dec_Value32
	mov 	ah, 0x0E
	mov 	al, ':'
	int 	0x10
	mov 	ax, bx
	and 	ax, (111111b << 5)
	shr 	ax, 5
	cmp 	al, 10
	jnb 	NoTimeZero2
	push 	ax
	mov 	ax, 0x0E30
	int 	0x10
	pop 	ax
NoTimeZero2:
	call 	Print_Dec_Value32
	mov 	ah, 0x0E
	mov 	al, ':'
	int 	0x10
	mov 	ax, bx
	and 	ax, 11111b
	cmp 	al, 10
	jnb 	NoTimeZero3
	push 	ax
	mov 	ax, 0x0E30
	int 	0x10
	pop 	ax
NoTimeZero3:
	call 	Print_Dec_Value32
	popa
ret

Print_Fat_Date:
	pusha
	mov 	bx, ax
	xor 	eax, eax
	mov 	ax, bx
	and 	ax, 11111b
	cmp 	al, 10
	jnb 	NoZero1
	push 	ax
	mov 	ax, 0x0E30
	int 	0x10
	pop 	ax
NoZero1:
	call 	Print_Dec_Value32
	mov 	ah, 0x0E
	mov 	al, '/'
	int 	0x10
	mov 	ax, bx
	and 	ax, (1111b << 5)     ;(1111b << 5) = 480 = 111100000b
	shr 	ax, 5
	cmp 	al, 10
	jnb 	NoZero2
	push 	ax
	mov 	ax, 0x0E30
	int 	0x10
	pop 	ax
NoZero2:
	call 	Print_Dec_Value32
	mov 	ah, 0x0E
	mov 	al, '/'
	int 	0x10
	mov 	ax, bx
	and 	ax, (1111111b << 9)
	shr 	ax, 9
	sub 	ax, 20
	add 	ax, 2000
	call 	Print_Dec_Value32
	popa
ret

Print_Name_File:
	pusha
	mov 	cx, 11
	mov 	ah, 0x0E
	mov 	dl, byte[es:di + 11]
	xor 	bx, bx
Analyse:
	mov 	al, byte[es:di]
	cmp 	al, 0x20
	je 		NoPrintSpace
	cmp 	cx, 11
	je 		Display
	cmp 	al, 0x40
	ja 		ConvertCase
	jmp 	Display
ConvertCase:
	cmp 	al, 0x5B
	jnb 	Display
	add 	al, 0x20
Display:
	int 	0x10
NoPrintSpace:
	cmp 	cx, 4
	jne 	NoPrintDot
	cmp 	dl, 0x20
	jne 	NoPrintDot
	mov 	al, '.'
	int 	0x10
NoPrintDot:
	inc 	di
	loop 	Analyse
.DONE:
	popa
ret

Print_Hexa_Value8:
	pusha
	xor 	ah, ah
	mov 	si, ax
	mov 	dx, 0x00F0
	mov 	cl, 4
Print_Hexa8:
	mov 	bx, si
	and 	bx, dx
	shr 	bx, cl
	push 	si
	mov 	ah, 0Eh
	mov 	al, byte[VetorHexa + bx]
	int 	10h
	pop 	si
	cmp 	cl, 0
	jz 		RetHexa1
	sub 	cl, 4
	shr 	dx, 4 
	jmp 	Print_Hexa8
	RetHexa1:
	popa
ret

Print_Hexa_Value16:
	pusha
	mov 	si, ax
	mov 	dx, 0xF000
	mov 	cl, 12
Print_Hexa16:
	mov 	bx, si
	and 	bx, dx
	shr 	bx, cl
	push 	si
	mov 	ah, 0Eh
	mov 	al, byte[VetorHexa + bx]
	int 	10h
	pop 	si
	cmp 	cl, 0
	jz 		RetHexa16
	sub 	cl, 4
	shr 	dx, 4 
	jmp 	Print_Hexa16
	RetHexa16:
	popa
ret

Print_Hexa_Value32:
	pushad
	mov 	esi, eax
	mov 	edx, 0xF0000000
	mov 	cl, 28
Print_Hexa32:
	mov 	ebx, esi
	and 	ebx, edx
	shr 	ebx, cl
	push 	esi
	mov 	ah, 0Eh
	mov 	al, byte[VetorHexa + bx]
	int 	10h
	pop 	esi
	cmp 	cl, 0
	jz 		RetHexa32
	sub 	cl, 4
	shr 	edx, 4 
	jmp 	Print_Hexa32
	RetHexa32:
	popad
ret

Print_Dec_Value32:
	pushad
	cmp 	eax, 0
	je 		ZeroAndExit
	xor 	edx, edx
	mov 	ebx, 10
	mov 	ecx, 1000000000
DividePerECX:
	cmp 	eax, ecx      ; EAX = 950000
	jb 		VerifyZero
	mov 	byte[Zero], 1
	push 	eax
	div 	ecx
	xor 	edx, edx
	push 	ax
	push 	bx
	mov 	bx, ax
	mov 	ah, 0Eh
	mov 	al, byte[VetorDec + bx]
	int 	10h
	pop 	bx
	pop 	ax
	mul 	ecx
	mov 	edx, eax
	pop 	eax
	sub 	eax, edx
	xor 	edx, edx
DividePer10:
	cmp 	ecx, 1
	je 		Ret_Dec32
	push 	eax
	mov 	eax, ecx
	div 	ebx
	mov 	ecx, eax
	pop 	eax
	jmp 	DividePerECX
VerifyZero:
	cmp 	byte[Zero], 0
	je 		ContDividing
	push 	ax
	mov 	ax, 0E30h
	int 	10h
	pop 	ax
ContDividing:
	jmp 	DividePer10
ZeroAndExit:
	mov 	ax, 0E30h
	int  	10h
Ret_Dec32:
	mov 	byte[Zero], 0
	popad
ret

Print_String:
	pusha
	mov 	ah, 0Eh
	Prints:
		mov 	al, [si]
		cmp 	al, 0
		jz 		ret_print
		inc 	si
		int 	10h
		jmp 	Prints
	ret_print:
	popa
ret

Break_Line:
	push 	ax
	mov 	ax, 0x0E0A
	int 	0x10
	mov 	ax, 0x0E0D
	int 	0x10
	pop		ax
ret

Create_Panel:
	pusha
	mov 	ah, 06h
	mov 	al, 0
	int 	10h
	popa
ret

Clear_Screen:
	pusha
	mov 	ah, 06h
	mov 	al, 0
	mov 	ch, 0
	mov 	cl, 0
	mov 	dh, 25
	mov 	dl, 80
	mov 	bh, 0x10  ; 0001_0000
	int 	10h
	popa
ret

Move_Cursor:
	pusha
	mov 	ah, 02h
	mov 	bh, 00h
	int 	10h
	popa
ret

Get_Cursor:
	push ax
	push cx
	push bx
	mov 	ah, 03h
	mov 	bh, 00h
	int 	10h
	pop bx
	pop cx
	pop ax
ret

Show_Cursor:
	pusha
	mov 	ah, 01h
	mov 	ch, 00h
	mov 	cl, 07h
	int 	10h
	popa
ret

Hide_Cursor:
	pusha
	mov 	ah, 01h
	mov 	ch, 20h
	mov 	cl, 07h
	int 	10h
	popa
ret

Write_Info:
	pusha
Write_I:
	call 	Move_Cursor
	call 	Print_String
	call 	NextInfo
	inc 	dh
	loop 	Write_I
	popa
ret

NextInfo:
	inc 	si
	cmp 	byte[si], 0
	jne 	NextInfo
	inc 	si
ret

; ==============================================================
; Rotina que mostra o conteúdo do vetor formatado
; IN: ECX = Tamanho do Vetor
;     ESI = Endereço do Vetor

; OUT: Nenhum.
; ==============================================================
Show_Vector32:
	pushad
	
	mov 	ax, 0x0E7B
	int 	0x10
	xor 	ebx, ebx
	
ShowVector:
	push 	ebx
	shl		ebx, 2
	mov 	eax, dword[esi + ebx]
	call 	Print_Dec_Value32
	pop 	ebx
	inc 	ebx
	mov 	ah, 0x0E
	mov 	al, ','
	int 	0x10
	loop 	ShowVector
	mov 	ax, 0x0E7D
	int 	0x10
	mov 	ax, 0x0E0D
	int 	0x10
	mov 	ax, 0x0E0A
	int 	0x10
	
	popad
ret

; ==============================================================
; Rotina que aloca uma quantidade de bytes e retorna endereço
; IN: ECX = Tamanho de Posições (Size)
;     EBX = Tamanho do Inteiro (SizeOf(int))

; OUT: EAX = Endereço Alocado
; ==============================================================
Calloc:
	pushad
	
	xor 	eax, eax
	;mov 	ax, ds
	;shl 	eax, 4
	mov 	eax, SERIAL
	push 	ecx
	mov 	ecx, SERIAL_NUM_SECTORS
	
	Skip_Offset:
		add 	eax, 512
		loop 	Skip_Offset
		
	add 	eax, 4
	mov 	edi, eax
	xor 	eax, eax
	pop 	ecx
	push 	edi
	
	;mov 	es, ax
	
	cmp 	ebx, 1
	je 		Alloc_Size8
	cmp 	ebx, 2
	je 		Alloc_Size16
	cmp 	ebx, 4
	je 		Alloc_Size32
	jmp 	Return_Call
	
	; TODO 
	; Dados que podem estar na memória serão perdidos
	; nesta alocação, então melhor certificar que salvamos 
	; estes dados em algum lugar (talvez via push)
	; e recuperarmos na função Free()
	Alloc_Size8:  
		mov 	dword[Size_Busy], ecx
		rep 	stosb
		jmp 	Return_Call
	Alloc_Size16: 
		mov 	dword[Size_Busy], ecx
		shl 	dword[Size_Busy], 1
		rep 	stosw
		jmp 	Return_Call
	Alloc_Size32: 
		mov 	dword[Size_Busy], ecx
		shl 	dword[Size_Busy], 2
		rep 	stosd
		jmp 	Return_Call
	
Return_Call:
	pop 	DWORD[Return_Var_Calloc]
	popad
	mov 	eax, DWORD[Return_Var_Calloc]
	mov 	byte[Memory_Busy], 1
ret

Return_Var_Calloc dd 0
Size_Busy 	dd 0
Memory_Busy db 0


; ==============================================================
; Libera espaço dado um endereço alocado
; IN: EBX = Ponteiro de Endereço Alocado
;
; OUT: Nenhum.
; ==============================================================
Free:
	pushad
	mov 	edi, dword[ebx]
	mov 	dword[ebx], 0x00000000
	
	mov 	ecx, dword[Size_Busy]
	rep 	stosb
	
	;push 	ds
	;pop 	es
	
	mov 	dword[Size_Busy], 0
	mov 	dword[Return_Var_Calloc], 0
	mov 	dword[Memory_Busy], 0
	popad
ret


; --------------------------------------------------------
; Inclusões de Sistemas Adicionais

;%INCLUDE "Library/Sort/SortingMethods.inc"
;%INCLUDE "Library/Drv/confpci.asm"

; --------------------------------------------------------


END:
; Zera na reinicialização todos os endereços de memória utilizados
	; ________________________________________________________________
	mov word[POSITION_X], 0000h
	mov word[POSITION_Y], 0000h
	mov word[QUANT_FIELD], 0000h
	mov word[LIMIT_COLW], 0000h
	mov word[LIMIT_COLX], 0000h
	mov word[QuantPos], 0000h
	mov word[CountPositions], 0000h
	mov byte[StatusLimitW], 0
	mov byte[StatusLimitX], 0
	mov byte[CursorTab], 0
	; ________________________________________________________________
	; Reinicia sistema
	; _________________________________________
	mov ax, 0040h
	mov ds, ax
	mov ax, 1234h
	mov [0072h], ax
	jmp 0FFFFh:0000h
; _____________________________________________
; _____________________________________________

