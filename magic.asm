\\MAGIC used to inteligently guess exe and or load address
\Magic <fsp> (<drv>) (<dno>/<dsp>)
\TODO honour |Q sooner
\if exe is in the range 7F00 then exe will not be analysied as firm indication of file given 
\load address will change for rom to &8000
\will Guess screen load mode from load address and size
\load address will be altered for BASIC progs with <>&E00 or <>&1100
\normal *drive command and *din command will be issued (default to drive 3)
\file information will be gathered 
\Outputs E% execution L% load address  does not change progam
\use Alter to change file details
\\

\Magic used to alter exe and or load address
\Usage <|Q> <fsp> (<dno>/<dsp>) (<drv>)
INCLUDE "VERSION.asm"
INCLUDE "SYSVARS.asm"			; OS constants
INCLUDE "BEEBINTS.asm"			; A% to Z% as a ... z

__DEBUG = FALSE

\…Variables
\NoSpecials%=1:\"offset from 1
\EndSpecial%=&FF-NoSpecials%
\ZERO page
\&12 - &13 TOP
matchlen=&13
\IntA &2A -&2D
\---------------
TextAdd=&2A
Aptr=&2C
\---------------
\&2E TO &35 basic float
\---------------
highestbyte=&2E
noofbytes=&2F
ypush=&30
len =&31
OptionBit% =&32 \used by command args.asm
\--------------
\&3B to &42 basic float
\single bytes
\-----------------------
filesize=&3B
NoofArgs% =&3C
tempx=&3D
switch=&3E
basic=&3F
tempy%=&40
strAoffset = &41
RequestedDrive% =&42
\----------------------
\&70 to &8F reserved for 
blockstart=&70
load%=blockstart+2
exe%=blockstart+6
size%=blockstart+&A
cat=&72
\codestart=&70
zz=&8E


\end zero 

\&600 String manipulation
\strB%=&620
strA%=&620
pram%=&680
OptionStr%=&6F0
\&900 rs232/cassette o/p buffer envelope buffer
rawdat=&900:\output for file read
\&A00 RS232 & cassette
conb=&7B00 :\control block for reading disk
countpg=&7A00:\pProcessNextRece for count's

\&1100-7C00 main mem



ORG &6900
GUARD &7A00
\GUARD = conb

.start
\------------------------------------------------------
\setup for OSARGS
__OSARGSinit = TRUE
__OSARGSargXtoOSARGSStrLenA = TRUE
__OSARGSargGetDrive = TRUE
__OSARGSFileNameToOSARGSPram = TRUE
__OSARGSOptions = TRUE
\Variables - 
OSARGSstrA =strA%
OSARGSStrLenA = strAoffset
OSARGStempy% = tempy%
OSARGSrequesteddrive = RequestedDrive%
OSARGSpram% = pram%
\OSARGSpramlen% = pramlen
OSARGSNoofArgs% = NoofArgs%
IF __OSARGSOptions = TRUE
	OSARGSOptions% = OptionStr%
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
\ notfound% = 4--can alter if required
\		EQUS"file not found",&8D
\-------------------------------------------------------
INCLUDE "OSARGS.ASM"
\-------------------------------------------------------
__MAGICHELPPRINT = TRUE
__MAGICHELPPRINTSELECTED = FALSE
MAGICHELPAptr = Aptr
MAGICHELPload%=load%
MAGICHELPexe%=exe%
IF __MAGICHELPPRINTSELECTED = TRUE
	MAGICHELPPrintType% = Printtype%
ENDIF
IF __OSARGSOptions = TRUE
	MAGICHELPOptionBit% = OptionBit%
ENDIF
\-------------------------------------------------------
INCLUDE "MAGIC_SOURCE.asm"		\magic configuration
INCLUDE "MAGICHELP.ASM"
INCLUDE "command args.asm"
\start ends here!
\we have drive set / filename in pram
\any switches in option% null terminated
		.ZeroVariables
		{
		LDA #0
		STA basic
		}
		.dealwithoptions
		{
		\done in osargs only Quiet and Verbose coded only quiet used
		\LDA options%
		\BEQ exit
		\CMP #'Q'
		\BNE aa
		\.ab
		\INC quiet%
		\BNE exit
		\.aa
		\CMP #'q'
		\BEQ ab
		\.exit
		}

\JMP MAGICHELPPRINT

		\clear E%,L%:S%
		.clearints
		{
		LDX #(('E'-'A')*4)
		JSR clearint
		LDX #(('L'-'A')*4)
		JSR clearint
		LDX #(('P'-'A')*4)
		JSR clearint
		}
\"Process filename
\now have blockstart with filename does file exist
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
		JSR diserror
		JMP MAGICHELPPRINT
		.havefile
		}
		.clearloadpage
		\during testing if a very small file (<255) previous load
		\needs to be cleared out
		{
		LDA #0
		TAX
		.aa
		STA rawdat,X
		DEX
		BNE aa
		}
		.startchecks
		{
		LDA exe%+1
		CMP #&7F
		BEQ alreadyset
		LDA load%+1
		CMP #&7F
		BNE Magic
		.alreadyset
		LDX #MagicAreadyset%
		JSR diserror
		RTS
		}
\this is where the Magic happens uses the tables:-
\.MagicData needs data loading
\entrytype,Offset, nobytes,exec,load ident
\.countable needs data loading and count table
\byte,no,exec,load,ident
\.strcheck needs data loading
\nobytes,exec,load ident
\.loadcheck needs load info so do first!
\loadadd,exec,ident
\.loadcheck
\loadadd,exec,load,ident
\.execheck
\exe,exec,load,ident

.Magic
\load a Magic of data in
		.Loadfirstpageoffile
		{
		LDX blockstart
		LDY blockstart+1
		LDA #OSFINDOpenChannelforInput%
		JSR OSFIND
		BNE db
		RTS
		.db
		STA conb
		LDA #0
		LDY #&C
		.de
		STA conb,Y
		DEY
		BNE de
		LDA #HI(rawdat)
		STA conb+2
		LDA #&FF
		STA conb+5
		LDA #OSGBPBReadbytesignoringnewpointer%
		LDX #LO(conb)
		LDY #HI(conb)
		JSR OSGBPB
		\Close File
		LDA #OSFINDCloseChannel%
		LDY conb
		JSR OSFIND
		}
		JSR statistic

		.Magicfile
\set aptr to Magic block
		.InitAptrtoMagicData
		{
		LDA #LO(MagicData)
		STA Aptr
		LDA #HI(MagicData)
		STA Aptr+1
		}
\first byte is ident so construct case statement
		.TableScan
		{
		LDY #0
		LDA (Aptr),Y
		BNE aa
		.exittablescan
		JSR screencheck
		JMP alldone
		.aa
		IF __DEBUG
			{
			CLC
			ADC #'0'
			JSR OSASCI
			LDX #&FF
			.aa
			INX
			LDA debugtext,X
			JSR OSASCI
			CMP #&D
			BNE aa
			BEQ ab
			.debugtext
			EQUS "Table entrytype"
			EQUB &D
			.ab
			JSR gti
			LDY#0
			LDA (Aptr),Y
			}
		ENDIF
		TAX
		CMP #&FF
		BNE Notff
		JMP MagicFF
		.Notff
		DEX
		BNE Not1
		JMP Magic1
		.Not1
		DEX
		BNE Not2
		JMP Magic2
		.Not2
		DEX
		BNE Not3
		JMP Magic3
		.Not3
		DEX
		BNE Not4
		JMP Magic4
		.Not4
		DEX
		BNE Not5
		JMP Magic5
		.Not5
		DEX
		BNE Not6
		JMP Magic6
		.Not6
		DEX
		BNE Not7
		JMP Magic7
		.Not7
		DEX
		BNE Not8
		JMP Magic8
		.Not8
		DEX
		BNE exittablescan
		JMP Magic9
		}
\should not be here
\drop through to screencheck
BRK
\if Quiet check E and L existing

\screencheck TODO add this to magic file - how can we differentiate modes 
\with same load and size? currently pick the first one!
		.screencheck
		{
		\mode 7 &7C00 len &400
		LDA l+1
		CMP #&7C
		BNE Notmode7
			{
			LDA s+1
			CMP #4
			BNE exit
			LDA #7
			JMP setexe \rts
			}
		.Notmode7
		\mode 6 &6000 len &2000
		CMP #&60
		BNE Notmode6
			{
			LDA s+1
			CMP #&20
			BNE exit
			LDA #6
			JMP setexe
			}
		.Notmode6
		\mode 4,5 &5800 len &2800
		CMP  #&58
		BNE Notmode4
			{
			LDA s+1
			CMP #&28
			BNE exit
			LDA #4
			JMP setexe
			}
		.Notmode4
		\mode 3 &4000 len &4000
		CMP  #&40
		BNE Notmode3
			{
			LDA s+1
			CMP #&40
			BNE exit
			LDA #3
			JMP setexe
			}
		.Notmode3
		\mode 0,1,2 &3000 len &5000
		CMP #&30
		BNE Notmode0
			{
			LDA s+1
			CMP #&50
			BNE exit
			LDA #0
			JMP setexe
			}
		.Notmode0
		.exit
		RTS
		}

		.alldone
		{
		LDA exe%
		CMP e
		BNE bd
		LDA exe%+1
		CMP e+1
		BNE bd
		LDX #(('E'-'A')*4)
		JSR clearint
		.bd
		LDA load%
		CMP l
		BNE exit
		LDA load%+1
		CMP l+1
		BNE exit
		LDX #(('L'-'A')*4)
		JSR clearint
		.exit
		RTS
		}


\ALL Magic subs end with either Fullmatch if matched
\Fullmatch needs to point to exe
\or movenext - requires Y to be in the description part of the record
\&FF,exec,load ident
		.MagicFF
		{
		LDY #5
		JMP NextRec
		}
\1,Offset -number of bytes in to read then use content of this to checkfrom, nobytes,exec,load ident
\Magic1
		.Magic1
		{
		INY
		LDA (Aptr),Y
		.ac
		TAX
		.fg
		INY
		LDA (Aptr),Y
		STA matchlen
		CLC
		ADC #7
		STA tempy%
		.fh
		INY
		LDA (Aptr),Y
		CMP rawdat,X
		BEQ aa
		LDY tempy%
		JMP NextRec
		.aa
		INX
		DEC matchlen
		BPL fh
		INY
		JMP fullmatch
		}

\2,Startrange,Endrange,minvalue,maxvalue,exec,load ident
\Magic2
		.Magic2
		{
		LDA e
		CLC
		ADC e+1
		BNE ab
		.cd
		\JSR statistic
		JSR GethighestByte
		LDY #1
		LDA (Aptr),Y
		CMP highestbyte
		BCS ab \< startrange
		INY
		LDA (Aptr),Y
		CMP highestbyte
		BCC ab \> Endrange
		INY 
		LDA (Aptr),Y
		CMP noofbytes
		BCS ab \< minvalue
		INY
		LDA (Aptr),Y
		CMP noofbytes
		BCC ab \> maxvalue
		INY
		JMP fullmatch
		.ab 
		LDY #&A
		JMP NextRec
		}
		
\3,loadadd,exec,load,ident
\Magic3
		.Magic3
		{
		INY
		LDA(Aptr),Y
		CMP load%
		BNE ProcessNextRec
		INY
		LDA(Aptr),Y
		CMP load%+1
		BNE ProcessNextRec
		INY
		JMP fullmatch
		.ProcessNextRec
		LDY #7
		JMP NextRec
		}
		
\4,exec,exec,load,ident 7 to ident
\Magic4
		.Magic4
		{
		INY
		LDA (Aptr),Y:
		CMP exe%
		BNE ProcessNextRec
		INY
		LDA (Aptr),Y
		CMP exe%+1
		BNE ProcessNextRec
		INY
		JMP fullmatch
		.ProcessNextRec
		LDY #7
		JMP NextRec
		}

\5, no of high byte pairs, (high,count or higher),exec,load,ident
\Magic5
		.Magic5
		{
		\JSR statistic
		JSR GethighestByte
		LDY #1
		LDA (Aptr),Y 
		STA tempx
		CLC
		ROL A
		STA tempy%
		LDA e
		CLC
		ADC e+1
		BNE ao
		.cd
		.an
		INY
		LDA (Aptr),Y
		CMP highestbyte
		BNE ao
		INY
		LDA (Aptr),Y
		CMP noofbytes
		BCS ao
		DEC tempx
		BNE ap
		INY
		JMP fullmatch
		.ap
		LDX highestbyte
		LDA #0
		STA countpg,X
		STY ypush
		JSR GethighestByte
		LDY ypush
		JMP an
		.ao
		\move to next rec 
		CLC
		LDA tempy%
		ADC #6
		TAY
		JMP NextRec
		}
\Magic6
		.Magic6
		{
		INY
		LDA (Aptr),Y
		TAY
		LDA rawdat,Y
		TAX 
		LDY #2
		LDA (Aptr),Y
		STA matchlen
		CLC
		ADC #7
		STY tempy%
		.al
		INY
		LDA (Aptr),Y
		CMP rawdat,X
		BEQ am
		LDY tempy%
		JMP NextRec
		.am
		INX
		DEC matchlen
		BPL al
		INY
		JMP fullmatch
		}
\Magic7
		.Magic7
		{
		\JSR statistic
		LDA#0
		STA noofbytes
		INY
		LDA(Aptr),Y
		STA tempx:\count
		INY
		LDA(Aptr),Y
		STA tempy% \no entries
		.cb
		INY
		LDA(Aptr),Y
		TAX
		LDA countpg,X:
		CLC
		ADC noofbytes
		STA noofbytes
		DEC tempy%
		BPL cb
		CMP tempx
		BCS cc
		LDY #2
		LDA (Aptr),Y
		CLC
		ADC #7
		TAY
		JMP NextRec
		.cc
		INY
		JMP fullmatch
		}
\Magic8
		.Magic8
		{
		INY
		LDA(Aptr),Y
		CMP size%
		BNE ProcessNextRec
		INY
		LDA (Aptr),Y
		CMP size%+1
		BNE ProcessNextRec
		INY
		JMP fullmatch
		.ProcessNextRec
		LDY #7
		JMP NextRec
		}
\Magic9
		.Magic9
		{
		INY
		LDA (Aptr),Y
		STA matchlen \no of bytes to match
		INY \first char of search string
		LDX #0
		.loop
		LDA (Aptr),Y
		CMP rawdat,X
		BEQ trynextchar
		INX
		BNE loop
		LDA matchlen
		CLC
		ADC #8
		TAY
		JMP NextRec \no match next entry
		.trynextchar
		INX
		STX tempx
		STY tempy%
		LDA matchlen
		STA len
		.al
		INY
		LDA (Aptr),Y
		CMP rawdat,X
		BNE nomatch
		INX
		DEC len
		BNE al
		\have a match
		INY
		JMP fullmatch
		.nomatch
		LDY tempy%
		LDX tempx
		BNE loop
		}
\GethighestByte
		.GethighestByte
		{
		LDA #0
		TAY
		.aa
		CMP countpg,Y
		BCS ab
		LDA countpg,Y
		STY highestbyte
		BCC aa
		.ab
		INY
		BNE aa
		STA noofbytes
		RTS
		}
\statistic		
		.statistic \need to create a page of freqs
		{
		LDA #0
		STA zz
		STA zz+1
		TAY
		.fa
		STA countpg,y
		DEY
		BNE fa\clear countpg
		.fb
		LDA rawdat,Y
		TAX
		CLC
		ADC zz
		STA zz
		LDA zz+1
		ADC #0
		STA zz+1
		STY tempy%
		TXA
		TAY
		LDA countpg,Y
		TAX
		INX
		TXA
		STA countpg,Y
		LDY tempy%
		INY
		BNE fb
		LDA zz
		STAz
		LDA zz+1
		STA z+1
		RTS
		}
\NextRec		
		.NextRec
		{
		.aa
		INY
		LDA (Aptr),Y
		CMP #13
		BNE aa
		INY
		TYA
		CLC
		ADC Aptr
		STA Aptr
		LDA #0
		ADC Aptr+1
		STA Aptr+1
		JMP TableScan
		}

\tables are all consistant at the end namely
\exec,load,ident
\if E%=0 overwrite same with L%
\report confict and clear E% and L%
		.fullmatch
		{
		TYA
		LDA #6
		CLC
		ADC ypush
		STA ypush
		\is E% empty
		CLC
		LDA e
		ADC e+1
		BEQ bc
		CLC
		LDA (Aptr),Y
		INY
		ADC (Aptr),Y
		BEQ bd
		DEY
		LDA (Aptr),Y
		CMP e
		BNE abort
		INY
		LDA (Aptr),Y
		CMP e+1
		BNE abort
		BEQ bd
		.bc:\e is 0 need to write out
		LDA (Aptr),Y
		STA e
		INY
		LDA (Aptr),Y
		STA e+1
		.bd
		INY
		CLC
		\is L% empty
		LDA l
		ADC l+1
		BEQ bf
		CLC
		LDA(Aptr),Y
		INY
		ADC(Aptr),Y
		BEQ bg
		DEY
		LDA (Aptr),Y
		CMP l
		BNE abort
		.aa
		INY
		LDA (Aptr),Y
		CMP l+1
		BNE abort
		BEQ bg
		.bf \l is 0 need to write out
		LDA(Aptr),Y
		STA l
		INY
		LDA(Aptr),Y
		STA l+1
		.bg
		INY
		STY tempy%
		JSR printdescription
		LDY tempy%
		.noprint
		JMP NextRec
		.ac
		LDA (Aptr),Y
		INY
		CMP #13
		BNE ac
		TYA
		CLC
		ADC Aptr
		STA Aptr
		LDA #0
		ADC Aptr+1
		STA Aptr+1
		JMP NextRec
		}
		.printdescription
		{
		IF __OSARGSOptions = TRUE
			{
			LDA OptionBit%
			AND #OSARGSbitOptionQuiet%
			BEQ aa
			RTS
			.aa
			}
		ENDIF
		
		LDA (Aptr),Y
		JSR OSASCI
		INY
		CMP #13
		BNE printdescription
		RTS
		}
		.abort
\		(
		JSR printdescription
		LDX #ConflictDetected%
		JMP diserror \RTS
		\BRK
		\EQUS 0,"Conflict detected",&D ,0
\		)
\Clearint cli offset from a in X
		.clearint
		{
		LDA #0
		LDY #3
		.dx
		STA a,X
		INX
		DEY
		BPL dx
		RTS
		}
\setexe
		.setexe
		{
		STA e
		LDA #&7C
		STA e+1
		.exit
		RTS
		}


\------------------
\ strings and things
\------------------
.CommandAndText
dricmd%=1
EQUS"DR. ",&8D
dincmd% =2
EQUS"DIN",' '+&80
usage%=3 
EQUS"Usage <fsp> (<drv>) (<dno>/<dsp>)",&D
EQUS"L% for load 0=do not change",&D
EQUS"E% for exe 0=do not change",&80+&D
notfound% =4
EQUS"file not found",&8D
\Loadcmd% = 5
\EQUS"LO.",&A0
ConflictDetected% = 5
EQUS"Conflict detected",&8D
NoSpecialexe =6
EQUS"Special exe add not coded",&8D
MagicAreadyset%=7
EQUS"Magic already set",&8D
.pageload
.end


SAVE "magic", start, end,startexec
\cd D:\GitHub\beebyams\beebasm
\beebasm -i .\Magic\Magic.asm -do .\Magic\magic.ssd -boot Magic -v -title Magic
\beebasm -i .\Magic\Magic.asm -di .\Magic\Magic-dev.ssd -do .\Magic\Magic.ssd -v 
\cd C:\GitHub\beebyams


\ ./tools/beebasm/beebasm.exe -i ./magic.asm -do ./build/magic.ssd -boot magic -v -title magic