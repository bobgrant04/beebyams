
\MAGIC used to inteligently guess exe and or load address
\Usage <fsp> (<dno>/<dsp>) (<drv>)
\if exe is in the range 7F00 then exe will not be analysied as firm indication of file given 
\load address will change for rom to &8000
\will Guess screen load mode from load address and size
\load address will be altered for BASIC progs with <>&E00
\normal *drive command and *din command will be issued (default to drive 3)
\file information will be gathered 
\Outputs E% execution L% load address  

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
\&400 A%-Z% INT
 a=&404:b=&408:c=&40C:d=&410:e=&414:f=&418:g=&41C:h=&420:i=&424:j=&428
 k=&42C:l=&430:m=&434:n=&438:o=&43C:p=&440:q=&444:r=&448:s=&44C:t=&450
 u=&454:v=&458:w=&45C:x=&460:y=&464:z=&468
\&600 String manipulation
strB%=&640
strA%=&6A0
\&900 rs232/cassette o/p buffer envelope buffer
rawdat=&900:\output for file read
\&A00 RS232 & cassette
countpg=&A00:\page for count's

\&1100-7C00 main mem
conb=&7B90 :\control block for reading disk

\os calls
osasci=&FFE3:osbyte=&FFF4:oswrch=&FFEE:osnewl=&FFE7:osgbpb=&FFD1:osfile=&FFDD
osargs=&FFDA:osbget=&FFD7:osbput=&FFD4:osbpb=&FFD1:osfind=&FFCE:osrdch=&FFE0
oscli=&FFF7:osfsc=&21E:osword=&FFF1

ORG &7100
GUARD &7C00

.start

\10 20 3dsurfa
\10 80 cow daffy guards nfl quaza
\10 00 arnee wwolf
\60 40 shape sail root03 mand01 mand02 mand04 root01 root02
\20 40 mand03
\section for magic tables

.magicdata
\all entrys of the type
\entrytype,xxxxxxx,exec,load ident
\where xxxx has different code to be run
\note order is important as a rom and basic can have characteristics of text


\Entry type 1
\Offset, nobytes,exec,load ident
\1,Offset -number of bytes in to read then use content of this to checkfrom, nobytes,exec,load ident
EQUS 1,4,7,&E7,&90,"<>&E00",&23,&80,0,&E,"relocation to E00 #1",13
EQUS 1,0,1,&10,&80,&FE,&7F,0,0,"Ldpic #1",13
EQUS 1,0,1,&60,&40,&FE,&7F,0,0,"Ldpic #2",13
EQUS 1,0,1,&10,0,&FE,&7F,0,0,"Ldpic #3",13
EQUS 1,0,1,&0D,00,&23,&80,0,0,"Basic #1",13
EQUS 1,1,2,&30,0,&30,&F8,&7F,0,0,"DEC compressed picture #1",13
\Entry 6
\6,offset,nobytes,check bytes,exec,load,ident
EQUS 6,7,3,0,"(C)",&CD,&D9,0,&80,"Rom",13
\Entry type 2
\2,Startrange,Endrange,minvalue,maxvalue,,exec,load ident
EQUS 2,&66,&78,0,&20,&F9,&7F,0,&11,"TYB music samples #6",13
\Entry type 3 
\3,loadadd,exec,load,ident
EQUS 3,&E0,&31,&F6,&7F,0,0,"Repton 3 screen #1",13
\Entry type 4
\4,exec,exec,load,ident
EQUS 4,&23,&80,&23,&80,0,0,"Basic #2",13
EQUS 4,&1F,&80,&23,&80,0,0,"Basic #3",13
EQUS 4,&2B,&80,&23,&80,0,0,"Basic #4",13
\see DecodingRepton.pdf
\8,length,exec,load,ident
EQUS 8,&30,&25,&F4,&7F,0,0,"Repton Infinity screen",13
EQUS 8,&20,&26,&F6,&7F,&E0,&31,"Repton 3 screen #2",13

\Entry 5
\5 no of high byte pairs (high,count or higher),exec,load,ident
EQUS 5,1,&77,&7,&F9,&7F,0,&11,"TYB music samples #1",13
EQUS 5,1,&76,&B,&F9,&7F,0,&11,"TYB music samples #2",13
EQUS 5,1,&66,&7,&F9,&7F,0,&11,"TYB music samples #3",13
EQUS 5,1,&68,&7,&F9,&7F,0,&11,"TYB music samples #4",13
EQUS 5,1,&67,&7,&F9,&7F,0,&11,"TYB music samples #5",13
EQUS 5,1,01,&40,&F5,&7F,0,0,"ScrLoad",13
EQUS 5,1,&FF,&A0,&F5,&7F,0,0,"ScrLoad",13
EQUS 5,2,' ',0,'e',0,&FC,&7F,0,0,"text/word #1",13
EQUS 5,2,' ',0,'E',0,&FC,&7F,0,0,"text/word #2",13
\EQUS 5,3,0,1,&80,1,&2E,1,&F7,&7F,0,0,"viewsheet",13


\https://en.wikipedia.org/wiki/Letter_frequency
\counts above 5%
\'a','e','h','i','n','o','r','s','t' =45% 
\allow for spaces commas full stops etc
\Entry 7
\7,count,no entries,bytes,exec,load,ident
EQUS 7,110,8,'a','e','h','i','n','o','r','s','t',&FC,&7F,0,0,"text/word #3",13
EQUS 7,110,8,'A','E','H','I','N','O','R','S','T',&FC,&7F,0,0,"text/word #4",13




EQUS 0

.startexec
{
\get osargs into blockstart
LDX #blockstart:LDY #0:LDA #1:JSR osargs  
\ptr to command into blockstart&70
\X,Y,A are preserved osargs
TYA:LDA #0
STA quiet
STA basic
\filesize =0 indicates no shift
\basic =0 indicates not basic
\STA loadadd
TAX:LDA(blockstart),Y:CMP #&D:BNE aa
LDX #1:JSR diserror:LDX #5:JMP diserror:\RTS
.aa:
CMP #('-'):BNE xa
INY:LDA(blockstart),Y
CMP #('Q'):BNE shift
INC quiet
.shift
LDX #0
INY:
.xb:
LDA(blockstart),Y:STA strB%,x:INY:INX:CMP #&D:BNE xb
LDY #0
.xc
LDA strB%,Y:STA (blockstart),Y:INY:CMP #&D:BNE xc
LDY #0:TYA:TAX
.xa
CMP #&D:BEQ cmdend:INY:LDA(blockstart),Y:CMP #32:BNE xa:INX:BNE xa
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
LDX #(('E'-'A')*4):JSR clearint
LDX #(('L'-'A')*4):JSR clearint
LDX #(('P'-'A')*4):JSR clearint
\"Process filename
\now have blockstart with filename does file exist

LDX #blockstart:LDY #0:LDA #5:JSR osfile:CMP #1:BEQ al:LDX #2:STX p:JMP diserror:.al
\LDA load:STA l: LDA load+1:STA l+1:LDA size:STA s:LDA size+1:STA s+1
\LDA exe:STA e:LDA exe+1:STA e+1
\check to see if exe is in the 7CXX range
LDA exe+1:CMP #&7F:BNE magic:
LDA quiet:BNE ax
LDX #4:JSR diserror
.ax
RTS
}
\this is where the magic happens uses the tables:-
\.magicdata needs data loading
\entrytype,Offset, nobytes,exec,load ident
\.countable needs data loading and count table
\byte,no,exec,load,ident
\.strcheck needs data loading
\nobytes,exec,load ident
\.loadcheck needs load info so do first!
\loadadd,exec,ident
\.loadcheck
\loadadd,exec,load,ident
\.execheck
\exe,exec,load,ident

.magic




\load a page of data in
.loadprogpage
{
LDX blockstart:LDY blockstart+1:LDA #&40:JSR osfind:BNE db:RTS:.db:STA conb
LDA #0:LDY #&C:.de:STA conb,Y:DEY:BNE de:LDA #HI(rawdat):STA conb+2
LDA #&FF:STA conb+5:LDA #4:
LDX #LO(conb):
LDY #HI(conb):
JSR osgbpb
\Close File
LDA #0:LDY conb:JSR osfind
}




.magicfile
{

LDA #LO(magicdata):STA Aptr
LDA #HI(magicdata):STA Aptr+1
\first byte is ident so construct case statement
.ff:
LDY#0:LDA(Aptr),Y:BNE ab:JSR screencheck:
\if Quiet check against existing
.alldone
{
LDA quiet:BEQ exit
LDA exe:CMP e:BNE bd
LDA exe+1:CMP e+1:BNE bd
LDX #(('E'-'A')*4):JSR clearint
.bd
LDA load:CMP l:BNE exit
LDA load+1:CMP l+1:BNE exit
LDX #(('L'-'A')*4):JSR clearint
.exit
RTS
}
.ab:


\Entry type 1
\1,Offset -number of bytes in to read then use content of this to checkfrom, nobytes,exec,load ident
\1,Offset, nobytes,exec,load ident
CMP #1:BNE cb:
{
INY:LDA(Aptr),Y:
.ac
TAX:
.fg
INY:LDA(Aptr),Y:STA matchlen:
.fh
{
INY:LDA(Aptr),Y:CMP rawdat,X:BNE movenxt
INX
DEC matchlen:BPL fh
INY
JSR fullmatch:JMP ff
}

.movenxt
{
LDY #2:LDA(Aptr),Y:CLC:ADC #7:TAY
JSR nextrec:JMP ff
}
}
.cb
\Entry type 2
\2,Startrange,Endrange,minvalue,maxvalue,exec,load ident
CMP #2:BNE aa:
{
LDA e:CLC:ADC e+1:BEQ cd
JMP alldone:\RTS
.cd
JSR statistic
JSR GethighestByte
LDY #1:LDA(Aptr),Y
CMP highestbyte:BCS ab:\< startrange
INY:LDA(Aptr),Y
CMP highestbyte:BCc ab:\> Endrange
INY:LDA(Aptr),Y
CMP noofbytes:BCS ab:\< minvalue
INY:LDA(Aptr),Y
CMP noofbytes:BCC ab:\> maxvalue
INY
JSR fullmatch:JMP ff
.ab 
LDY #7:JSR nextrec:JMP ff
}
.aa
\Entry type 3 
\3,loadadd,exec,load,ident
CMP #3:BNE ad:
{
INY:LDA(Aptr),Y
CMP load:BNE ag
INY:LDA(Aptr),Y:CMP load+1:BNE ag
INY
JSR fullmatch:JMP ff
}
.ag
LDY #7:JSR nextrec:JMP ff
.ad
\Entry type 4
\4,exec,exec,load,ident
CMP #4:BNE ah
{
INY:LDA(Aptr),Y:
CMP exe:BNE ag
INY:LDA(Aptr),Y
CMP exe+1:BNE ag
INY:JSR fullmatch:JMP ff
}
.ah
\Entry type 5
\5, no of high byte pairs, (high,count or higher),exec,load,ident
CMP #5:BNE aj
{
LDA e:CLC:ADC e+1:BEQ cd
JMP alldone:\RTS
.cd
JSR statistic
JSR GethighestByte
LDY #1
LDA(Aptr),Y:STA tempx:CLC:ROL A:STA tempy
.an
INY
LDA(Aptr),Y:CMP highestbyte:BNE ao
INY:LDA(Aptr),Y
CMP noofbytes:BCS ao
DEC tempx:BNE ap
INY:JSR fullmatch:JMP ff
.ap
LDX highestbyte
LDA #0:STA countpg,X
STY ypush
JSR GethighestByte
LDY ypush
JMP an
.ao
\move to next rec 
CLC:LDA tempy:ADC#6:TAY:JSR nextrec:JMP ff
}

.aj
\Entry 6
\6,ofset,nobytes,check bytes,exec,load,ident
CMP #6:BNE ak
{
INY
LDA(Aptr),Y:TAY:LDA rawdat,Y:TAX:
LDY #2:LDA (Aptr),Y:STA matchlen
.al
INY:LDA(Aptr),Y:CMP rawdat,X:BEQ am
JMP movenxt
.am
INX
DEC matchlen:BPL fh
INY
JSR fullmatch:JMP ff
.fh
{
INY:LDA(Aptr),Y:CMP rawdat,X:BNE movenxt
INX
DEC matchlen:BPL fh
INY
JSR fullmatch:JMP ff
}
.movenxt
{
LDY #2:LDA(Aptr),Y:CLC:ADC #7:TAY
JSR nextrec:JMP ff
}
}
.ak
\Entry type 7
\7,count,no entries,bytes,exec,load,ident
CMP #7:BNE ca
{
JSR statistic
LDA#0: STA noofbytes
INY:LDA(Aptr),Y:STA tempx:\count
INY:LDA(Aptr),Y:STA tempy:\no entries
.cb
INY:LDA(Aptr),Y:TAX
LDA countpg,X:
CLC:ADC noofbytes:STA noofbytes
DEC tempy:BPL cb
CMP tempx
BCS cc
TYA:CLC:ADC #5:TAY:JSR nextrec:JMP ff
.cc
INY
JSR fullmatch:JMP ff
}
.ca
\Entry type 8
\8,length,exec,load,ident
CMP #8:BNE bv:
{
INY:LDA(Aptr),Y
CMP size:BNE ag
INY:LDA(Aptr),Y:CMP size+1:BNE ag
INY
JSR fullmatch:JMP ff
.ag
LDY #7:JSR nextrec:JMP ff
}
.bv
\should not be here
RTS
}:\magic


.GethighestByte
{
LDA #0:TAY:
.aa:CMP countpg,Y:BCS ab
LDA countpg,Y
STY highestbyte:BCC aa
.ab
INY:BNE aa:STA noofbytes:
RTS
}
.statistic: \need to create a page of freqs
{
LDA #0:STA zz:STA zz+1:TAY:.fa:STA countpg,y:DEY:BNE fa:\clear countpg
.fb:LDA rawdat,Y:TAX:CLC:ADC zz:STA zz:LDA zz+1:ADC #0:STA zz+1
STY tempy:TXA:TAY:LDA countpg,Y:TAX:INX:TXA:STA countpg,Y:LDY tempy:INY:BNE fb
LDA zz:STAz:LDA zz+1:STA z+1
RTS
}
.nextrec
{
.aa
INY:LDA(Aptr),Y:CMP #13:BNE aa
INY:TYA
CLC:ADC Aptr:STA Aptr:LDA #0:ADC Aptr+1:STA Aptr+1
RTS
}

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
:LDY #strA% DIV 256:LDX #strA% MOD 256:JMP oscli
}


.diserror
{
LDA erraddr:STA erradd:LDA erraddr+1:STA erradd+1
LDY #0:.ba:DEX:BNE bb:.bc:LDA(erradd),Y:CMP #&80:BCC bd:AND #&7F:JSR osasci:RTS
.bd:JSR osasci:INY:BNE bc
\have more than 255 chars
inc erradd+1:BNE bc
.bb:LDA(erradd),Y:INY:CMP #&80:BCC bb:CLC:TYA:ADC erradd:STA erradd:LDA #0
ADC erradd+1:STA erradd+1:LDY #0:BEQ ba
}
\tables are all consistant at the end namely
\exec,load,ident
\need to ensure that deal with dissagreements
\if E%=0 overwrite same with L%
\report confict and clear E% and L%
.fullmatch
{
STY ypush
CLC:LDA e:ADC e+1:BEQ bc
CLC:LDA(Aptr),Y:INY:ADC(Aptr),Y:BEQ bd
DEY
LDA(Aptr),Y:CMP e:BNE abort
INY
LDA(Aptr),Y:CMP e+1:BNE abort
BEQ bd
.bc:\e is 0 need to write out
LDA(Aptr),Y:STA e
INY
LDA(Aptr),Y:STA e+1
.bd
INY
CLC:LDA l:ADC l+1:BEQ bf
CLC:LDA(Aptr),Y:INY:ADC(Aptr),Y:BEQ bg
DEY
LDA(Aptr),Y:CMP l:BNE abort
.aa
INY
LDA(Aptr),Y:CMP l+1:BNE abort
BEQ bg
.bf:\l is 0 need to write out
LDA(Aptr),Y:STA l
INY
LDA(Aptr),Y:STA l+1
.bg
INY
LDA quiet:BNE noprint
.printdescription
{
.aa
LDA(Aptr),Y:

JSR osasci:INY:CMP #13:BNE aa
TYA:CLC:ADC Aptr:STA Aptr:
LDA #0:ADC Aptr+1:STA Aptr+1
RTS
}
.noprint
{
.aa
LDA(Aptr),Y:
INY:CMP #13:BNE aa
TYA:CLC:ADC Aptr:STA Aptr:
LDA #0:ADC Aptr+1:STA Aptr+1
RTS
}
.abort
LDA #6:CLC:ADC ypush
JSR printdescription
\clear E%,L%
\LDX #(('E'-'A')*4):JSR clearint
\LDX #(('L'-'A')*4):JSR clearint
BRK
EQUS 0,"Conflict detected",&D ,0
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
.exit: RTS
}

\Clearint cli offset from a in X
.clearint
{
LDA#0:LDY#3:.dx:STA a,X:INX:DEY:BPL dx:RTS
}

.setexe
{
:STA e:LDA #&7C:STA e+1:
.exit: RTS
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
EQUS"Usage (-Q) <fsp> (<dno>/<dsp>) (<drv>)":EQUB &8D
\ 2 file not found 
EQUS"file not foun",&E4
\ 3 exe address invalid
EQUS"Special exe add not code",&E4
\ 4 magic set
EQUS"Magic already set",&8D
\ 5 extended help 
EQUS"outputs":EQUB &D
EQUS"L% for load 0=do not change":EQUB &D
EQUS"E% for exe 0=do not change":EQUB &D
EQUS"P%<>0 error":EQUB &D
 .masterlist
EQUS"E%   L% ":EQUB &D
EQUS"8023 0000 Basic":EQUB &D
EQUS"D9CD 8000 Rom":EQUB &D
EQUS"7FFE 0000 LDPIC compressed picture":EQUB &D
EQUS"7FFD 0000 SHOWPIC":EQUB &D
EQUS"7FFC 0000 type word text":EQUB &D
EQUS"7FFB 0000 DUMP":EQUB &D
EQUS"7FFA 0000 EXEC":EQUB &D
EQUS"7FF9 0000 TYB music samples":EQUB &D
EQUS"7FF8 0000 DEC compressed picture":EQUB &D
EQUS"7FF7 0000 viewsheet":EQUB &D
EQUS"7FF6 31E0 repton 3 level":EQUB &D
EQUS"7FF5 0000 ScrLoad":EQUB &D
EQUS"7FF4 0000 Repton Infinity level":EQUB &D
EQUS"7F07 7C00 mode 7 Screen":EQUB &D
EQUS"7F06 6000 mode 6 Screen":EQUB &D
EQUS"7F05 5800 mode 5 Screen":EQUB &D
EQUS"7F04 5800 mode 4 Screen":EQUB &D
EQUS"7F03 4000 mode 3 Screen":EQUB &D
EQUS"7F02 3000 mode 2 Screen":EQUB &D
EQUS"7F01 3000 mode 1 Screen":EQUB &D
EQUS"7F00 3000 mode 0 Screen":EQUB &8D

.end


SAVE "magic", start, end,startexec
\cd D:\GitHub\beebyams\beebasm
\beebasm -i .\magic\magic.asm -do .\magic\magic.ssd -boot magic -v -title magic
\beebasm -i .\magic\magic.asm -di .\magic\magic-dev.ssd -do .\magic\magic.ssd -v 
\