INCLUDE "VERSION.asm"

INCLUDE "SYSVARS.asm"			; OS constants

INCLUDE "BEEBINTS.asm"			; A% to Z% as a ... z

\\GFN 

\\inputs text drive diskname U% as cat entry
\Usage <dno> <fsp>  
\output  
\ U%



\…Variables
\\ZERO page
\&16 -&17 basic err jump add

\\IntA &2A -&2D

\\&2E TO &35 basic float
aptr=&2E
\&3B to &42 basic float
\\single bytes 
tempx=&3B
tempy=&3C

\\&F8-F9 UNUSED BY OS
blockstart=&F8
\end zero page

\\&600 String manipulation
strA%=&6A0
pram%=&6F0
FnAdd%= &6B0

ORG &0900
GUARD &0B00
cat = &0E00
.start
\\init stuff
\\clear %
LDX #(('U'-'A')*4): \JSR clearint
.clearint
{
LDA#0
LDY#3
.dx
STA a,X
INX
DEY
BPL dx
\\need to add RTS if using elsewhere!
}
{
\\clear  strA%
LDX#7
LDA#32
.ab
STA strA%,X
DEX
BPL ab
.aa
}
\\get OSARGS into blockstart
LDX #blockstart
LDY #0
LDA #1
JSR OSARGS  
\\ptr to command into blockstart
\\X,Y,A are preserved OSARGS
LDY #0

\\note not in braces
\\sanity check to we have command line args
LDA (blockstart),Y
CMP #&D
BNE ok
.error
LDX #usage
JMP printcmd:\RTS
.ok
{
SEC
SBC #'0'
STA dir
.aa
}
\\ next char should be #32
{
INY
LDA (blockstart),Y
CMP #32
BNE error
\load filename into strA%
\\Y=1
LDX #0
.ab
INY
LDA (blockstart),Y
STA strA%,X
CMP #&D
BEQ ac
CMP #32
BEQ ac
\captialise
CMP #97
BCC ae
SEC
SBC #32
.ae
STA strA%,X
INX
BNE ab
.ac
LDA #&D
STA strA%,X
\X = StrA% len inc 0d
\Y = unknown
}
\\now have  Captilaised filename in strA%
\\process into FnAdd%
{
LDA #0
TAY
TAX
LDA strA%+1
CMP #'.'
BNE ia
LDA strA%
STA FnAdd%+7
INY
DEX \move beyond 
.ib
INY
INX
.ih
CMP #&D
BEQ id
CPX #7
BEQ ie
LDA strA%,Y
STA FnAdd%,X
BNE ib  
.id
DEX
DEX
.ig
CPX #6
BEQ ie
LDA #&20
INX
STA FnAdd%,X
BNE ig

.ia
LDA #'$'
STA FnAdd%+7
BNE ih
.ie
}
\\ok read cat
.READCAT
{
LDA #&7F
LDX #LO(dir)
LDY #HI(dir)
JSR OSWORD
LDA result:\should be zero
BEQ aa
LDX #uabletoreadcat
JMP printcmd:\RTS
.aa
}
\now to match against cat
{
LDY#0
STY tempy
LDX#1
STX tempx
DEX
.af
LDA cat+8,Y
AND #&7F
CMP FnAdd%,X
BEQ ah
SEC
SBC#&20
CMP FnAdd%,X
BEQ ah
INC tempx
LDA #8
CLC
ADC tempy
STA tempy
BCS ak
TAY
LDX #0
BEQ af
.ak
RTS
.ah
INY
INX
CPX #8
BEQ ai
BNE af
.ai
LDA tempx
STA u
RTS
}
.printcmd
{
LDY #0
.ez: 
DEX
BNE nexcmd

.ey
LDA cmdadd,Y
CMP #&80
BCC am
AND #&7F
JMP OSASCI :\rts
.am
JSR OSASCI
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
\\note this data block needs to be <&FF you have been warned

\\1
usage=1
EQUS"Usage <dno> <fsp> output U% (U%=0 fail)":EQUB &8D

\\2
uabletoreadcat=2
EQUS "Unable to read catalogue":EQUB &8D

\\.pramadd
\EQUW pram:
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
\\EQUB Dr%: EQUD cat: EQUB 3: EQUB &53: EQUB 0: EQUB 0: EQUB &22: EQUB 0:.cat:



SAVE "gfn", start, end
\\cd D:\GitHub\beebyams\beebasm
\beebasm -i .\U\U.asm -do .\U\U.ssd -boot U -v -title U

\\cd C:\GitHub\beebyams


\\ ./tools/beebasm/beebasm.exe -i ./gfn.asm -do ./build/gfn.ssd -boot U -v -title gfn
