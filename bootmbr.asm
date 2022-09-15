[ORG 0x0600]

TOTALSECTORS      EQU   0x00EE2000
TRACK_PER_HEAD    EQU   971
NUM_HEADS         EQU   255
SECTORS_PER_TRACK EQU   63

jmp BootStrap

BUFFER_NAME    db "MSDOS5.0"   ; <- compatibilidade
BPB:
	BytesPerSector      dw 0x0200  ; <- 512 bytes por setor
	SectorsPerCluster   db 1       ; <- Setores por cada cluster
	ReservedSectors     dw 7       ; <- Setores reservados + setores escondidos
	TotalFATs           db 2       ; <- Fat original + a sua cópia
	MaxRootEntries      dw 0x0200  ; <- 512 entradas de diretórios
    TotalSectorSmall    dw 0x0000 ; <- Cilindros x Setores (FAT16)
	MediaDescriptor     db 0xF8    ; <- Tipo de mídia Disquete
    SectorsPerFAT       dw 246     ; <- Setores por FAT
	SectorsPerTrack     dw SECTORS_PER_TRACK      ; <- Setores por trilha
	NumHeads            dw NUM_HEADS     ; <- Quantidade de cabeçotes
	HiddenSectors       dd 0x00000000    ; <- Setores escondidos
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

PartOffset         dw 0x0000    ; <- Offset da partição

BootStrap:
	cli                 ; Desabilitamos as interrupções
	xor ax, ax          ; ax = 0
	mov ds, ax          ; define segmento de dados para 0
	mov es, ax          ; define segmento extra para 0
	mov ss, ax          ; define segmento de pilha para 0
	mov sp, ax          ; define ponteiro de pilha para 0
	.CopyLower:
		mov cx, 0x0100  ; 256 WORDS na MBR
		mov si, 0x7C00  ; Endereço da MBR Atual
		mov di, 0x0600  ; Novo endereço da MBR
		rep movsw       ; Cópia da MBR
		jmp 0:LowStart
		
LowStart:
	sti                          ; Habilita as interrupções
	mov byte[DriveNumber], dl    ; Salvar o Drive de Boot
	.CheckPartitions:
		mov bx, PART1            ; base = Partição 1
		mov cx, 4                ; Há 4 entradas de partições
		.CKPTLoop:
			mov al, byte[bx]     ; Pegar o indicador de boot
			test al, 0x80        ; Verifica o bit ativo (10000000)
			jnz .CKPTFound       ; Nós encontramos a partição ativa
			add bx, 0x10         ; Desloca 16 bytes
			loop .CKPTLoop
			mov ah, 0x0e
			mov al, 'A'
			int 0x10
            jmp ERROR
		.CKPTFound:
			mov word[PartOffset], bx     ; Salve o offset da partição ativa
			add bx, 8                    ; desloque 8 bytes para a LBA Inicial
		.ReadVBR:
			mov EAX, DWORD[bx]           ; Movemos o endereço da LBA inicial
			mov bx, 0x7C00               ; Vamos carregar a VBR para 0x07C0:0x0000
			mov cx, 1                    ; Apenas 1 setor para ler
			call ReadSectors             ; Le este setor
			
			
		.JumpToVBR:
			cmp word[0x7DFE], 0xAA55     ; Verifica se existe assinatura de boot
			jne ERROR                    ; Se não existir, falha de boot
			mov si, word[PartOffset]     ; Define DS:SI Para a partição ativa
			mov dl, byte[DriveNumber]    ; Defina DL para o número de Drive
			jmp 0x7C00                   ; Salte para a VBR no endereço 07C0:0000
			
			
	ReadSectors:
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
		mov dl, 0x80
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
		jmp ERROR
		
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

ERROR:
	int 0x18
				
; Códigos de inicialização

TIMES 0x1BE-($-$$) DB 0

OFFSETL    EQU  3             ; 1536 bytes de deslocamento
LBASIZE    EQU (TOTALSECTORS - (OFFSETL + 1))  ; 0xEE1FFC Tamanho lógico da partição

; Partition Table

;         HCS Inicial   HCS Final     LBA Inicial   LBA Final
PART1:

	FLAG: 		 db 0x80               ; Inicializável
	HCS_BEGIN:   db 0x00, 0x00, 0x03   ;(0, 0, 3)
 	PART_TYPE    db 0x0B               ; Tipo FAT
	HCS_FINAL    db 0xFE, 0xCA, 0xFF   ; (254, 970, 63)
	LBA_BEGIN    dd OFFSETL            ; Deslocamento
   	PART_SIZE    dd LBASIZE            ; Tamanho de setores LBA


; <- Partição 1

PT2    dd 0x00000000,   0x00000000,   0x00000000,   0x00000000   ; <- Partição 2
PT3    dd 0x00000000,   0x00000000,   0x00000000,   0x00000000   ; <- Partição 3
PT4    dd 0x00000000,   0x00000000,   0x00000000,   0x00000000   ; <- Partição 4

MBR_SIGNATURE:

	TIMES 510-($-$$) DB 0
	DW 0xAA55
