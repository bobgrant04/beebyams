
\based on ideas in CHe00 by martin mather 14/10/2006 
\Usage <fsp> (<dno>/<dsp>)
\todo repton screens will fail if not drive 3


\"…Variables
NoSpecials%=7:\"offset from 1
EndSpecial%=&FF-NoSpecials%
\ZERO page
\&00 - &01 LOMEM
\pointer to the start of BASIC variables.
\--------------------------------------------------------------
\&02 - &03 VARTOP
\pointer to the end of BASIC variabtes.
\--------------------------------------------------------------
\&04 — &05 BASIC STACK POINTER
\pointer to most recent entry in the BASIC stack.
\--------------------------------------------------------------
\&06 - &07 HIMEM
\pointer to the start of screen memory-mapped area.
\--------------------------------------------------------------
\&08 - &09 ERL
\the address of the instruction which errored.
\--------------------------------------------------------------
\&0A BASIC TEXT POINTER OFFSET
\the offset with respect to &B,&C of the
\byte of BASIC text currently being processed.
\--------------------------------------------------------------
\&0B - &0C BASIC TEXT POINTER
\pointer to start of BASIC text line being processed.
\--------------------------------------------------------------
\&0D - &11 RND WORK AREA
\
\--------------------------------------------------------------
\&12 - &13 TOP
\pointer to the end of BASIC program not
\including variables.
\--------------------------------------------------------------
\&14 PRINT BYTES
\the number of bytes in a print output field.
\--------------------------------------------------------------
\&15 PRINT FLAG
\0 = decimal
\-ve = hexadecimal
\--------------------------------------------------------------
\&16 - &17 ERROR ROUTINE VECTOR
\pointer to the address of the BASIC error routine.
\--------------------------------------------------------------
\&18 PAGE DIV 256
\page number where BASIC program starts.
\--------------------------------------------------------------
\&19 - &1A SECONDARY BASIC TEXT POINTER
\secondary &B,&C.
\--------------------------------------------------------------
\&1B SECONDARY BASIC TEXT OFFSET
\secondary &A.
\--------------------------------------------------------------
\&1C - &1D BASIC PROGRAM START
\pointer to start of BASIC program.
\--------------------------------------------------------------
\&1E COUNT
\number of bytes printed since Last new tine.
\--------------------------------------------------------------
\&1F LISTO FLAG
\a number ANDed from the list below.
\0 = LISTO off
\1 = insert space after line number
\2 = indent FOR loops
\4 = indent REPEAT loops
\--------------------------------------------------------------
\&20 TRACE FLAG
\0 = trace off
\1 = trace on
\--------------------------------------------------------------
\&21 - &22 MAXIMUM TRACE LINE NUMBER
\--------------------------------------------------------------
\&23 WIDTH
\as set by WIDTH command.
\--------------------------------------------------------------
\&24 REPEAT LEVEL
\number of nested REPEATS outstanding.
\--------------------------------------------------------------
\&25 GOSUB LEVEL
\number of nested GOSUBS outstanding.
\--------------------------------------------------------------
\&26 15*FOR LEVEL
\15 * number of nested FOR Loops outstanding.
\--------------------------------------------------------------
\&27 VARIABLE TYPE
\&00 = byte
\&04 = integer
\&05 = fLoating point
\&81 = string
\&A4 = function name
\&F2 = procedure name
\--------------------------------------------------------------
\&28 OPT FLAG
\bit 0 = list flag
\bit 1 = errors flag
\bit 2 = retocate flag (BASIC 2 only)
\--------------------------------------------------------------
\&29 not used
\--------------------------------------------------------------
\--------------------------------------------------------------
\&2A - &2D INTEGER WORK AREA
strptr=&2A
Aptr=&2C
\--------------------------------------------------------------
\&2E - &35 FLOATING POINT WORK AREA A
trueadd=&2E
loadadd=&30
exeadd=&32
erradd=&34
filetype=&35
\--------------------------------------------------------------
\&36 LENGTH OF STRING BUFFER
\--------------------------------------------------------------
\&37 - &3A GENERAL AREAS
\--------------------------------------------------------------
\&3B - &42 FLOATING POINT WORK AREA B
\single bytes
filesize=&3B
strAoffset=&3C
tempx=&3D
switch=&3E
basic=&3F
tempy=&40
requesteddrive=&41
drive=&42
\--------------------------------------------------------------
\&43 - &4F FLOATING POINT TEMPORARY AREAS
zp=&43
\--------------------------------------------------------------
\&50 - &6F not used
\--------------------------------------------------------------
\IntA &2A -&2D

\&2E TO &35 basic float

\&3B to &42 basic float
\single bytes

\&50-&6F Not used
osargsptr=&50
\&70 to &8F reserved for 
blockstart=&70:load=blockstart+2:exe=blockstart+6:size=blockstart+&A
cat=&72
codestart=&70
zz=&8E
\90-9F	allocated for Econet system
\A0-A7	used by current NMI (mostly disc and network filing)
\   A8-AF	used for OS commands when executing
\   B0-BF	filing system scratch space
\   C0-CF	allocated to current active filing system
\   D0-E1	allocated to VDU driver
\   E2		cassette filing system status
\   E3		cassette filing system options
\   E4-E6	OS workspace
\   E7		auto repeat countdown timer
\   E8-E9	pointer to OSWORD &01 input buffer
\   EA		RS423 timeout counter
\   EB		cassette filing system flag
\   EC		internal number of last key pressed
\   ED		as above ,but for key still being pressed
\   EE		internal number of key to ignore ,set by OSBYTE &79
\   EF		accumulator value of most recent OSBYTE/OSWORD
\   F0		X register value of most recent OSBYTE/OSWORD
\		 or stack pointer value of last BRK
\   F1		Y register value of most recent OSBYTE/OSWORD
\   F2-F3	text pointer
\   F4		RAM copy number of currently selected paged ROM
\   F5		current PHROM or ROM filing system ROM number
\   F6-F7	address pointer to paged ROM
\&F8-F9 UNUSED BY OS
\FA-FB	general workspace for OS
\   FC		user IRQ routine slave slot for register
\   FD-FE	pointer to byte after last BRK
\   FF		Escape flag
\end zero page

\vectors
USERV =&200	\reserved
brkv =&202	\break vector
IRQ1V = &204	\all IRQ vector
IRQ2V = &206	\unrecognised IRQ
CLIV = &208	\interpret command line given
BYTEV = &20A	\miscellaneous OS operations (register parameters)
WORDV = &20C	\miscellaneous OS operations (control block parameters)
WRCHV =&20E	\write character to screen from A
RDCHV =&210 \read character to A from keyboard
FILEV =&212	\load or save file
ARGSV =&214	\load or save data on file
BGETV =&216	\load byte to A from file
BPUTV =&218	\save byte to file from A
GBPBV =&21A	\load or save block of memory to file
FINDV =&21C	\open or close file
FSCV =&21E	\file system control entry
EVNTV =&220	\event interrupt
UPTV =&220	\user print routine


\&400 A%-Z% INT
 a=&404:b=&408:c=&40C:d=&410:e=&414:f=&418:g=&41C:h=&420:i=&424:j=&428
 k=&42C:l=&430:m=&434:n=&438:o=&43C:p=&440:q=&444:r=&448:s=&44C:t=&450
 u=&454:v=&458:w=&45C:x=&460:y=&464:z=&468
\&46C - &470 TEMP 1
\&471 - &475 TEMP 2
\&476 - &47A TEMP 3
\&478 - &47F TEMP 4
\&600 String manipulation
osgbpbdata%=&600
shortcode=&640
strA%=&6A0
pram%=&6F0
filename%=&6D0
\&900 - &AFF RS232 & cassette openin/open out
\&B00 &BFF programmable keys
\&C00 CFF extended character
\&D00 DFF  disk operations
\&1100-7C00 main mem


\os calls
osasci=&FFE3:osbyte=&FFF4:oswrch=&FFEE:osnewl=&FFE7:
osgbpb=&FFD1:osargs=&FFDA:osfile=&FFDD

osbget=&FFD7:osbput=&FFD4:osbpb=&FFD1:osfind=&FFCE
osrdch=&FFE0:oscli=&FFF7:osfsc=&21E:osword=&FFF1


ORG &6800
GUARD &7C00

.start
\"„"RUN this can not be over page boundry hence put at top
.run
EQUS"RUN",13,0

.modexec
INCBIN ".\x\$.modexec"

.altdec
INCBIN ".\x\$.altdec"

.scrload
INCBIN ".\x\$.altscrl"
\scrload headerless 

.ldpic
INCBIN ".\x\$.altldpc"
\the yorkshire boys music

\SKIPTO &7200

.tybmusic
INCBIN ".\x\$.code2"



.startexec
\init stuff
\filesize =0 indicates no shift
\basic =0 indicates not basic
{
LDA #0
STA loadadd
STA filesize:STA basic
LDA #'3':STA requesteddrive
JSR getfilesystemtype
LDA filetype:CMP #&80:BCS fc
\should not be here unsupported filing system
LDA #unsupported%:JMP diserror:\JMP so end
.fc
LDA filetype:AND #&7F
STA filetype
}
JSR getargumentcount
\get osargs into blockstart
\LDX #blockstart:LDY #0:LDA #1:JSR osargs  
\ptr to command into blockstart&70
\X,Y,A are preserved osargs will explicitly set


CPX #0:BNE za:\no parms?
LDX #1:JSR diserror
LDX #3:JSR diserror
LDX #4:JSR diserror
LDX #5:JMP diserror:\rts
.za
{
CPX #3:BCC zb
LDX #1:JSR diserror
LDX #tomanyargs%:JMP diserror:\RTS
}
.zb
CPX #2:BNE zc

JSR copyargumentXintostrA
JSR StrAtopram
BVC ready:\jmp 
.zc
JSR gettitleopt
{
LDX #0
.bb:LDA strA%+1,X:STA pram%,X:INX:CMP #0
BEQ bc:CPX #13:BEQ bc:BNE bb
.bc:DEX:LDA #&D:STA pram%,X
}

.ready
JSR setdisk
LDX requesteddrive
JSR setdrivex
LDX #1
JSR copyargumentXintostrA
\JSR StrAtopram
\check for !boot
\See ADVANCED DISKUSER GUIDE pg168
.boot
{
LDY #4:.ca:LDA boottxt,Y:CMP strA%,Y:BEQ cc:CLC:ADC #32
CMP strA%,Y:BNE notboot:.cc:DEY:BPL ca
JSR gettitleopt
\Check for exec  (OPT4,3)
LDY strA%:LDA strA%+1,Y:CMP #3:BNE notboot
LDX #execfilecmd%:JMP formcmdandexec:\rts
}
.notboot
JSR copyargumentXintostrA
JSR StrAtopram
LDA #LO(strA%):STA blockstart:
LDA #HI(strA%):STA blockstart+1:
LDX #blockstart:LDY #0:LDA #5:JSR osfile:CMP #1:BEQ al:

\Have drive param
\LDA(blockstart),Y:STA requesteddrive:TAX:
\JSR setdrivex
\LDX #dricmd%:JSR initprepcmd:LDA requesteddrive:INX:STA strA%,X
\INX:LDA #&D:STA strA%,X
\DEY:STA(blockstart),Y:STY tempy
\JSR execmd
\LDX tempx:LDY tempy
\.aaab:STX tempx:DEY:STY tempy
\CPX #1:BCS ad
\Do not have Disktitle to will read the current one
\JSR gettitleopt
\ret strA
\len title
\n bytes title
\opt 4.X
{
\LDX #0
\.bb:LDA strA%+1,X:STA pram%,X:INX:CMP #0:BEQ bc:CPX #13:BEQ bc:BNE bb
\.bc:DEX:LDA #&D:STA pram%,X:BVC issuedin
}
\Have DIN param
\.debug
\.ad:DEY:LDA(blockstart),Y:CMP #32:BNE ad
\LDA #&D:STA(blockstart),Y
\DEY
\.dd:DEY:LDA(blockstart),Y:CMP #32:BNE dd
\LDX #&FF:STY tempy
\.fr:INY:INX:LDA(blockstart),Y:STA pram%,X:CMP #&D:BNE fr

\have all the info we need to issue din command
\.issuedin
\RTS

\LDY tempy
\.ae:INY:INX:LDA(blockstart),Y:STA strA%,X:CMP #&D:BNE ae
\CMP #&32:BEQ ae
\LDA #&D:STA strA%,X
\JSR execmd
.ac
\"Process filename
\now have blockstart with filename

\Check FOR !BOOT
\.boot
\{
\LDY #4:.ca:LDA boottxt,Y:CMP(blockstart),Y:BEQ cc:CLC:ADC #32
\CMP(blockstart),Y:BNE notboot:.cc:DEY:BPL ca
\Have boot
\See ADVANCED DISKUSER GUIDE pg168
\JSR gettitleopt
\Check for exec  (OPT4,3)
\LDY strA%:LDA strA%+1,Y:CMP #3:BNE notboot
\LDX #execfilecmd%:JSR initprepcmd:JSR addosparam:JMP execmd:\rts
\get file info
\}
\.notboot

\LDX #blockstart:LDY #0:LDA #5:JSR osfile:CMP #1:BEQ al:

\file not found
\get file info if A<> 1 not a file
\check for specials
LDX #notfound%:JMP diserror:\RTS
.al
LDA exe+1:CMP #&7F:BEQ specials
CMP #&80:BNE endspecial
LDA exe:CMP #&23:BNE endspecial
\basic program
{
LDA load+1:STA &18:\set page
\code to add chars to buffer ("RUN",13)
\fragile code if over page boundary
.ui:LDY run:BEQ ab:INC ui+1
LDA #138:
LDX #0:JSR osbyte:BNE ui:.ab:INC basic
}
.endspecial:JMP prepload
 
\Specials
.specials
{

LDA exe:LDX #0
CMP #&FE:BNE ca
\7FFE LDPIC compressed picture
{
LDA blockstart:STA z:LDA blockstart+1:STA z+1
LDY #0:.xb:LDA (blockstart),y:STA strA%,Y:INY:CMP #&D:BNE xb

INC blockstart:bne sa:INC blockstart+1:.sa

LDY #0:.xx
LDA ldpic,Y:STA &900,Y
LDA ldpic+&100,Y:STA &A00,Y
INY:BNE xx
LDX #LO(strA%):LDY #HI(strA%):LDA #&40
JMP &900:\RTS
}
\7FFD SHOWPIC"
.ca:CMP #&FD:BNE cc
LDX #scrloadcmd%
\7FFC type word text
.cc:CMP #&FC:BNE cd
LDX #typecmd%
\7FFB DUMP
.cd:CMP #&FB:BNE ce
LDX #dumpcmd%
\7FFA EXEC
.ce:CMP #&FA:BNE cf
LDX #execfilecmd%
\7FF9 TYB music samples
.cf:CMP #&F9:BNE cg
{
LDY #0:.xy:LDA tybmusic,Y:STA &900,Y:INY:BNE xy
LDA #35:STA &74:LDAload+1::STA &75:CLC:ADC size+1:STA &76
\setup load command
LDX #loadcmd%:JSR initprepcmd:JSR addpram
\now have *lo. FILENAME &D ready
\LDY #0:DEX
LDX #laddcmd%:JSR prepcmd
\.bv:LDA ladd,Y::STA strA%,X:INX:INY:CMP #&D:BNE bv
\now have *l. FILENAME &1100 OD
\code for shortcode
\no of bytes 10 so make &10
LDY #8
.kk:LDA shiftme,Y:STA shortcode,Y:DEY:BPL kk
LDY #HI(strA%):LDX #LO(strA%)
JMP shortcode
.shiftme
JSR oscli
JMP &900
}
}
\7FF8 DEC compressed picture
.cg:CMP #&F8:BNE ch
{
\load altdec into A00
LDY #0:.xx
LDA altdec,Y:STA &A00,Y:
LDA altdec+&100,Y:STA &B00,Y
INY:BNE xx
LDY #0:.xb
LDA (blockstart),y:STA &BDD,Y:INY:CMP #&D:BNE xb
JMP &A00:\rts
}

\7FF7 viewsheet
.ch:CMP #&F7:BNE ci
LDX #9
.ci CMP #&F6:BNE cj

\7FF6 repton3 screen
\setup *k.1
\need to select repton3 disk
\display text g=get
\*rep2
.repton3
{
LDX #1:JSR copyargumentXintostrA
JSR StrAtopram
LDX #key1cmd%:JSR formcmdandexec

\todo
LDX #'0'
STX requesteddrive
JSR setdrivex
\JSR setdisk
\set drive 0 to x-files
\LDX #2:JSR copyargumentXintostrA
\JSR StrAtopram
LDX #xfilescmd%:JSR initprepcmd
JSR StrAtopram
JSR setdisk
\LDX #1:JSR copyargumentXintostrA
\JSR StrAtopram
\JSR execmd

\*k.1 setup
\LDX #key1cmd%:JSR formcmdandexec
\JSR initprepcmd:JSR addparam:JSR execmd
\*repton2
LDX #reptonthreecmd%:JSR initprepcmd:


\display text
{
LDA #repinfin%:STA tempx
JSR reptoninstructions
}

\need to init zero page (&70 &82 loaded with zero)
LDX #18:LDA #0
.ab
STA &70,X:DEX:BPL ab
\need to initaise &7C and &7F
lDA #&60:STA &7C
LDA #&3:STA &7F

JMP setandexe:\RTS


}
\7FF5 scrload
.cj CMP #&F5:BNE ck
{
LDY #0:.xx:LDA scrload,Y:STA &900,Y:INY:BNE xx
LDY #0:.xa:LDA scrload+&100,Y:STA &A00,Y:INY:BNE xa
JSR sco
\set file name into strA%
LDA #0:TAY:TAX:JSR addosparam
JMP &900
}
.ck:CMP #&F4:BNE cl
\repton infinity
\note it may be possible to overly the file directly into the game file
\*keys do not work as memory overwritten
\ see https://www.reptonresourcepage.co.uk/Downloads/Items/DecodingRepton.pdf
\set to dr.0
\set drive 0 to x-files
\need to delete g.a from x-files if it exists
\copy file to xfiles (dr.0)
\access file
\rename file to g.a
\display information
\*repi
\------
\set to dr.0
LDX #'0':STX requesteddrive
JSR setdrivex
\set drive 0 to x-files
LDX #xfilescmd%:JSR initprepcmd:JSR StrAtopram
JSR setdisk
LDX #1
JSR copyargumentXintostrA
JSR StrAtopram
\LDX #xfilescmd%:JSR initprepcmd:JSR execmd
\need to delete prelude from x-files without interaction
LDX #LO(preludetxt):LDY #HI(preludetxt):LDA #6:JSR osfile

\copy file to xfiles (dr.0) 
\copy 3 0 XXXX
LDX #copycmd%
JSR formcmdandexec
\JSR initprepcmd:JSR addparam:

\DEX:JSR addprelude:
\JSR execmd
\LDX #'0':JSR setdrivex

\LDX #NoSpecials%+6
\JSR initprepcmd:JSR execmd
\rename file to prelude
LDX #renamecmd%
JSR initprepcmd:JSR addpram:
LDX #preludecmd%:JSR prepcmd:JSR execmd
\DEX:JSR addprelude:JSR execmd

\display text
LDA #repinfin%:STA tempx
JSR reptoninstructions

\{
\LDX #0
\.aa:LDA reptoninfinitytext,X:BEQ ac:JSR osasci:INX:BNE aa
\.ac
\JSR gti
LDX #reptonicmd%
JSR initprepcmd:
\}
\setmode and execute
.setandexe
{
LDY #0:.xx:LDA modexec,Y:STA &900,Y:INY:BNE xx
LDX #5:JMP &900
}
\*repi
\LDX #NoSpecials%+9
\JSR initprepcmd:JMP execmd:\RTS
.cl
.cz:CPX#00:BEQ screencheck:
JMP formcmdandexec:\rts
\JSR initprepcmd:JSR addparam:JMP execmd
\JMP so end


.screencheck
{
CMP #8:BCS notcoded

LDA #22:JSR osasci:LDA exe:JSR osasci:JSR sco
LDX #loadcmd%:JSR formcmdandexec
JMP gti
\now have *lo. FILENAME &D ready
RTS
\EQUS"7F07 mode 7 Screen":EQUB &D
\EQUS"7F06 mode 6 Screen":EQUB &D
\EQUS"7F05 mode 5 Screen":EQUB &D
\EQUS"7F04 mode 4 Screen":EQUB &D
\EQUS"7F03 mode 3 Screen":EQUB &D
\EQUS"7F02 mode 2 Screen":EQUB &D
\EQUS"7F01 mode 1 Screen":EQUB &D
\EQUS"7F00 mode 0 Screen":EQUB &D \22 7 curser off g=get
}
LDA #EndSpecial%:STA switch:LDX #dricmd%
LDA exe
.ag:CMP switch:BNE aw
.exespecial:JMP formcmdandexec:\rts
\JMP so end
.aw:INC switch:DEX:BNE ag
\Special exe address not coded
.notcoded
LDX #3:JSR diserror:LDX #4:JSR diserror:LDX #5:JMP diserror:\rts
\JMP so end
\prepload
.prepload
LDA load:STA trueadd:LDA load+1:STA trueadd+1
LDX #loadcmd%:JSR initprepcmd:JSR addpram
\now have *lo. FILENAME &D ready
\to execute
LDA exe:STA exeadd:LDA exe+1:STA exeadd+1
LDA load+1:CMP #&11:BCC ay
\romcheck 
.romcheck
CMP #&80:BNE zeropage
.bx:JMP execmd
\JMP so end 
.ay
\below &1100 so need to shift
LDA #&11:STA loadadd+1
LDA size+1:STA filesize:INC filesize:DEX:LDY #0
LDx #laddcmd%:JSR prepcmd
\.bv:LDA ladd,Y:STA strA%,X:INX:INY:CMP #&D:BNE bv
\now have *LOAD fname 1100 ready
.zeropage
\debug
\RTS

\JMPtest
LDY #codeend-codebegin:.av:LDA codebegin,Y:STA codestart,Y:DEY:BPL av
\CODE NOW IN ZERO PAGE
LDY #HI(strA%):LDX #LO(strA%)
JMP codestart
\-----------------------
.codebegin
\need to keep code here to min
\loadfile and shift if required
JSR oscli
LDY #0:LDX filesize:BEQ at
.iq1:LDA(loadadd),Y:STA(trueadd),Y:INY:BNE iq1:INC loadadd+1:INC trueadd+1:DEX:BPL iq1
\JUMP OR RTS
\Note jmp will save RTS!
.at:LDA basic:BNE bz:JMP(exeadd):.bz:RTS
.codeend
\--------------------------------------------
\Routines
.addprelude
{
LDY #0:.af:LDA preludetxt,Y:STA strA%,X:INX:INY:CMP #&D:BNE af:RTS
}
.formcmdandexec
{
JSR initprepcmd:JSR addpram:JMP execmd:\RTS
}
\addparam
.addosparam
{
LDX strAoffset
LDY #&FF:
.af:INX:INY:LDA(blockstart),Y:STA strA%,X::CMP #&D:BNE af:
STX strAoffset
RTS
}

\add pram$ to strA%
.addpram
{
LDY #&FF
LDX strAoffset
.ae:INY:INX:LDA pram%,Y:STA strA%,X:CMP #&D:BEQ af:BNE ae
.af:DEX:STX strAoffset
RTS
}
\copy from StrA% to param% 
.StrAtopram
{
LDY #&FF:LDX #0
.mq:INY:LDA strA%,Y:STA pram%,X:INX:CMP #&D:BNE mq:RTS
}
\execmd
.execmd
{
LDY #HI(strA%):LDX #LO(strA%):JSR oscli
LDY #0:LDA filesize:TAX:RTS
}
\getcurrent drive
.getcurrentdrive
{
lDA #7:LDX #LO(conb):LDY #HI(conb):JMP osgbpb:\RTS
}
.conb:EQUB 0:EQUD osgbpbdata%:EQUD 0:EQUD 0
.gettitleopt
\ret strA
\len title
\n bytes title
\opt 4.X
{
LDA #0:STA cat:LDA #LO(strA%):STA cat+1:LDA #HI(strA%):STA cat+2
LDA #0:STA cat+3:STA cat+4:LDA #5:LDX #LO(cat):LDY #HI(cat):JMP osgbpb:\rts
}

\Prepcmd
\takes x as cmdno ret x ptr to
\strA%
\.prepcmd
\{
\LDY #0
\.ez:DEX:BNE nexcmd:.ey:LDA cmdadd,Y:CMP #&80:BCC am:AND #&7F
\STA strA%,X:INX:RTS
\.am:STA strA%,X:INX:INY:BNE ey
\.nexcmd:LDA cmdadd,Y:INY:CMP #&80:BCC nexcmd:BCS ez 
\}  
.initprepcmd
LDA #0:STA strAoffset 
.prepcmd
{
LDY #0
.ez:DEX:BNE nexcmd:LDX strAoffset:.ey:LDA cmdadd,Y:CMP #&80:BCC am:AND #&7F
STA strA%,X:STX strAoffset:RTS
.am:STA strA%,X:INX:INY:BNE ey
.nexcmd:LDA cmdadd,Y:INY:CMP #&80:BCC nexcmd:BCS ez 
}
 
\Display error
\takes x as strno
.diserror
{
LDA #LO(errtxt):STA erradd:LDA #HI(errtxt):STA erradd+1
LDY #0:.ba:DEX:BNE bb:.bc:LDA(erradd),Y:CMP #&80:BCC bd:AND #&7F:JSR osasci:RTS
.bd:JSR osasci:INY:BNE bc
.bb:LDA(erradd),Y:INY:CMP #&80:BCC bb:
CLC:TYA:ADC erradd:STA erradd:LDA #0
ADC erradd+1:STA erradd+1:LDY #0:BEQ ba
}
\SPECIAL ROUTINES

\Music
.music
\get *K.0 DEFINED AND IN BUFFER
LDX #key1cmd%:JSR initprepcmd:JSR execmd
LDA #15:JSR osbyte
LDA #255:LDX #1:JSR osbyte
LDA #138:LDX #0:LDY #128:JSR osbyte
LDA #35:STA &74:LDAload+1::STA &75:CLC:ADC size+1:STA &76
LDX #loadcmd%:JMP formcmdandexec
\utility routines
\Set cursor off
.sco
{
LDA #23:JSR osasci:LDA #1:JSR osasci
LDX #9:LDA #0:.aa:JSR osasci
DEX:BNE aa:RTS
}
\Get input 
.gti
{
LDA #&91:LDX #0:JSR osbyte:BCS gti:RTS
}
\issue *dr.X command
.setdrivex
{
STX tempx
LDX #dricmd%:JSR initprepcmd:LDY tempy:INX:LDA tempx
STA strA%,X:INX:LDA #&D:STA strA%,X:JMP execmd:\RTS
}

.reptoninstructions
{
LDX #7:JSR setmode
LDX #0
.aa:LDA reppre,X:BEQ ad:JSR osasci:INX:BNE aa
.ad
LDX tempx:JSR diserror
LDX #0
.ab:LDA reppost,X:BEQ ac:JSR osasci:INX:BNE ab
.ac
JMP gti:\rts
}

\select mode X
.setmode \x=requiredmode
{
LDA #22:JSR osasci:TXA:JMP osasci:\RTS
}
.getfilesystemtype
{
LDA #0:TAY:TAX:JSR osargs:CMP #4:STA filetype:BEQ bb
CMP #12:BEQ bc
STA filetype
RTS
.bc
\file type 12
LDA #&83:STA filetype
RTS
.bb

\ file type 04

LDA #0:STA tempx
.cc:INC tempx:LDX tempx
JSR initprepcmd
LDA strA%:CMP #&D:BEQ exit
JSR issuecmd
\STA a
CMP #254
BEQ cc
.cmdok
LDA tempx:CLC:ADC #&80
STA filetype

.exit
RTS
}
\-----------------------------------
\osargs subroutines

\Getargumentcount result in X
.getargumentcount
{
LDX #osargsptr:LDY #0:LDA #1:JSR osargs
LDX #0:LDY #0
.aa:LDA (osargsptr),Y:CMP #&D:BEQ cmdend:INY:CMP #32:BNE aa:
INX:BNE aa
.cmdend
CPY #0:BEQ ab:\have no args
INX
.ab
RTS
}

\ptr to command into osargsptr
\X,Y,A are preserved osargs 

\copyargumentAintostrA takes X rets strA%
.copyargumentXintostrA
{
\PHA
\LDX #osargsptr:LDY #0:LDA #1:JSR osargs
\PLA:TAX
LDY #0
.aa:DEX:BEQ ab:.ac:LDA(osargsptr),Y:INY:CMP #32:BEQ aa:CMP #&D:BEQ exit:BNE ac
.ab
\good to copy!
\ X=0!
.ad:LDA(osargsptr),Y:STA strA%,X:CMP #32:BEQ ae:CMP #&D:BEQ af:INX:INY:BNE ad
.ae
LDA #&D:STA strA%,X
.af
.exit:
RTS
}
\Y is 0
\-----------------------------------
.issuecmd
\takes cmdno in
{
LDA strA%:CMP #&D:BEQ exit
JSR xos_call:EQUW execmd
\STA a
.exit
RTS
}
\use Parm$ as disktitle
\drive as requested drive
\filetype
\.comadd entries 1-3 for din type commands
\also in .comadd
\addD%
\addneg3%
\add3%
\postcmd%
.setdisk
{
\LDA filetype
\TAX:
LDX filetype
JSR initprepcmd:\now have "din "+D or other
LDA filetype:CMP #1:BNE fa
\0 \now have "din "
LDX #add3%:JSR prepcmd:\now have "din 3 "+D
LDY strAoffset:DEY
LDA requesteddrive:STA strA%,Y
JSR addpram
BNE af
.fa
CMP #2:BNE fb
\1 \now have "mmcdisc "
JSR addpram
\now have "mmcdisc xxxxx"
LDX #addD%:JSR prepcmd
\now have "mmcdisc xxxxx D"
LDY strAoffset:
LDA requesteddrive:CLC:ADC #16:\change 0 to A 1 to B etc
STA strA%,Y
BNE af
.fb
CMP #3:BNE fc
LDX #addneg3%:JSR prepcmd:\now have "import -3 "+D
LDY strAoffset:DEY
LDA requesteddrive:STA strA%,Y
JSR addpram
\now have 
LDX #postcmd%:JSR prepcmd:\now have "import -3 xxxxx.ssd"+D
BNE af
.fc :\should not be here unsupported filing system
LDX #unsupported%:JSR diserror:\JMP so end
.af
JMP execmd:\RTS
}
    \https://mdfs.net/Misc/BeebWiki/jgh/Programmin/CatchingEr    
	\ xos_call - call inline address, catching any returned error
    \ ===========================================================
    \ Called with
    \   JSR  xos_call
    \   EQUW dest
    \ On entry, A,X,Y hold entry parameters
    \ On exit,  V clear - no error, A,X,Y,P hold return parameters
    \           V set   - error, A=ERR, &FD=>error block
    \
    .xos_call
	{
    PHA:TXA:PHA                     :\ Stack holds X, A, main
    LDA brkv+1:PHA:LDA brkv+0:PHA
    LDA oldSP:PHA:TSX:STX oldSP     :\ Stack holds oldSP, oldbrkv, X, A, main
    LDA #error DIV 256:STA brkv+1   :\ Redirect BRKV
    LDA #error AND 255:STA brkv+0
    LDA #(return-1)DIV 256:PHA
    LDA #(return-1)AND 255:PHA      :\ Stack return address
    PHA:PHA:PHA:PHA                 :\ Make space to hold dest and X, A
    LDA zp+1:PHA:LDA zp:PHA:CLC     :\ Save zp workspace
    LDA &106,X:STA zp:ADC #2:STA &106,X     :\ Get mainline address and step
    LDA &107,X:STA zp+1:ADC #0:STA &107,X   :\ past inline dest address
    TYA:PHA:TSX                     :\ Save Y, get new SP
    LDY #2:LDA (zp),Y:STA &107,X
    DEY:LDA (zp),Y:STA &106,X       :\ Copy inline address to stack
    LDA &10E,X:STA &105,X           :\ Copy A to top of stack
    LDA &10D,X:STA &104,X           :\ Copy X to top of stack
    :
    \ Stack holds Y, zp, X, A, dest, return, oldSP, oldbrkv, X, A, main
    :
    PLA:TAY:PLA:STA zp:PLA:STA zp+1 :\ Restore Y and zp workspace
    PLA:TAX:PLA:PHP:RTI             :\ Restore X, A, jump to stacked dest addr
    :
    .return                         :\ Stack holds oldSP, oldbrkv, X, A, main
    PHA:TXA:TSX                     :\ Stack A
    STA &105,X:PLA:STA &105,X       :\ Copy X, A to top of stack
    PLA:STA oldSP                   :\ Restore oldSP
    PLA:STA brkv+0:PLA:STA brkv+1   :\ Restore BRKV
    PLA:TAX:PLA:RTS                 :\ Get returned X, A and return to main
    :
    .error
    LDX oldSP:TXS:PLA:STA oldSP     :\ Restore oldSP
    PLA:STA brkv+0:PLA:STA brkv+1   :\ Restore BRKV
    PLA:PLA:LDY #0:LDA (&FD),Y      :\ Drop X, A, get error number
    BIT P%-1:RTS                    :\ Set V from inline &FD byte and return
    :
    .oldSP
    EQUB 0                          :\ Saved stack pointer

}
\needsto be <&ff
\Strings
.cmdadd
\1 
EQUS"DIN":EQUB &A0
\2
EQUS"MMCDisc":EQUB &A0
\3 
EQUS"import":EQUB &A0
\4 used to terminate disk system check
EQUB &8D

\*EXEC FA
execfilecmd%=5
 EQUS"EX",&AE
 \*dec F9
 deccmd%=6
 EQUS"dec",&A0
\SPECIALS ABOVE ALTER NoSpecials%
\*DRIVE #0
dricmd%=7
EQUS"DR",'.'+&80
\*DIN #1
dincmd%=8
EQUS"DIN",&A0
\*LOAD #2
loadcmd%=9
EQUS"LO.",&A0
\select repton3 disk #3
xfilescmd%=10
EQUS "x-files",&8D
\* run repton3 #4
reptonthreecmd%=11
EQUS "REP3",&8D
\*K.1 #5
key1cmd%=12
EQUS "K.1:3",'.'+&80
\delete prelude #6
delprelude%=13
EQUS "del. prelude",&8D
\copy start #7
copycmd%=14
EQUS "copy 3 0",&A0
\rename #8
renamecmd%=15
EQUS "Ren.",&A0
\ REPi #9
reptonicmd%=16
EQUS "RepI",&8D
\1100
laddcmd%=17
EQUS" 1100",&8D
\prelude
.preludetxt
preludecmd%=18
EQUS " g.a",&8D\????
\*LDPIC FE
ldpiccmd%=19
EQUS"LDPIC",&A0
\*SCRLOAD FD not working !
scrloadcmd%=20
EQUS"SCRLOAD",&A0
\*TYPE FC
typecmd%=21
EQUS"TY",&AE
\*DUMP FB
dumpcmd%=22
 EQUS"DU",&AE
\add " B"
addD%=23
EQUS " ",'D'+&80
\add " -3"
addneg3%=24
EQUS " -",'3'+&80
\add "3"
add3%=25
EQUS " 3":EQUB &A0
\".ssd"
postcmd%=26
EQUS".ss":EQUB 'd'+&80


.boottxt:EQUS"!BOOT"


.errtxt
\ 1 usage"
EQUS"Usage <fsp> (<dno>/<dsp>)":EQUB &8D
\ 2 file not found 
notfound%=2
EQUS"file not found",&8D
\ 3 exe address invalid
EQUS"If none of below will treat as MC",&D
EQUS"!BOOT will be run as per disk option":EQUB &D

EQUS"8023 correct page BASIC":EQUB &D
EQUS"xxxx 8000 ROM":EQUB &D
EQUS"7FFE LDPIC compressed picture":EQUB &D
EQUS"7FFD SHOWPIC not working":EQUB &D
EQUS"7FFC type word text":EQUB &D
EQUS"7FFB DUMP":EQUB &8D
\ 4 extended help
EQUS"7FFA EXEC":EQUB &D
EQUS"7FF9 TYB music samples":EQUB &D
EQUS"7FF8 DEC compressed picture":EQUB &D
EQUS"7FF7 viewsheet":EQUB &D
EQUS"7FF6 31E0 repton 3 lvl (screen)":EQUB &D
EQUS"7FF5 SCRLOAD TODO":EQUB &D
EQUS"7FF4 31E0 repton infinity lvl (screen)":EQUB &D
EQUS"7F07 mode 7 Screen":EQUB &D
EQUS"7F06 mode 6 Screen":EQUB &D
EQUS"7F05 mode 5 Screen":EQUB &D
EQUS"7F04 mode 4 Screen":EQUB &8D
\#5 EXTENDED HELP CONT
EQUS"7F03 mode 3 Screen":EQUB &D
EQUS"7F02 mode 2 Screen":EQUB &D
EQUS"7F01 mode 1 Screen":EQUB &D
EQUS"7F00 mode 0 Screen":EQUB &D \22 7 curser off g=get
EQUS"Version 2.0"
EQUD &8D
\ #6
\#9 repinfinity
repinfin%=6
EQUS"F",'1'+&80
\#8 rep3
rep3%=7
EQUS 'A'+&80
\10
unsupported%=8
EQUS"Unsupported filing system",&8D
tomanyargs%=9
EQUS"Too many args",&8D

 
.reppre
EQUS &D,&D,&D,&D,&D,&D,"When game loads please press",130,"L",&D,"Then press",130,0
.reppost
EQUS 135,"to load selected level",&D,131,136,"Press any key",&D,0



\.preludetxt
\EQUS " g.a",&D
\.preludeptr
\EQUW preludetxt
.end
SAVE "x", start, end,startexec

\cd d:\bbc/beebasm
\cd D:\GitHub\beebyams\beebasm
\beebasm -i .\x\x.asm -do .\x\x.ssd -boot x -v -title x
\beebasm -i .\x\x.asm -di .\x\x-devtemplate.ssd -do .\x\x-dev.ssd -v
\beebasm -i .\x\x.asm -di .\x\x-filestemplate.ssd -do .\x\x-files.ssd -v

