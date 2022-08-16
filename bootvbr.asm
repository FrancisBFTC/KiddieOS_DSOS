[BITS 16]
[ORG 0x0000]

TOTALSECTORS      EQU   0x00EE2000
TRACK_PER_HEAD    EQU   971
NUM_HEADS         EQU   255
SECTORS_PER_TRACK EQU   63

jmp Boot_Begin

BUFFER_NAME    db "MSDOS5.0"   ; <- compatibilidade
BPB:
	BytesPerSector      dw 0x0200  ; <- 512 bytes por setor
	SectorsPerCluster   db 1       ; <- Setores por cada cluster
	ReservedSectors     dw 4       ; <- Setores reservados + setores escondidos
	TotalFATs           db 2       ; <- Fat original + a sua cópia
	MaxRootEntries      dw 0x0200  ; <- 512 entradas de diretórios
    TotalSectorSmall    dw 0x0000 ; <- Cilindros x Setores (FAT16)
	MediaDescriptor     db 0xF8    ; <- Tipo de mídia Disquete
    SectorsPerFAT       dw 246     ; <- Setores por FAT
	SectorsPerTrack     dw SECTORS_PER_TRACK      ; <- Setores por trilha
	NumHeads            dw NUM_HEADS     ; <- Quantidade de cabeçotes
	HiddenSectors       dd 0x00000003    ; <- Setores escondidos
	TotalSectorsLarge   dd TOTALSECTORS  ; <- Setores largos (FAT32)
EBPB:
	DriveNumber         db 0x00        ; <- Primeira ordem de Boot
	Flags               db 0x00        ; <- Reservado para o Windows NT
	Signature           db 0x28        ; <- Assinatura
	BUFFER_VOLUME_ID    dd 0x00000000  ; <- ID do Volume/partição
	VolumeLabel         db "KIDDIEOS   "   ; <- Label do disco
	SystemID            db "FAT16   "      ; <- Tipo de sistema de arquivos
	
DAPSizeOfPacket    db 10h
DAPReserved        db 00h
DAPTransfer        dw 0001h
DAPBuffer          dd 00000000h
DAPStart           dq 0000000000000000h 

DATASTART    DW  0x0000
FATSTART     DW  0x0000
ROOTDIRSTART EQU (BUFFER_NAME)
ROOTDIRSIZE  EQU (BUFFER_NAME+4)

BAD_CLUSTER      EQU 0xFFF7
END_OF_CLUSTER1  EQU 0xFFF8
END_OF_CLUSTER2  EQU 0xFFFF
FCLUSTER_ENTRY   EQU 0x001A
FSIZE_ENTRY      EQU 0x001C
ROOT_SEGMENT     EQU 0x07C0
FAT_SEGMENT      EQU 0x17C0
KERNEL_SEGMENT   EQU 0x0800
DIRECTORY_SIZE   EQU 32
EXT_LENGTH       EQU 3
NAME_LENGTH      EQU 8

Extension 	  db "OSF"  ; Operating System File
ClusterFile   dw 0x0000
FileFound     db 0
	
Boot_Begin:
	cli
	mov 	ax, ROOT_SEGMENT
	mov 	ds, ax
	mov 	es, ax
	mov 	ax, 0x0000
	mov 	ss, ax
	mov 	sp, 0x6000
	sti
	
	mov 	byte[DriveNumber], dl
	mov 	ax, 02h
	int 	0x10
	
	call 	LoadRootDirectory
	call 	LoadFAT
	call 	SearchFile
	mov 	dl, byte[DriveNumber]
	
	jmp 	KERNEL_SEGMENT:0x0000
	
LoadRootDirectory:
	; InicioDoFat = SetoresReservados + SetoresEscondidos
	xor 	cx, cx
	mov 	ax, word[ReservedSectors]
	add 	ax, word[HiddenSectors]
	mov 	word[FATSTART], ax      ; InicioDoFat = 7
	
	; TamanhoDiretorioRaiz = (TamanhoEntradaDiretorios x QuantidadeEntradas) / BytesPorSetor
	mov 	ax, DIRECTORY_SIZE
	mul 	word[MaxRootEntries]
	div 	word[BytesPerSector]
	mov 	word[ROOTDIRSIZE], ax
	mov 	cx, ax           ; TamanhoDiretorioRaiz = 32 setores
	
	; InicioDiretorio = (SetoresPorFat x QuantidadeFats) + InicioDoFat
	xor 	ax, ax
	mov 	al, byte[TotalFATs]
	mul 	word[SectorsPerFAT]
	add 	ax, word[FATSTART]   
	mov 	word[ROOTDIRSTART], ax   ; InicioDiretorio = 499
	
	; InicioAreaDados = InicioDiretorio + TamanhoDiretorioRaiz
	push 	ax
	add 	ax, cx
	mov 	word[DATASTART], ax  ; InicioAreaDados = 531
	
	mov 	ax, ROOT_SEGMENT
	mov 	es, ax
	pop 	ax
	
	; Carrega em 0x07C0:0x0200 512 entradas do setor inicial 499
	mov 	bx, 0x0200
	call 	ReadLogicalSectors
ret

LoadFAT:
	mov 	ax, FAT_SEGMENT
	mov 	es, ax
	
	; Carrega em 0x17C0:0x0200 123 Setores do FAT do setor inicial 7
	mov 	ax, word[FATSTART]
	mov 	cx, (246/2)
	mov 	bx, 0x0200
	call 	ReadLogicalSectors
ret

SearchFile:
	mov 	ax, ROOT_SEGMENT
	mov 	es, ax
	mov 	cx, word[MaxRootEntries]
	mov 	di, 0x0200  
	add 	di, NAME_LENGTH
	xor 	bx, bx
_Loop:
	push 	cx
	mov 	cx, EXT_LENGTH
	mov 	si, Extension
	push 	di
	repe 	cmpsb
	pop 	di
	jnz 	ContSearch
	call 	LoadFile
ContSearch:
	pop 	cx
	add 	di, DIRECTORY_SIZE
	loop 	_Loop
	cmp 	byte[FileFound], 0
	je 		BOOT_FAILED
ret

; Carregue arquivos OSF a partir do Endereço 0x0800:0x0000
LoadFile:
	push 	di
	push 	bx
	
	mov 	byte[FileFound], 1
	sub 	di, NAME_LENGTH
	mov 	dx, word[es:di + FCLUSTER_ENTRY]
	mov 	word[ClusterFile], dx
	
	mov 	ax, KERNEL_SEGMENT
	mov 	es, ax
	
	mov 	ax, FAT_SEGMENT
	mov 	gs, ax
	
ReadDataFile:
	pop 	bx
	
	mov 	ax, word[ClusterFile]
	call 	ClusterLBA
	xor 	cx, cx
	mov 	cl, byte[SectorsPerCluster]
	call 	ReadLogicalSectors
	
	push 	bx
	mov 	ax, word[ClusterFile]
	add 	ax, ax
	mov 	bx, 0x0200
	add 	bx, ax
	mov 	dx, word[gs:bx]
	mov 	word[ClusterFile], dx
	
	cmp 	dx, END_OF_CLUSTER1
	je 		End_Of_File
	cmp 	dx, END_OF_CLUSTER2
	je 		End_Of_File
	
	jmp 	ReadDataFile
	
	
End_Of_File:
	pop 	bx
	pop 	di
	
	mov 	ax, ROOT_SEGMENT
	mov 	es, ax
	
	mov 	edx, dword[es:di + (FSIZE_ENTRY - NAME_LENGTH)]
	add 	bx, dx
	add 	bx, 2
ret

ReadLogicalSectors:
		mov word[DAPBuffer], bx
		mov word[DAPBuffer+2], es        ; ES:BX - Para onde os dados vão
		mov word[DAPStart], ax           ; Setor lógico inicial
	_MAIN:
		mov di, 0x0005                   ; 5 tentativas de leitura
	_SECTORLOOP:
		push ax
		push bx
		push cx
		

		push si
		mov ah, 0x42
		mov dl, byte[DriveNumber]
		mov si, DAPSizeOfPacket
		int 0x13
		pop si
		jnc _SUCCESS           ; Testa por erro de leitura
		xor ax, ax             ; BIOS Reset Disk
		int 0x13
		dec di
		
		pop cx
		pop bx
		pop ax
		
		jnz _SECTORLOOP
		jmp BOOT_FAILED
		
    _SUCCESS:
		pop cx
		pop bx
		pop ax
		
		; Desloca para próximo Buffer
		add bx, word[BytesPerSector]
		cmp bx, 0x0000
		jne _NEXTSECTOR
		
		push ax
		mov ax, es
		add ax, 0x1000
		mov es, ax
		pop ax
		
	_NEXTSECTOR:
		inc ax
		mov word[DAPBuffer], bx
		mov word[DAPStart], ax
		loop _MAIN
ret
	
	
	
;Converter cluster FAT em eschema de endereçamento LBA
; LBA = ((NumeroCluster - 2) x SetoresPorCluster) + InicioAreaDados
ClusterLBA:
	sub 	ax, 2
	xor 	cx, cx
	mov 	cl, byte[SectorsPerCluster]
	mul 	cx
	add 	ax, word[DATASTART]
ret
	
BOOT_FAILED:
	int 0x18
	
MBR_SIG:
	TIMES 510 - ($-$$) DB 0
	DB 0x55, 0xAA
	
