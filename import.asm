INCLUDE "VERSION.asm"
INCLUDE "SYSVARS.asm"			; OS constants
INCLUDE "BEEBINTS.asm"			; A% to Z% as a ... z
\If the filing system does not support *import 
\takes *import -<drv> <fsp>.ssd 
\programe will display end of line text
\o/p selected drive selected <dsp>
\will try to keep to a page




\…Variables
Novariants=2
Dr%=3
\ZERO page
\&16 -&17 basic err jump add

\IntA &2A -&2D

\&2E TO &35 basic float
aptr=&2E
OSARGSptr=&30
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

\&600 String manipulation
strA%=&6D0
StrB%=&610
pram%=&6D0
\&A00 RS232 & cassette
\&1100-7C00 main mem


ORG &900
GUARD &B00

.start
\init stuff
\get current drive (incase not in request)
JSR getdrive: STA drive%
\get OSARGS into blockstart
\ptr to command into blockstart&70
\X,Y,A are preserved OSARGS
LDX #OSARGSptr: LDY #0: LDA #1: JSR OSARGS  

	{
	LDY #0
	LDA (OSARGSptr),Y: CMP #&D: BNE aa
	LDX #usage: JSR initprepcmd:JSR printstrA
	.aa
	}
	LDX #detail: JSR initprepcmd:JSR printstrA
	LDX #detail1: JSR initprepcmd:JSR printstrA
	
	

{
LDX #diskname
JSR initprepcmd:\now have "disc name "+D
}
.getargumentcount
{
	LDA #0: TAX : TAY
	.aa: LDA (OSARGSptr),Y: CMP #&D: BEQ cmdend: INY: CMP #32: BNE aa:
	INX:BNE aa
	.cmdend
}
\X contains no of args -1!

LDY #&FF
CPX #1: BNE ab
\have drive diskname
\dealwith drive
LDY #1
LDA (OSARGSptr),Y: 
STA drive%
INY
.ab 
LDX strAoffset

{
.ae:INY:INX:LDA (OSARGSptr),Y:STA strA%,X:CMP #'.':BNE ae
.af:LDA #&D: STA strA%,X: JSR printstrA

}
{
LDX #drive: JSR initprepcmd: 
LDA drive%:STA strA%,X:
INX : LDA #&D: STA strA%,X: JMP printstrA: \RTS
}


\ subs below 
.printstrA
		{
		LDX #&FF:.ak:INX:LDA strA%,X:JSR OSASCI:CMP #&D:BNE ak
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
.ez: DEX: BNE nexcmd: LDX strAoffset:.ey: LDA cmdadd,Y: CMP #&80: BCC am: AND #&7F
STA strA%,X: INX : LDA #&D: STA strA%,X: DEX :STX strAoffset: RTS
.am:STA strA%,X:INX:INY:BNE ey
.nexcmd:LDA cmdadd,Y:INY:CMP #&80:BCC nexcmd:BCS ez 
}

\the advanced disk user guide pg170
.getdrive
{
LDA #6: LDX #LO(conb) : LDY #HI(conb): JSR OSGBPB
LDA data+1: RTS 
.data: EQUS "    "
.conb EQUB 0 :EQUD data: EQUD 0 : EQUD 0
}


\note this data block needs to be <&FF you have been warned
.cmdadd
\1 usage
usage=1
EQUS"Usage import -<drv> <fsp>.ssd":EQUB &8D
\2
detail=2
EQUS"unfortunatly your DFS is unsupported.If your DFS does support disc selection by name":EQUB &8D
detail1=3
EQUS "code will be needed to select it":EQUB &8D
drive=4
EQUS"selected drive ":EQUB &A0
diskname=5
EQUS"drivename":EQUB &A0
.end


SAVE "import", start, end
\cd D:\GitHub\beebyams\beebasm
\beebasm -i .\import\import.asm -do .\import\import.ssd -boot import -v -title import

\cd C:\GitHub\beebyams


\ ./tools/beebasm/beebasm.exe -i ./IMPORT.asm -do ./build/IMPORT.ssd -boot IMPORT -v -title IMPORT