
\gfi GET FILE INFORMATION
\Usage <fsp> (<dno>/<dsp>) (<drv>)"
\Usage <fsp> (<dno>/<dsp>) (<drv>)
\RETURNS l% = LOAD , e% = EXECUTION, S% = LENGTH
\RETURNS ZERO IN l%, e%, n% ON FAIL
\Outputs E% execution L% load address  N% = length
\Usage GFI (|Q) <fsp> (<drv>) (<dno>/<dsp>)"

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
OptionBit%=&42

blockstart=&70
load%=blockstart+2
exe%=blockstart+6
size%=blockstart+&A
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
ORG &900
GUARD &C00

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
	OSARGSbitOptions% = OptionBit%
ENDIF
\constants
OSARGSbitOptionQuiet% = 1
OSARGSbitOptionVerbose% =2
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
\__MAGICHELPPRINT = TRUE
\__MAGICHELPPRINTSELECTED =TRUE
\MAGICHELPAptr = Aptr
\MAGICHELPload%=load%
\MAGICHELPexe%=exe%
\IF __MAGICHELPPRINTSELECTED
\	MAGICHELPPrintType% = Printtype%
\ENDIF
\-------------------------------------------------------
\INCLUDE "MAGIC_SOURCE.asm"		\magic configuration
\INCLUDE "MAGICHELP.ASM"
INCLUDE "command args.asm"
\start ends here!
\ok so end of standard select stuff
		\clear E%,L%:S%
		{
		LDX #(('E'-'A')*4)
		JSR clearint
		LDX #(('L'-'A')*4)
		JSR clearint
		LDX #(('S'-'A')*4)
		JSR clearint
		}
		.fileinfo
		{
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
		{
		LDA load%
		STA l
		LDA load%+1
		STA l+1
		LDA size%
		STA s:
		LDA size%+1
		STA s+1
		LDA exe%
		STA e
		LDA exe%+1
		STA e+1
		RTS
		}
		.clearint
		{
		LDA #0
		LDY #3
		.dx
		STA a,X
		INX
		DEY
		BPL dx
		RTS
		}
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
		EQUS "Usage (|Q) <fsp>(<drv>)(<dno>/<dsp>)",&D
		EQUS "O/P E% exe L% load  N% length",&D
		EQUS "Zero = fail",&8D
	notfound%=4
		EQUS"file not found",&80+&D
.end
SAVE "GFI", start, end,startexec

\cd D:\GitHub\beebyams\beebasm
\beebasm -i .\magic\magic.asm -do .\magic\magic.ssd -boot magic -v -title magic
\beebasm -i .\magic\magic.asm -di .\magic\magic-dev.ssd -do .\magic\magic.ssd -v 
\cd C:\GitHub\beebyams


\ ./tools/beebasm/beebasm.exe -i ./GFI.asm -do ./build/GFI.ssd -boot GFI -v -title GFI