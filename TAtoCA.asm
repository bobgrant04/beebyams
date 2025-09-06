INCLUDE "VERSION.asm"
INCLUDE "SYSVARS.asm"			; OS constants
INCLUDE "BEEBINTS.asm"			; A% to Z% as a ... z

storestart=&19
storeend=&7C
namelen=7
filename=&404
fspadr=&500
\OSFILE=&FFDD
\OSBYTE=&FFF4
\OSRDCH=&FFE0
\OSNEWL=&FFE7
\OSASCI=&FFE3
\OSWORD=&FFF1
\OSGBPB=&FFD1
cmdptr=&70
temp=&72
lastfile=&74
fspptr=&75
num=&76
pblk=&7E
fileinfo=&50
wildname=&5A

ORG &900
GUARD &7C00

.start
.startexe
.setvector
{
LDA &209
CMP #HI(newrtn)
BEQ exit
STA oldrtn+2
LDA &208
STA oldrtn+1
SEI
LDA #LO(newrtn)
STA &208
LDA #HI(newrtn)
STA &209
CLI
.exit
}
RTS 

.out
LDX cmdptr
LDY cmdptr+1
PLA
PLP
.oldrtn
JMP 0
.newrtn
PHP
PHA
STX cmdptr
STY cmdptr+1
LDY #0
STY fspptr
.chkcmd
LDA cmdtd,Y
BEQ tapedsk
CMP (cmdptr),Y
BNE chk2
INY
BNE chkcmd
.chk2
LDY#0
.chkcmd2
LDA cmddt,Y
BEQ dsktape
CMP (cmdptr),Y
BNE out
INY
BNE chkcmd2

.dsktape
PLA
PLA
JSR skipspace
STY lastfile
JSR readdir
.dtloop
JSR getfilename
BCS nxtfile
JSR discload
BCS nxtfile
JSR tapesave
.nxtfile
LDA fspptr
BNE dtloop
LDA lastfile
BEQ dtloop
BNE disc


.tapedsk
PLA
PLA
JSR skipspace
STY num
.getnum
LDA (cmdptr),Y
CMP #'0'
BCC tdloop
CMP #'9'+1
BCS tdloop
AND #&F
STA temp
LDA num
ASL A
ASL A
CLC
ADC num
ASL A
CLC
ADC temp
STA num
INY
BNE getnum
.tdloop
JSR tapeload
BCS nosave
JSR disc
JSR chkpresence
BNE nosave
JSR discsave
.nosave
DEC num
BNE tdloop

.disc
{
LDX #LO(dsk)
LDY #HI(dsk)
JMP oldrtn \RTS
}
.tape
{
LDA #OSBYTEtape%
LDX #OSBYTEtapex1200baud%
JMP OSBYTE \RTS
}
.endadr
{
LDA #storestart
CLC
ADC fileinfo+9
STA temp+1
LDA #0
CMP fileinfo+8
LDA #storeend
SBC temp+1
RTS
}
.getfilename
{
LDY #0
LDA fspptr
BEQ getfn2
JMP chkwild
.getfn2
JSR getname
LDY #namelen
LDA filename+1
CMP #ASC(".")
BNE getname2
LDY #namelen+2
.getname2
CPY temp
BCC lenerr
LDY temp
BEQ lenerr
.getname3
LDA filename,Y
CMP #'*'
BEQ setwild
CMP #'#'
BEQ setwild
DEY
BPL getname3
CLC
RTS
}
.lenerr
{
JSR printname
JSR message
EQUS " - Bad name"
EQUB(&0D)
EQUB(0)
SEC
RTS
}

.setwild
LDX #namelen+1
LDA #32
.setwild2
STA wildname,X
DEX
BNE setwild2
LDA #'$'
STA wildname
LDA #'.'
STA wildname+1
LDY #0
CMP filename+1
BNE setwild3
LDA filename
STA wildname
LDY #2
CMP #'*'
BNE setwild3
LDA #ASC("#")
STA wildname
.setwild3
LDA filename,Y
CMP #13
BEQ wilddone
JSR capital
STA wildname+2,X
CMP #ASC("*")
BNE setwild5
LDA #ASC("#")
.setwild4
STA wildname+2,X
INX
CPX #namelen
BCC setwild4
DEX
.setwild5
INX
INY
BNE setwild3

.wilddone
{
CPX #namelen+1
BCS lenerr
LDA fspadr+&105
STA fspptr
BNE chkwild
}
.nomatch
{
SEC
RTS
}

.chkwild
{
LDX fspptr
TXA
SEC
SBC #8
STA fspptr
LDA fspadr+7,X
AND #&7F
STA filename
LDA #ASC(".")
STA filename+1
LDY #2
.getfsp2
LDA fspadr,X
STA filename,Y
INX
INY
CPY #namelen+2
BNE getfsp2
LDA #&0D
STA filename,Y
LDX #namelen+1
.chkwild3
LDA wildname,X
CMP #'#'
BEQ chkwild4
LDA filename,X
JSR capital
CMP wildname,X
BNE nomatch
.chkwild4
DEX
BPL chkwild3
INX
LDA filename
CMP #'$'
BNE chkwild6
.chkwild5
LDA filename+2,X
STA filename,X
INX
CPX #namelen+1
BNE chkwild5
.chkwild6
CLC
RTS
}
.getname
{
LDA (cmdptr),Y
STA filename,Y
CMP #13
BEQ lastfile2
CMP #32
BEQ gotname
CMP #'|'
BEQ gotname
INY
BNE getname
.lastfile2
INC lastfile
.gotname
LDA #&D
STA filename,Y
STY temp
}
.skipspace
{
LDA (cmdptr),Y
INY
CMP #32
BEQ skipspace
DEY
BEQ skipsp4
.skipsp2
INC cmdptr
BNE skipsp3
INC cmdptr+1
.skipsp3
DEY
BNE skipsp2
.skipsp4
RTS
}
.capital
{
CMP #ASC("a")
BCC capital2
CMP #ASC("z")+1
BCS capital2
AND #&5F
.capital2
RTS
}
.setblk
{
LDA #0
LDX #15
.sb
STA pblk+2,X
DEX
BPL sb
LDX #LO(filename)
STX pblk
LDX #HI(filename)
STX pblk+1
LDX #LO(pblk)
LDY #HI(pblk)
RTS
}
.OSFILE5
{
JSR setblk
LDA #OSFILEReadFileInfo%
JSR OSFILE
CMP #OSFILEReturnFileFound%
RTS
}
.tapeload
JSR tape
LDA #&0D
STA filename
JSR load
LDX #7
.tload4
LDA &3BE,X
STA fileinfo,X
DEX
BPL tload4
INX
LDA pblk+10
STA fileinfo+8
LDA pblk+11
STA fileinfo+9
JSR endadr
BCC toolarge2
.tload2
LDA &3B2,X
BEQ tload3
STA filename,X
INX
BNE tload2
.tload3
LDA #&0D
STA filename,X
STA filename+namelen+2
LDY filename+1
CPY #'.'
BEQ skip3
STA filename+namelen
.skip3
CLC
RTS

.discload
JSR disc
JSR OSFILE5
BNE notfound
LDX #9
.dload2
LDA pblk+2,X
STA fileinfo,X
DEX
BPL dload2
JSR endadr
BCC toolarge

.load
JSR setblk
LDA #storestart
STA pblk+3
LDA #&FF
JSR OSFILE
CLC
RTS
.toolarge2
LDA #12
JSR OSASCI
.toolarge
JSR printname
JSR message
\OPT FNequs(" - too large")
\OPT FNequb(&0D)
\OPT FNequb(0)
EQUS " - too large",&D,0
SEC
RTS
.notfound
JSR printname
JSR message
\OPT FNequs(" - not found")
\OPT FNequb(&0D)
\OPT FNequb(0)
EQUS" - not found",&d,0
SEC
RTS

.chkpresence
JSR OSFILE5
BNE notpresent
JSR printname
JSR message
\OPT FNequs(" exists on disc.")
\OPT FNequb(&0D)
\OPT FNequs("Save it (Y/N/R)?")
\OPT FNequb(0)
EQUS " exists on disc.",&D,"Save it (Y/N/R)?",0
.getynr
LDA #OSBYTEFlushAllBuffers%
LDX #1
JSR OSBYTE
JSR OSRDCH
CMP #&1B
BEQ escape
AND #&5F
CMP #'Y'
BEQ yn2
CMP #'R'
BEQ yn2
CMP #'N'
BNE getynr
.yn2
TAY
JSR OSASCI
JSR OSNEWL
CPY #'R'
BNE exitcp
JSR message
\OPT FNequs("New name: ")
\OPT FNequb(0)
EQUS "New name: ",0
LDA #OSWORDReadInputToMemory%
LDX #LO(nameblk)
LDY #HI(nameblk)
JSR OSWORD
BCS escape
.notpresent
LDY #'Y'
.exitcp
CPY #'Y'
RTS
.escape
BRK
\OPT FNequb(17)
\OPT FNequs("Escape")
\OPT FNequb(0)
EQUS 17,"Escape",0
.tapesave
JSR tape
LDY #0
LDA (cmdptr),Y
CMP #'|'
BNE tsave2
INY
JSR skipspace
JSR getname
LDY temp
BEQ tsave3
CPY #11
BCC tsave2
.tsave3
JMP lenerr
.tsave2
LDA #OSBYTEFlushAllBuffers%
LDX #OSBYTEFlushXInputBuffer%
JSR OSBYTE
LDA #OSBYTEPlaceCharacterIntoBuffer%
LDX #OSBYTEXKeyboardBuffer%
LDY #&0D \character to place
JSR OSBYTE

.discsave
JSR setblk
LDX #7
.save2
LDA fileinfo,X
STA pblk+2,X
DEX
BPL save2
LDA #storestart
STA pblk+11
JSR endadr
LDA fileinfo+8
STA pblk+14
LDA temp+1
STA pblk+15
LDA #OSFILESaveFile%
LDX #LO(pblk)
JMP OSFILE

.printname
LDX #0
.pfn
LDA filename,X
CMP #&0D
BEQ pfn2
JSR OSASCI
INX
BNE pfn
.pfn2
RTS

.message
PLA
STA temp
PLA
STA temp+1
LDY #1
.mes
LDA (temp),Y
BEQ mes2
JSR OSASCI
INY
BNE mes
.mes2
INC temp
BNE mes3
INC temp+1
.mes3
DEY
BPL mes2
JMP (temp)

.readdir
JSR disc
JSR setblk
STA pblk
LDA #LO(filename)
STA pblk+1
LDA #HI(filename)
STA pblk+2
LDA #1
STA pblk+5
LDA #OSGBPBGetDirectoryName%
JSR OSGBPB
LDA filename+1
AND #3
STA sectblk
LDX #LO(sectblk)
LDY #HI(sectblk)
LDA #OSWORDCheckForEOF%
JSR OSWORD
LDA sectblk+10
BNE readerr
RTS
.readerr
BRK
\OPT FNequb(?(sectblk+10))
\OPT FNequs("Disc error")
\OPT FNequb(0)
EQUS 0,"Disc error",0
.dsk
\OPT FNequs("*CARD")
\OPT FNequb(&0D)
EQUS "*CARD",&D

.cmddt
EQUS "*DISCTAPE ",0

.cmdtd
EQUS "*TAPEDISC ",0
.sectblk
\OPT FNequb(0)
\OPT FNequd(fspadr)
\OPT FNequd(&00005303)
\OPT FNequb(&22)
\OPT FNequb(0)
EQUS 0,LO(fspadr),HI(fspadr),0,0,3,&53,0,0,&22,0
\TODO 
.nameblk
\OPT FNequb(filename MOD 256)
\OPT FNequb(filename DIV 256)
\OPT FNequb(namelen+2)
\OPT FNequb(33)
\OPT FNequb(126)
EQUS LO(filename),HI(filename),namelen+2,33,126

 \6020]:NEXT
 \6030ENDPROC
 \6040:
 \6050DEF PROCcheck
 \6060S%=0
 \6070FOR J%=start TO P%-1
 \6080S%=S%+?J%
 \6090NEXT
 \6100ENDPROC
 \6110:
 \6120DEF FNequb(A%)
 \6130?P%=A%
 \6140P%=P%+1
 \6150=opt
 \6160:
 \6170DEF FNequd(A%)
 \6180!P%=A%
 \6190P%=P%+4
 \6200=opt
 \6210:
 \6220DEF FNequs(A$)
 \6230$P%=A$
 \6240P%=P%+LEN(A$)
 \6250=opt
.end 
 
SAVE "TAtoCA", start, end, startexe

\  ./tools/beebasm/beebasm.exe -i ./TAtoCA.asm -do ./build/TAtoCA.ssd -boot TAtoCA -v -title TAtoCA
