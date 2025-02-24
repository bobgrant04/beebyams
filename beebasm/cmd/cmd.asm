
\Whatfs 
\https://beebwiki.mdfs.net/Filing_system_numbers
\https://beebwiki.mdfs.net/OSARGS
\&2A1. It has a single byte for each ROM and it is clear that the machine uses bit 7 of the table entry to decide whether or not the socket is to be ignored or called as a subroutine
\do not need to know the rom number however as can issue command specific to filesystem type
\and read the err no if it is 254 command has not been processed by any ROM this err appears to be stored in &101
\for basic err pointed via &FD &FE

\…Variables
Novariants=2
\ZERO page
\&16 -&17 basic err jump add

\IntA &2A -&2D

\&2E TO &35 basic float
aptr=&2E
\&3B to &42 basic float
\single bytes
tempx=&3B
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
\clear %
LDX #(('Z'-'A')*4):JSR clearint

\get osargs into blockstart
LDX #blockstart:LDY #0:LDA #1:JSR osargs  
\ptr to command into blockstart&70
\X,Y,A are preserved osargs

JSR xos_call:EQUW cmd
STA z
RTS
.cmd
{
LDX blockstart:LDY blockstart+1
JSR oscli
LDA #0
RTS
}
.clearint
{LDA #0:LDY #3:.dx:STA a,X:INX:DEY:BPL dx:RTS }

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


.end


SAVE "cmd", start, end
\D:\GitHub\beebyams\beebasm
\beebasm -i .\cmd\cmd.asm -do .\cmd\cmd.ssd -boot cmd -v -title cmd