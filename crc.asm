INCLUDE "VERSION.asm"
INCLUDE "SYSVARS.asm"			; OS constants
INCLUDE "BEEBINTS.asm"			; A% to Z% as a ... z

__DEBUG = TRUE
\CRC used to give details of the file
\Usage <fsp> (<dno>/<dsp>) (<drv>)
\E%=Exec L%=Load N%=length  M%=CRC
\CRC routine from BBC micro advanced PG.348"

\…Variables
NoSpecials%=1:\"offset from 1
EndSpecial%=&FF-NoSpecials%
\ZERO page
\IntA &2A -&2D
TextAdd=&2A
Aptr=&2C
\&2E TO &35 basic float
crc=&2E
loadadd=&30
exeadd=&32
erradd=&34
\&3B to &42 basic float
\single bytes
filesize=&3B
tempx=&3D
\switch=&3E
ptr = &3E
basic=&3F
tempy=&40
strAoffset=&41
RequestedDrive% =&42
\&70 to &8F reserved for 
blockstart=&70
load=blockstart+2
exe=blockstart+6
size=blockstart+&A
cat=&72
codestart=&70
zz=&8E
\&F8-F9 UNUSED BY OS
pramlen=&F8
NoofArgs% = &F9
\end zero page

\&600 String manipulation
strA%=&6A0
pram%= &690
\&A00 RS232 & cassette
\&1100-7C00 main mem
conb=&5000 :\control block for reading disk
rawdat=&6000:\output for file read
countpg=&6100:\page for count's

ORG &7700
GUARD &7C00
\------------------------------------------------------
\setup for OSARGS
__OSARGSinit = TRUE
__OSARGSargXtoOSARGSStrLenA = TRUE
__OSARGSargGetDrive = TRUE
__OSARGSFileNameToOSARGSPram = TRUE
__OSARGSOptions = FALSE
\Variables - 
OSARGSstrA =strA%
OSARGSStrLenA = strAoffset
OSARGStempY = tempy
OSARGSrequesteddrive = RequestedDrive%
OSARGSpram% = pram%
OSARGSpramlen% = pramlen
OSARGSNoofArgs% = NoofArgs%
IF __OSARGSOptions
	OSARGSOptions% = OptionStr%
	OSARGSbitOptions% = OptionBit%
ENDIF
\-------------------------------------------------------
.start
INCLUDE "OSARGS.ASM"
\INCLUDE "MAGIC_SOURCE.asm"		\magic configuration
\INCLUDE "MAGICHELP.ASM"
\-------------------------
\------------------------
\startexe set within command args.asm file!
\------------------------		
\.startexec
\-------------------------
INCLUDE "command args.asm"
\clear %
LDX #(('E'-'A')*4):JSR clearint
LDX #(('L'-'A')*4):JSR clearint
LDX #(('N'-'A')*4):JSR clearint
LDX #(('M'-'A')*4):JSR clearint


\now have blockstart with filename
.checkforfile
		{
		LDA #HI(pram%)
		STA blockstart+1
		LDA #LO(pram%)
		STA blockstart
		LDX #blockstart
		LDY #0
		LDA #OSFILEReadFileInfo%
		JSR OSFILE
		CMP #OSFILEReturnFileFound%
		BEQ havefile
		LDX #notfound%
		STX p
		JSR diserror
		LDX #usage%
		JMP diserror
		\JMP MAGICHELPPRINT
		.havefile
		}



		\Record file details
		{
		LDY #&B
		.tp
		LDA blockstart+2,Y
		STA l,Y
		DEY
		BPL tp
		LDA #0
		STA l+2
		STA l+3
		STA m+2
		STA m+3
		STA n+3
		STA n+2
		}

		\set up and call OSFILE
		LDA #OSFINDOpenChannelforInput%
		LDX blockstart
		LDY blockstart+1
		JSR OSFIND
		TAY
		BNE calcrc
		LDX #nofilehandle%
		JMP diserror \RTS

		.calcrc
		{
		STA ptr
		.ak
		LDX ptr
		LDA #1
		JSR ao \because JSR(OSFSC) is not supported!
		TXA
		BEQ zz
		LDY ptr
		JSR OSBGET
		EOR crc+1
		STA crc+1
		JSR addcrc
		JMP ak
		\close file handle
		.zz
		LDA crc
		STAz
		LDA crc+1
		STAz+1
		LDY ptr
		LDA #0
		JSR OSFIND
		RTS:\Ret
		.ao
		JMP (OSFSC)
		}
\have L% for load ADD and E% for EXE address
CLC:LDA l:ADC l+1:BEQ noload
LDA #0:JSR lock
LDA l:STA blockstart+2:LDA l+1:STA blockstart+3::LDA l+2:STA blockstart+4:LDA l+3:STA blockstart+5
LDX #blockstart:LDY #0:LDA #2:JSR OSFILE:
LDA #&A:JSR lock
.noload
CLC:LDA e:ADC e+1:BEQ noexe
LDA #0:JSR lock
LDA e:STA blockstart+6:LDA e+1:STA blockstart+7:LDA e+2:STA blockstart+8:LDA e+3:STA blockstart+9
LDX #blockstart:LDY #0:LDA #3:JSR OSFILE:
LDX #&A:JSR lock
.noexe
RTS

		\addcrc
		.addcrc
		 {
		 LDX #8
		.bf
		LDA crc+1
		ROL A
		BCC bg
		LDA crc+1
		EOR #8
		STA crc+1
		LDA crc
		EOR #&10
		STA crc
		.bg
		ROL crc
		ROL crc+1
		DEX
		BNE bf
		RTS
		}
		\Clearint
		.clearint
		{
		LDA #0
		LDY #3
		.dx
		STA a,X
		DEY
		BPL dx
		RTS
		}
		\lock
		.lock
		{
		STA blockstart+&E
		LDX #blockstart
		LDY #0
		LDA #4
		JMP OSFILE \RTS
		}


.cmdadd
.CommandAndText
dricmd%=1
EQUS"DR. ",&8D
dincmd% =2
EQUS"DIN",' '+&80
usage%=3 
EQUS"Usage <fsp> (<drv>)(<dno>/<dsp>)  E%=exec L%=load N%=length M%=CRC":EQUB &8D
nofilehandle% = 4
EQUS"Unable to create file handle",&8D 
notfound% = 5
EQUS"file not foun",&E4







.end


SAVE "crc", start, end, startexec
\D:\GitHub\beebyams\beebasm
\beebasm -i .\crc\crc.asm -do .\crc\crc.ssd -boot crc -v -title crc

\cd C:\GitHub\beebyams\beebasm


\ ./tools/beebasm/beebasm.exe -i ./CRC.asm -do ./build/CRC.ssd -boot CRC -v -title CRC