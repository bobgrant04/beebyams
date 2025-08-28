
\ extended file information
\Usage EFI <fsp> (<drv>) (<dno>/<dsp>)
INCLUDE "VERSION.asm"
INCLUDE "SYSVARS.asm"			; OS constants
INCLUDE "BEEBINTS.asm"			; A% to Z% as a ... z
\INCLUDE "TELETEXT.asm"

__DEBUG = FALSE

\IntA &2A -&2D
len =&2A
\&2E TO &35 basic float
strptr=&2E
Aptr=&30
exeadd=&32
erradd=&34
\&3B to &42 basic float
\single bytes
TextAdd=&3B
NoofArgs%=&3C
strAoffset = &3D
tempy%=&3E
pramlen =&3F
Printtype% = &40
RequestedDrive%=&41
\NoofArgs% =&40
\matchlen=&3C
\tempx=&3D
\ypush=&3E
\highestbyte=&3F
\noofbytes=&40
\quiet =&41
\basic=&42

blockstart=&70
load%=blockstart+2
exe%=blockstart+6
length%=blockstart+&A
Locked%= blockstart+&E

\&600 String manipulation
\osgbpbdata%=&600
\WORKINGStrA=&650
shortcode=&640
strA%=&6B0\
\strB%=&690
pram%=&6D0 \strB%
filename%=&6D0
options% =&6F0
ORG &7000
GUARD &7C00

.start
\------------------------------------------------------
\setup for OSARGS
__OSARGSinit = TRUE
__OSARGSargXtoOSARGSStrLenA = TRUE
__OSARGSargGetDrive = TRUE
__OSARGSFileNameToOSARGSPram = TRUE
__OSARGSOptions = FALSE
\Variables - 
OSARGSstrA =strA%
OSARGSStrLenA = strAoffset
OSARGStempY = tempy%
OSARGSrequesteddrive = RequestedDrive%
OSARGSpram% = pram%
\OSARGSpramlen% = pramlen
OSARGSNoofArgs% = NoofArgs%
IF __OSARGSOptions
	OSARGSOptions% = options%
ENDIF
\needs following routines 
\		initprepcmd
\		prepcmd - part of initprepcmd
\		MoveToRec
\		PrintRecord
\		diserror
\		execmd
\		setrequesteddrive
\		getcurrentdrive
\		gti	- needed for __debug
\needs following in data section
\.CommandAndText
\&80 terminated with last character added to &80
\	dricmd%=1 --can alter if required
\\		EQUS"DR. ",&8D
\	dincmd%=2  --can alter if required
\\		EQUS"DIN",' '+&80
\	usage%=3 --can alter if required
\\ 		EQUS"Usage <fsp> (<drv>) (<dno>/<dsp>)",&80+&D --edit as needed

\-------------------------------------------------------
INCLUDE "OSARGS.ASM"
\-------------------------------------------------------
__MAGICHELPPRINT = TRUE
__MAGICHELPPRINTSELECTED =TRUE
MAGICHELPAptr = Aptr
MAGICHELPload%=load%
MAGICHELPexe%=exe%
IF __MAGICHELPPRINTSELECTED
	MAGICHELPPrintType% = Printtype%
ENDIF
\-------------------------------------------------------
INCLUDE "MAGIC_SOURCE.asm"		\magic configuration
INCLUDE "MAGICHELP.ASM"
INCLUDE "command args.asm"
\start ends here!
\ok so end of standard select stuff
		LDA #HI(pram%)
		STA blockstart+1
		LDA #LO(pram%)
		STA blockstart
		LDX #blockstart
		LDY #0
		LDA #OSFILEReadFileInfo%
		JSR OSFILE
		CMP #OSFILEReturnFileFound%
		BEQ ok
		LDX #notfound%
		JSR diserror
		LDX #usage%
		JMP diserror
		.ok
		\Now have file information
		\lets print
		{
		LDA load%+1
		JSR PrHex
		LDA load%
		JSR PrHex
		LDX #loadAddress%
		JSR diserror
		LDA exe%+1
		JSR PrHex
		LDA exe%
		JSR PrHex
		LDX #executionAddress%
		JSR diserror
		LDA length%+1
		JSR PrHex
		LDA length%
		JSR PrHex
		LDX #filelength%
		JSR diserror
		LDX #Fileis%
		JSR diserror
		LDA Locked%
		LDX #FileLocked%
		CMP #OSFILELocked%
		BEQ aa
		LDX #FileUnLocked%
		.aa
		JSR diserror
		}
		\now need to see if it matches magic...
		LDA #MAGICHELPMatchEitherLoadOrExe
		JMP MAGICHELPPRINT \RTS
		
		\LDA #MAGICHELPMatchexe
		\LDA #MAGICHELPMatchLoad
		\LDA #MAGICHELPFullprint
		\LDA #MAGICHELPFullprint
		\JMP MAGICHELPPRINT







	
		
\---------------------------------
\ Data
\---------------------------------
\---------------------------------
.CommandAndText
\&80 terminated with last character added to &80
	dricmd%=1
		EQUS"DR. ",&8D
	dincmd%=2
		EQUS"DIN",' '+&80
	usage%=3
		EQUS"Usage <fsp> (<drv>) (<dno>/<dsp>)",&80+&D
	notfound%=4
		EQUS"file not found",&80+&D
	StartHelp%=5
		EQUS" EXE Load Adress",&80+&D
	MagicNotFound%=6
		EQUS"Special exe add not code",&E4
	loadAddress%=7
		EQUS" = Load Address",&80+&D
	executionAddress%=8
		EQUS" = Execute Address",&80+&D
	filelength%	=9
		EQUS" = File length",&80+&D
	Fileis%	=10
		EQUS"File is",&80+' '
	FileLocked% =11
		EQUS"Locked",&80+&D
	FileUnLocked% = 12
		EQUS"Unlocked",&80+&D
		
\should not be here
\drop through to screencheck
.end
SAVE "EFI", start, end,startexec



\cd D:\GitHub\beebyams\beebasm
\beebasm -i .\EFI\EFI.asm -do .\EFI\EFI.ssd -boot EFI -v -title EFI

\cd C:\GitHub\beebyams\beebasm


\ ./tools/beebasm/beebasm.exe -i ./EFI.asm -do ./build/EFI.ssd -boot EFI -v -title EFI