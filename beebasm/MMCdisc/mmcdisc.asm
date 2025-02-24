
\If the filing system does not support *mmcdisc this
\takes *MMCDisc (<name>) (A|B|C|D) 
\programe will run trying "import -3 xxxxx.ssd"+D
\o/p import -<drv> <fsp>.ssd
\will try to keep to a page




\…Variables
Novariants=2
Dr%=3
\ZERO page
\&16 -&17 basic err jump add

\IntA &2A -&2D

\&2E TO &35 basic float
aptr=&2E
osargsptr=&30
\&3B to &42 basic float
\single bytes
tempx=&3B
tempy=&3C
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
strA%=&620
StrB%=&610
pram%=&6D0
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


ORG &900
GUARD &B00

.start
\init stuff
\get current drive (incase not in request)
JSR getdrive: STA drive%
\get osargs into blockstart
\ptr to command into blockstart&70
\X,Y,A are preserved osargs
LDX #osargsptr: LDY #0: LDA #1: JSR osargs  

	{
	LDY #0
	LDA (osargsptr),Y: CMP #&D: BNE aa
	LDX #usage: JSR initprepcmd
	.printstrA
		{
		LDX #&FF:.ak:INX:LDA strA%,X:JSR osasci:CMP #&D:BNE ak
		RTS
		}
	.aa:
	}

{
LDX #import
JSR initprepcmd:\now have "import -"+D
}
.getargumentcount
{
	LDA #0: TAX : TAY
	.aa: INY : LDA (osargsptr),Y: CMP #&D: BEQ cmdend: INY : CMP #32: BNE aa:
	INX : BNE aa
	.cmdend
}
\X contains no of args -1!




CPX #1: BNE ab
\have drive diskname
\dealwith drive
DEY
LDA (osargsptr),Y: 
SEC : SBC #('A'-'0'): CLC : 
STA drive%

.ab
LDX strAoffset
LDA drive%: STA strA%,X: INX
LDA #32: STA strA%,X:
LDY #&FF

{
.ae: INY : INX : LDA (osargsptr),Y : STA strA%,X: CMP #&D: BEQ af: CMP #32: BNE ae
.af: STX strAoffset
}
LDX #postcmd
JSR prepcmd
\now have should have "import -3 xxxxx.ssd"+D

LDY #HI(strA%):LDX #LO(strA%):JMP oscli: \RTS




\ subs below 




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
.ez: DEX: BNE nexcmd: LDX strAoffset:.ey: LDA cmdadd,Y: CMP #&80: BCC am: AND #&7F
STA strA%,X: INX : LDA #&D: STA strA%,X: DEX :STX strAoffset: RTS
.am:STA strA%,X:INX:INY:BNE ey
.nexcmd:LDA cmdadd,Y:INY:CMP #&80:BCC nexcmd:BCS ez 
}

\the advanced disk user guide pg170
.getdrive
{
LDA #6: LDX #LO(conb) : LDY #HI(conb): JSR osgbpb
LDA data+1: RTS 
.data: EQUS "    "
.conb EQUB 0 :EQUD data: EQUD 0 : EQUD 0
}


\note this data block needs to be <&FF you have been warned
.cmdadd
\1 usage
usage=1
EQUS"Usage <fsp> <drv> (A|B|C|D)":EQUB &8D
\2
import=2
EQUS"import -":EQUB &A0
postcmd=3
EQUS".ssd":EQUB &8D
.end


SAVE "MMCdisc", start, end
\cd D:\GitHub\beebyams\beebasm
\beebasm -i .\MMCdisc\MMCdisc.asm -do .\MMCdisc\MMCdisc.ssd -boot mmcdisc -v -title mmcdisc