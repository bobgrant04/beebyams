
\ extended file information
\Usage EFI <fsp> (<drv>) (<dno>/<dsp>)
INCLUDE "VERSION.asm"
INCLUDE "SYSVARS.asm"			; OS constants
INCLUDE "BEEBINTS.asm"			; A% to Z% as a ... z
\INCLUDE "TELETEXT.asm"

__DEBUG = TRUE

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
ORG &6800
GUARD &7C00

.start
\------------------------------------------------------
\setup for OSARGS
__OSARGSinit = TRUE
__OSARGSargXtoOSARGSStrLenA = TRUE
__OSARGSargGetDrive = TRUE
__OSARGSFileNameToOSARGSPram = TRUE
__OSARGSOptions = TRUE
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
\-------------------------------------------------------
INCLUDE "OSARGS.ASM"
\-------------------------------------------------------
__MAGICHELPPRINT = TRUE
__MAGICHELPPRINTSELECTED =TRUE
MAGICHELPAptr = Aptr
MAGICHELPload%=load%
MAGICHELPexe%=exe%
MAGICHELPPrintType% = Printtype%
\-------------------------------------------------------
INCLUDE "MAGIC_SOURCE.asm"		\magic configuration
INCLUDE "MAGICHELP.ASM"

\Get input 
	IF __DEBUG
		.gti
		{
		LDA #OSBYTEReadCharacterFromBuffer%
		LDX #OSBYTEXKeyboardBuffer%
		JSR OSBYTE
		BCS gti \no character
		RTS
		}
	ENDIF	
		.getcurrentdrive
		{
		\see https://stardot.org.uk/forums/viewtopic.php?p=30012&hilit=assembler+selected+drive#p30012
		\lDA #OSGBPBGetLibraryName%
		\LDX #LO(conb)
		\LDY #HI(conb)
		\JSR OSGBPB
		\Hack
		LDA OScurrentDrive%
		CLC
		ADC #'0'
		IF __DEBUG
			{
			LDA OScurrentDrive%
			CLC
			ADC #'0'
			JSR OSASCI
			LDX #&FF
			.aa
			INX
			LDA debugtext,X
			JSR OSASCI
			CMP #&D
			BNE aa
			BEQ ab
			.debugtext
			EQUS " = Currentdrive "
			EQUB &D
			.ab
			JSR gti
			}
		ENDIF
		\LDA osgbpbdata%+1
		LDA OScurrentDrive%
		CLC
		ADC #'0'		
		RTS \RTS
		}
		.setrequesteddrive
		{
		LDX #dricmd%
		JSR initprepcmd
		LDA RequestedDrive%
		STA strA%+3
		JMP execmd \RTS
		}
		
		.execmd
		{
		IF __DEBUG
			{
			LDY #&FF
			.aa
			INY
			LDA strA%,Y
			JSR OSASCI
			CMP #&D
			BNE aa
			JSR gti 
			}
		ENDIF
		LDY #HI(strA%)
		LDX #LO(strA%)
		JMP OSCLI \RTS
		}
		
		.initprepcmd
		{
		LDA #0
		STA strAoffset 
		}
		.prepcmd
		{
		JSR MoveToRec
		LDX strAoffset
		LDY #0
		.ey
		LDA (TextAdd),Y
		CMP #&80
		BCC am
		AND #&7F
		STA strA%,X
		INX
		STX strAoffset
		LDA #&D
		STA strA%,X
		RTS
		.am
		STA strA%,X
		INX
		INY
		BNE ey
		}
		.diserror
		{
		JSR MoveToRec
		JMP PrintRecord
		}
		.PrintRecord
		{
		LDY #0
		.bc
		LDA (TextAdd),Y
		CMP #&80
		BCC bd
		AND #&7F
		JMP OSASCI \RTS
		RTS
		.bd
		JSR OSASCI
		INY
		BNE bc
		}
		.MoveToRec
		{
		LDA #LO(CommandAndText)
		STA TextAdd
		LDA #HI(CommandAndText)
		STA TextAdd+1
		LDY #0
		.ba
		DEX
		BNE bb
		RTS
		.bb
		LDA (TextAdd),Y
		INY
		CMP #&80
		BCC bb
		CLC
		TYA
		ADC TextAdd
		STA TextAdd
		LDA #0
		ADC TextAdd+1
		STA TextAdd+1
		LDY #0
		BEQ ba
		}

		.Nocommands
		LDX #usage%
		JMP diserror
\---------------------------		
		.startexec
\---------------------------		
		{
		\set current drive
		JSR getcurrentdrive
		STA RequestedDrive%
		JSR OSARGSinit
		\ X has no of arguments
		\as has OSARGSNoofArgs%
		CPX #1
		BCC Nocommands
		JSR OSARGSFileNameToOSARGSPram
		LDX OSARGSNoofArgs%
		CPX #2
		BCC Justfilename
		JSR OSARGSGetDrive \parm 2
		LDX OSARGSNoofArgs%
		CPX #3
		\issues din cmd
		LDX #dincmd%
		JSR initprepcmd
		LDX #2
		JSR OSARGSargXtoOSARGSStrLenA
		LDX #3
		JSR OSARGSargXtoOSARGSStrLenA
		LDX strAoffset
		\DEX
		LDA #&D
		STA strA%,X 
		JSR execmd
		.Justfilename
		JSR setrequesteddrive
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
		}
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
		JMP MAGICHELPPRINT
		
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