INCLUDE "VERSION.asm"
INCLUDE "SYSVARS.asm"			; OS constants
INCLUDE "BEEBINTS.asm"			; A% to Z% as a ... z
\gfi GET FILE INFORMATION
\Usage <fsp> (<dno>/<dsp>) (<drv>)"
\Usage <fsp> (<dno>/<dsp>) (<drv>)
\RETURNS l% = LOAD , e% = EXECUTION, S% = LENGTH
\RETURNS ZERO IN l%, e%, n% ON FAIL
\Outputs E% execution L% load address  N% = length
\Usage (-Q) <fsp> (<dno>/<dsp>) (<drv>)"


\…Variables
NoSpecials%=1:\"offset from 1
EndSpecial%=&FF-NoSpecials%
\ZERO page
\IntA &2A -&2D

\&2E TO &35 basic float
strptr=&2E
Aptr=&30

exeadd=&32
erradd=&34
\&3B to &42 basic float
\single bytes
tempy=&3B
matchlen=&3C
tempx=&3D
ypush=&3E
highestbyte=&3F
noofbytes=&40
quiet =&41
basic=&42




\&70 to &8F reserved for user
blockstart=&70:load=blockstart+2:exe=blockstart+6:size=blockstart+&A
cat=&72
codestart=&70
zz=&8E
\&F8-F9 UNUSED BY OS

\end zero page

\&600 String manipulation
strB%=&640
strA%=&6A0
\&900 rs232/cassette o/p buffer envelope buffer
rawdat=&900:\output for file read
\&A00 RS232 & cassette
countpg=&A00:\page for count's

\&1100-7C00 main mem
conb=&7B90 :\control block for reading disk


ORG &900
GUARD &C00

.start

.startexec
{
\clear E%,L%:S%
LDX #(('E'-'A')*4):JSR clearint
LDX #(('L'-'A')*4):JSR clearint
LDX #(('S'-'A')*4):JSR clearint
\get OSARGS into blockstart
LDX #blockstart:LDY #0:LDA #1:JSR OSARGS  
\ptr to command into blockstart&70
\X,Y,A are preserved OSARGS
TYA:LDA #0
STA quiet
STA basic
\filesize =0 indicates no shift
\basic =0 indicates not basic
\STA loadadd
}
TAX:LDA(blockstart),Y:CMP #&D:BNE aa
LDX #usage:JMP diserror
.aa:
CMP #('-'):BNE xa
INY:LDA(blockstart),Y
CMP #('Q'):BNE shift
INC quiet
.shift
LDX #0
INY:
.xb:
LDA(blockstart),Y :STA strB%,x:INY:INX:CMP #&D:BNE xb
LDY #0
.xc
LDA strB%,Y:STA (blockstart),Y:INY:CMP #&D:BNE xc
LDY #0:TYA:TAX
.xa
CMP #&D:BEQ cmdend:INY:LDA(blockstart),Y:CMP #32:BNE xa:INX:BNE xa
.cmdend:CPX #2:BNE ab:STX tempx:DEY:STY tempy
\"…"Have drive param
LDX #NoSpecials%:JSR prepcmd:LDY tempy:LDA(blockstart),Y:STA strA%,X
INX : LDA #&D : STA strA%,X
DEY:STA(blockstart),Y:STY tempy
JSR execmd
LDX tempx:LDY tempy
.ab:CPX #1:BCC ac
\"…"Have DIN param
.ad: DEY : LDA(blockstart),Y : CMP #32:BNE ad:LDA #&D:STA(blockstart),Y:STY tempy
LDX #NoSpecials%+1:JSR prepcmd:LDY tempy
DEX
.ae:INY:INX:LDA(blockstart),Y:STA strA%,X:CMP #&D:BNE ae:CMP #&32:BEQ ae
LDA #&D:STA strA%,X
JSR execmd
.ac

\"Process filename
\now have blockstart with filename does file exist?
LDX #blockstart
LDY #0
LDA #5
JSR OSFILE
CMP #1
BEQ al
RTS \no file exit
.al
LDA load
STA l
LDA load+1
STA l+1
LDA size
STA s:
LDA size+1
STA s+1
LDA exe
STA e
LDA exe+1
STA e+1

RTS

.prepcmd
{
:LDY #0:.ez:DEX:BNE nexcmd:.ey:LDA cmdadd,Y:CMP #&80:BCC am:AND #&7F
STA strA%,X:INX:RTS
.am:STA strA%,X:INX:INY:BNE ey
.nexcmd:LDA cmdadd,Y:INY:CMP #&80:BCC nexcmd:BCS ez 
}
\execmd
.execmd
{
:LDY #strA% DIV 256:LDX #strA% MOD 256:JMP OSCLI
}


.diserror
{
LDA #LO(errtxt)
STA erradd
LDA #HI(errtxt)
STA erradd+1
LDY #0:.ba:DEX:BNE bb:.bc:LDA(erradd),Y:CMP #&80:BCC bd:AND #&7F:JSR OSASCI:RTS
.bd:JSR OSASCI:INY:BNE bc

.bb:LDA(erradd),Y:INY:CMP #&80:BCC bb
BCS ba
}
\tables are all consistant at the end namely
\exec,load,ident
\need to ensure that deal with dissagreements
\if E%=0 overwrite same with L%
\report confict and clear E% and L%


\Clearint cli offset from a in X
.clearint
{
LDA#0:LDY#3:.dx:STA a,X:INX:DEY:BPL dx:RTS
}

.cmdadd

\SPECIALS ABOVE ALTER NoSpecials%
\*DRIVE
EQUS"*DR.",&A0
\*DIN
EQUS"*DIN",&A0
\*LOAD
EQUS"LO.",&A0

\.erraddr:EQUW errtxt
.errtxt
\ 1 usage"
usage=1
EQUS"Usage (-Q) <fsp> (<dno>/<dsp>) (<drv>)":EQUB &8D

.end




SAVE "Gfi", start, end,startexec
\cd D:\GitHub\beebyams\beebasm
\beebasm -i .\magic\magic.asm -do .\magic\magic.ssd -boot magic -v -title magic
\beebasm -i .\magic\magic.asm -di .\magic\magic-dev.ssd -do .\magic\magic.ssd -v 
\cd C:\GitHub\beebyams


\ ./tools/beebasm/beebasm.exe -i ./GFI.asm -do ./build/GFI.ssd -boot magic -v -title magic