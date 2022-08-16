[BITS 16]

.Cookie:
	db 'conectix'
.Features:
	dd 0
.PlatFormVersion:
	dd 0x00001000
.DataOffset:
	dd 0xFFFFFFFF, 0xFFFFFFFF
.TimeStamp:
	dd 0x5868091E
.CreatorApp:
	dd 0x61766D6A
.CreatorVersion:
	dd 0x0A000400
.CreatorOS:
	dd 0x6B326957
.OriginalSize:
	dd 1,0xDC300000
.CurrentSize:
	dd 1,0xDC300000
.DiskGeometry:
	dw 971            ; Cilindros
	db 255            ; Cabeçote
	db 63             ; Setores
.DiskType:
	dd 0x02000000     ; Fixed = 0x02000000, Dinamic = 0x03...., Differencing = 0x04...
.CheckSum:
	dd 0xC2E7FFFF     ; Igual ou acima de 32 MB partição
.UniqueID:
	db 0x10, 0x80, 0xF0, 0x60   ; {88888888-8888888-446595D4-62F38111}
	db 0xD0, 0x95, 0x65, 0x44   ; 60f08010-95d0-4465
	db 0x88, 0x88, 0x88, 0x88
	db 0x88, 0x88, 0x88, 0x88  
.SaveState:
	db 0
.Reserved:
	TIMES 427 db 0