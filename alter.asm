
\alter used to alter exe and or load address
\Usage <fsp> (<dno>/<dsp>) (<drv>)
INCLUDE "VERSION.asm"
INCLUDE "SYSVARS.asm"			; OS constants
INCLUDE "BEEBINTS.asm"			; A% to Z% as a ... z

\…Variables
NoSpecials%=1:\"offset from 1
EndSpecial%=&FF-NoSpecials%
\ZERO page
\IntA &2A -&2D
strptr=&2A
Aptr=&2C
\&2E TO &35 basic float
trueadd=&2E
loadadd=&30
exeadd=&32
erradd=&34
\&3B to &42 basic float
\single bytes
filesize=&3B
tempx=&3D
switch=&3E
basic=&3F
tempy=&40
\&70 to &8F reserved for 
blockstart=&70:load=blockstart+2:exe=blockstart+6:size=blockstart+&A
cat=&72
codestart=&70
zz=&8E
\&F8-F9 UNUSED BY OS
\end zero page


\&600 String manipulation
strA%=&6A0
\&A00 RS232 & cassette
\&1100-7C00 main mem
conb=&5000 :\control block for reading disk
rawdat=&6000:\output for file read
countpg=&6100:\page for count's
\os calls


ORG &7800
GUARD &7C00

.start
\get OSARGS into blockstart
LDX #blockstart:LDY #0:LDA #1:JSR OSARGS  
\ptr to command into blockstart&70
\X,Y,A are preserved OSARGS
TYA:LDA #0
\filesize =0 indicates no shift
\basic =0 indicates not basic
STA loadadd
STA filesize:STA basic:TAX:LDA (blockstart),Y:CMP #&D:BNE aa
LDX #1
JSR diserror
LDX #4
JSR diserror
LDX #5
JSR diserror
LDX #6
JMP diserror:\JMP so end

.aa:CMP #&D:BEQ cmdend:INY:LDA (blockstart),Y:CMP #32:BNE aa:INX:BNE aa
.cmdend:CPX #2:BNE ab:STX tempx:DEY:STY tempy
\"…"Have drive param
LDX #NoSpecials%:JSR prepcmd:LDY tempy:LDA (blockstart),Y:STA strA%,X
INX:LDA #&D:STA strA%,X
DEY:STA (blockstart),Y:STY tempy
JSR execmd
LDX tempx:LDY tempy
.ab:CPX #1:BCC ac
\"…"Have DIN param
.ad:DEY:LDA (blockstart),Y:CMP #32:BNE ad:LDA #&D:STA (blockstart),Y:STY tempy
LDX #NoSpecials%+1:JSR prepcmd:LDY tempy
DEX
.ae:INY:INX:LDA(blockstart),Y:STA strA%,X:CMP #&D:BNE ae:CMP #&32:BEQ ae
LDA #&D:STA strA%,X
JSR execmd
.ac
\"Process filename
\now have blockstart with filename

LDX #blockstart:LDY #0:LDA #5:JSR OSFILE:CMP #1:BEQ al:LDX #2:JMP diserror:.al
\have L% for load ADD and E% for EXE address
CLC: LDA l :ADC l+1:BEQ noload
LDA #0:JSR lock
LDA l:STA blockstart+2:LDA l+1:STA blockstart+3::LDA l+2:STA blockstart+4:LDA l+3:STA blockstart+5
LDX #blockstart:LDY #0:LDA #2:JSR OSFILE:
LDA #&A:JSR lock
.noload
CLC:LDA e:ADC e+1:BEQ noexe
LDA #0:JSR lock
LDA e:STA blockstart+6:LDA e+1:STA blockstart+7:LDA e+2:STA blockstart+8:LDA e+3:STA blockstart+9
LDX #blockstart:LDY #0:LDA #3:JSR OSFILE:
LDX #&A:JSR lock
.noexe
RTS

\lock
.lock
STA blockstart+&E:LDX #blockstart:LDY #0:LDA #4:JMP OSFILE:


\Prepcmd
\takes x as cmdno ret x ptr to
\strA%
.prepcmd:LDY #0:.ez:DEX:BNE nexcmd:.ey:LDA cmdadd,Y:CMP #&80:BCC am:AND #&7F
STA strA%,X:INX:RTS
.am:STA strA%,X:INX:INY:BNE ey
.nexcmd:LDA cmdadd,Y:INY:CMP #&80:BCC nexcmd:BCS ez 


\execmd
.execmd:LDY #strA% DIV 256:LDX #strA% MOD 256:JMP OSCLI


.diserror
{
LDA #LO(errtxt)
STA Aptr
LDA #HI(errtxt)
STA Aptr+1

/LDA erraddr
/STA erradd
/LDA erraddr+1
/STA erradd+1
LDY #0
.ba
DEX
BNE bb
.bc
LDA (Aptr),Y
CMP #&80
BCC bd
AND #&7F
JSR OSASCI
RTS
.bd:
JSR OSASCI
INY
BNE bc
.bb
LDA (Aptr),Y
INY:CMP #&80
BCC bb
CLC
TYA
ADC Aptr
STA Aptr
LDA #0
ADC Aptr+1
STA Aptr+1
LDY #0
BEQ ba
}

.cmdadd

\SPECIALS ABOVE ALTER NoSpecials%
\*DRIVE
EQUS"*DR.",&A0
\*DIN
EQUS"*DIN",&A0
\*LOAD
EQUS"LO.",&A0
\*CODE for music the yorkshire boys
EQUS"K.0 */code|M",&8D

.erraddr:EQUW errtxt
.errtxt
\ 1 usage"
EQUS"Usage <fsp> (<dno>/<dsp>) (<drv>)":EQUB &8D
\ 2 file not found 
EQUS"file not foun",&E4
\ 3 exe address invalid
EQUS"Special exe add not code",&E4
\ 4 extended help 
EQUS"L% for load 0=do not change":EQUB &D
EQUS"E% for exe 0=do not change":EQUB &D
EQUS"8000 load ROM":EQUB &D
EQUS"Basic load add set to run pa":EQUB &D
EQUS"8023 Basic":EQUB &D
EQUS"7FFE LDPIC":EQUB &D
EQUS"7FFD SHOWPIC not implemented":EQUB &D
EQUS"7FFC *TYPE":EQUB &8D


\#5 EXTENDED HELP CONT
EQUS"7FFB *DUMP":EQUB &D
EQUS"7FFA *EXEC":EQUB&D
EQUS"7FF9 TYB music samples":EQUB &D
EQUS"7FF8 0000 DEC compressed picture":EQUB &D
EQUS"7FF7 0000 viewsheet":EQUB &D
EQUS"7F07 7C00 mode 7 Screen":EQUB &D
EQUS"7F06 6000 mode 6 Screen":EQUB &D
EQUS"7F05 5800 mode 5 Screen":EQUB &D
EQUS"7F04 5800 mode 4 Screen":EQUB &8D
\#6 EXTENDED HELP CONT
EQUS"7F03 4000 mode 3 Screen":EQUB &D
EQUS"7F02 3000 mode 2 Screen":EQUB &D
EQUS"7F01 3000 mode 1 Screen":EQUB &D
EQUS"7F00 3000 mode 0 Screen":EQUB &D
EQUS"Version 1.0"
EQUB&8D

.end


SAVE "alter", start, end
\D:\GitHub\beebyams\beebasm
\beebasm -i alter.asm -do alter.ssd -boot alter -v -title alter

\cd C:\GitHub\beebyams

\ ./tools/beebasm/beebasm.exe -i ./build/ALTER.asm -do ./ALTER.ssd -boot ALTER -v -title ALTER 