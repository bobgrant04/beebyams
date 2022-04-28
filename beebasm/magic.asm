
\alter used to inteligently guess exe and or load address
\Usage <fsp> (<dno>/<dsp>) (<drv>)
\if exe is in the range 7F00 then exe will not be analysied as firm indication of file given E% will return current value
\load address will change for rom to &8000
\will Guess screen load mode from load address and size
\load address will be altered for BASIC progs with <>&E00
\normal *drive command and *din command will be issued (default to drive 3)
\file information will be gathered 
\Outputs E% execution L% load address S% size 

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
matchlen=&41

\&70 to &8F reserved for 
blockstart=&70:load=blockstart+2:exe=blockstart+6:size=blockstart+&A
cat=&72
codestart=&70
zz=&8E
\&F8-F9 UNUSED BY OS
\end zero page
\&400 A%-Z% INT
 a=&404:b=&408:c=&40C:d=&410:e=&414:f=&418:g=&41C:h=&420:i=&424:j=&428
 k=&42C:l=&430:m=&434:n=&438:o=&43C:p=&440:q=&444:r=&448:s=&44C:t=&450
 u=&454:v=&458:w=&45C:x=&460:y=&464:z=&468
\&600 String manipulation
strA%=&6A0
\&A00 RS232 & cassette
\&1100-7C00 main mem
conb=&7B90 :\control block for reading disk
rawdat=&900:\output for file read
countpg=&A00:\page for count's
\os calls
osasci=&FFE3:osbyte=&FFF4:oswrch=&FFEE:osnewl=&FFE7:osgbpb=&FFD1:osfile=&FFDD
osargs=&FFDA:osbget=&FFD7:osbput=&FFD4:osbpb=&FFD1:osfind=&FFCE:osrdch=&FFE0
oscli=&FFF7:osfsc=&21E:osword=&FFF1


ORG &7500
GUARD &7C00

.start

\10 20 3dsurfa
\10 80 cow daffy guards nfl quaza
\10 00 arnee wwolf
\60 40 shape sail root03 mand01 mand02 mand04 root01 root02
\20 40 mand03


.magicdata
\entrytype,Offset, nobytes,exec,load ident
EQUS 0,0,1,&10,&80,&7F,&FE,0,0,"Ldpic",13
EQUS 0,0,1,&60,&40,&7F,&FE,0,0,"Ldpic",13
EQUS 0,0,1,&10,0,&7F,&FE,0,0,"Ldpic",13
EQUS 0,0,1,&0D,00,&80,&23,0,0,"Basic",13
EQUS 0,1,1,&30,&90,&7F,&F8,0,0,"Dec",13
EQUS 1,7,3,0,&28,&43,&29,0,0,&80,00,"Rom",13
EQUS &FF

.countable
\byte,no,exec,load,ident
EQUS 32,1,&7F,&FC,0,0,"text/word",13
EQUS &2E,10,&7F,&F7,0,0,"viewsheet",13
EQUS 0,0

.strcheck
\nobytes,exec,load ident
EQUS 7,&E7,&90,"<>&E00",&E,0,0,0,"relocation to E00",13
EQUS 0

.startexec

\get osargs into blockstart
LDX #blockstart:LDY #0:LDA #1:JSR osargs  
\ptr to command into blockstart&70
\X,Y,A are preserved osargs
TYA:LDA #0
\filesize =0 indicates no shift
\basic =0 indicates not basic
STA loadadd
STA filesize:STA basic:TAX:LDA(blockstart),Y:CMP #&D:BNE aa
LDX #1:JSR diserror:LDX #4:JSR diserror:LDX #5:JSR diserror:LDX #6:JMP diserror:\JMP so end
.aa:CMP #&D:BEQ cmdend:INY:LDA(blockstart),Y:CMP #32:BNE aa:INX:BNE aa
.cmdend:CPX #2:BNE ab:STX tempx:DEY:STY tempy
\"…"Have drive param
LDX #NoSpecials%:JSR prepcmd:LDY tempy:LDA(blockstart),Y:STA strA%,X
INX:LDA #&D:STA strA%,X
DEY:STA(blockstart),Y:STY tempy
JSR execmd
LDX tempx:LDY tempy
.ab:CPX #1:BCC ac
\"…"Have DIN param
.ad:DEY:LDA(blockstart),Y:CMP #32:BNE ad:LDA #&D:STA(blockstart),Y:STY tempy
LDX #NoSpecials%+1:JSR prepcmd:LDY tempy
DEX
.ae:INY:INX:LDA(blockstart),Y:STA strA%,X:CMP #&D:BNE ae:CMP #&32:BEQ ae
LDA #&D:STA strA%,X
JSR execmd
.ac
\clear E%,L%:S%
LDX #('E'-'A'):JSR clearint
LDX #('L'-'A'):JSR clearint
LDX #('S'-'A'):JSR clearint
\"Process filename
\now have blockstart with filename does file exist

LDX #blockstart:LDY #0:LDA #5:JSR osfile:CMP #1:BEQ al:LDX #2:JMP diserror:.al
LDA load:STA l: LDA load+1:STA l+1:LDA size:STA s:LDA size+1:STA s+1
LDA exe:STA e:LDA exe+1:STA e+1
\check to see if exe is in the 7CXX range
LDA exe+1:CMP #&7F:BNE trybasic:
STA l+1:LDA exe:STA l:RTS
.trybasic:CMP #&80:BNE magic
LDA exe:CMP #&23:BEQ setbasic
CMP #&2B:BEQ setbasic
CMP #&1F:BNE magic
.setbasic
LDA #&23:STA e:RTS
.magic
\First load a page of data in

LDX blockstart:LDY blockstart+1:LDA #&40:JSR osfind:BNE db:RTS:.db:STA conb
LDA #0:LDY #&C:.de:STA conb,Y:DEY:BNE de:LDA #&60:STA conb+2
LDA #&FF:STA conb+5:LDA #4:
LDX #LO(conb):
LDY #HI(conb):
JSR osgbpb
\Close File
LDA #0:LDY conb:JSR osfind

.magicfile
{
LDA #LO(magicdata):STA Aptr
LDA #HI(magicdata):STA Aptr+1

\entrytype,Offset, nobytes,values,filetype ident
.ff:LDY#0:LDA(Aptr),Y:BNE offset
INY:LDA(Aptr),Y:TAX:
.fg
INY:LDA(Aptr),Y:STA matchlen:
.fh:INY:LDA(Aptr),Y:CMP rawdat,X:BNE movenxt
INX
DEC matchlen:BPL fh
JSR fullmatch
LDA e:CMP #&23:BNE fj:LDA e+1:CMP #&80:BNE fj:
JMP relocationcheck
.fj:JSR screencheck
RTS

.offset
CMP #&FF:BEQ statistic
INY:LDA(Aptr),Y:TAX:LDA rawdat,X:TAX:BNE fg

.movenxt

LDY #2:LDA(Aptr),Y:CLC:ADC #6:TAY
.jj
INY:LDA(Aptr),Y:CMP #13:BNE jj
INY:TYA:CLC:ADC Aptr:STA Aptr:LDA #0:ADC Aptr+1:STA Aptr+1:JMP ff
}

.statistic: \need to create a page of freqs
{
LDA #0:STA zz:STA zz+1:TAY:.fa:STA countpg,y:DEY:BNE fa:\clear countpg
.fb:LDA rawdat,Y:TAX:CLC:ADC zz:STA zz:LDA zz+1:ADC #0:STA zz+1
STY tempy:TXA:TAY:LDA countpg,Y:TAX:INX:TXA:STA countpg,Y:LDY tempy:INY:BNE fb
LDA zz:STAz:LDA zz+1:STA z+1
}
.highestByte
{
LDA #&FF:TAX:LDY #0
.gg:CMP countpg,Y:BEQ gh:DEY:BNE gg:DEX:TXA:BNE gg
.gh:STY y:STA x
\byte,no,exec,load,ident
.counttable
LDA #LO(countable):STA Aptr
LDA #HI(countable):STA Aptr+1
.bb:LDY #0
LDA(Aptr),Y:CMP y:BEQ bc:INY:LDA(Aptr),Y:
BNE nxtrec:RTS
.bc:
INY:LDA(Aptr),Y:cmp #0:BNE bv:RTS:.bv:CMP x:BCS nxtrec:JMP fullmatch
.nxtrec:LDY #6:.bf:INY:LDA(Aptr),Y:CMP #13:BNE bf:
INY:TYA:CLC:ADC Aptr:STA Aptr:LDA #0:ADC Aptr+1:STA Aptr+1:JMP bb
}

\Prepcmd
\takes x as cmdno ret x ptr to
\strA%
.prepcmd:LDY #0:.ez:DEX:BNE nexcmd:.ey:LDA cmdadd,Y:CMP #&80:BCC am:AND #&7F
STA strA%,X:INX:RTS
.am:STA strA%,X:INX:INY:BNE ey
.nexcmd:LDA cmdadd,Y:INY:CMP #&80:BCC nexcmd:BCS ez 


\execmd
.execmd:LDY #strA% DIV 256:LDX #strA% MOD 256:JMP oscli

\checks for byte patterns and alters L or E as appropriate
.relocationcheck
{
LDA #LO(strcheck):STA Aptr
LDA #HI(strcheck):STA Aptr+1
LDA #0:TAX:
.ad:LDY #0:
LDA(Aptr),Y:BEQ aa:STA matchlen:
INY:LDA(Aptr),Y:
.ac:CMP rawdat,X:BEQ ab:INX:BNE ac:RTS
.ab:LDA matchlen:STA tempx
.af
DEC tempx:BPL ae:INY:JMP fullmatch
.ae:INY:INX:LDA(Aptr),Y:CMP rawdat,X:BNE ad:BEQ af
.aa:RTS
}

.diserror
{
LDA erraddr:STA erradd:LDA erraddr+1:STA erradd+1
LDY #0:.ba:DEX:BNE bb:.bc:LDA(erradd),Y:CMP #&80:BCC bd:AND #&7F:JSR osasci:RTS
.bd:JSR osasci:INY:BNE bc
.bb:LDA(erradd),Y:INY:CMP #&80:BCC bb:CLC:TYA:ADC erradd:STA erradd:LDA #0
ADC erradd+1:STA erradd+1:LDY #0:BEQ ba
}

.fullmatch
{
LDA(Aptr),Y:STA e:INY:LDA(Aptr),Y:BEQ aa:STA e+1:INY:LDA(Aptr),Y:STA e:INY:.ab:LDA(Aptr),Y:BEQ ac:STA l+1:INY:LDA(Aptr),Y:STA l
.fi
INY:LDA(Aptr),Y:JSR osasci:CMP #13:BNE fi:RTS
.aa:INY:INY:BNE ab:.ac:INY:BNE fi
}
\checks for full screen load

.screencheck
{
\mode 7 &7C00 len &400
LDA l+1:CMP #&7C:BNE aa
LDA s+1:CMP #4:BNE exit
LDA #7:JMP setexe
.aa
\mode 6 &6000 len &2000
CMP  #&60:BNE ab
LDA s+1:CMP #&20:BNE exit
LDA #6:JMP setexe
.ab
\mode 4,5 &5800 len &2800
CMP  #&58:BNE ac
LDA s+1:CMP #&28:BNE exit
LDA #4:JMP setexe
.ac
\mode 3 &4000 len &4000
CMP  #&40:BNE ad
LDA s+1:CMP #&40:BNE exit
LDA #3:JMP setexe
.ad
\mode 0,1,2 &3000 len &5000
CMP  #&30:BNE exit
LDA s+1:CMP #&50:BNE exit
LDA #0:JMP setexe
}
\Clearint cli offset from a in X
.clearint
{
LDA#0:LDY#3:.dx:STA a,X:INX:DEY:BPL dx:RTS
}
.setexe:STA e:LDA #&7C:STA e+1:
.exit: RTS

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
EQUS"outputs":EQUB &D
EQUS"L% for load 0=do not change":EQUB &D
EQUS"E% for exe 0=do not change":EQUB &D
 .masterlist
EQUS"E%   L% ":EQUB &D
EQUS"8023 0000 Basic":EQUB &D
EQUS"0000 8000 Rom":EQUB &8D
\#5 EXTENDED HELP CONT
EQUS"7FFE 0000 LDPIC compressed picture":EQUB &D
EQUS"7FFD 0000 SHOWPIC":EQUB &D
EQUS"7FFC 0000 type word text":EQUB &D
EQUS"7FFB 0000 DUMP":EQUB &D
EQUS"7FFA 0000 EXEC":EQUB &D
EQUS"7FF9 0000 TYB music samples":EQUB &D
EQUS"7FF8 0000 DEC compressed picture":EQUB &D
EQUS"7FF7 0000 viewsheet":EQUB &D
EQUS"7F07 7C00 mode 7 Screen":EQUB &D
EQUS"7F06 6000 mode 6 Screen":EQUB &D
EQUS"7F05 5800 mode 5 Screen":EQUB &D
EQUS"7F04 5800 mode 4 Screen":EQUB &D
EQUS"7F03 4000 mode 3 Screen":EQUB &D
EQUS"7F02 3000 mode 2 Screen":EQUB &D
EQUS"7F01 3000 mode 1 Screen":EQUB &D
EQUS"7F00 3000 mode 0 Screen":EQUB &D
EQUD&8D

.end


SAVE "magic", start, end,startexec
\cd D:\GitHub\beebyams\beebasm
\beebasm -i magic.asm -do magic.ssd -boot magic -v -title magic