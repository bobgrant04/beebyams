
\alter used to alter exe and or load address
\Usage <fsp> (<dno>/<dsp>) (<drv>)

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
\&400 A%-Z% INT
 a = &404:b=&408:c=&40C:d=&410:e=&414:f=&418:g=&41C:h=&420:i=&424:j=&428
 k=&42C:l=&430:m=&434:n=&438:o=&43C:p=&440:q=&444:r=&448:s=&44C:t=&450
 u=&454:v=&458:w=&45C:x=&460:y=&464:z=&468
\&600 String manipulation
strA%=&6A0
\&A00 RS232 & cassette
\&1100-7C00 main mem
conb=&5000 :\control block for reading disk
rawdat=&6000:\output for file read
countpg=&6100:\page for count's
\os calls
osasci=&FFE3:osbyte=&FFF4:oswrch=&FFEE:osnewl=&FFE7:osgbpb=&FFD1:osfile=&FFDD
osargs=&FFDA:osbget=&FFD7:osbput=&FFD4:osbpb=&FFD1:osfind=&FFCE:osrdch=&FFE0
oscli=&FFF7:osfsc=&21E:osword=&FFF1


ORG &7800
GUARD &7C00

.start
\get osargs into blockstart
LDX #blockstart:LDY #0:LDA #1:JSR osargs  
\ptr to command into blockstart&70
\X,Y,A are preserved osargs
TYA:LDA #0
\filesize =0 indicates no shift
\basic =0 indicates not basic
STA loadadd
STA filesize:STA basic:TAX:LDA (blockstart),Y:CMP #&D:BNE aa
LDX #1:JSR diserror:LDX #4:JSR diserror:LDX #5:JMP diserror:\JMP so end

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

LDX #blockstart:LDY #0:LDA #5:JSR osfile:CMP #1:BEQ al:LDX #2:JMP diserror:.al
\have L% for load ADD and E% for EXE address
CLC:LDA l:ADC l+1:BEQ noload
LDA #0:JSR lock
LDA l:STA blockstart+2:LDA l+1:STA blockstart+3::LDA l+2:STA blockstart+4:LDA l+3:STA blockstart+5
LDX #blockstart:LDY #0:LDA #2:JSR osfile:
LDA #&A:JSR lock
.noload
CLC:LDA e:ADC e+1:BEQ noexe
LDA #0:JSR lock
LDA e:STA blockstart+6:LDA e+1:STA blockstart+7:LDA e+2:STA blockstart+8:LDA e+3:STA blockstart+9
LDX #blockstart:LDY #0:LDA #3:JSR osfile:
LDX #&A:JSR lock
.noexe
RTS

\lock
.lock
STA blockstart+&E:LDX #blockstart:LDY #0:LDA #4:JMP osfile:


\Prepcmd
\takes x as cmdno ret x ptr to
\strA%
.prepcmd:LDY #0:.ez:DEX:BNE nexcmd:.ey:LDA cmdadd,Y:CMP #&80:BCC am:AND #&7F
STA strA%,X:INX:RTS
.am:STA strA%,X:INX:INY:BNE ey
.nexcmd:LDA cmdadd,Y:INY:CMP #&80:BCC nexcmd:BCS ez 


\execmd
.execmd:LDY #strA% DIV 256:LDX #strA% MOD 256:JMP oscli


.diserror
{
LDA erraddr:STA erradd:LDA erraddr+1:STA erradd+1
LDY #0:.ba:DEX:BNE bb:.bc:LDA(erradd),Y:CMP #&80:BCC bd:AND #&7F:JSR osasci:RTS
.bd:JSR osasci:INY:BNE bc
.bb:LDA(erradd),Y:INY:CMP #&80:BCC bb:CLC:TYA:ADC erradd:STA erradd:LDA #0
ADC erradd+1:STA erradd+1:LDY #0:BEQ ba
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
 EQUS"Basic progs need exe 8023":EQUB &D
 EQUS"Basic progs need load add set to run pa":EQUB &D
 EQUS"ROM load should be 8000":EQUB &D
 EQUS"LDPIC on disk DATA has exe 7FFE":EQUB &D
 EQUS"SHOWPIC DATA has exe 7FFD":EQUB &D
 EQUS"Files to be *TYPE exe 7FFC":EQUB &8D


\#5 EXTENDED HELP CONT
EQUS"Files to be *DUMP exe 7FFB":EQUB &D
EQUS"Files to be *EXEC exe 7FFA":EQUB&D
EQUS"TYB music samples to be exe 7FF9":EQUB &D
EQUS"Version 0.9"
EQUD&8D

.end


SAVE "alter", start, end
\D:\GitHub\beebyams\beebasm
\beebasm -i alter.asm -do alter.ssd -boot alter -v -title alter