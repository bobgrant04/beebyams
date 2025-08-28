
\alter used to alter exe and or load address
\Usage <fsp> (<dno>/<dsp>) (<drv>)
INCLUDE "VERSION.asm"
INCLUDE "SYSVARS.asm"			; OS constants
INCLUDE "BEEBINTS.asm"			; A% to Z% as a ... z

__DEBUG = TRUE
\…Variables
\NoSpecials%=1:\"offset from 1
\EndSpecial%=&FF-NoSpecials%
\ZERO page
\IntA &2A -&2D
TextAdd=&2A
Aptr=&2C
\&2E TO &35 basic float
trueadd=&2E
loadadd=&30
exeadd=&32
erradd=&34
\&3B to &42 basic float
\single bytes
filesize=&3B
NoofArgs% = &3C
tempx=&3D
switch=&3E
basic=&3F
tempy%=&40
strAoffset = &41
RequestedDrive% =&42
\&70 to &8F reserved for 
blockstart=&70:load%=blockstart+2:exe%=blockstart+6:size=blockstart+&A
cat=&72
codestart=&70
zz=&8E
\&F8-F9 UNUSED BY OS
\end zero page


\&600 String manipulation
strA%=&6A0
pram%=&610
options% =&6F0
\&A00 RS232 & cassette
\&1100-7C00 main mem
\conb=&5000 :\control block for reading disk
\rawdat=&6000:\output for file read
\countpg=&6100:\page for count's
\os calls


ORG &7000
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
OSARGStempy% = tempy%
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
\ notfound% = 4--can alter if required
\		EQUS"file not found",&8D
\-------------------------------------------------------
INCLUDE "OSARGS.ASM"
\-------------------------------------------------------
__MAGICHELPPRINT = TRUE
__MAGICHELPPRINTSELECTED = FALSE
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
\we have drive set / filename in pram
\"Process filename
		.startprocesswithfile
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
		JSR diserror
		JMP MAGICHELPPRINT
		.ok
		}

		\have L% for load ADD and E% for EXE address
		.loadaddress
		CLC
		LDA l 
		ADC l+1
		BEQ noload
		LDA #OSFILEUnLocked% \unlock
		JSR lock
		LDA l
		STA blockstart+2
		LDA l+1
		STA blockstart+3
		LDA l+2
		STA blockstart+4
		LDA l+3
		STA blockstart+5
		LDX #blockstart
		LDY #0
		LDA #OSFILEWriteLoadAddress%
		JSR OSFILE
		LDA #OSFILELocked% \lock
		JSR lock
		.noload
		.execaddress
		{
		CLC
		LDA e
		ADC e+1
		BEQ noexe
		LDA #OSFILEUnLocked%
		JSR lock
		LDA e
		STA blockstart+6
		LDA e+1
		STA blockstart+7
		LDA e+2
		STA blockstart+8
		LDA e+3
		STA blockstart+9
		LDX #blockstart
		LDY #0
		LDA #OSFILEWriteExecutionAddress%
		JSR OSFILE
		LDA #OSFILELocked%
		JSR lock
		}
		.noexe
		RTS

		\lock
		.lock
		STA blockstart+&E
		LDX #blockstart
		LDY #0
		LDA #OSFILEWriteAttributes%
		JMP OSFILE \RTS

\-------------------------------------------------
\  data structures below
\-------------------------------------------------
		
.CommandAndText
dricmd%=1
EQUS"DR. ",&8D
dincmd% =2
EQUS"DIN",' '+&80
usage%=3 
EQUS"Usage <fsp> (<drv>) (<dno>/<dsp>)",&D
EQUS"L% for load 0=do not change",&D
EQUS"E% for exe 0=do not change",&80+&D
notfound% =4
EQUS"file not found",&8D




\EQUS"LO.",&A0
\*CODE for music the yorkshire boys
\EQUS"K.0 */code|M",&8D

\.erraddr:EQUW errtxt
\.errtxt
\ 1 usage"
\EQUS"Usage <fsp> (<dno>/<dsp>) (<drv>)":EQUB &8D
\ 2 file not found 
\EQUS"file not foun",&E4
\ 3 exe address invalid
\EQUS"Special exe add not code",&E4
\ 4 extended help 
\EQUS"L% for load 0=do not change":EQUB &D
\EQUS"E% for exe 0=do not change":EQUB &D
\EQUS"8000 load ROM":EQUB &D
\EQUS"Basic load add set to run pa":EQUB &D
\EQUS"8023 Basic":EQUB &D
\EQUS"7FFE LDPIC":EQUB &D
\EQUS"7FFD SHOWPIC not implemented":EQUB &D
\EQUS"7FFC *TYPE":EQUB &8D


\#5 EXTENDED HELP CONT
\EQUS"7FFB *DUMP":EQUB &D
\EQUS"7FFA *EXEC":EQUB&D
\EQUS"7FF9 TYB music samples":EQUB &D
\EQUS"7FF8 0000 DEC compressed picture":EQUB &D
\EQUS"7FF7 0000 viewsheet":EQUB &D
\EQUS"7F07 7C00 mode 7 Screen":EQUB &D
\EQUS"7F06 6000 mode 6 Screen":EQUB &D
\EQUS"7F05 5800 mode 5 Screen":EQUB &D
\EQUS"7F04 5800 mode 4 Screen":EQUB &8D
\\#6 EXTENDED HELP CONT
\EQUS"7F03 4000 mode 3 Screen":EQUB &D
\EQUS"7F02 3000 mode 2 Screen":EQUB &D
\EQUS"7F01 3000 mode 1 Screen":EQUB &D
\EQUS"7F00 3000 mode 0 Screen":EQUB &D
\EQUS"Version 1.0"
\EQUB&8D

.end


SAVE "alter",start, end,startexec
\D:\GitHub\beebyams\beebasm
\beebasm -i alter.asm -do alter.ssd -boot alter -v -title alter

\cd C:\GitHub\beebyams

\ ./tools/beebasm/beebasm.exe -i ./ALTER.asm -do ./build/ALTER.ssd -boot ALTER -v -title ALTER 