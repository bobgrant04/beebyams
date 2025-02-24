
\U 
\see whatFS for file system explanation
\inputs text diskname U% as cat entry
\output  Usage <fsp> (<dno>/<dsp>) (<drv>)
\ X  filename$ diskname$ 3



\…Variables
Novariants=2
Dr%=3
\ZERO page
\&16 -&17 basic err jump add

\IntA &2A -&2D

\&2E TO &35 basic float
aptr=&2E
\&3B to &42 basic float
\single bytes
tempx=&3B
filetype=&3C
strAoffset=&3D
drive%=&3E
\&70 to &8F reserved for 

zp=&A8
\&F8-F9 UNUSED BY OS
blockstart=&F8
\end zero page
\&400 A%-Z% INT
 a = &404:b=&408:c=&40C:d=&410:e=&414:f=&418:g=&41C:h=&420:i=&424:j=&428
 k=&42C:l=&430:m=&434:n=&438:o=&43C:p=&440:q=&444:r=&448:s=&44C:t=&450
 u=&454:v=&458:w=&45C:x=&460:y=&464:z=&468
\&600 String manipulation
strA%=&6A0
pram%=&6F0
\&A00 RS232 & cassette
\&1100-7C00 main mem

\vectors
uptv=&222:evntv=&220:fscv=&21E:findv=&21C:gbpbv=&21A:bgetv=&216:argsv=&214
filev=&212:rdchv=&210:wrchv=&20E:wordv=&20C:bytev=&20A:cliv=&208:irq2v=&206
irq1v=&204:brkv=&202:userv=&200

\os calls
osasci=&FFE3:osbyte=&FFF4:oswrch=&FFEE:osnewl=&FFE7:osgbpb=&FFD1:osfile=&FFDD
osargs=&FFDA:osbget=&FFD7:osbput=&FFD4:osbpb=&FFD1:osfind=&FFCE:osrdch=&FFE0
oscli=&FFF7:osfsc=&21E:osword=&FFF1


ORG &7700
GUARD &7C00

.start
\init stuff
\clear %
LDX #(('F'-'A')*4):JSR clearint

\get osargs into blockstart
LDX #blockstart:LDY #0:LDA #1:JSR osargs  
\ptr to command into blockstart&70
\X,Y,A are preserved osargs
LDY #0
{
LDA (blockstart),Y:CMP #&D:BNE aa
LDX #usage:JSR initprepcmd
JMP printstrA:\RTS
.aa:
}

{
.main
JSR getpramfromosargs:\sets pram$
JSR getfilesystemtype
LDA filetype:CMP #&80:BCC fc
LDA filetype:AND #&7F
STA filetype
LDA #'3':STA drive%
JSR setdisk \uses pram$ and drive%
\now have din or equiv executed
\lets convert U%
\read catalogue
LDA u:BNE aa
LDA #22:JSR osasci:LDA #7:JSR osasci:\mode 7
LDX #catcmd:JSR initprepcmd:JMP execmd:\RTS
.aa

JSR readCat
\go back to dr.0
\LDA #dr0:JSR prepandexec

\so now need to get X command (X file disk)
LDX #xcmd:JSR initprepcmd: \now have "X "+D
JSR addfilename
\now have x filename
JSR addpram
\now have x filename diskname 
STX strAoffset
\lets add " 3"
LDX #add3 :JSR prepcmd:LDA #&D:STA strA%,X
\now have x filename diskname 3
JSR execmd
.exit
RTS
.fc :\should not be here unsupported filing system
LDX #unsupported:JSR initprepcmd
JMP printstrA:\RTS
}

\ subs below 
.printstrA
{
LDX #&FF:.ak:INX:LDA strA%,X:JSR osasci:CMP #&D:BNE ak
RTS
}
.setdisk
{
LDA filetype
TAX:JSR initprepcmd:\now have "din "+D
LDA filetype:CMP #1:BNE fa
\0 \now have "din "
LDX #add3:JSR prepcmd:\now have "din 3 "+D
JSR addpram
BNE af
.fa
CMP #2:BNE fb
\1 \now have "mmcdisc "
JSR addpram
\now have "mmcdisc xxxxx"
LDX #addB
\now have "mmcdisc xxxxx B"
BNE af
.fb
CMP #3:BNE fc
LDX #addneg3:JSR prepcmd:\now have "import -3 "+D
JSR addpram
\now have 
LDX #postcmd:JSR prepcmd:\now have "import -3 xxxxx.ssd"+D
BNE af
.fc :\should not be here unsupported filing system
LDX #unsupported:JSR initprepcmd
JMP printstrA:\RTS
.af
JMP execmd:\RTS
}

.addpram
{
\add pram$ to strA%
LDY#&FF
.ae:INY:INX:LDA pram%,Y:STA strA%,X:CMP #&D:BEQ af:BNE ae
.af:STX strAoffset
RTS
}


.getpramfromosargs
{
\put arg to pram$
LDA#&FF:TAY:TAX
.ae:INY:INX:LDA(blockstart),Y:STA pram%,X:CMP #&D:BEQ af:CMP #&32:BNE ae
.af:LDA #&D:STA pram%,X
RTS
}
.prepandexec
{
JSR prepcmd:JSR execmd
}

\ReadCat rac ret 0 OR NOT IN A
.readCat
{
LDA #&7F:LDX pramadd:LDY pramadd+1:JSR osword:RTS
}
.addfilename
{
LDY u:LDA #0:CLC:.oi:ADC#8:DEY:BNE oi
TAY:INX
LDA cat+7,Y:STA strA%,X:INX:LDA #46:STA strA%,X
INX
.oj:LDA cat,Y:CMP #32:BEQ rq:STA strA%,X:INY:INX:CPX #9:\9 assumes "x "
BNE oj:.rq:LDA #32:STA strA%,X
RTS
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
\routines
\initates strA

.initprepcmd
LDA #0:STA strAoffset
\Prepcmd
\takes x as cmdno ret x ptr to
\strA%
.prepcmd
{
LDY #0
.ez:DEX:BNE nexcmd:LDX strAoffset:.ey:LDA cmdadd,Y:CMP #&80:BCC am:AND #&7F
STA strA%,X:INX:LDA #&D:STA strA%,X:DEX:STX strAoffset:RTS
.am:STA strA%,X:INX:INY:BNE ey
.nexcmd:LDA cmdadd,Y:INY:CMP #&80:BCC nexcmd:BCS ez 
}



.issuecmd
\takes cmdno in
{
LDA strA%:CMP #&D:BEQ exit
JSR xos_call:EQUW execmd
\STA a
.exit
RTS
}

\execmd

.execmd
{
LDY #HI(strA%):LDX #LO(strA%):JMP oscli
}


.clearint
.cli
{
LDA #0:LDY #3:.dx:STA a,X:INX:DEY:BPL dx:RTS
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



.cmdadd

\note this data block needs to be <&FF you have been warned
\1 
EQUS"DIN":EQUB &A0
\2
EQUS"MMCDisc":EQUB &A0
\3 
EQUS"import":EQUB &A0
\4 used to terminate disk system check
EQUB &8D
\5
postcmd=5
EQUS".ss":EQUB 'd'+&80
\6
drcmd=6
EQUS"dr.3":EQUB &8D
\7
xcmd=7
EQUS"X":EQUB &A0
\8
add3=8
EQUS " 3":EQUB &A0
\9 usage"
usage=9
EQUS"takes diskname and U% output X cmd or   cat if u%=0":EQUB &8D
\A
dr0=&A
EQUS "dr.":EQUB '0'+&80
\B
addB=&B
EQUS"B":EQUB &A0
\C
addneg3=&C
EQUS"-3":EQUB &A0
\D
unsupported=&D
EQUS"Unsupported filesystem type":EQUB &8D
\E
catcmd=&E
EQUS ". 3":EQUB &8D

.pramadd
EQUW pram:.pram:EQUB Dr%:EQUD cat:EQUB 3:EQUB &53:EQUB 0:EQUB 0:EQUB &22:EQUB 0:.catadd
EQUW cat:.search:.cat:

.end


SAVE "U", start, end
\cd D:\GitHub\beebyams\beebasm
\beebasm -i .\U\U.asm -do .\U\U.ssd -boot U -v -title U