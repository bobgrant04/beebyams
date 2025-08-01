\Constants
INCLUDE "VERSION.asm"
INCLUDE "SYSVARS.asm"			; OS constants
INCLUDE "BEEBINTS.asm"			; A% to Z% as a ... z
\Utility routines
\(<drv>) (<dno>/<dsp>)
ORG &900
GUARD &B00

\TODO IF U%=0 Just launch disk!????
\U 
\inputs text diskname U% as cat entry
\output  Usage (<dno>/<dsp>) (<drv>)
\ X  filename$ diskname$ 3



\…Variables
\Novariants=2
\Dr%=3
\ZERO page
\&16 -&17 basic err jump add

\IntA &2A -&2D

\&2E TO &35 basic float
aptr=&2E
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
cat = &7000
\&600 String manipulation
\strB%=&620
strA%=&650

\pram%=&6F0
\&A00 RS232 & cassette
\&1100-7C00 main mem
\MODULE SETUP
\------------------------------------------------------
\setup for OSARGS
__OSARGSinit = TRUE
__OSARGSargXtoOSARGSstrB = FALSE
__OSARGSargcountX = TRUE
__OSARGSallcmdintoOSARGSstrAoffsetX = TRUE
\Variables - 
OSARGSptr =blockstart
\OSARGSstrB =strB% 
OSARGSstrA =strA%
\-------------------------------------------------------

ORG &900
GUARD &B00

.error
{
LDX #usage
JSR initprepcmd
JMP printstrA:\RTS
}
.start
\init stuff
\clear %
\LDX #(('F'-'A')*4): JSR clearint


{
JSR OSARGSinit
LDA (blockstart),Y
BEQ error
}

{
JSR OSARGSargcountX \X now has arg count!
\Usage(<drv>) (<dno>/<dsp>)
\need to count down
CPX #2
BNE error
}
{
\going to issue din cmd
lDX #dincmd
JSR initprepcmd
JSR OSARGSallcmdintoOSARGSstrAoffsetX
}
\set drive for catalogue
{
LDA strA%+3 \drive
STA drive%
SEC
SBC #'0'
STA dir
}

{
\issue Din cmd
JSR exeStrA%
}

\read cat
{
LDA #&7F
LDX #LO(dir)
LDY #HI(dir)
JSR OSWORD
LDA result:\should be zero
BEQ aa
LDX #uabletoreadcat
JSR initprepcmd
JMP printstrA
.aa
}
\create x command
\x filename drive din
{
LDX #xcmd
JSR initprepcmd
\X is pointer to next char in strA%
\.ab
\DEY
\BPL ab
LDA u
BEQ boot
TAY
LDA #0
INX
CLC
.oi
ADC#8
DEY 
BNE oi
TAY
LDA cat+7,Y
STA strA%,X
INX
LDA #'.'
STA strA%,X
INX
.oj
LDA cat,Y
CMP #' '
BEQ addosargs
STA strA%,X
INY
INX
CPX #11 \9 chars for full filename+"X "
BNE oj
}
.addosargs
{
LDA #' '
STA strA%,X
INX
JSR OSARGSallcmdintoOSARGSstrAoffsetX
}


\------------------------------------
\ subs below 
.exeStrA%
{
LDY #HI(strA%)
LDX #LO(strA%)
JMP OSCLI\rts
}
\We do not have U% so launch the disk!
.boot
{
LDX #bootcmd
JSR initprepcmd
INX
JMP addosargs \RTS
}
.printstrA
{
LDX #&FF
.ak
INX
LDA strA%,X
JSR OSASCI
CMP #&D
BNE ak
RTS
}


\routines
\initates strA

.initprepcmd
LDA #0
STA strAoffset
\Prepcmd
\takes x as cmdno ret x ptr to
\strA%
.prepcmd
{
LDY #0
.ez
DEX
BNE nexcmd
LDX strAoffset 
.ey
LDA cmdadd,Y
CMP #&80
BCC am
AND #&7F
STA strA%,X
INX 
LDA #&D
STA strA%,X
DEX
STX strAoffset
RTS \all done
.am
STA strA%,X
INX
INY
BNE ey
.nexcmd
LDA cmdadd,Y
INY
CMP #&80
BCC nexcmd
BCS ez 
}

.cmdadd
\note this data block needs to be <&FF you have been warned
\-----------------------len warning--------------
\1 
dincmd=1
EQUS"DIN":EQUB &80+' '
\2
xcmd=2
EQUS"X":EQUB &80+' '

\3 usage
usage=3
EQUS"(<drv>) (<dno>/<dsp>) and U% output X cmd or   cat if u%=0":EQUB &8D
\4
uabletoreadcat=4
EQUS"unable to read ca":EQUB &80+'t'
bootcmd=5
EQUS"X !boo":EQUB &80+'t'
\--------------- end warning------------------------


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

\
INCLUDE "OSARGS.ASM"
.end


SAVE "U", start, end
\cd D:\GitHub\beebyams\beebasm
\beebasm -i .\U\U.asm -do .\U\U.ssd -boot U -v -title U

\cd C:\GitHub\beebyams


\ ./tools/beebasm/beebasm.exe -i ./U.asm -do ./build/U.ssd -boot U -v -title U