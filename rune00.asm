
\gfi GET FILE INFORMATION
\Usage <fsp> (<dno>/<dsp>) (<drv>)"
\Usage <fsp> (<dno>/<dsp>) (<drv>)
\RETURNS l% = LOAD , e% = EXECUTION, S% = LENGTH
\RETURNS ZERO IN l%, e%, n% ON FAIL
\Outputs E% execution L% load address  N% = length
\Usage GFI (|Q) <fsp> (<drv>) (<dno>/<dsp>)"

INCLUDE "VERSION.asm"
INCLUDE "SYSVARS.asm"			; OS constants
INCLUDE "BEEBINTS.asm"			; A% to Z% as a ... z
\INCLUDE "TELETEXT.asm"

\IntA &2A -&2D
len =&2A
\&2E TO &35 basic float
trueadd=&2E
loadadd=&30
strptr=&2E
Aptr=&30
exeadd=&32
erradd=&34
Runcmdadd%=&34
\&3B to &42 basic float
\single bytes
TextAdd=&3B
NoofArgs%=&3C
strAoffset = &3D
tempy%=&3E
pramlen =&3F
Printtype% = &40
RequestedDrive%=&41
\NoofArgs% =&40
\matchlen=&3C
\tempx=&3D
\ypush=&3E
\highestbyte=&3F
\noofbytes=&40
\quiet =&41
OptionBit%=&42
Filehandle%=&42
codestart=&70
blockstart=&70
load%=blockstart+2
exe%=blockstart+6
size%=blockstart+&A
Locked%= blockstart+&E

\&600 String manipulation
\osgbpbdata%=&600
\WORKINGStrA=&650
shortcode=&640
strA%=&6B0\
\strB%=&690
pram%=&6D0 \strB%
filename%=&6D0
options% =&6F0
ORG &7700
GUARD &7C00
\only size to keep to minimum is codetoadd to EndCodeToAdd
.start
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
OSARGStempY = tempy%
OSARGSrequesteddrive = RequestedDrive%
OSARGSpram% = pram%
\OSARGSpramlen% = pramlen
OSARGSNoofArgs% = NoofArgs%
IF __OSARGSOptions
	OSARGSOptions% = options%
	OSARGSbitOptions% = OptionBit%
ENDIF
\constants
OSARGSbitOptionQuiet% = 1
OSARGSbitOptionVerbose% =2
\needs following routines 
\		initprepcmd
\		prepcmd - part of initprepcmd
\		MoveToRec
\		PrintRecord
\		diserror
\		execmd
\		setrequesteddrive
\		getcurrentdrive
\		gti	- needed for __debug
\needs following in data section
\.CommandAndText
\&80 terminated with last character added to &80
\	dricmd%=1 --can alter if required
\\		EQUS"DR. ",&8D
\	dincmd%=2  --can alter if required
\\		EQUS"DIN",' '+&80
\	usage%=3 --can alter if required
\\ 		EQUS"Usage <fsp> (<drv>) (<dno>/<dsp>)",&80+&D --edit as needed

\-------------------------------------------------------
INCLUDE "OSARGS.ASM"
\-------------------------------------------------------
\__MAGICHELPPRINT = TRUE
\__MAGICHELPPRINTSELECTED =TRUE
\MAGICHELPAptr = Aptr
\MAGICHELPload%=load%
\MAGICHELPexe%=exe%
\IF __MAGICHELPPRINTSELECTED
\	MAGICHELPPrintType% = Printtype%
\ENDIF
\-------------------------------------------------------
\INCLUDE "MAGIC_SOURCE.asm"		\magic configuration
\INCLUDE "MAGICHELP.ASM"
INCLUDE "command args.asm"
\start ends here!
\ok so end of standard select stuff
		\\clear E%,L%:S%
		\{
		\LDX #(('E'-'A')*4)
		\JSR clearint
		\LDX #(('L'-'A')*4)
		\JSR clearint
		\LDX #(('S'-'A')*4)
		\JSR clearint
		\}
		.fileinfo
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
		BEQ ok
		LDX #notfound%
		JSR diserror
		LDX #usage%
		JMP diserror
		.ok
		}
		\Now have file information
		\check basic 8023 or 801F
		{
		LDA #&80
		CMP exe%+1
		BNE notbasic
		LDA exe%
		CMP #&23
		BEQ ok
		CMP #&1F
		BEQ ok
		.notbasic
		LDX #notbasic%
		JSR diserror
		LDX #usage%
		JMP diserror
		.ok
		}

		\alter code as is not all relocatable 
		\.destpage+1 for page
		\run 
		\incrun1
		\incrun2
		\loadrun
		\todo -destpage+1 if want to honour current load%
		.setrequiredparams
		{
		LDA load%+1
		CMP #&11
		BCS doneloadadd \>=&11 so not set
		STA destpage+1
		.doneloadadd
		LDX size%+1
		INX
		STX NoofPages+1
		\work out run address
		LDA size%
		CLC
		\load address will be &1100 so add 0!
		ADC #run-CodeToAdd
		\STA Runcmdadd%
		\STA incrun1+1
		\STA incrun2+1
		STA loadrun+1
		LDA size%+1
		ADC #&11
		\STA Runcmdadd%+1
		\STA incrun1+2
		\STA incrun2+2
		STA loadrun+2
		LDA size%
		CLC
		ADC #loadrun-CodeToAdd+1
		STA incrun1+1
		STA incrun2+1
		LDA size%+1
		ADC #&11
		STA incrun1+2
		STA incrun2+2
		}
		
		
		\unlock file
		LDA #OSFILEUnLocked% \unlock
		JSR Lock
		
		\set load address to &1100
		{
		\LDA #0
		\LDY #3
		\.aa
		\STA load%,Y
		\DEY
		\BPL aa
		LDA #&11
		STA load%+1
		LDX #blockstart
		LDY #0
		LDA #OSFILEWriteLoadAddress%
		JSR OSFILE
		}
		\set exe address to length+&1100
		{
		\LDA #0
		\LDY #3
		\.aa
		\STA exe%,Y
		\DEY 
		\BPL aa
		LDA size%
		STA exe%
		LDA size%+1
		CLC
		ADC #&11
		STA exe%+1
		LDX #blockstart
		LDY #0
		LDA #OSFILEWriteExecutionAddress%
		JSR OSFILE
		}
		
		
		\now to add codetoadd to end of FILE
		\osfind 
		{
		\OSFINDOpenChannelforInput% =&40 	 \Open for input
		\OSFINDOpenChannelforOutput% =&80
		LDA #OSFINDOpenChannelInAndOut%  \todo 
		LDX #LO(pram%)
		LDY #HI(pram%)
		JSR OSFIND
		TAY \to ensure Z flag set correclty pg197 advanced disc user guide
		\also where it need to be!
		BNE ok
		LDX #filenotopened%
		JMP diserror \RTS
		.ok
		\STA Filehandle% not needed put in Y and leave
		}
		.GettoFileEnd
		{
		LDX size%
		LDA #OSARGSReadLen%
		JSR OSARGS
		LDA #OSARGSWritePTR%
		JSR OSARGS
		}
		.Addcodetofile
		{
		LDX #0
		.aa
		LDA CodeToAdd,X
		JSR OSBPUT
		INX
		CPX #EndCodeToAdd-CodeToAdd+1
		BNE aa
		LDA #OSARGSUpdateFile%
		JSR OSARGS
		LDA #OSFINDCloseChannel%
		JSR OSFIND
		}
		
		
		\lockfile
		LDA #OSFILELocked% \lock
		JMP Lock \end prog!
		\
		
		.CodeToAdd
		
		\program is already in memory from &1100
		\Need to shift to E00
		.destpage
		{
		LDA #&E
		STA &18 \set page
		STA trueadd+1
		
		LDA #0
		STA trueadd
		STA loadadd
		LDA #&11
		STA loadadd+1
		}
		\code to add chars to buffer ("RUN",13)
		\fragile code if over page boundary
		\advanced user guide pg 162
		\ buffer table pg 138
		\clear BUFFER
		{
		LDX #OSBYTEXKeyboardBuffer% 
		LDA #OSBYTEFlushSelectedBuffer%
		JSR OSBYTE
		}
		.ui
		.loadrun
		LDY run \0 ldy 1 lowbyte
		IF __DEBUG
			TYA
			JSR OSASCI
		ENDIF
		BEQ ab
		LDA #OSBYTEPlaceCharacterIntoBuffer%
		LDX #OSBYTEXKeyboardBuffer%
		JSR OSBYTE
		
		.incrun1
		{
		INC ui+1
		BNE ui
		}
		.incrun2
		{
		INC ui+2
		BNE ui
		}
		.ab
		\to the shift to E00
		LDY #0
		
		.NoofPages
		{
		LDX #0 \replaced by program
		\BEQ at
		.iq1
		LDA (loadadd),Y
		STA (trueadd),Y
		INY
		BNE iq1
		INC loadadd+1
		INC trueadd+1
		DEX
		BPL iq1
		.at
		RTS \should have RUN exe in buffer
		}
		
		\EQUB 0
		\"„"RUN this can not be over page boundery hence put at top
		.run
		EQUS "*T.",13 \may not be needed but will not hurt
		\EQUS "*B.",13 need to set page if issue this!
		EQUS"O.",13
		EQUS"RUN",13,0
		BUILD_VERSION
		EQUS 0
		.EndCodeToAdd
		\END OOF Code to add
		.Lock
		{
		STA blockstart+&E
		LDX #blockstart
		LDY #0
		LDA #OSFILEWriteAttributes%
		JMP OSFILE \RTS
		}
\---------------------------------
\ Data
\---------------------------------
\---------------------------------

.CommandAndText
\&80 terminated with last character added to &80
	dricmd%=1
		EQUS"DR. ",&8D
	dincmd%=2
		EQUS"DIN",' '+&80
	usage%=3
		EQUS "Usage <fsp> (<drv>) (<dno>/<dsp>)",&D
		EQUS "convert <fsp> basic to MC PA.=&E00",&D
		EQUS "unless load add is set to something less than &1100",&D
		EQUS "in which case it will be honoured",&D
		BUILD_VERSION
		EQUS &8D
	notfound%=4
		EQUS"file not found",&80+&D
	notbasic%=5
		EQUS "file not basic",&80+&D
	filenotopened% =6
		EQUS" file can't be open",&80+&D
.end
SAVE "runE00", start, end,startexec

\ ./tools/beebasm/beebasm.exe -i ./runE00.asm -do ./build/runE00.ssd -boot runE00 -v -title runE00