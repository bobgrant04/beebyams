\Utility routines
\(<drv>) (<dno>/<dsp>) (description) (program type) (publisher) (FAV (y/n))
\output  Usage (<drv>) (<dno>/<dsp>) 
\ X  filename$ 1 diskname$
\Constants
INCLUDE "VERSION.asm"
INCLUDE "SYSVARS.asm"			; OS constants
INCLUDE "BEEBINTS.asm"			; A% to Z% as a ... z
INCLUDE "TELETEXT.asm" \TELETEXT constants
\-------------------------------
\constants
\-------------------------------
PrePrint%=2 \no of special chars before text
OSARGDiscName% =2
OSARGDescription%=3
OSARGProgramType%=4
OSARGPublisher%=5
OSARGFavorite%=6
TOPLines%=3
BOTTOMLines%=3
TOPWindow%=0
BOTTOMWindow%=4
MAINWindow%=8


\TODO IF U%=0 Just put $.!boot as file name dealing with it is then an X issue
\as a special case
\U 
\inputs text diskname U% as cat entry


\-------------------------------
\Zero page Variables
\-------------------------------

\&16 -&17 basic err jump add

\IntA &2A -&2D
	tempy%=&2A
	NoofArgs%=&2B
\&2E TO &35 basic float
	aptr=&2E
	TextAdd =&30
\&3B to &42 basic float
\single bytes
\tempx=&3B
\filetype=&3C
	strAoffset=&3D
	drive%=&3E
\&70 to &8F reserved for 

\zp=&A8
\&F8-F9 UNUSED BY OS
	blockstart=&F8 \needed by OSARGS
\blockstart=&F8
\end zero page
	cat = &7A00
\&600 String manipulation
\strB%=&620
	strA%=&680
	\pram% has !boot in it
\Pram%=&6E0
\&A00 RS232 & cassette
\&1100-7C00 main mem
\MODULE 

\-------------------------------------------------------

ORG &7000
GUARD &7A00

\------------------------------------------------------
__OSARGSinit = TRUE
__OSARGSargXtoOSARGSStrLenA = TRUE
__OSARGSargGetDrive = FALSE
__OSARGSFileNameToOSARGSPram = FALSE
__OSARGSOptions = FALSE
\Variables - 
IF __OSARGSargXtoOSARGSStrLenA
	OSARGSstrA =strA%
	OSARGSStrLenA = strAoffset
ENDIF
OSARGStempy% = tempy%
IF __OSARGSargGetDrive
	OSARGSrequesteddrive = RequestedDrive%
ENDIF
IF __OSARGSFileNameToOSARGSPram
	OSARGSpram% = xpram%
ENDIF
\OSARGSpramlen% = pramlen
OSARGSNoofArgs% = NoofArgs%
IF __OSARGSOptions
	OSARGSOptions% = OptionStr%
	OSARGSbitOptions% = OptionBit%
	\constants
	OSARGSbitOptionQuiet% = 1
	OSARGSbitOptionVerbose% =2
ENDIF

\------------------------------------------------------

.start
INCLUDE "OSARGS.ASM"
		.AddCharToStrA
		{
		LDY strAoffset
		STA strA%,Y
		INC strAoffset
		RTS
		}
		.AddPramToStrA
		{
		LDY strAoffset
		LDX #0
		.loop
		LDA Pram%,X
		STA strA%,Y
		CMP #13
		BNE aa
		STY strAoffset
		RTS
		.aa
		INY
		INX
		BNE loop
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
		.printdoubleheight
		{
		LDA #13
		JSR AddCharToStrA
		JSR PrintstrA
		JMP PrintstrA
		}
		
\--------------
.startexec
\--------------
		\not going to do to much error checking as 
		\should only be used from mnudisp
		
		
		JSR OSARGSinit
		\ X has no of arguments
		\as has OSARGSNoofArgs%
		CPX #2
		BCS ok
		LDX #usage%
		JSR initprepcmd
		LDX #0
		JMP PrintstrA:\RTS
		.ok
		LDA u+1
		BNE ab
		JMP workoutfilename
		.ab
		.printKeyBtmText
		{
		LDY #BOTTOMWindow%
		JSR Selectwindow
		LDY #&FF
		.ol
		INY
		LDA lowertxt,Y
		BEQ exit
		JSR OSASCI
		BNE ol
		.exit
		}
		LDY #MAINWindow%
		JSR Selectwindow
		\will just process each line from command
		\(description) (program type) (publisher) (FAV (y/n))
		\mainwindow is selected
		\CLS
		\inital setup
		\go double height?
		LDA #0
		STA strAoffset
		LDA #TELETEXTDoubleheight%
		JSR AddCharToStrA
		LDA #TELETEXTcyantext%
		JSR AddCharToStrA
		\Description
		LDX #description%
		JSR prepcmd
		LDA #TELETEXTyellowtext%
		JSR AddCharToStrA
		LDX #OSARGDescription%
		JSR OSARGSargXtoOSARGSStrLenA
		\LDA #13
		\JSR AddCharToStrA
		\JSR PrintstrA
		JSR printdoubleheight
		\Program type
		LDA #PrePrint%
		STA strAoffset
		LDX #Programtype%
		JSR prepcmd
		LDA #TELETEXTyellowtext%
		JSR AddCharToStrA
		LDX #OSARGProgramType%
		JSR OSARGSargXtoOSARGSStrLenA
		\LDA #13
		\JSR AddCharToStrA
		\JSR PrintstrA
		JSR printdoubleheight
		\Publisher
		LDA #PrePrint%
		STA strAoffset
		LDX #Publisher%
		JSR prepcmd
		LDA #TELETEXTyellowtext%
		JSR AddCharToStrA
		LDX #OSARGPublisher%
		JSR OSARGSargXtoOSARGSStrLenA
		\LDA #13
		\JSR AddCharToStrA
		\JSR PrintstrA
		JSR printdoubleheight
		\Favorite
		LDA #PrePrint%
		STA strAoffset
		LDX #Favorite%
		JSR prepcmd
		LDA #TELETEXTyellowtext%
		JSR AddCharToStrA
		LDX #OSARGFavorite%
		JSR OSARGSargXtoOSARGSStrLenA
		\LDA #13
		\JSR AddCharToStrA
		\JSR PrintstrA
		JSR printdoubleheight
		\disc
		LDA #PrePrint%
		STA strAoffset
		LDX #Diskname%
		JSR prepcmd
		LDA #TELETEXTyellowtext%
		JSR AddCharToStrA
		LDX #OSARGDiscName%
		JSR OSARGSargXtoOSARGSStrLenA
		\LDA #13
		\JSR AddCharToStrA
		\JSR PrintstrA
		JSR printdoubleheight
		\do the work to convert U% into filename
		\set drive for catalogue
		.workoutfilename
		{
		LDA #0
		STA strAoffset
		LDX #1
		JSR OSARGSargXtoOSARGSStrLenA
		LDA strA% \drive
		STA drive%
		SEC
		SBC #'0'
		STA dir
		}
		
		\going to issue din cmd
		{
		LDX #dincmd%
		JSR initprepcmd
		LDX #1
		JSR OSARGSargXtoOSARGSStrLenA
		LDX #2
		JSR OSARGSargXtoOSARGSStrLenA
		LDX strAoffset
		\DEX
		LDA #&D
		STA strA%,X 
		JSR execmd \issue Din cmd
		}

		\read cat?
		{
		LDA u
		BNE readcat
		LDA #0
		STA strAoffset
		LDA #TELETEXTgreentext%
		JSR AddCharToStrA
		LDX #Nocatno%
		JSR prepcmd
		JSR PrintstrA
		JMP printfilename
		.readcat
		LDX #LO(dir)
		LDY #HI(dir)
		LDA #&7F \read no of sectors on disk
		JSR OSWORD
		LDA result \should be zero
		BEQ aa
		LDX #uabletoreadcat%
		JSR initprepcmd
		JMP PrintstrA \RTS
		.aa
		}
		.storefilenameintoPram%
		{
		LDY u
		\TAY
		LDA #0
		TAX
		CLC
		.oi
		ADC #8
		DEY 
		BNE oi
		TAY
		LDA cat+7,Y
		STA Pram%,X
		INX
		LDA #'.'
		STA Pram%,X
		INX
		.oj
		LDA cat,Y
		CMP #' '
		BEQ exit
		STA Pram%,X
		INY
		INX
		CPX #9 \9 chars for full filename+"X "
		BNE oj
		.exit
		LDA #13
		STA Pram%,X
		}
		.printfilename
		\print info?
		{
		LDA u+1
		BEQ exit
		LDA #0
		STA strAoffset
		LDA #TELETEXTDoubleheight%
		JSR AddCharToStrA
		LDA #TELETEXTcyantext%
		JSR AddCharToStrA
		\LDA #PrePrint%
		\STA strAoffset
		\LDA #TELETEXTcyantext%
		\STA strA%
		\Filename
		LDX #Filename%
		JSR prepcmd
		LDA #TELETEXTyellowtext%
		JSR AddCharToStrA
		JSR AddPramToStrA
		JSR printdoubleheight
		\JSR PrintstrA
		\PREss any key
		JSR gti
		\create x command
		\x filename drive din
		.exit
		}
		\do not need to set drive back as read cat without dr cmd!
		

		LDX #xcmd%
		JSR initprepcmd
		JSR AddPramToStrA
		DEC strAoffset
		LDA #' '
		JSR AddCharToStrA
		LDA drive%
		JSR AddCharToStrA
		LDA #&D
		JSR AddCharToStrA
		\JMP execmd \rts
		RTS
		
		\X is pointer to next char in strA%
		\.ab
		\DEY
		\BPL ab
		
		\ok so all done!
		
		

\------------------------------------
\ subs below 
		\Selectwindow slw TAKES Y TOPWindow,btmw%,mainW%
		.Selectwindow
		{
		LDX #5
		LDA #28 \VDU28
		.mj
		JSR OSASCI
		LDA window,Y
		INY
		DEX
		BNE mj
		LDA #12
		JMP OSASCI \him\rts
		}
		.gti
		{
		LDA #OSBYTEReadCharacterFromBuffer%
		LDX #OSBYTEXKeyboardBuffer%
		JSR OSBYTE
		BCS gti \no character
		RTS
		}

		.addosargs
		{
		LDA #' '
		STA strA%,X
		INX
		\JSR OSARGSallcmdintoOSARGSstrAoffsetX
		}
		.exeStrA%
		{
		LDY #HI(strA%)
		LDX #LO(strA%)
		JMP OSCLI\rts
		}

		.PrintstrA
		{
		LDX #&FF
		.printstrAloop
		INX
		LDA strA%,X
		CMP #'#'
		BNE aa
		LDA #TELETEXTmagentatext%
		.aa
		JSR OSASCI
		CMP #&D
		BNE printstrAloop
		RTS
		}


\routines
\initates strA

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
\---------------------------
\ Data structures
\---------------------------
.Pram%
	EQUS"$.!boot",&D
.CommandAndText
 
dincmd%=1
	EQUS"DIN",&80+' '
xcmd%=2
	EQUS "X",&80+' '
usage%=3
	EQUS"(<drv>) (<dno>/<dsp>) and U% output X cmd or cat if u%=0",&D
	EQUS"(description) (program type) (publisher) (FAV (y/n))",&D
	BUILD_VERSION
	EQUS &8D
uabletoreadcat%=4
	EQUS"unable to read ca":EQUB &80+'t'
Filename%=5
	EQUS"Filename",&80+':'
description% =6
	EQUS"Description",&80+':'
Programtype% =7
	EQUS"Program type",&80+':'
Publisher%=8
	EQUS"Publisher",&80+':'
Favorite%=9
	EQUS"Favorite",&80+':'
Diskname%=10
	EQUS"Disk name",&80+':'
Nocatno%=11
	EQUS"No catalogue number given so..",&8D
	.lowertxt
	\-------------------------------
	\NB keep below 255 chars zero ternminated
	EQUB 13\line 1
	EQUB TELETEXTmagentatext%,"I",TELETEXTyellowtext%,"nvulnerable"
	EQUB TELETEXTmagentatext%,"P",TELETEXTyellowtext%,"assword"
	EQUB TELETEXTmagentatext%,"J",TELETEXTyellowtext%,"oystick"
	EQUB TELETEXTmagentatext%,"T",TELETEXTyellowtext%,"ape"
	\line 2
	EQUB TELETEXTmagentatext%,"N",TELETEXTyellowtext%,"2nd proc"
	EQUB TELETEXTmagentatext%,"E",TELETEXTyellowtext%,"lectron"
	EQUB TELETEXTmagentatext%,"X",TELETEXTyellowtext%,"life"
	EQUB TELETEXTmagentatext%,"S",TELETEXTyellowtext%,"peed"
	EQUB TELETEXTmagentatext%,"R",TELETEXTyellowtext%,"om"
	\line 3
	EQUB TELETEXTmagentatext%,"2",TELETEXTyellowtext%,"player"
	EQUB TELETEXTmagentatext%,"D",TELETEXTyellowtext%,"isc"
	EQUB TELETEXTmagentatext%,"L",TELETEXTyellowtext%,"evel"

	EQUB 0	
 .window
 \left X, bottom Y, right X and top Y
 \top
EQUB 0
EQUB TOPLines%   
EQUB 39
EQUB 0
 \btm
EQUB 0
EQUB 24        
EQUB 39
EQUB 24-BOTTOMLines%
 \main
EQUB 0
EQUB 24-BOTTOMLines%
EQUB 39
EQUB TOPLines%



.dir: 
EQUB 0  \DRIVE
EQUD cat\DATA LOCATION
EQUB 3  \NO OF PRAMS
EQUB &53\ multi-sector
EQUB 0	\TRACK
EQUB 0	\SECTOR
EQUB &21	\SECTOR 256 bytes
.result
EQUB 0



.end


SAVE "U", start, end,startexec
\cd D:\GitHub\beebyams\beebasm
\beebasm -i .\U\U.asm -do .\U\U.ssd -boot U -v -title U

\cd C:\GitHub\beebyams


\ ./tools/beebasm/beebasm.exe -i ./U.asm -do ./build/U.ssd -boot U -v -title U