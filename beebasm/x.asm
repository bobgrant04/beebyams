
\based on CHe00 by martin mather 14/10/2006 
\Usage <fsp> (<dno>/<dsp>) (<drv>)
\basic progs have exe of 8023
\basic prog load add is correct
\roms have load add of 8000
\ldpic on disk with the file
\ldpic files have exe of 7FFE
\Showpic files exe of 7FFD
\Showpic  on disk
\Files to be typed exe 7FFC
\Files to be dumped exe 7FFB
\Files to be EXEC exe 7FFA
\"…Variables
NoSpecials%=7:\"offset from 1
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
 a=&404:b=&408:c=&40C:d=&410:e=&414:f=&418:g=&41C:h=&420:i=&424:j=&428
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


ORG &7000
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
STA filesize:STA basic:TAX:LDA(blockstart),Y:CMP #&D:BNE aa
LDX #1:JSR diserror:LDX #4:JSR diserror:LDX #5:JMP diserror:\JMP so end

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
\"Process filename
\now have blockstart with filename
\Check FOR !BOOT
LDY #4:.ca:LDA boot,Y:CMP(blockstart),Y:BEQ cc:CLC:ADC #32
CMP(blockstart),Y:BNE cb:.cc:DEY:BPL ca
\Have boot
\See ADVANCED DISKUSER GUIDE pg168
LDA #0:STA cat:LDA #strA% MOD 256:STA cat+1:LDA# strA% DIV 256:STA cat+2
LDA #0:STA cat+3:STA cat+4:LDA #5:LDX #cat MOD 256:LDY #cat DIV 256:JSR osgbpb
\Check for exec  (OPT4,3)
LDY strA%:LDA strA%+1,Y:CMP #3:BNE cb
LDX #5:JSR prepcmd:JSR addparam:JMP execmd
\get file info
.cb
LDX #blockstart:LDY #0:LDA #5:JSR osfile:CMP #1:BEQ al:LDX #2:JMP diserror:.al
\DEBUG FOR FILE TYPE MAGIC
JMP magic
\file not found
\get file info if A<> 1 not a file
\check for specials
LDA #EndSpecial%:STA switch:LDX #NoSpecials%
LDA exe
.ag:CMP switch:BNE aw
.exespecial:JSR prepcmd:JSR addparam:JMP execmd
\JMP so end
.aw:INC switch:DEX:BNE ag
\Special exe address not coded
LDX #3:JSR diserror:LDX #4:JSR diserror:LDX #5:JMP diserror
\JMP so end
\prepload
.prepload
LDA load:STA trueadd:LDA load+1:STA trueadd+1
LDX #NoSpecials%+2:JSR prepcmd:JSR addparam
\now have *lo. FILENAME &D ready
\to execute
LDA load+1:CMP #&11:BCC ay
\romcheck 
.romcheck:CMP #&80:BNE bascheck:JMP execmd
\JMP so end 
.ay
\below &1100 so need to shift
LDA #&11:STA loadadd+1
LDA size+1:STA filesize:INC filesize:DEX:LDY #0
.bv:LDA ladd,Y::STA strA%,X:INX:INY:CMP #&D:BNE bv
\now have *LOAD fname 1100 ready
\bascheck
\if basic put command in kbd buf
\and set basic flag
.bascheck:LDA exe+1:STA exeadd+1:LDA exe:STA exeadd:CMP #&23:BNE ax
LDA exeadd+1:CMP #&80:BNE ax:LDA trueadd+1:STA &18:LDA #138:.ui:LDY run
LDX #0:JSR osbyte:INC ui+1:BNE ui:INC basic:.ax
\JMPtest
LDY #codeend-codebegin:.av:LDA codebegin,Y:STA codestart,Y:DEY:BPL av
\CODE NOW IN ZERO PAGE
LDY #strA% DIV 256:LDX #strA% MOD 256
\-----------------------
.codebegin
\need to keep code here to min
\loadfile and shift if required
JSRoscli
LDY #0:LDX filesize:BEQ at
.iq1:LDA(loadadd),Y:STA(trueadd),Y:INY:BNE iq1:INC loadadd+1:INC trueadd+1:DEX:BNE iq1
\JUMP OR RTS
\Note jmp will save RTS!
.at:LDA basic:BNE bz:JMP(exeadd):.bz:RTS
.codeend
\-----------------------
\Routines
\addparam
.addparam
LDY #0:.af:LDA(blockstart),Y:STA strA%,X:INX:INY:CMP #&D:BNE af:RTS
\execmd
.execmd:LDY #strA% DIV 256:LDX #strA% MOD 256:JSR oscli
LDY #0:LDA filesize:TAX:RTS
\Prepcmd
\takes x as cmdno ret x ptr to
\strA%
.prepcmd:LDY #0:.ez:DEX:BNE nexcmd:.ey:LDA cmdadd,Y:CMP #&80:BCC am:AND #&7F
STA strA%,X:INX:RTS
.am:STA strA%,X:INX:INY:BNE ey
.nexcmd:LDA cmdadd,Y:INY:CMP #&80:BCC nexcmd:BCS ez     
\Display error
\takes x as strno
.diserror
LDA erraddr:STA erradd:LDA erraddr+1:STA erradd+1
LDY #0:.ba:DEX:BNE bb:.bc:LDA(erradd),Y:CMP #&80:BCC bd:AND #&7F:JSR osasci:RTS
.bd:JSR osasci:INY:BNE bc
.bb:LDA(erradd),Y:INY:CMP #&80:BCC bb:CLC:TYA:ADC erradd:STA erradd:LDA #0
ADC erradd+1:STA erradd+1:LDY #0:BEQ ba
\SPECIAL ROUTINES
\magic will checK for -
.magicdata:EQUW &1080:\"…ldpic
EQUW &0D00:\" …Basic
EQUW &1130:\"…dec
.magic
\First load a page of data in

LDX blockstart:LDY blockstart+1:LDA #&40:JSR osfind:BNE db:RTS:.db:STA conb
LDA #0:LDY #&C:.de:STA conb,Y:DEY:BNE de:LDA #&60:STA conb+2
LDA #&FF:STA conb+5:LDA #4:LDX #0:LDY #&50:JSR osgbpb
\Close File
LDA #0:LDY conb:JSR osfind

JMP statistic
\Magic file ,ybit
LDA rawdat:LDX #4:.df:CMP magicdata,X:BEQ dg:DEX:DEX:BNE df:BEQ statistic
.dg:LDA rawdat+1:INX:CMP magicdata,X:BEQ hit:
.statistic: \need to create a page of freqs
LDA #0:STA zz:STA zz+1:TAY:.fa:STA countpg,y:DEY:BNE fa:\clear countpg
.fb:LDA rawdat,Y:TAX:CLC:ADC zz:STA zz:LDA zz+1:ADC #0:STA zz+1
STY tempy:TXA:TAY:LDA countpg,Y:TAX:INX:TXA:STA countpg,Y:LDY tempy:INY:BNE fb
LDA zz:STAz:LDA zz+1:STA z+1
RTS
.hit:CPX #1:BEQ magldpic:CPX #3:BEQ magbasic:CPX #5:BEQ magdecompact
.magldpic:.magbasic:.magdecompact:RTS
\Music
.music
\get *K.0 DEFINED AND IN BUFFER
LDX #NoSpecials%+3:JSR prepcmd:JSR execmd
LDA #15:JSR osbyte
LDA #255:LDX #1:JSR osbyte
LDA #138:LDX #0:LDY #128:JSR osbyte
LDA #35:STA &74:LDAload+1::STA &75:CLC:ADC size+1:STA &76
LDX #NoSpecials%+2:JSR prepcmd:JSR addparam:JMP execmd
\Strings
.cmdadd
\*LDPIC FE
EQUS"LDPIC",&A0
\*SCRLOAD FD not working !
EQUS"SCRLOAD",&A0
\*TYPE FC
EQUS"*TY",&AE
\*DUMP FB
 EQUS"DU",&AE
\*EXEC FA
 EQUS"EX",&AE
 \*dec F9
 EQUS"dec",&A0
\SPECIALS ABOVE ALTER NoSpecials%
\*DRIVE
EQUS"*DR",&AE
\*DIN
EQUS"*DI",&CE
\*LOAD
EQUS"LO.",&A0
\*CODE for music the yorkshire boys
EQUS"K.0 */code|M",&8D
\1100
.ladd
EQUS" 1100",&D
.boot:EQUS"!BOOT"
.erraddr:EQUW errtxt
.errtxt
\ 1 usage"
EQUS"Usage <fsp> (<dno>/<dsp>) (<drv>)":EQUB &8D
\ 2 file not found 
EQUS"file not foun",&E4
\ 3 exe address invalid
EQUS"Special exe add not code",&E4
\ 4 extended help 
 EQUS"Basic progs need exe 8023":EQUB &D
 EQUS"Basic progs need load add set to run pa":EQUB &D
 EQUS"!BOOT will be run as per disk opt":EQUB &D
 EQUS"ROM load should be 8000":EQUB &D
 EQUS"LDPIC on disk DATA has exe 7FFE":EQUB &D
 EQUS"SHOWPIC DATA has exe 7FFD NOT WORKING":EQUB &D
 EQUS"Files to be *TYPE exe 7FFC":EQUB &D
EQUS"Files to be *DUMP exe 7FFB":EQUB &D
EQUS"TYB music samples to be exe 7FFA":EQUB &8D
\#5 EXTENDED HELP CONT
EQUS"Files to be *EXEC exe 7FFA":EQUB &D
EQUS"BOOT will be run as per disk option":EQUB &D
EQUS"Version 1.1"
EQUD &8D
\"„"RUN
.run
EQUS"RUN",13,0
.end

SAVE "x", start, end
\cd bbc/beebasm
\beebasm -i x.asm -do x.ssd -boot x -v