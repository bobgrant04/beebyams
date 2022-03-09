
\alter used to alter exe and or load address
\Usage <fsp> (<dno>/<dsp>) (<drv>)

\…Variables
NoSpecials%=0:\"offset from 1
EndSpecial%=&FF-NoSpecials%
\ZERO page
\IntA &2A -&2D
strptr =&2A
APtr=&2C
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
cmdcount=&41
StrAlen =&42
\&70 to &8F reserved for 
blockstart=&70:load=blockstart+2:exe=blockstart+6:size=blockstart+&A
cat=&72
codestart=&70
sno =&8C
zz=&8E
\&F8-F9 UNUSED BY OS
\end zero page
\&400 A%-Z% INT
 a=&404:b=&408:c=&40C:d=&410:e=&414:f=&418:g=&41C:h=&420:i=&424:j=&428
 k=&42C:l=&430:m=&434:n=&438:o=&43C:p=&440:q=&444:r=&448:s=&44C:t=&450
 u=&454:v=&458:w=&45C:x=&460:y=&464:z=&468
\&600 String manipulation
StrA% =&6A0
strB%=&6F0
\&A00 RS232 & cassette
\&1100-7C00 main mem
conb=&5000 :\control block for reading disk
rawdat=&6000:\output for file read
countpg=&6100:\page for count's
\os calls
osasci=&FFE3:osbyte=&FFF4:oswrch=&FFEE:osnewl=&FFE7:osgbpb=&FFD1:osfile=&FFDD
osargs=&FFDA:osbget=&FFD7:osbput=&FFD4:osbpb=&FFD1:osfind=&FFCE:osrdch=&FFE0
oscli=&FFF7:osfsc=&21E:osword=&FFF1


ORG &7000
GUARD &7C00

.start
.init
{
LDA #0
STA loadadd
STA filesize:STA basic:TAX
}
JSR NoCmdLineEntries:CMP #1:BCS ca
LDX #1:JSR diserror:LDX #4:JSR diserror:LDX #5:JMP diserror:\JMP so end
.ca:
STX cmdcount
lDX #1:JSR GetCmdLineNoX: INY:LDA (blockstart),y:CMP #':':JMP cmdswitch
\get osargs into blockstart
LDX #blockstart:LDY #0:LDA #1:JSR osargs  
\ptr to command into blockstart&70
\X,Y,A are preserved osargs
TYA:LDA #0
\filesize =0 indicates no shift
\basic =0 indicates not basic
STA loadadd
STA filesize:STA basic:TAX:LDA(blockstart),Y:CMP #&D:BNE aa
LDX #1:JSR diserror:LDX #4:JSR diserror:LDX #5:JMP diserror:\JMP so end

.aa:CMP #&D:BEQ cmdend:INY:LDA(blockstart),Y:CMP #32:BNE aa:INX:BNE aa
.cmdend:CPX #2:BNE ab:STX tempx:DEY:STY tempy
\"…"Have drive param
LDX #NoSpecials%:JSR prepcmd:LDY tempy:LDA(blockstart),Y:STA StrA%,X
INX:LDA #&D:STA StrA%,X
DEY:STA(blockstart),Y:STY tempy
JSR execmd
LDX tempx:LDY tempy
.ab:CPX #1:BCC ac
\"…"Have DIN param
.ad:DEY:LDA(blockstart),Y:CMP #32:BNE ad:LDA #&D:STA(blockstart),Y:STY tempy
LDX #NoSpecials%+1:JSR prepcmd:LDY tempy
DEX
.ae:INY:INX:LDA(blockstart),Y:STA StrA%,X:CMP #&D:BNE ae:CMP #&32:BEQ ae
LDA #&D:STA StrA%,X
JSR execmd
.ac
\"Process filename
\now have blockstart with filename

LDX #blockstart:LDY #0:LDA #5:JSR osfile:CMP #1:BEQ al:LDX #2:JMP diserror:.al
\have L% for load ADD and M% for EXE address
CLC:LDA l:ADC l+1:BEQ noload
LDA #0:JSR lock
LDA l:STA blockstart+2:LDA l+1:STA blockstart+3
LDX #blockstart:LDY #0:LDA #2:JSR osfile:
LDA #&A:JSR lock
.noload
CLC:LDA m:ADC m+1:BEQ noexe
LDA #0:JSR lock
LDA m:STA blockstart+6:LDA m+1:STA blockstart+7
LDX #&A:JSR lock
.noexe
RTS

\lock unlock
.lock
STA blockstart+&E:LDX #blockstart:LDY #0:LDA #4:JMP osfile:


\Prepcmd
\takes x as cmdno ret x ptr to
\StrA%
.prepcmd:LDY #0:.ez:DEX:BNE nexcmd:.ey:LDA cmdadd,Y:CMP #&80:BCC am:AND #&7F
STA StrA%,X:INX:RTS
.am:STA StrA%,X:INX:INY:BNE ey
.nexcmd:LDA cmdadd,Y:INY:CMP #&80:BCC nexcmd:BCS ez 


\execmd
.execmd:LDY #StrA% DIV 256:LDX #StrA% MOD 256:JMP oscli

\display error
.diserror
{
LDA erraddr:STA erradd:LDA erraddr+1:STA erradd+1
LDY #0:.ba:DEX:BNE bb:.bc:LDA(erradd),Y:CMP #&80:BCC bd:AND #&7F:JSR osasci:RTS
.bd:JSR osasci:INY:BNE bc
.bb:LDA(erradd),Y:INY:CMP #&80:BCC bb:CLC:TYA:ADC erradd:STA erradd:LDA #0
ADC erradd+1:STA erradd+1:LDY #0:BEQ ba
}

\get no of command line args
\expects string pointer in blockstart
\returns A destroys A,Y,X
.NoCmdLineEntries
{
lDA #0:TAX:TAY
.aa
LDA(blockstart),Y:CMP #' ':BEQ ab:CMP #&D:BEQ ac:.ad:INY:BNE aa
.ab:INX:BNE ad:
.ac:RTS
}

.Etypes
EQUS"BASI":EQUB &C3
EQUS"LDPI":EQUB &C3
EQUS"SHOWPI":EQUB &C3
EQUS"TYP":EQUB &C5
EQUS"DUM":EQUB &D0
EQUS"TY":EQUB &C2
EQUB 0

.Ltypes
EQUS"ROM"
EQUB 0

.Eaddress
EQUW &8023:\basic
EQUW &7FFE:\ldpic
EQUW &7FFD:\showpic
EQUW &7FFC:\type
EQUW &7FFB:\dump
EQUW &7FF9:\TYB music
.cmdadd





\deal with switch command
\for this implemntation deal with T: E: L:
\return a=0 if NOT processed
.cmdswitch
{
DEY:\ point back to first char
LDA (blockstart),Y
CMP #'a':BCCaa:SEC:SBC #32:\convert from lower to upper case
\put switches in here
CMP #'T':BEQ cmdT:CMP #'L':BEQ cmdL:CMP #'E':BEQ cmdE:
LDA #0:RTS \did not process!
.cmdT:\we have T: so want to set according to type
INY:INY:LDX #0:.aa:LDA (blockstart),Y:CMP #' ':BEQ ab:CMP #&D:BEQ ab:STA StrA%,X:INY:INX:BNE aa
.ab:LDA #&D:STA StrA%,X
JSR SortStr:LDX StrAlen
DEX:LDA StrA%,X:ORA #&80:STA StrA%,X
LDA #0:STA sno:STA sno+1
LDA LO(Etypes):STA APtr:LDA HI(Etypes):STA APtr+1
JSR Search
 
.cmdE:\we have E: so want to set Execution address
JSR GetCmdNumber:JSR PutNoinzz:LDY #m-a:JMP czi:\ ret
.cmdL:\we have L: so want to set Load address
JSR GetCmdNumber:JSR PutNoinzz:LDY #l-a:JMP czi:\ ret
}


.GetCmdNumber
{
INY:INY:LDX #0
.ad
LDA (blockstart),y:cmp #'&':BEQ ab:CMP #&D:BEQ ac:CMP #' ':BEQ ac
STA StrA%,X:.ab:INY:INX:BNE ad
.ac:INX:LDA #&D:STA StrA%,X:RTS
}

.PutNoinzz
{
DEX:BPL ae
LDA StrA%,X:SEC:SBC #'0':STA zz:DEX:BPL ae:LDA StrA%,X:SEC:SBC #'0'
ROL A:ROL A:ROL A:ROL A:CLC:ADC zz:STA zz
DEX:BPL ae
LDA StrA%,X:SEC:SBC #'0':STA zz+1:DEX:BPL ae:LDA StrA%,X:SEC:SBC #'0'
ROL A:ROL A:ROL A:ROL A:CLC:ADC zz+1:STA zz+1
.ae:RTS
}
.czi
\copy zz to %
{
LDA zz:STA a,Y:LDA zz+1:STA a+1,Y:RTS
}
\get offset for command
\expects string in blockstart
\x no of command
\returns offset in Y X will be zero
.GetCmdLineNoX
{
LDY #0
.aa
LDA(blockstart),Y:CMP #' ':BEQ ab:CMP #&D:BEQ ac:.ad:INY:BNE aa
.ab:DEX:BNE ad:
.ac:RTS
}


.Search
{
LDX StrA%:STX tempx:LDY #0:.qj:LDA(APtr),Y:BNE vb:RTS:.vb:CMP tempx:BEQ try:CMP #&80:BCS endrec:INY:BNE qj
.try:LDX #0:STY tempy:.trynext:INX:CPX StrAlen:BNE vc:TXA:RTS:.vc:INY:LDA(APtr),Y:CMP StrA%,X:BEQ trynext:AND #&80:
CMP StrA%,X:BEQ trynext:LDY tempy:INY:BNE qj
.endrec:JSR nxr:LDY #0:BEQ qj
}

.SortStr
{
JSR stl:JSR Capitalise:JMP CheckLen:\rts
\SetLen stl StrAlen from &od
.stl:LDY #0:LDA #&0D:.wz:CMP StrA%,Y:BEQ wy:INY:BNE wz:.wy:STY StrAlen:RTS
\Capitalise StrA%
.Capitalise:LDY StrAlen:.aa:LDA StrA%,Y:CMP #97:BCC ab:SBC #32:STA StrA%,Y:.ab:DEY:BPL aa:RTS
\CheckLen
\look for nulls and space at end
.CheckLen:RTS:LDY StrAlen:.ya:DEY:LDA StrA%,Y:BEQ ya:CMP #' ':BEQ ya:INY:STY StrAlen:RTS
}
.nextrecord
.nxr
{
LDY #&FF:.qe:INY:LDA(APtr),Y:BEQ aa:CMP #&80:BCC qe:INY:TYA:CLC:
ADC APtr:STA APtr:LDA #0:ADC APtr+1:STA APtr+1

.isn:INC sno:BNE pb:INC sno+1:.pb:.aa:RTS
}

\SPECIALS ABOVE ALTER NoSpecials%
\*DRIVE
EQUS"*DR",&AE
\*DIN
EQUS"*DI",&CE
\*LOAD
EQUS"LO.",&A0
\*CODE for music the yorkshire boys
EQUS"K.0 */code|M",&8D

.erraddr:EQUW errtxt
.errtxt
\ 1 usage"
EQUS"Usage <fsp> L:0000 E:0000 (<dno>/<dsp>) (<drv>)":EQUB &8D
\ 2 file not found 
EQUS"file not foun",&E4
\ 3 exe address invalid
EQUS"....",&E4
\ 4 extended help 
EQUS"L% for load 0=do not change":EQUB &D
EQUS"M% for exe 0=do not change":EQUB &D
EQUS"BASIC sets exe 8023":EQUB &D
EQUS"Basic progs need load add set to run pa":EQUB &D
EQUS"ROM lsets load 8000":EQUB &D
EQUS"LDPIC sets exe 7FFE":EQUB &D
EQUS"SHOWPIC sets exe 7FFD":EQUB &D
EQUS"TYPE sets exe 7FFC":EQUB &D
EQUS"DUMP sets exe 7FFB":EQUB &8D

\#5 EXTENDED HELP CONT
EQUS"EXEC sets exe 7FFA":EQUB&D
EQUS"TYB (the yorkshire boys music) sets exe 7FF9":EQUB &D
EQUS"Version 0.9"
EQUD&8D

.end


SAVE "alter+", start, end
\cd bbc/beebasm
\beebasm -i alter+.asm -do alter+.ssd -boot alter -v -title alter+