ECHO OFF
cls

cd /
cd C:\KiddieOS_DSOS\

setlocal enabledelayedexpansion


set QuantFile=6

set Drive=6

set file1=kernel
set file2=window
set file3=fwriter
set file4=shell16
set file5=serial
set file6=keyboard

set filebin1=Binary\%file1%.osf
set filebin2=Binary\%file2%.osf
set filebin3=Binary\%file3%.osf
set filebin4=Binary\%file4%.osf
set filebin5=Driver\%file5%.drv
set filebin6=Driver\%file6%.drv

set VHD=KiddieOS
set LibFile=Hardware\memory.lib
set ImageFile=DiskImage\%VHD%.vhd
set OffsetPartition=0

del %ImageFile%

set /A nasm=0
set SizeSector=512


set /p Choose="Do you want to reassemble the FAT16 and MBR? (Y\N)"
if %Choose% EQU Y CALL :ReassembleFAT
if %Choose% EQU y CALL :ReassembleFAT

CALL  ::SendFatToVHD

cecho {\n}

:Assembler
	set /a i=i+1
	set "NameVar=filebin%i%"
	set "NameVar1=file%i%"
	call set FileOut=%%%NameVar%%%
	call set MyFile=%%%NameVar1%%%
	cecho {0C}
	if NOT EXIST %MyFile%.asm goto NoExistFile 
	nasm -O0 -f bin %MyFile%.asm -o %FileOut%
	if %ERRORLEVEL% EQU 1 goto BugCode
	cecho {#}
	if %nasm% NEQ 1 (cecho {0B}"%MyFile%" file Mounted successfully!{\n}) else ( cecho {0B}.)
	if %i% NEQ %QuantFile% goto Assembler
	if %nasm% NEQ 0 GOTO:EOF
	

	set i=0
	set Sector=531
	set Segment=0x0800   rem Segmento do kernel
	set Boot=0x7C00      rem Offset do Inicial Bootloader
	set Kernel=0x0000    rem Offset Inicial Do Kernel
	call :AutoGenerator
	
:ReadFile
	set /a i=i+1
	set "NameVar=filebin%i%"
	set "NameVar1=file%i%"
	call set FileOut=%%%NameVar%%%
	call set MyFile=%%%NameVar1%%%
	
	for %%a in (dir "%FileOut%") do set size=%%~za
	cecho {0A}Processing '%MyFile%'

	set /A Counter=1
	set /A NumSectors=1

	for /l %%g in (1, 1, %size%) do (

		if !Counter! == 512 ( 
			set /A Counter=1
			if %i% NEQ 1 set /A NumSectors+=1
			cecho {0A}.
		)
		set /A Counter=Counter+1
	)

set /A "W=0"
	echo.
	

	if %i% == 1 set /A StartAddr=Kernel
	if %i% GEQ 2 set /A StartAddr=FinalAddr+2
	set /A FinalAddr=StartAddr+size
	call :ToHex
	call :WriteDefLib
	
	cecho {0F} SIZE BYTES     = {0D}%size%{#}{\n}
	cecho {0F} INIT SECTOR    = {0D}%Sector%{#}{\n}
	cecho {0F} QUANT. SECTORS = {0D}%NumSectors%{#}{\n}
	cecho {0F} START ADDRESS  = {0D}%StartAddr%{#}{\n}
	cecho {0F} FINAL ADDRESS  = {0D}%FinalAddr%{#}{\n}
	
	set /A Sector+=NumSectors
	
	if %i% NEQ %QuantFile% goto ReadFile
	
	call :WriteEndDef
	call :ReAssembler
	call :VHDCreate
	call :BootFlashDrive
	

	cecho {\n}
	
	echo Which virtual machine do you want to run?
	echo.
	echo 1. KiddieOSUSB
	echo 2. KiddieOSVHD
	echo 0. Nothing
	echo.
	set /p Choose=
	if %Choose% EQU 1 "%programfiles%\oracle\virtualbox\VBoxManage.exe" startvm --putenv VBOX_GUI_DBG_ENABLED=true KiddieOS_USB 
	if %Choose% EQU 2 "%programfiles%\oracle\virtualbox\VBoxManage.exe" startvm --putenv VBOX_GUI_DBG_ENABLED=true KiddieOS_VHD 
	
	cecho {\n}
	goto END
	
:ToHex
set "hex="
set "map=0123456789ABCDEF"
for /L %%N in (1,1,4) do (
   set /a "d=StartAddr&15,StartAddr>>=4"
   for /f %%D in ("!d!") do (
      set "hex=!map:~%%D,1!!hex!"
   )
)
set "StartAddr=0x%hex%"
set "hex="
for /L %%N in (1,1,4) do (
   set /a "d=FinalAddr&15,FinalAddr>>=4"
   for /f %%D in ("!d!") do (
      set "hex=!map:~%%D,1!!hex!"
   )
)
set "FinalAddr=0x%hex%"
GOTO:EOF

:BugCode
	echo.
	echo Fix the Error in the file!
	cecho {0F}
	echo.
	pause
	goto END
	
:NoExistFile
	echo.
	echo The '%MyFile%.asm' File not exist!
	cecho {0F}
	echo.
	pause
	goto END
	
:AutoGenerator
	echo ; =============================================== > %LibFile%
	echo ; AUTO GENERATED FILE - NOT CHANGE! >> %LibFile%
	echo ; >> %LibFile%
	echo ; KiddieOS - Memory Library Routines >> %LibFile%
	echo ; Created by Autogen >> %LibFile%
	echo ; Version 1.0.0 >> %LibFile%
	echo ; =============================================== >> %LibFile%
	echo. >> %LibFile%
	echo %%IFNDEF _MEMORY_LIB_ >> %LibFile%
	echo %%DEFINE _MEMORY_LIB_ >> %LibFile%
	echo. >> %LibFile%
	echo %%DEFINE SYSTEM 16 >> %LibFile%
	echo. >> %LibFile%
	GOTO:EOF
	
:WriteDefLib
	CALL :UpCase MyFile
	echo %%DEFINE !MyFile!             !StartAddr! >> %LibFile%
	echo %%DEFINE !MyFile!_SECTOR      !Sector! >> %LibFile%
	echo %%DEFINE !MyFile!_NUM_SECTORS !NumSectors! >> %LibFile%
	GOTO:EOF
	
:WriteEndDef
	echo. >> %LibFile%
	echo %%ENDIF >> %LibFile%
	echo. >> %LibFile%
	cecho {\n}New "%LibFile%" LIB File Generated{\n}
	GOTO:EOF
		
:UpCase
SET %~1=!%~1:a=A!
SET %~1=!%~1:b=B!
SET %~1=!%~1:c=C!
SET %~1=!%~1:d=D!
SET %~1=!%~1:e=E!
SET %~1=!%~1:f=F!
SET %~1=!%~1:g=G!
SET %~1=!%~1:h=H!
SET %~1=!%~1:i=I!
SET %~1=!%~1:j=J!
SET %~1=!%~1:k=K!
SET %~1=!%~1:l=L!
SET %~1=!%~1:m=M!
SET %~1=!%~1:n=N!
SET %~1=!%~1:o=O!
SET %~1=!%~1:p=P!
SET %~1=!%~1:q=Q!
SET %~1=!%~1:r=R!
SET %~1=!%~1:s=S!
SET %~1=!%~1:t=T!
SET %~1=!%~1:u=U!
SET %~1=!%~1:v=V!
SET %~1=!%~1:w=W!
SET %~1=!%~1:x=X!
SET %~1=!%~1:y=Y!
SET %~1=!%~1:z=Z!
GOTO:EOF

:ReAssembler
	set i=0
	set /A nasm=1
	echo.
	cecho {0B}Remounting Binary Files.
	call :Assembler
	
:: Algumas coisas serão feitas aqui no futuro

	cecho {\n}
	cecho {0A}%i% Binary Files remounted successfully{\n\n}
	cecho {0F}
	GOTO:EOF


:VHDCreate
	cecho {0A}Mounting VHD File...{\n}
	cecho {0B}
	imdisk -a -f %ImageFile% -s 33554432 -m W:
	set i=0
	
	:Creating
		set /a i=i+1
		set "Var1=filebin%i%"
		set "Var3=file%i%"
		call set BinFile=%%%Var1%%%
		call set Bin=%%%Var3%%%
		
		cecho {0B}Adding '%Bin%' to the VHD file{\n}
		copy %BinFile% W:
		
		if %i% NEQ %QuantFile% goto Creating
		
		xcopy /I /E KiddieOS W:\KiddieOS
		
		cecho {0A}Dismounting VHD File... {\n}
		cecho {0B}
		imdisk -D -m W:
		
		cecho {0A}{\n}The '%VHD%.vhd' was created successfully!{\n\n}
GOTO:EOF


:ReassembleFAT
	cecho {0B} Assembling FAT16 and MBR...{\n}
	nasm -O0 -f bin -o Binary\bootmbr.osf bootmbr.asm
	nasm -O0 -f bin -o Binary\bootvbr.osf bootvbr.asm
	nasm -O0 -f bin -o Binary\FAT.osf FAT.asm
	nasm -O0 -f bin -o Binary\footvhd.osf footvhd.asm
	nasm -O0 -f bin -o Binary\volume.osf Volume.asm
GOTO:EOF

:SendFatToVHD
	cecho {0B} Sending FAT16 and MBR into VHD...{\n}
	dd count=2 seek=0 bs=512 if=Binary\bootmbr.osf of=%ImageFile%
	dd count=2 seek=3 bs=512 if=Binary\bootvbr.osf of=%ImageFile%
	dd count=2 seek=7 bs=512 if=Binary\FAT.osf of=%ImageFile%
	dd count=2 seek=499 bs=512 if=Binary\volume.osf of=%ImageFile%
	dd count=2 seek=65535 bs=512 if=Binary\footvhd.osf of=%ImageFile%
	cecho {0A} Done! {\n}
	cls
GOTO:EOF
	

:BootFlashDrive
	
	cecho {0B}Writing system in Disk (Drive %Drive%) ...{\n}
	rmpartusb drive=%Drive% filetousb file="%ImageFile%" filestart=0 length=33.554.432 usbstart=%OffsetPartition%
	cecho {0A}The System was written successfully{\n\n}
	cecho {0F}
GOTO:EOF

:END