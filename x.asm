
\based on ideas in CHe00 by martin mather 14/10/2006 
\Usage <fsp> (<dno>/<dsp>) (<drv>)
\todo repton screens will fail if not drive 3
INCLUDE "VERSION.asm"
INCLUDE "SYSVARS.asm"			; OS constants
INCLUDE "BEEBINTS.asm"			; A% to Z% as a ... z
INCLUDE "TELETEXT.asm"
__DEBUG =TRUE
\"…Variables
NoSpecials%=7:\"offset from 1
EndSpecial%=&FF-NoSpecials% \ TODO REMOVE
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
\erradd=&34
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
\--------------------------------------------------------------
\&50 - &6F not used
\--------------------------------------------------------------
\IntA &2A -&2D
Osargsadd =&2A
TextAdd =&2C
\&2E TO &35 basic float

\&3B to &42 basic float
\single bytes
key=&3B
\&50-&6F Not used
\&70 to &8F reserved for 
blockstart=&70
load=blockstart+2
exe=blockstart+6
size=blockstart+&A
cat=&72
codestart=&70

\90-9F	allocated for Econet system
\A0-A7	used by current NMI (mostly disc and network filing)
\   A8-AF	used for OS commands when executing
ScrLoadPtr =&A8
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

\&600 String manipulation
osgbpbdata%=&600
WORKINGStrA=&650
shortcode=&640
strA%=&6B0
strB%=&690
pram%=strB%
filename%=&6D0
\&900 - &AFF RS232 & cassette openin/open out
\&B00 &BFF programmable keys
\&C00 CFF extended character
\&D00 DFF  disk operations
\&1100-7C00 main mem
\------------------------------------------------------
\setup for OSARGS
__OSARGSinit = TRUE
__OSARGSargXtoOSARGSstrB = TRUE
__OSARGSargcountX = TRUE
__OSARGSallcmdintoOSARGSstrAoffsetX = TRUE
\Variables - 
OSARGSptr = Osargsadd
OSARGSstrB =strB% 
OSARGSstrA =strA%
\-------------------------------------------------------

ORG &6800
GUARD &7C00

.start
BUILD_VERSION

\"„"RUN this can not be over page boundery hence put at top
.run
EQUS"O.",13
EQUS"RUN",13,0
.modexec
{
LDA #&16
JSR OSASCI
TXA
JSR OSASCI
\LDX #0
\STX &FE01
LDY #HI(strA%)
LDX #LO(strA%)
JMP OSCLI
}
.endmodexec
\INCBIN ".\x\$.modexec"
.altdec
INCBIN ".\x\$.altdec"
.scrload
\INCBIN ".\x\$.altscrl"
INCBIN ".\x\$.scrload"
\scrload headerless 
.ldpic
INCBIN ".\x\$.altldpc"
\the yorkshire boys music
\SKIPTO &7200
.tybmusic
INCBIN ".\x\$.code2"
INCLUDE "OSARGS.ASM"
		
		.GetDrive
		{
		LDX #2
		JSR OSARGSargXtoOSARGSstrB
		\returns X as LENGTH
		CPX #1
		BNE ret
		LDA pram%
		CMP #'0'
		BCC ret
		CMP #'4'
		BCS ret
		STA requesteddrive
		LDA #0 
		.ret
		RTS \RTS
		}
\getcurrent drive
		.getcurrentdrive
		{
		lDA #OSGBPBGetLibraryName%
		LDX #LO(conb)
		LDY #HI(conb)
		JSR OSGBPB
		IF __DEBUG
			{
			LDX #&FF
			.aa
			INX
			LDA debugtext,X
			JSR OSASCI
			CMP #&D
			BNE aa
			BEQ ab
			.debugtext
			EQUS "Currentdrive "
			EQUB &D
			.ab
			LDA osgbpbdata%+1
			JSR OSASCI
			JSR gti
			}
		ENDIF
		LDA osgbpbdata%+1
		
		
		RTS \RTS
		}
		.addAtoStrA
		{
		LDX strAoffset
		INX
		STA strA%,X
		INX
		LDA #&D
		STA strA%,X
		DEX
		STX strAoffset
		RTS
		}
		.DealwithArgCount
		{
		CPX #2
		BCC aa
		\have full command line
		\<fsp> (<drv>) (<dno>/<dsp>)
		\or <fsp>  (<drv>)
		\or <fsp> (<dno>/<dsp>)
		LDX #dincmd%
		JSR initprepcmd
		JSR GetDrive
		BNE Justdsp
		JSR addpram
		LDA #' '
		JSR addAtoStrA
		LDX #3
		JSR OSARGSargXtoOSARGSstrB
		JSR addpram
		JMP execmd
		.Justdsp
		LDA requesteddrive
		JSR addAtoStrA
		LDA #' '
		JSR addAtoStrA
		JSR addpram
		JMP execmd \RTS end of DIN
		\filename
		.aa
		\<fsp>
		IF __DEBUG
			{
			LDX #&FF
			.aa
			INX
			LDA debugtext,X
			JSR OSASCI
			CMP #&D
			BNE aa
			BEQ ab
			.debugtext
			EQUS "Command line just filename"
			EQUB &D
			.ab
			JSR gti
			}
		ENDIF
		\set requesteddrive
		JSR getcurrentdrive
		STA requesteddrive
		RTS
		}
\issue *dr.X command
		
		.setrequesteddrive
		{
		LDX #dricmd%
		JSR initprepcmd
		LDA requesteddrive
		STA strA%+3
		JMP execmd \RTS
		}
		.gettitleopt
		{
		lDA #OSGBPBTitleAndboot%
		LDX #LO(conb)
		LDY #HI(conb)
		JSR OSGBPB
		LDA osgbpbdata%
		TAY
		INY
		\This is an int!
		LDA osgbpbdata%,Y
		RTS
		}
		\execmd
		.execmd
		{
		IF __DEBUG
			{
			LDY #&FF
			.aa
			INY
			LDA strA%,Y
			JSR OSASCI
			CMP #&D
			BNE aa
			JSR gti 
			}
		ENDIF
		LDY #HI(strA%)
		LDX #LO(strA%)
		JSR OSCLI \change to JMP below lines are for ?
		LDY #0
		LDA filesize
		TAX
		RTS
		}
		\Get input 
		.gti
		{
		LDA #OSBYTEReadCharacterFromBuffer%
		LDX #OSBYTEXKeyboardBuffer%
		JSR OSBYTE
		BCS gti \no character
		RTS
		}
		.addprelude
		{
		LDY #0
		.af
		LDA preludetxt,Y
		STA strA%,X
		INX
		INY
		CMP #&D
		BNE af
		RTS
		}
		.initprepcmd
		{
		LDA #0
		STA strAoffset 
		}
		.prepcmd
		{
		JSR MoveToRec
		LDX strAoffset
		LDY #0
		.ey
		LDA (TextAdd),Y
		CMP #&80
		BCC am
		AND #&7F
		STA strA%,X
		STX strAoffset
		INX
		LDA #&D
		STA strA%,X
		RTS
		.am
		STA strA%,X
		INX
		INY
		BNE ey
		}
		\Set cursor off
		.sco
		{
		LDA #23
		JSR OSASCI
		LDA #1
		JSR OSASCI
		LDX #9
		LDA #0
		.aa
		JSR OSASCI
		DEX
		BNE aa
		RTS
		}
	\add pram$ to strA%
		.addpram
		{
		LDY #&FF
		LDX strAoffset
		.ae
		INY
		INX
		LDA pram%,Y
		STA strA%,X
		CMP #&D
		BEQ af
		BNE ae
		.af
		LDA #' '
		STA strA%,X
		STX strAoffset
		INX
		LDA #&D
		STA strA%,X
		RTS
		}
		.music
		\get *K.0 DEFINED AND IN BUFFER
		{
		IF __DEBUG
			{
			LDX #&FF
			.aa
			INX
			LDA debugtext,X
			JSR OSASCI
			CMP #&D
			BNE aa
			BEQ ab
			.debugtext
			EQUS "Music busted !!!"
			EQUB &D
			.ab
			JSR gti
			}
		ENDIF
		LDX #key1cmd%
		JSR initprepcmd
		JSR execmd
		LDA #FUNCTIONkey2
		STA key
		JSR putkeyinbuffer
		LDA #35
		STA &74
		LDAload+1
		STA &75
		CLC
		ADC size+1
		STA &76
		LDX #loadcmd%
		JSR initprepcmd
		JSR addpram
		JMP execmd
		}
		.putkeyinbuffer
		{
		IF __DEBUG
			{
			LDX #&FF
			.aa
			INX
			LDA debugtext,X
			JSR OSASCI
			CMP #&D
			BNE aa
			BEQ ab
			.debugtext
			EQUS "put key in buffer"
			EQUB &D
			.ab
			JSR gti
			}
		ENDIF
		LDX #OSBYTEXKeyboardBuffer%
		LDA #OSBYTEFlushSelectedBuffer%
		JSR OSBYTE 
		LDA #OSBYTEPlaceCharacterIntoBuffer% 
		LDX #OSBYTEXKeyboardBuffer%
		LDY key
		JMP OSBYTE \RTS
		}
		.reptoninstructions
		{
		LDX #7
		JSR setmode
		LDX #0
		.aa
		LDA reppre,X
		BEQ ad
		JSR OSASCI
		INX
		BNE aa
		.ad
		LDX tempx
		JSR diserror
		LDX #0
		.ab
		LDA reppost,X
		BEQ ac
		JSR OSASCI
		INX
		BNE ab
		.ac
		JMP gti:\rts
		}
		\select mode X
		.setmode \x=requiredmode
		{
		LDA #22
		JSR OSASCI
		TXA
		JMP OSASCI \RTS
		}
		.OSFILEdelete
		{
		IF __DEBUG
			{
			LDX #&FF
			.aa
			INX
			LDA debugtext,X
			JSR OSASCI
			CMP #&D
			BNE aa
			BEQ ab
			.debugtext
			EQUS "delete file"
			EQUB &D
			.ab
			JSR gti
			}
		ENDIF
		LDA #OSFILEdelete%
		JMP OSFILEexecute \rts
		}
		.OSFILEexecute
		{
		LDX #LO(block)
		LDY #HI(block)
		JMP OSFILE \rts
		}
	\Display error
		\takes x as strno
		.diserror
		{
		JSR MoveToRec
		JMP PrintRecord
		}
		.PrintRecord
		{
		LDY #0
		.bc
		LDA (TextAdd),Y
		CMP #&80
		BCC bd
		AND #&7F
		JMP OSASCI \RTS
		RTS
		.bd
		JSR OSASCI
		INY
		BNE bc
		}
		.MoveToRec
		{
		LDA #LO(CommandAndErrorText)
		STA TextAdd
		LDA #HI(CommandAndErrorText)
		STA TextAdd+1
		LDY #0
		.ba
		DEX
		BNE bb
		RTS
		.bb
		LDA (TextAdd),Y
		INY
		CMP #&80
		BCC bb
		CLC
		TYA
		ADC TextAdd
		STA TextAdd
		LDA #0
		ADC TextAdd+1
		STA TextAdd+1
		LDY #0
		BEQ ba
		}
		.ToManyVariables
		.ZeroError
		.NoDisk
		{
		LDX #usage%
		JSR diserror
		LDX #extendedhelp%
		JSR diserror
		LDX #extendedhelpcont1%
		JSR diserror
		LDX #extendedhelpcont2%
		JSR diserror
		LDX #extendedhelpcont3%
		JMP diserror:\JMP so end
		}
\-------------------------
		
.startexec

\-------------------------
		IF __DEBUG
			LDX #7
			JSR setmode
		ENDIF
		.init
		{
		LDA #'3'
		STA requesteddrive
		LDA #0
		STA loadadd
		\filesize =0 indicates no shift
		STA filesize
		\basic =0 indicates not basic
		STA basic
		LDA #HI(pram%)
		STA blockstart+1
		LDA #LO(pram%)
		STA blockstart
		\filesize =0 indicates no shift
		\basic =0 indicates not basic
		
		}
\osargs initiate
		{
		JSR OSARGSinit
		JSR OSARGSargcountX
		CPX #0
		BEQ ZeroError
		CPX #4
		BCS ToManyVariables
		JSR DealwithArgCount
		}
		\Din command issued
		\requesteddrive Set
		JSR setrequesteddrive
		\Lets get file info!
		LDX #1
		JSR OSARGSargXtoOSARGSstrB
		\filenameintopram%
		\Process filename
		\Check FOR !BOOT
		.boot
		{
		LDY #4
		.ca
		LDA boottxt,Y
		CMP strB%,Y
		BEQ cc
		CLC
		ADC #32
		CMP strB%,Y
		BNE notboot
		.cc
		DEY
		BPL ca
		}
		IF __DEBUG
			{
			LDX #&FF
			.aa
			INX
			LDA debugtext,X
			JSR OSASCI
			CMP #&D
			BNE aa
			BEQ ab
			.debugtext
			EQUS "Have !boot"
			EQUB &D
			.ab
			JSR gti
			}
		ENDIF
		\Have boot
		\See ADVANCED DISKUSER GUIDE pg168
		JSR gettitleopt
		\Check for exec  (OPT4,3)
		CMP #3
		BNE NotExe
		LDX #execfilecmd%
		JSR initprepcmd
		JSR addpram
		JMP execmd \rts
		.NotExe
		CMP #2
		BNE catalogue
		LDA #&FF
		STA strAoffset
		JSR addpram
		JMP execmd \rts
		.catalogue
		LDX #catcmd%
		JSR initprepcmd
		JMP execmd \rts
		.notboot
		\now have blockstart with filename
		IF __DEBUG
			{
			LDX #&FF
			.aa
			INX
			LDA debugtext,X
			JSR OSASCI
			CMP #&D
			BNE aa
			BEQ ab
			.debugtext
			EQUS "Not !boot"
			EQUB &D
			.ab
			JSR gti
			}
		ENDIF
		LDX #blockstart
		LDY #0
		LDA #OSFILEReadFileInfo%
		JSR OSFILE
		\get file info if A<> 1 not a file
		CMP #OSFILEReturnFileFound%
		BEQ havefiledetails
		\file not found
		LDX #notfound%
		JMP diserror \RTS
		.havefiledetails
		IF __DEBUG
			{
			LDX #&FF
			.aa
			INX
			LDA debugtext,X
			JSR OSASCI
			CMP #&D
			BNE aa
			BEQ ab
			.debugtext
			EQUS "Have file details"
			EQUB &D
			.ab
			JSR gti
			}
		ENDIF
		\TO DO Put all descisions here and make jmps?
		LDA exe+1
		CMP #&7F
		BEQ specials
		CMP #&80
		BNE LoadSpecial
		LDA exe
		CMP #&23
		BEQ basicprog
		CMP #&1F
		BEQ	basicprog
		.LoadSpecial
		LDA load+1
		CMP #&7F
		BNE endspecial
		LDA load
		CMP #&FD
		BNE endspecial
		\Scrload
		{
		LDA blockstart
		STA ScrLoadPtr
		LDA blockstart+1
		STA ScrLoadPtr+1
		.xx
		LDA scrload,Y
		STA &900,Y
		LDA scrload+&100,Y
		STA &A00,Y
		INY
		BNE xx
		JMP &900
		}
		.basicprog
		IF __DEBUG
			{
			LDX #&FF
			.aa
			INX
			LDA debugtext,X
			JSR OSASCI
			CMP #&D
			BNE aa
			BEQ ab
			.debugtext
			EQUS "Basic program"
			EQUB &D
			.ab
			JSR gti
			}
		ENDIF
\basic program
		LDA load+1
		STA &18 \set page
		\code to add chars to buffer ("RUN",13)
		\fragile code if over page boundary
		\advanced user guide pg 162
		\ buffer table pg 138
		\clear BUFFER
		LDX #OSBYTEXKeyboardBuffer% 
		LDA #OSBYTEFlushSelectedBuffer%
		JSR OSBYTE
		.ui
		LDY run \0 ldy 1 lowbyte
		IF __DEBUG
			TYA
			JSR OSASCI
		ENDIF
		BEQ ab
		INC ui+1
		LDA #OSBYTEPlaceCharacterIntoBuffer%
		LDX #OSBYTEXKeyboardBuffer%
		JSR OSBYTE
		BVC ui \loop jmp
		.ab
		INC basic
		.endspecial
		JMP prepload
\Specials
		.specials
		IF __DEBUG
			{
			LDX #&FF
			.aa
			INX
			LDA debugtext,X
			JSR OSASCI
			CMP #&D
			BNE aa
			BEQ ab
			.debugtext
			EQUS "Specials"
			EQUB &D
			.ab
			JSR gti
			}
		ENDIF
		LDA exe
		LDX #0
		CMP #&FE
		BNE ca
\7FFE LDPIC compressed picture
		IF __DEBUG
			{
			LDX #&FF
			.aa
			INX
			LDA debugtext,X
			JSR OSASCI
			CMP #&D
			BNE aa
			BEQ ab
			.debugtext
			EQUS "LDpic"
			EQUB &D
			.ab
			JSR gti
			}
		ENDIF
		LDA blockstart
		STA z
		LDA blockstart+1
		STA z+1
		LDY #0
		.xb
		LDA (blockstart),y
		STA strA%,Y
		INY
		CMP #&D
		BNE xb
		INC blockstart
		bne sa
		INC blockstart+1
		.sa
		LDY #0
		.xx
		LDA ldpic,Y
		STA &900,Y
		LDA ldpic+&100,Y
		STA &A00,Y
		INY
		BNE xx
		LDX #LO(strA%)
		LDY #HI(strA%)
		LDA #&40
		JMP &900
\7FFD SHOWPIC"
		.ca
		CMP #&FD
		BNE cc
		IF __DEBUG
			{
			LDX #&FF
			.aa
			INX
			LDA debugtext,X
			JSR OSASCI
			CMP #&D
			BNE aa
			BEQ ab
			.debugtext
			EQUS "Showpic"
			EQUB &D
			.ab
			JSR gti
			}
		ENDIF
		LDX #scrloadcmd%
\7FFC type word text
		.cc
		CMP #&FC
		BNE cd
		LDX #typecmd%
\7FFB DUMP
		.cd
		CMP #&FB
		BNE ce
		LDX #dumpcmd%
\7FFA EXEC
		.ce
		CMP #&FA
		BNE cf
		LDX #execfilecmd%
\7FF9 TYB music samples
		.cf
		CMP #&F9
		BNE cg
		IF __DEBUG
			{
			LDX #&FF
			.aa
			INX
			LDA debugtext,X
			JSR OSASCI
			CMP #&D
			BNE aa
			BEQ ab
			.debugtext
			EQUS "TYB music"
			EQUB &D
			.ab
			JSR gti
			}
		ENDIF
		LDY #0
		.xy
		LDA tybmusic,Y
		STA &900,Y
		INY
		BNE xy
		LDA #35
		STA &74
		LDAload+1
		STA &75
		CLC
		ADC size+1
		STA &76
\setup load command
		LDX #loadcmd%
		JSR initprepcmd
		JSR addpram
		\now have *lo. FILENAME &D ready
		\LDY #0:DEX
		LDX #laddcmd%
		INC strAoffset
		JSR prepcmd
		LDY #8
		.kk
		LDA shiftme,Y
		STA shortcode,Y
		DEY
		BPL kk
		LDY #HI(strA%)
		LDX #LO(strA%)
		JMP shortcode
		.shiftme
		JSR OSCLI
		JMP &900
\7FF8 DEC compressed picture
		.cg
		CMP #&F8
		BNE ch
		{
		\load altdec into A00
		LDY #0:.xx
		LDA altdec,Y
		STA &A00,Y
		LDA altdec+&100,Y
		STA &B00,Y
		INY
		BNE xx
		LDY #0
		.xb
		LDA (blockstart),y
		STA &BDD,Y
		INY
		CMP #&D
		BNE xb
		JMP &A00\rts
		}
\7FF7 viewsheet
		.ch
		CMP #&F7
		BNE ci
		LDX #9
		.ci
		CMP #&F6
		BNE cj
\7FF6 repton3 screen
\need to select repton3 disk
\display text g=get
\setup *k.1
		.repton3
		{
		\todo
		IF __DEBUG
			{
			LDX #&FF
			.aa
			INX
			LDA debugtext,X
			JSR OSASCI
			CMP #&D
			BNE aa
			BEQ ab
			.debugtext
			EQUS "Repton 3"
			EQUB &D			
			.ab
			JSR gti
			}
		ENDIF
		LDA requesteddrive
		STA tempx
		LDA #'0'
		STA requesteddrive
		JSR setrequesteddrive
		LDA tempx
		STA requesteddrive
		\set drive 0 to x-files
		LDX #xfilescmd%
		JSR initprepcmd
		JSR execmd
		LDA tempx
		STA requesteddrive
		\set requeested drive back
		\display text
		{
		LDA #rep3instruction%
		STA tempx
		JSR reptoninstructions
		}
		
		\*k.1 setup
		LDX #key1cmd%
		JSR initprepcmd
		JSR addpram
		LDA requesteddrive
		STA strA%+4
		JSR execmd
		LDX #repton3keyset2%
		JSR initprepcmd
		JSR execmd
		LDX #18
		LDA #0
		.ab
		STA &70,X
		DEX
		BPL ab
		\need to initaise &7C and &7F
		LDA #&60
		STA &7C
		LDA #&3
		STA &7F
		LDA #FUNCTIONkey2
		STA key
		JMP putkeyinbuffer \RTS
		
		
		\*repton2
		\LDX #reptonthreecmd%
		\JSR initprepcmd
		\RTS:\debug
		}
		\display text
		{
\		LDA #repinfin%:STA tempx
\		JSR reptoninstructions
		}
		{
		\need to init zero page (&70 &82 loaded with zero)
\		LDX #18
\		LDA #0\
\		.ab
\		STA &70,X
\		DEX
\		BPL ab
\		\need to initaise &7C and &7F
\		LDA #&60
\		STA &7C
\		LDA #&3
\		STA &7F
\		LDA #FUNCTIONkey2
\		STA key
\		JMP putkeyinbuffer \RTS
		\JMP setandexe
		}
\7FF5 scrload
		.cj
		CMP #&F5
		BNE ck
		{
		LDY #0
		.xx
		LDA scrload,Y
		STA &900,Y
		INY
		BNE xx
		LDY #0
		.xa
		LDA scrload+&100,Y
		STA &A00,Y
		INY
		BNE xa
		JSR sco
		\set file name into strA%
		LDA #0
		TAY
		TAX
		JSR addpram
		JMP &900
		}
		.ck
		CMP #&F4
		BNE cl
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
		IF __DEBUG
			{
			LDX #&FF
			.aa
			INX
			LDA debugtext,X
			JSR OSASCI
			CMP #&D
			BNE aa
			BEQ ab
			.debugtext
			EQUS "rep inf"
			EQUB &D
			.ab
			JSR gti
			}
		ENDIF
		LDA requesteddrive
		STA tempx
		LDA #'0'
		STA requesteddrive
		JSR setrequesteddrive
		\set drive 0 to x-files
		LDA tempx
		STA requesteddrive
		LDX #xfilescmd%
		JSR initprepcmd
		JSR execmd
		
		\need to delete prelude from x-files without interaction
		JSR OSFILEdelete
		
		\LDX #LO(preludetxt)
		\LDY #HI(preludetxt)
		\LDA #6
		\JSR OSFILE
		\copy file to xfiles (dr.0) 
		\copy 3 0 XXXX
		LDX #copycmd%
		JSR initprepcmd
		LDA requesteddrive
		STA strA%+5
		JSR addpram
		\DEX:JSR addprelude:
		JSR execmd
		\drive 0
		\JSR setrequesteddrive
		\LDX #NoSpecials%+6
		\JSR initprepcmd:JSR execmd
		\rename file to prelude
		LDX #renamecmd%
		JSR initprepcmd
		JSR addpram
		INC strAoffset
		LDX #preludecmd%
		JSR prepcmd
		JSR execmd
		\*k,2 mo.5 repI
		LDX #reptonIkeyset2%
		JSR initprepcmd
		JSR execmd
		LDA #repinfin%
		STA tempx
		JSR reptoninstructions
		LDA #FUNCTIONkey2
		STA key
		JMP putkeyinbuffer \RTS
		\DEX:JSR addprelude:JSR execmd
\display text
		
		\{
		\LDX #0
		\.aa:LDA reptoninfinitytext,X:BEQ ac:JSR osasci:INX:BNE aa
		\.ac
		\JSR gti
		\LDX #reptonicmd%
		\JSR initprepcmd
\setmode and execute
		
\*repi
\LDX #NoSpecials%+9
\JSR initprepcmd:JMP execmd:\RTS
		.cl
		.cz
		CPX #00
		BEQ screencheck:
		JSR initprepcmd
		JSR addpram
		JMP execmd
		\JMP so end
		.screencheck
		{
		CMP #8
		BCS notcoded
		LDA #22
		JSR OSCLI  \?
		LDA exe
		JSR OSCLI  \?
		JSR sco
		LDX #loadcmd%
		JSR initprepcmd
		JSR addpram
		JSR execmd
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
		LDA #EndSpecial%
		STA switch
		LDX #dricmd%
		LDA exe
		.ag
		CMP switch
		BNE aw
		.exespecial
		JSR initprepcmd
		JSR addpram
		JMP execmd
		\JMP so end
		.aw
		INC switch
		DEX
		BNE ag
		\Special exe address not coded
		.notcoded
		LDX #exeaddressinvalid%
		JSR diserror
		LDX #extendedhelp%
		JSR diserror
		LDX #extendedhelpcont1%
		JMP diserror:\rts
\JMP so end
\prepload
		.prepload
		IF __DEBUG
			{
			LDX #&FF
			.aa
			INX
			LDA debugtext,X
			JSR OSASCI
			CMP #&D
			BNE aa
			BEQ ab
			.debugtext
			EQUS "loading file"
			EQUB &D
			.ab
			JSR gti
			}
		ENDIF
		LDA load
		STA trueadd
		LDA load+1
		STA trueadd+1
		LDX #loadcmd%
		JSR initprepcmd
		JSR addpram
		\now have *lo. FILENAME &D ready
		\to execute
		LDA exe
		STA exeadd
		LDA exe+1
		STA exeadd+1
		LDA load+1
		CMP #&11
		BCC shiftrequired
		IF __DEBUG
			{
			LDX #&FF
			.aa
			INX
			LDA debugtext,X
			JSR OSASCI
			CMP #&D
			BNE aa
			BEQ ab
			.debugtext
			EQUS "No shift required"
			EQUB &D
			.ab
			JSR gti
			}
		ENDIF
\romcheck 
		.romcheck
		CMP #&80
		BNE zeropage
		.bx
		IF __DEBUG
			{
			LDX #&FF
			.aa
			INX
			LDA debugtext,X
			JSR OSASCI
			CMP #&D
			BNE aa
			BEQ ab
			.debugtext
			EQUS "Have a ROM Just loading TODO"
			EQUB &D
			.ab
			JSR gti
			}
		ENDIF
		JMP execmd \rts
\JMP so end 
\below &1100 so need to shift
		.shiftrequired
		IF __DEBUG
			{
			LDX #&FF
			.aa
			INX
			LDA debugtext,X
			JSR OSASCI
			CMP #&D
			BNE aa
			BEQ ab
			.debugtext
			EQUS "Shift required"
			EQUB &D
			.ab
			JSR gti
			}
		ENDIF
		LDA #&11
		STA loadadd+1
		LDA size+1
		STA filesize
		INC filesize
		DEX
		LDY #0
		LDX #laddcmd%
		\*lo. FILENAME &1100 &D
		JSR prepcmd
\.bv:LDA ladd,Y:STA strA%,X:INX:INY:CMP #&D:BNE bv
\now have *LOAD fname 1100 ready
\Move code to zeropage
		.zeropage
		IF __DEBUG
			{
			LDX #&FF
			.aa
			INX
			LDA debugtext,X
			JSR OSASCI
			CMP #&D
			BNE aa
			BEQ ab
			.debugtext
			EQUS "Zeropage code reached"
			EQUB &D
			.ab
			JSR gti
			}
		ENDIF
		LDY #codeend-codebegin
		.av
		LDA codebegin,Y
		STA codestart,Y
		DEY
		BPL av
		\CODE NOW IN ZERO PAGE
		LDY #HI(strA%)
		LDX #LO(strA%)
		JMP codestart
		
		\.setandexe
		\{
		\LDY #endmodexec-modexec
		\.xx
		\LDA modexec,Y
		\STA &900,Y
		\DEY
		\BPL xx
		\LDX #5 \mode5
		\JMP &900 \rts
		\}
\-----------------------
		.codebegin
		\need to keep code here to min
		\loadfile and shift if required
		JSR OSCLI
		LDY #0
		LDX filesize
		BEQ at
		.iq1
		LDA (loadadd),Y
		STA (trueadd),Y
		INY
		BNE iq1
		INC loadadd+1
		INC trueadd+1
		DEX
		BPL iq1
		\JUMP OR RTS
		\Note jmp will save RTS!
		.at
		LDA basic
		BNE endbasic
		JMP (exeadd)
		.endbasic
		RTS \should have RUN in buffer
		.codeend
\--------------------------------------------
	\Data structures

	.conb
		EQUB 0
		EQUD osgbpbdata%
		EQUD 0
		EQUD 0
		
	.block
		EQUB Lo(preludetxt)
		EQUB HI(preludetxt)
		EQUB 0
		EQUB 0
		EQUW 0
		EQUW 0
		EQUD 0	
		

\-----------------------
\Strings
\-----------------------		
		.boottxt
		EQUS"!BOOT"
		.CommandAndErrorText
		.cmdadd
		.errtxt
		\*LDPIC FE
	ldpiccmd%=1
		EQUS"LDPIC",&A0
		\*SCRLOAD FD not working !
	scrloadcmd%=2
		EQUS"SCRLOAD",&A0
		\*TYPE FC
	typecmd%=3
		EQUS"TY",&AE
		\*DUMP FB
	dumpcmd%=4
		EQUS"DU",&AE
		\*EXEC FA
	execfilecmd%=5
		EQUS"EX",&AE
	deccmd%=6
		EQUS"dec",&A0
		\SPECIALS ABOVE ALTER NoSpecials%
		\*DRIVE #0
	dricmd%=7
		EQUS"DR.",' '+&80
	dincmd%=8
		EQUS"DIN",' '+&80
	loadcmd%=9
		EQUS"LO.",' '+&80
		\select repton3 disk #3
	xfilescmd%=10
		EQUS "DIN x-files",&8D
		\* run repton3 #4
	reptonIkeyset2%=11
		EQUS "K.2MO.5|M*RepI|M",&8D
		\*K.1 #5
	key1cmd%=12
		EQUS "K.1",':'+&80
	delprelude%=13
		EQUS "del. prelude",&8D
	copycmd%=14
		EQUS "copy 3 0",' '+&80
	renamecmd%=15
		EQUS "Ren.",' '+&80
	reptonicmd%=16
		EQUS "RepI",&8D
		\1100
	laddcmd%=17
		EQUS" 1100",&8D
			
	catcmd%=18
		EQUB'*',&80+'.'
		\prelude
		.preludetxt
	preludecmd%=19
		EQUS " g.a",&D,&8D
			
	repton3keyset2%=20
		EQUS "k.2MO.5|M*REP3|M",&8D
			\repinfin%=21
			\EQUS 'A'+&80

	usage%=21
		EQUS"Usage <fsp> (<drv>) (<dno>/<dsp>)":EQUB &8D
	notfound%=22
		EQUS"file not found",&8D
	exeaddressinvalid%=23
		EQUS"Special exe address not code",&80+'d' 
	extendedhelp%=24
		EQUS"Basic progs have exe 8023":EQUB &D
		EQUS"And will be Run from load address":EQUB &D
		EQUS"!BOOT will be run as per disk opt":EQUB &D
		EQUS"ROM load should be 8000":EQUB &D
		EQUS"Files to be *DUMP exe 7FFB":EQUB &D
		EQUS"TYB music samples to be exe 7FFA":EQUB &D
		EQUS"Files to be *EXEC exe 7FFA",&8D
		\#5 EXTENDED HELP CONT
	extendedhelpcont1%=25
		EQUS"7FFE LDPIC compressed picture",&D
		EQUS"7FFD SHOWPIC not working",&D
		EQUS"7FFC type word text",&D
		EQUS"7FFB DUMP",&D
		EQUS"7FFA EXEC",&8D
	extendedhelpcont2%=26	
		EQUS"7FF9 TYB music samples":EQUB &D
		EQUS"7FF8 DEC compressed picture":EQUB &D
		EQUS"7FF7 viewsheet":EQUB &D
		EQUS"7FF6 31E0 repton 3 level(screen)":EQUB &D
		EQUS"7FF5 SCRLOAD TODO":EQUB &D
		EQUS"7FF4 31E0 repton infinity level(screen)", &D
		EQUS"7F07 mode 7 Screen":EQUB &D
		EQUS"7F06 mode 6 Screen":EQUB &8D
	extendedhelpcont3%=27
		EQUS"7F05 mode 5 Screen":EQUB &D
		EQUS"7F04 mode 4 Screen":EQUB &D
		EQUS"7F03 mode 3 Screen":EQUB &D
		EQUS"7F02 mode 2 Screen":EQUB &D
		EQUS"7F01 mode 1 Screen":EQUB &D
		EQUS"7F00 mode 0 Screen":EQUB &D \22 7 curser off g=get
		EQUS"Version ": BUILD_VERSION
		EQUD &8D
		\#9 repinfinity
	rep3instruction%=28
		EQUS"F",'1'+&80
		\#8 rep3
		\rep3%=9
	repinfin%=29
		EQUS 'A'+&80

		\Zero terminated strings 
		.reppre
		EQUS &D,&D,&D,&D,&D,&D,"When game loads please press"
		EQUS TELETEXTgreentext,"L",&D,"Then press"
		EQUS TELETEXTgreentext
		EQUB 0
		.reppost
		EQUS TELETEXTyellowtext,"to load selected level",&D
		EQUS TELETEXTyellowtext
		EQUS TELETEXTflashon,"Press any key",&D
		EQUB 0



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
\ ./tools/beebasm/beebasm.exe -i ./x.asm -do ./build/x.ssd -boot x -v -title x

