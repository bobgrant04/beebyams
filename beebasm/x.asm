
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
\--------------------------------------------------------------
\&36 LENGTH OF STRING BUFFER
\--------------------------------------------------------------
\&37 - &3A GENERAL AREAS
\--------------------------------------------------------------
\&3B - &42 FLOATING POINT WORK AREA B
\single bytes
filesize=&3B
tempx=&3D
switch=&3E
basic=&3F
tempy=&40
\--------------------------------------------------------------
\&43 - &4F FLOATING POINT TEMPORARY AREAS
\--------------------------------------------------------------
\&50 - &6F not used
\--------------------------------------------------------------
\IntA &2A -&2D

\&2E TO &35 basic float

\&3B to &42 basic float
\single bytes

\&50-&6F Not used
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
\&400 A%-Z% INT
 a=&404:b=&408:c=&40C:d=&410:e=&414:f=&418:g=&41C:h=&420:i=&424:j=&428
 k=&42C:l=&430:m=&434:n=&438:o=&43C:p=&440:q=&444:r=&448:s=&44C:t=&450
 u=&454:v=&458:w=&45C:x=&460:y=&464:z=&468
\&46C - &470 TEMP 1
\&471 - &475 TEMP 2
\&476 - &47A TEMP 3
\&478 - &47F TEMP 4
\&600 String manipulation
strA%=&6A0
\&900 - &AFF RS232 & cassette openin/open out
\&B00 &BFF programmable keys
\&C00 CFF extended character
\&D00 DFF  disk operations
\&1100-7C00 main mem
conb=&5000 :\control block for reading disk
rawdat=&6000:\output for file read
countpg=&6100:\page for count's
\vectors
USERV =&200	\reserved
BRKV =&202	\break vector
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
\os calls
osasci=&FFE3:osbyte=&FFF4:oswrch=&FFEE:osnewl=&FFE7:osgbpb=&FFD1:osfile=&FFDD
osargs=&FFDA:osbget=&FFD7:osbput=&FFD4:osbpb=&FFD1:osfind=&FFCE:osrdch=&FFE0
oscli=&FFF7:osfsc=&21E:osword=&FFF1


ORG &7000
GUARD &7C00

.start
.ldpic
INCBIN "$.altldpc"
\the yorkshire boys music
.tybmusic
SKIPTO &7100
INCBIN "$.code2"
SKIPTO &7200
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
\"Process filename
\now have blockstart with filename
\Check FOR !BOOT
.boot
{
LDY #4:.ca:LDA boottxt,Y:CMP(blockstart),Y:BEQ cc:CLC:ADC #32
CMP(blockstart),Y:BNE notboot:.cc:DEY:BPL ca
\Have boot
\See ADVANCED DISKUSER GUIDE pg168
LDA #0:STA cat:LDA #strA% MOD 256:STA cat+1:LDA# strA% DIV 256:STA cat+2
LDA #0:STA cat+3:STA cat+4:LDA #5:LDX #cat MOD 256:LDY #cat DIV 256:JSR osgbpb
\Check for exec  (OPT4,3)
LDY strA%:LDA strA%+1,Y:CMP #3:BNE notboot
LDX #5:JSR prepcmd:JSR addparam:JMP execmd
\get file info
}
.notboot

LDX #blockstart:LDY #0:LDA #5:JSR osfile:CMP #1:BEQ al:LDX #2:JMP diserror:.al
\file not found
\get file info if A<> 1 not a file
\check for specials
LDA exe+1:CMP #&7F:BEQ specials:JMP prepload
\Specials
.specials
{
LDA exe:LDX #0
CMP #&FE:BNE ca
\7FFE LDPIC compressed picture
LDY #0:.xx:LDA &7000,Y:STA &900,Y:INY:BNE xx
JMP &900

\7FFD SHOWPIC"
.ca:CMP #&FD:BNE cc
LDX #3
\7FFC type word text
.cc:CMP #&FC:BNE cd
LDX #4
\7FFB DUMP
.cd:CMP #&FB:BNE ce
LDX #5
\7FFA EXEC
.ce:CMP #&FA:BNE cf
LDX #6
\7FF9 TYB music samples
.cf:CMP #&F9:BNE cg

LDY #0:.xy:LDA &7100,y:STA &900,Y:INY:BNE xy
LDA #15:JSR osbyte
LDA #255:LDX #1:JSR osbyte
LDA #138:LDX #0:LDY #128:JSR osbyte
LDA #35:STA &74:LDAload+1::STA &75:CLC:ADC size+1:STA &76
\setup load command
LDX #NoSpecials%+2:JSR prepcmd:JSR addparam
\now have *lo. FILENAME &D ready
LDY #0:DEX
.bv:LDA ladd,Y::STA strA%,X:INX:INY:CMP #&D:BNE bv
\code for D00
\no of bytes 10 so make &10
LDY #&10
.kk:LDA shiftme,Y:STA &D00,Y:DEY:BPL kk
JMP &D00
.shiftme
LDY #strA% DIV 256:LDX #strA% MOD 256:JSR oscli
JMP &900
}
\7FF8 DEC compressed picture
.cg:CMP #&F8:BNE ch
LDX #8
\7FF7 viewsheet
.ch:CMP #&F7:BNE cz
LDX #9
.cz:CPX#00:BEQ screencheck:
JSR prepcmd:JSR addparam:JMP execmd
\JMP so end

.screencheck
{
CMP #8:BCS notcoded

LDA #22:JSR osasci:LDA exe:JSR osasci:JSR sco
LDX #NoSpecials%+2:JSR prepcmd:JSR addparam
JSR execmd:JMP gti
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
LDA #EndSpecial%:STA switch:LDX #NoSpecials%
LDA exe
.ag:CMP switch:BNE aw
.exespecial:JSR prepcmd:JSR addparam:JMP execmd
\JMP so end
.aw:INC switch:DEX:BNE ag
\Special exe address not coded
.notcoded
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
.romcheck
LDA load+1:CMP #&80:BNE bascheck:JMP execmd
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
.bascheck
{
LDA exe+1:STA exeadd+1:LDA exe:STA exeadd:CMP #&23:BNE ax
LDA exeadd+1:CMP #&80:BNE ax:LDA trueadd+1:STA &18:LDA #138:.ui:LDY run
LDX #0:JSR osbyte:INC ui+1:BNE ui:INC basic:.ax
}
\JMPtest
LDY #codeend-codebegin:.av:LDA codebegin,Y:STA codestart,Y:DEY:BPL av
\CODE NOW IN ZERO PAGE
LDY #strA% DIV 256:LDX #strA% MOD 256
\-----------------------
.codebegin
\need to keep code here to min
\loadfile and shift if required
JSR oscli
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

\Music
.music
\get *K.0 DEFINED AND IN BUFFER
LDX #NoSpecials%+3:JSR prepcmd:JSR execmd
LDA #15:JSR osbyte
LDA #255:LDX #1:JSR osbyte
LDA #138:LDX #0:LDY #128:JSR osbyte
LDA #35:STA &74:LDAload+1::STA &75:CLC:ADC size+1:STA &76
LDX #NoSpecials%+2:JSR prepcmd:JSR addparam:JMP execmd
\utility routines
\Set cursor off
.sco
{
LDA #23:JSR osasci:LDA #1:JSR osasci:LDX #9:LDA #0:.aa:JSR osasci:DEX:BNE aa:RTS
}
\Get input 
.gti
{
LDA #&91:LDX #0:JSR osbyte:BCS gti:RTS
}
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
.boottxt:EQUS"!BOOT"
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
 EQUS"Basic progs need load add set to run page":EQUB &D
 EQUS"!BOOT will be run as per disk opt":EQUB &D
 EQUS"ROM load should be 8000":EQUB &D
EQUS"Files to be *DUMP exe 7FFB":EQUB &8D
\#5 EXTENDED HELP CONT
EQUS"TYB music samples to be exe 7FFA":EQUB &D
EQUS"Files to be *EXEC exe 7FFA":EQUB &D
EQUS"BOOT will be run as per disk option":EQUB &D
EQUS"7FFE LDPIC compressed picture":EQUB &D
EQUS"7FFD SHOWPIC not working":EQUB &D
EQUS"7FFC type word text":EQUB &D
EQUS"7FFB DUMP":EQUB &D
EQUS"7FFA EXEC":EQUB &8D
EQUS"7FF9 TYB music samples":EQUB &D
EQUS"7FF8 DEC compressed picture":EQUB &D
EQUS"7FF7 viewsheet":EQUB &D
EQUS"7F07 mode 7 Screen":EQUB &D
EQUS"7F06 mode 6 Screen":EQUB &D
EQUS"7F05 mode 5 Screen":EQUB &D
EQUS"7F04 mode 4 Screen":EQUB &D
EQUS"7F03 mode 3 Screen":EQUB &D
EQUS"7F02 mode 2 Screen":EQUB &D
EQUS"7F01 mode 1 Screen":EQUB &D
EQUS"7F00 mode 0 Screen":EQUB &D \22 7 curser off g=get
EQUS"Version 1.1"
EQUD &8D
\"„"RUN
.run
EQUS"RUN",13,0
.end

SAVE "x", start, end,startexec

\cd bbc/beebasm
\cd D:\GitHub\beebyams\beebasm
\beebasm -i x.asm -do x.ssd -boot x -v
