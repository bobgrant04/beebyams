INCLUDE "VERSION.asm"
INCLUDE "SYSVARS.asm"			; OS constants
INCLUDE "BEEBINTS.asm"			; A% to Z% as a ... z

__DEBUG = TRUE


\\MAGIC used to inteligently guess exe and or load address
\Magic <fsp> (<dno>/<dsp>) (<drv>)
\if exe is in the range 7F00 then exe will not be analysied as firm indication of file given 
\load address will change for rom to &8000
\will Guess screen load mode from load address and size
\load address will be altered for BASIC progs with <>&E00 or <>&1100
\normal *drive command and *din command will be issued (default to drive 3)
\file information will be gathered 
\Outputs E% execution L% load address  does not change progam
\use Alter to change file details
\\

\…Variables
NoSpecials%=1 \"offset from 1
EndSpecial%=&FF-NoSpecials%
\ZERO pProcessNextRece
\IntA &2A -&2D
len =&2A
\&2E TO &35 basic float
strptr=&2E
Aptr=&30
exeadd=&32
erradd=&34
\&3B to &42 basic float
\single bytes
tempy=&3B
matchlen=&3C
tempx=&3D
ypush=&3E
highestbyte=&3F
noofbytes=&40
quiet =&41
basic=&42

\&70 to &8F reserved for user
blockstart=&70
load=blockstart+2
exe=blockstart+6
size=blockstart+&A
cat=&72
codestart=&70
zz=&8E
\&F8-F9 UNUSED BY OS

\end zero pProcessNextRece

\&600 String manipulation
strB%=&640
strA%=&6A0
\&900 rs232/cassette o/p buffer envelope buffer
rawdat=&900:\output for file read
\&A00 RS232 & cassette
countpg=&A00:\pProcessNextRece for count's

\&1100-7C00 main mem
conb=&7B90 :\control block for reading disk


ORG &7100
GUARD &7C00


.start
INCLUDE "MAGIC_SOURCE.asm"		\magic configuration


.startexec
{
\get OSARGS into blockstart
LDX #blockstart
LDY #0
LDA #1
JSR OSARGS  
\ptr to command into blockstart&70
\X,Y,A are preserved OSARGS
TYA
LDA #0
STA quiet
STA basic
\filesize =0 indicates no shift
\=0 indicates not basic
\STA loadadd
TAX
LDA(blockstart),Y
CMP #&D
BNE aa
LDX #1
JSR diserror
LDX #5
JMP diserror \RTS
.aa:
CMP #('-')
BNE xa
INY
LDA(blockstart),Y
CMP #('Q')
BNE shift
INC quiet
.shift
LDX #0
INY:
.xb:
LDA(blockstart),Y
STA strB%,x
INY
INX
CMP #&D
BNE xb
LDY #0
.xc
LDA strB%,Y
STA (blockstart),Y
INY
CMP #&D
BNE xc
LDY #0
TYA
TAX
.xa
CMP #&D
BEQ cmdend
INY
LDA(blockstart),Y
CMP #' '
BNE xa
INX
BNE xa
.cmdend
CPX #2
BNE ab
STX tempx
DEY
STY tempy
\"…"Have drive param
LDX #NoSpecials%
JSR prepcmd
LDY tempy
LDA(blockstart),Y
STA strA%,X
INX
LDA #&D
STA strA%,X
DEY
STA (blockstart),Y
STY tempy
JSR execmd
LDX tempx
LDY tempy
.ab
CPX #1
BCC ac
\"…"Have DIN param
.ad
DEY
LDA(blockstart),Y
CMP #32
BNE ad
LDA #&D
STA (blockstart),Y
STY tempy
LDX #NoSpecials%+1
JSR prepcmd
LDY tempy
DEX
.ae
INY
INX
LDA(blockstart),Y
STA strA%,X
CMP #&D
BNE ae
CMP #&32
BEQ ae
LDA #&D
STA strA%,X
JSR execmd
.ac
\clear E%,L%:S%
LDX #(('E'-'A')*4)
JSR clearint
LDX #(('L'-'A')*4)
JSR clearint
LDX #(('P'-'A')*4)
JSR clearint
\"Process filename
\now have blockstart with filename does file exist

LDX #blockstart
LDY #0
LDA #5
JSR OSFILE
CMP #1
BEQ al
LDX #2
STX p
JMP diserror
.al
LDA exe+1
CMP #&7F
BNE Magic:
LDA quiet
BNE ax
LDX #4
JSR diserror
.ax
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
		LDA #&40
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
		LDA #4:
		LDX #LO(conb)
		LDY #HI(conb)
		JSR OSGBPB
		\Close File
		LDA #0
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

\screencheck
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
		LDA quiet
		BEQ exit
		LDA exe
		CMP e
		BNE bd
		LDA exe+1
		CMP e+1
		BNE bd
		LDX #(('E'-'A')*4)
		JSR clearint
		.bd
		LDA load
		CMP l
		BNE exit
		LDA load+1
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
		STA tempy
		.fh
		INY
		LDA (Aptr),Y
		CMP rawdat,X
		BEQ aa
		LDY tempy
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
		CMP load
		BNE ProcessNextRec
		INY
		LDA(Aptr),Y
		CMP load+1
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
		CMP exe
		BNE ProcessNextRec
		INY
		LDA (Aptr),Y
		CMP exe+1
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
		STA tempy
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
		LDA tempy
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
		STY tempy
		.al
		INY
		LDA (Aptr),Y
		CMP rawdat,X
		BEQ am
		LDY tempy
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
		STA tempy \no entries
		.cb
		INY
		LDA(Aptr),Y
		TAX
		LDA countpg,X:
		CLC
		ADC noofbytes
		STA noofbytes
		DEC tempy
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
		CMP size
		BNE ProcessNextRec
		INY
		LDA (Aptr),Y
		CMP size+1
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
		STY tempy
		LDA matchlen
		STA len
		.al
		INY
		LDA (Aptr),Y
		CMP rawdat,X
		BNE nomatch
		INX
		DEC len
		BPL al
		\have a match
		INY
		JMP fullmatch
		.nomatch
		LDY tempy
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
		STY tempy
		TXA
		TAY
		LDA countpg,Y
		TAX
		INX
		TXA
		STA countpg,Y
		LDY tempy
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
\prepcmd
		.prepcmd
		{
		LDY #0
		.ez
		DEX
		BNE nexcmd
		.ey
		LDA cmdadd,Y
		CMP #&80
		BCC am
		AND #&7F
		STA strA%,X
		INX
		RTS
		.am
		STA strA%,X
		INX
		INY
		BNE ey
		.nexcmd
		LDA cmdadd,Y
		INY:CMP #&80
		BCC nexcmd
		BCS ez 
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
		LDY #strA% DIV 256
		LDX #strA% MOD 256
		JMP OSCLI \rts
		}
\diserror		
		.diserror
		{
		LDA #HI(errtxt)
		STA erradd+1
		LDA #LO(errtxt)
		STA erradd
		LDY #0
		.ba
		DEX
		BNE bb
		.bc
		LDA (erradd),Y
		CMP #&80
		BCC bd
		AND #&7F
		JSR OSASCI
		RTS
		.bd
		JSR OSASCI
		INY
		BNE bc
		\have more than 255 chars
		inc erradd+1
		BNE bc
		.bb
		LDA (erradd),Y
		INY
		CMP #&80
		BCC bb
		CLC
		TYA
		ADC erradd
		STA erradd
		LDA #0
		ADC erradd+1
		STA erradd+1
		LDY #0
		BEQ ba
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
		.bf:\l is 0 need to write out
		LDA(Aptr),Y
		STA l
		INY
		LDA(Aptr),Y
		STA l+1
		.bg
		INY
		LDA quiet
		BNE noprint
		STY tempy
		JSR printdescription
		LDY tempy
		.noprint
		JMP NextRec
		.ac
		LDA (Aptr),Y:
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
		BRK
		EQUS 0,"Conflict detected",&D ,0
\		)
\clear E%,L%
\LDX #(('E'-'A')*4):JSR clearint
\LDX #(('L'-'A')*4):JSR clearint

\}
\checks for full screen load

		

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

		IF __DEBUG
			.gti
			{
			LDA #&91
			LDX #0
			JSR OSBYTE
			BCS gti
			RTS
			}
		ENDIF
\------------------
\ strings and things
\------------------
.cmdadd

\SPECIALS ABOVE ALTER NoSpecials%
\*DRIVE
EQUS"*DR.",&A0
\*DIN
EQUS"*DIN",&A0
\*LOAD
EQUS"LO.",&A0
\*CODE for music the yorkshire boys
EQUS"K.0 */code|M",&8D

\.erraddr:EQUW errtxt
.errtxt
\ 1 usProcessNextRece"
EQUS"Usage (-Q) <fsp> (<dno>/<dsp>) (<drv>)":EQUB &8D
\ 2 file not found 
EQUS"file not foun",&E4
\ 3 exe address invalid
EQUS"Special exe add not code",&E4
\ 4 Magic set
EQUS"Magic already set",&8D
\ 5 extended help 
EQUS"outputs":EQUB &D
EQUS"L% for load 0=do not change":EQUB &D
EQUS"E% for exe 0=do not change":EQUB &D
EQUS"P%<>0 error":EQUB &D
 .masterlist
EQUS"E%   L% ":EQUB &D
EQUS"8023 0000 Basic":EQUB &D
EQUS"D9CD 8000 Rom":EQUB &D
EQUS"7FFE 0000 LDPIC compressed picture":EQUB &D
EQUS"7FFD 0000 SHOWPIC":EQUB &D
EQUS"7FFC 0000 type word text":EQUB &D
EQUS"7FFB 0000 DUMP":EQUB &D
EQUS"7FFA 0000 EXEC":EQUB &D
EQUS"7FF9 0000 TYB music samples":EQUB &D
EQUS"7FF8 0000 DEC compressed picture":EQUB &D
EQUS"7FF7 0000 viewsheet":EQUB &D
EQUS"7FF6 31E0 repton 3 level":EQUB &D
EQUS"7FF5 0000 ScrLoad":EQUB &D
EQUS"7FF4 0000 Repton Infinity level":EQUB &D
EQUS"7F07 7C00 mode 7 Screen":EQUB &D
EQUS"7F06 6000 mode 6 Screen":EQUB &D
EQUS"7F05 5800 mode 5 Screen":EQUB &D
EQUS"7F04 5800 mode 4 Screen":EQUB &D
EQUS"7F03 4000 mode 3 Screen":EQUB &D
EQUS"7F02 3000 mode 2 Screen":EQUB &D
EQUS"7F01 3000 mode 1 Screen":EQUB &D
EQUS"7F00 3000 mode 0 Screen":EQUB &8D
.end


SAVE "magic", start, end,startexec
\cd D:\GitHub\beebyams\beebasm
\beebasm -i .\Magic\Magic.asm -do .\Magic\magic.ssd -boot Magic -v -title Magic
\beebasm -i .\Magic\Magic.asm -di .\Magic\Magic-dev.ssd -do .\Magic\Magic.ssd -v 
\cd C:\GitHub\beebyams


\ ./tools/beebasm/beebasm.exe -i ./magic.asm -do ./build/magic.ssd -boot magic -v -title magic