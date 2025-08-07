INCLUDE "VERSION.asm"
INCLUDE "SYSVARS.asm"			; OS constants
INCLUDE "BEEBINTS.asm"			; A% to Z% as a ... zeroz
INCLUDE "TELETEXT.asm" \TELETEXT constants
\\ this program started as a conversion from a BBC basic /MC prog
\ as such memory was an issue so three letter routine naming is used
\ this will be changed over time
\ labels are two character unique after conversion again this will not
\be maintained as {} can be used to localise labels
\in order to allow for large collections spanning more than 512 disks 
\upto &7FF
\the same with software houses upto &7FF
\!boot file should be used to set up dr1 to dr3 with catdatx FILESYSTEM
\these should be sequentental on disk starting CATDAT0
\catdat file format
\description high bit terminated
\software house low byte y%
\disk no low byte x%
\diskrec 3 bits filename cat no 5 bits 
\softwarehouse 3 bits fav (1 bit) gametype(v%) 4 
\O/P descrip MSB termination
\"„1Byte Softwarehouse
\"„1Byte Diskrec 
\"„Diskrec 3bits Filename Catno
\"„SoftwareHouse 3bits
\"„lowest 3 bit
\"„fav 1bit Gametype 3bit
\y \x \x+1 (3) u (5)
\-----------------------------------------
\constants
__DEBUG  = FALSE
__CATDATTEST = TRUE
\FILTERS 1=disk 2=publish 4=gametype
\e cont 8=fav A=SearchText
FILTERdisk%=1
FILTERpublish%=2
FILTERgametype% =4
FILTERfav% =8
FILTERdescription% =&10
\consts used create seperate windows (top main btm)
\window bits
TOPLines=3
BOTTOMLines=3
CURSORInit=&7C01+(&28*(TOPLines))
TOPWindow=0
BOTTOMWindow=4
MAINWindow=8

\maximum filter description text
FILTERTxtLen%=13
\filter set character length
FILTERCharlength =16
\red
CURSORSelectColour=TELETEXTredtext
\green
LETTERColour=TELETEXTgreentext
\black background
CURSORCancelSelect=TELETEXTblackbackground
\MAXmenuitems A-S
MAXmenuitems=19
MAXmenuletter= 'A'+MAXmenuitems 
\PRINTLineLength
PRINTLineLength=37
INTatozLen=&68
\-------------------------------
\Constant Addresses
INTatozStart=&404
SEARCHtext=&620 \search text
WORKINGStrA=&640
\WORKINGStrB=&680
\FILENAMEStr=&6FF-10
FILTERDisplaySettings=&901
\Filter results"
FILTERResultsStartAddress=&1100
\catfile
CATLoadStartAddress=&1900
\dinrec Softrec
INDEXfileloadAddress=&6000
\Nolen=&A0
\end constants
\---------------------------------------------
\…Zero Page
\IntA &2A -&2D
	\USES ALL 4 Bytes
\	FilterMask =&2A
\	FilterMaskSoftwarelow =&2A
\	FilterMaskDiskLow=&2B
\	FilterMaskDiskHigh3Catno5 =&2C
\	FilterMaskSoftwarehigh3Fav1GameType3 =&2D
\&2E TO &35 BASIC FLOATING
\SINGLES
	StrAlen=&2E
	CurrentlineLengh=&2F
	\flag for is a compound rec
	comprec=&30
	lastline=&31
	CurrentCursorLetter=&32
	tempx=&33
	tempy=&34
	
\&3B TO &42 BASIC FLOATING
CurrentCursorAddress=&3B
AFilterPointer=&41
\&50-&6F Not used
PreviousRecordset =&50	
\&70 - 8F basic for users
	comprecstore=&70 \TODO
	zeroz=&74 
	sti=&76
	Apub=&7B
	sno=&7D
	APtr=&7F
	\4 bytes
	FilterMask =&81
	FilterMaskSoftwarelow =FilterMask
	FilterMaskDiskLow=FilterMask+1
	FilterMaskDiskHigh3Catno5 =FilterMask+2
	FilterMaskSoftwarehigh3Fav1GameType3 =FilterMask+3
	\4 bytes
	Filterbits=&85
	FilterbitsSoftwarelow=Filterbits
	FilterbitsDiskLow=Filterbits+1
	FilterbitsDiskHigh3Catno5=Filterbits+2
	FilterbitsSoftwarehigh3Fav1GameType3=Filterbits+3
	FilterFlag =&8F
\&90-&91 econet
	\zerozp=&A8
\&B0- &BF FILESYSTEM SCRATCH
\&F8-F9 unused by os1.2
\resultvar=&F8
	
\--------------------------------

\&404 -&407 A% &468 -&46B Z%
\A-Z integer space
\d used
\d Aptr store
\f AFilterPointer
Filtersomething =f
Filterpage = Filtersomething+1
catdrive=k
\Filterpage = p
\x for fisk no
\u for catno (0= launch disk)
\PG &600 STRING MANIPULATION

\PG A00-AFF rs232 and cassette


\SOFTREC


\cat load address

\MC variables
Dr%=3
\drive to be used to read cat etc

\os calls
ORG &6E00
GUARD &7C00
\BUILD_COPYRIGHT
.start
.startexec
JMP BCD
.helptxt 
\--------------------------------
\replace for &6E07
\display starts &6E10
\after display &6E18
\end by &6E23
\NB keep below 255 chars  zero ternminated
\printed twice as the banner
\mode 7
\EQUB 22
\EQUB 7
EQUB TELETEXTDoubleheight
EQUB TELETEXTwhitetext
EQUB TELETEXTnewbackground
EQUB TELETEXTbluetext
EQUS "MMC MENU DISPLAY              V"
BUILD_VERSION 
\EQUS TIME$("%x")
EQUB &D
EQUB 0
\ advanced disk user guide pg 241 , pg 42
.drivestatus

\ A has drive no
{
.aa
LDA #2
STA diskstatus
LDA #&7F
LDX #LO(diskstatus)
LDY #HI(diskstatus)
JSR OSWORD
\read result and bit 5 "FAULT" todo check
LDA diskstatus+7
AND #&10
RTS

.diskstatus
EQUB 0:
EQUB 0:
EQUB 0:
EQUB 0:
EQUB 0:
EQUB 0:
EQUB &6C:
EQUB 0:
}

\Primitaive Sub routines

\Set cursor off sco

		.sco
		{
		LDA #23
		JSR OSASCI
		LDA #1
		JSR OSASCI
		LDX #9
		LDA #0
		.ow
		JSR OSASCI
		DEX
		BNE ow
		RTS
		}

\TerminateFilterArray tfa
		.TerminateFilterArray
		{
		LDA #0
		TAY
		STA (AFilterPointer),Y
		\LDA AFilterPointer+1
		\STA g
		LDA AFilterPointer
		STA Filtersomething
		LDA AFilterPointer+1
		STA Filtersomething+1
		\STA Filterpage
		RTS 
		}

\Copy int to zeroz cizeroz Y to zeroz
		IF __DEBUG
			.cizeroz
			{
			LDA a,Y
			STA zeroz
			LDA a+1,Y
			STA zeroz+1
			RTS
			}
		ENDIF

\clearzeroz clzeroz
		.clearzeroz
		{
		LDA #0
		STA zeroz
		STA zeroz+1
		RTS
		}

\Clearint cli offset from a in X
		IF __DEBUG
			.clearint
			.cli
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
		ENDIF

\StrAlen len of str

\Cap WORKINGStrA
\		.Cap
\		{
\		LDY StrAlen
\		.aa
\		LDA WORKINGStrA,Y
\		CMP #'a'
\		BCC ab
\		SBC #32
\		STA WORKINGStrA,Y
\		.ab
\		DEY
\		BPL aa
\		RTS
\		}

\CheckLen
\look for nulls and space at end
\.CheckLen
\{
\RTS
\LDY StrAlen
.ya
\DEY

\LDA WORKINGStrA,Y
\BEQ ya
\CMP #32
\BEQ ya
\INY
\STY StrAlen
\RTS
\}

\MovetoReczeroz mrzeroz
		.mrzeroz
		{
		LDA zeroz
		BNE pc
		LDA zeroz+1
		BEQ pd
		DEC zeroz+1
		.pc
		DEC zeroz
		JSR NextRecord
		JMP mrzeroz
		.pd
		RTS
		}

\SetLen stl StrAlen from &od
\
\		\.stl
\		.SetStrAlen
\		{
\		LDY #0
\		LDA #&0D
\		.wzeroz
\		CMP WORKINGStrA,Y
\		BEQ wy
\		INY
\		BNE wzeroz
\		.wy
\		STY StrAlen
\		RTS
\		}

\DriveSelect ds Takes drive no in A

\No in A

\.ds

\{

		.DriveSelect
		{
		CLC 
		ADC #'0'
		STA drstr+3
		LDX #LO(drstr)
		LDY #HI(drstr)
		JMP OSCLI \ RTS
		.drstr
		EQUS"DR. "
		EQUB &D
		}

		.initcatdat
		{
		LDA #'0'-1
		STA catdat+6
		RTS\ one less than "0"
		}

\CheckCatfileExists cce

		.CheckCatfileExists
		{
		IF __DEBUG AND __CATDATTEST
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
			EQUS "Checkfileexits Drive"
			EQUB &D
			.ab
			LDA catdrive 
			CLC
			ADC #'0'
			JSR OSASCI
			LDX #&FF
			.ac
			INX
			LDA catdat,X
			JSR OSASCI
			CMP #&D
			BNE ac
			JSR gti	
			}
		ENDIF
		LDA catdrive
		JSR DriveSelect
		LDA #LO(catdat)
		STA block
		LDA #HI(catdat)
		STA block+1
		LDA #5
		LDX #LO(block)
		LDY #HI(block)
		JMP OSFILE
		}

		.LoadPreviouscatdat
		{
		LDA #'0'
		CMP catdat+6
		BEQ atfirstcatdat
		DEC catdat+6
		.atfirstcatdat
		JSR CheckCatfileExists
		CMP #1
		BNE backadrive
		JSR LoadCatfile
		\load catfile
		LDA #1
		RTS
		.backadrive
		\JSR CheckCatfileExists
		\CMP #1
		\BNE ab
		DEC catdrive
		JSR LoadCatfile
		\load catfile
		LDA #1
		.ab
		RTS
		}

		.loadnextcatdat
		{
		INC catdat+6
		JSR CheckCatfileExists
		CMP #1
		BNE aa
		\load catfile
		JSR LoadCatfile
		LDA #1
		RTS
		.aa
		INC catdrive 
		JSR drivestatus
		BNE ab
		JSR CheckCatfileExists
		CMP #1
		BNE ab 
		\load catfile
		JSR LoadCatfile
		LDA #1
		RTS
		.ab 
		DEC catdrive
		DEC catdat+6
		LDA #0
		RTS
		}\rts

\LoadCatfile lcf
		\.lcf
		.LoadCatfile
		{
		JSR InitFilecatdatAPtr
		LDA #4
		STA comprec
		LDA #LO(catdat)
		STA block
		LDA #HI(catdat)
		STA block+1
		JMP Loadfile \rts
		}

\Loadpublisher lpub
		.Loadpublisher
		{
		LDA#0
		JSR DriveSelect
		JSR InitFileSoftrecArrayPtr
		LDA #0
		STA comprec
		LDA #LO(pubrec)
		STA block 
		LDA #HI(pubrec)
		STA block+1
		JMP Loadfile \rts
		} 

\Loaddin ldin
		\.ldin
		.Loaddin
		{
		LDA #0
		JSR DriveSelect
		JSR InitFilecatdatAPtr
		LDA #0
		STA comprec
		LDA #LO(dinrec)
		STA block
		LDA #HI(dinrec)
		STA block+1
		JMP Loadfile \rts
		}

\Loadfile lf†Needs Aptr set
		.Loadfile
		{
		LDA APtr
		STA block+2
		LDA APtr+1
		STA block+3
		LDA #0
		STA block+6
		LDA #&FF
		LDX #LO(block)
		LDY #HI(block)
		JMP OSFILE \rts
		}

\SortStr
\		.SortStr
\		{
\		\JSR SetStrAlen
\		\JSR Cap
\		\JMP CheckLen
\		\JMP Cap
\		}\rts

\CopyRecordfromAptrtoFilterA crd

		\.crd
		.CopyRecordfromAptrtoFilterA
		{
		JSR GetEndDescription
		TYA
		CLC
		ADC comprec
		TAY
		TAX
		DEY
		.dm
		LDA (APtr),Y
		STA (AFilterPointer),Y
		DEY
		BPL dm
		TXA
		CLC
		ADC AFilterPointer
		STA AFilterPointer
		LDA #0
		ADC AFilterPointer+1
		STA AFilterPointer+1
		LDA #'.'
		JMP OSASCI
		}\rts

\Get end description ged ret Y

\GetEndDescription
		\.ged ret Y
		.GetEndDescription
		{
		\LDY #0
		\.ga
		\LDA (APtr),Y
		\INY
		\CMP #&80
		\BCC ga
		\RTS
		LDY #&FF
		.aa
		INY
		LDA (APtr),Y
		BPL aa
		INY
		RTS
		}

\Getsearchselection gss
		\.gss
		.Getsearchselection
		{
		\Set Aptr to loaded file?
		JSR CopyPreviousRecordSettoAptr
		\Initiate filter pointer
		JSR InitFilterResults
		\Get search term - have already rpinted prompt!
		JSR EnterSearchText
		\do search
		JSR SearchDescriptionTxt
		\terminate results
		JSR TerminateFilterArray
		\see if we have any results
		LDA FILTERResultsStartAddress
		BEQ ij
		\now need to select from filter results
		\set Aptr to D TODO should be Filter results?
		JSR InitdisplayFilterResults
		\
		JSR generalselection
		JSR getinput
		CPY #&D
		BEQ aa
		RTS
		.aa
		\have filter result can work with 
		JSR PostGeneralSelection
		\now have the filter results set result!
		\zeroZ has record count for displayfilter
		\Apr and Sno set to zero
		JSR InitdisplayFilterResults
		\move to selected record
		JSR mrzeroz
		\copy record to StrA
		JSR copyAptrTostrA
		\Set Aptr to Loaded file
		JSR CopyPreviousRecordSettoAptr
		\Find record in loaded file
		JSR Search
		JSR CopySearchNumbertoZeroZ
		.ij
		RTS
		}

\SearchDescriptionTxt sdt
		\.sdt
		.SearchDescriptionTxt
		{
		\SortStr not needed as StrAlen is Set
		\and cap only allowed to be input
		\JSR SortStr
		.va
		JSR Search
		BNE vd
		RTS
		.vd
		JSR CopyRecordfromAptrtoFilterA
		JSR NextRecord
		CLC
		BCC va
		}
\Zero no match
		.SearchSingleRecord
		{
		LDX WORKINGStrA
		STX tempx
		LDY #0
		.qj
		LDA (APtr),Y
		BMI exit
		AND #&DF \lowercase
		BNE vb
		.exit
		LDA #0
		.havematch
		RTS
		.vb
		CMP tempx
		BEQ try
		
		\CMP #&80
		\BCS exit
		\BMI exit
		INY
		BNE qj
		.try
		LDX #0
		STY tempy
		.trynext
		INX
		CPX StrAlen
		BNE vc
		TXA
		RTS
		.vc
		INY
		LDA (APtr),Y
		AND #&DF \lowercase
		CMP WORKINGStrA,X
		BEQ trynext
		AND #&7F
		CMP WORKINGStrA,X
		BEQ trynext
		LDY tempy
		INY
		BVC qj
		}
		.Search
		{
		LDX WORKINGStrA
		STX tempx
		LDY #0
		.qj
		LDA (APtr),Y
		BNE vb
		RTS
		.vb
		CMP tempx
		BEQ try
		\CMP #&80
		\BCS endrec
		BMI endrec
		INY
		BNE qj
		.try
		LDX #0
		STY tempy
		.trynext
		INX
		CPX StrAlen
		BNE vc
		TXA
		RTS
		.vc
		INY
		LDA (APtr),Y
		CMP WORKINGStrA,X
		BEQ trynext
		\SEC
		\SBC #&80
		AND #&7F
		CMP WORKINGStrA,X
		BEQ trynext
		LDY tempy
		INY
		BNE qj
		.endrec
		JSR NextRecord
		LDY #0
		BEQ qj
		}

\NextRecord nxr
		\.nxr
		.NextRecord
		{
		LDY #&FF
		.qe
		INY
		LDA (APtr),Y
		BEQ IncSearchNo
		\CMP #&80
		\BCC qe
		BPL qe
		INY
		TYA
		CLC
		ADC APtr
		STA APtr
		LDA #0
		ADC APtr+1
		STA APtr+1
		CLC
		LDA comprec
		ADC APtr
		STA APtr
		LDA #0
		ADC APtr+1
		STA APtr+1
		}

\incSearchNo IncSearchNo
		.IncSearchNo
		{
		INC sno
		BNE pb
		INC sno+1
		.pb
		RTS \RTS for IncSearchNo and nxr
		}

\get total record count trc

.trc

		.totalreccount
		{
		JSR NextRecord
		LDY #0
		LDA (APtr),Y
		BNE totalreccount
		RTS
		}

\"„CopySearchNumbertoZeroZ ssn
		.ssn
		.CopySearchNumbertoZeroZ
		{
		LDA sno+1
		STA zeroz+1
		LDA sno
		STA zeroz
		RTS
		}

\DisplayEnterText det
		\.det
		.DisplayEnterText
		{
		LDY #BOTTOMWindow
		JSR Selectwindow
		LDA #TELETEXTyellowtext
		JSR OSASCI
		JSR PrintStringX
		LDA #LETTERColour
		JMP OSASCI \RTS
		}

\CLC: ROL v: ROL v: LDA e: ORA #4:STA e:RTS\dead code ?

\Displayfilterscreen DFS dfs

.DFS
JSR HardInitmenu
		.dfs
		{
		LDX #0
		STX comprec
		STX comprecstore
		\JSR InitFilterPtr
		.InitFilterPtr
		{
		LDA #HI(filttxt%)
		STA APtr+1
		LDA #LO(filttxt%)
		STA APtr
		JSR initreccount
		}
		JSR Initmenuscreen
		LDY #0
		STY tempy
		.ma
		JSR DisplayStartLine
		JSR DisplayPrintEntry
		JSR printselection
		JSR NextRecord
		LDY #0
		LDA (APtr),Y
		BNE ma
		JSR cursorset
		}

		.tabscreeninput
		{
		JSR getinput
		CPY #9
		BEQ tabscreeninput
		CPY #&D 
		BEQ xu
		RTS
		}
		.xu

\selection section

		LDA CurrentCursorLetter
		CMP #'A'
		BNE aaa
		\Browse din code
		\X% = disk selection
		{
		JSR Loaddin
		JSR Generalselectcommon
		IF __DEBUG
			LDX #('X'-'A')*4
			JSR CopySnintoXinteger
		ENDIF
		JSR SetDiskFilterMask
		LDX #0
		JSR Writetofilterscreen
		\LDA #FILTERdisk
		\JSR Setfilter
		\JSR wdn
		JMP dfs
		}
.aaa
CMP #'B'
BNE bbb
		\favorate
		.ToggleFavorate
		{
		LDX #0
		IF __DEBUG
			LDA w
			EOR #&08
			STA w
		ENDIF
		\need to toggle bit 4 on mask and bit
		
		LDA FilterbitsSoftwarehigh3Fav1GameType3
		EOR #8
		STA FilterbitsSoftwarehigh3Fav1GameType3
		LDA FilterMaskSoftwarehigh3Fav1GameType3
		EOR #&8
		STA FilterMaskSoftwarehigh3Fav1GameType3
		AND #&8
		BNE jy
		LDX #0
		.jx
		INX 
		LDA fav,X
		CMP #&80
		BCC jx
		\BPL jx
		INX
		.jy
		LDA #FILTERfav%
		EOR FilterFlag
		STA FilterFlag
		LDY #0
		.jw
		LDA fav,X
		STA WORKINGStrA,Y
		INY
		INX
		CMP #&80
		BCC jw
		DEY
		STY StrAlen
		JSR expandStrAtoFiltercharlength
		JSR InitFilterstring
		JSR clearzeroz
		LDA #1
		STA zeroz
		JSR mrzeroz
		JSR copystrToArray
		JSR Initmenu
		JMP dfs
		}
		\Din by no
		\JSR gnzeroz
		\LDY #&5C
		\LDY #('X'-'A')*4
		\JSR cizeroz
		\JSR Loaddin
		\JSR mrzeroz
		\LDA #0
		\STA c
		\JSR Writetofilterscreen
		\JSR wdn
		\JMP dfs
.bbb
CMP #'C'
BNE ccc
		\publisher
		\Y% = publisher
		{
		JSR Loadpublisher
		JSR Generalselectcommon
		IF __DEBUG
			LDX #('Y'-'A')*4
			JSR CopySnintoXinteger
		ENDIF
		JSR SetSoftwareFilterMask
		LDX #2
		JSR Writetofilterscreen
		LDA #FILTERpublish%
		JSR Setfilter
		JMP dfs
		}
.ccc
CMP #'D'
BNE ddd
		\progtype
		{
		.stt
		LDA #FILTERgametype%
		JSR Setfilter
		JSR Initmenu
		\JSR InitprogTypeText
		.InitprogTypeText
		{
		LDA #HI(prtt)
		STA APtr+1 
		LDA #LO(prtt)
		STA APtr
		JSR CopyAptrtoPreviousRecordset
		JSR initreccount
		}
		JSR Initmenuscreen
		.mo
		JSR DisplayStartLine
		JSR DisplayPrintEntry
		\LDA #&D
		\JSR OSASCI
		JSR OSNEWL
		JSR NextRecord
		LDY #0
		LDA (APtr),Y
		BNE mo
		JSR cursorset
		JSR getinput
		CPY #&D
		BEQ xx
		RTS
		.xx
		JSR CopyPreviousRecordSettoAptr
		LDA CurrentCursorLetter
		SEC
		SBC #'A'
		STA zeroz
		STA tempx
		CLC 
		ROL A
		ROL A
		ROL A
		ROL A
		\ROL A
		IF __DEBUG
			STA v
		ENDIF
		ORA FilterMaskSoftwarehigh3Fav1GameType3
		STA FilterMaskSoftwarehigh3Fav1GameType3
		LDA #&70
		ORA FilterbitsSoftwarehigh3Fav1GameType3
		STA FilterbitsSoftwarehigh3Fav1GameType3
		JSR mrzeroz
		LDX #3
		JSR Writetofilterscreen
		\JSR lwtf
		JMP dfs
		}
.ddd
CMP #'E'
BNE eee
		\Search desc TODO 
		.ox
		{
		JSR getsearchtxt
		JMP dfs
		}		
.eee
CMP #'F'
BNE fff
		\Search pub
		\Y% = publisher
		{
		LDX #searchpublisher
		STX tempx
		JSR DisplayEnterText
		JSR Loadpublisher
		JSR Getsearchselection
		\CopySearchNumbertoZeroZ
		IF __DEBUG
			LDX #('Y'-'A')*4
			JSR CopySnintoXinteger
		ENDIF
		JSR SetSoftwareFilterMask
		LDA FILTERResultsStartAddress \do we have any results?
		BNE iy
		JSR nosearchresults
		JMP dfs
		.iy
		\JSR czerozi
		LDX #2
		JSR lwtf
		\JSR Writetofilterscreen
		LDA #FILTERpublish%
		JSR Setfilter
		JMP dfs
		}
.fff
CMP #'G'
BNE ggg
		\Search din
		{	
		LDX #searchdisktitle
		STX tempx
		JSR DisplayEnterText
		JSR Loaddin
		JSR Getsearchselection
		LDA FILTERResultsStartAddress
		BNE oy
		JSR nosearchresults
		JMP dfs \rts
		.oy
		IF __DEBUG
			LDX #('X'-'A')*4
			JSR CopySnintoXinteger
		ENDIF
		JSR SetDiskFilterMask
		LDX #0
		JSR lwtf \TODO was wtf
		\JSR wdn
		LDA #FILTERdisk%
		JSR Setfilter
		JMP dfs
		}
		
.ggg
CMP #'H'

BNE hhh
		\Applyfilterresults
		{
		JMP applyfilters
		}		
.hhh
CMP #'I'
BNE iii
		{	
		JMP DFS
		\Clear filters 
		}
.iii
CMP #'J'
BNE jjj
		\"„Sound off
		.snd
		{
		LDA #210
		LDX #1
		JSR OSBYTE
		}
.jjj
CMP #'K'
BNE kkk
		.tv
		\TV255
		{
		LDX #&FF
		LDY #0
		LDA #&90
		JSR OSBYTE
		JMP dfs
		}
.kkk
CMP #'L'
BNE lll
		\launch disk  TODO
		{
		LDA FilterFlag
		AND #FILTERdisk%
		BEQ enddisplayinput
		\x holds dinno
		\LDX #&50
		\LDX #('U'-'A')*4
		\JSR clearint
		LDA #0
		STA u
		JMP launchu
		}
.lll
CMP #'M'
BNE mmm
		{
		BEQ hlp
		}
.mmm
CMP #'N'
BNE nnn 
		{
		BEQ hlp
		}
.nnn
\CMP #'O'
\BNE ooo
		
\.ooo
CMP #'?'
BNE quest
		{
		LDA #'N'
		BEQ hlp
		}
.quest
CMP #9 \tab
BNE enddisplayinput
JMP BCD
.enddisplayinput
RTS \no action

\Launch help
		.hlp
		
		STA hlpcmd
		.straighthelp
		LDX #LO(hlpcmd)
		LDY #HI(hlpcmd)
		JMP OSCLI \RTS
		.hlpcmd
		EQUS"N"
		EQUB &D
		
\nosearchresults
		.nosearchresults
		{
		LDX #0
		STX comprec
		STX comprecstore
		LDA #LO(err)
		STA APtr
		LDA #HI(err)
		STA APtr+1
		JSR generalselection
		JMP getinput
		}\rts

\apply filters afs

.applyfilters
\are any filters set?
LDA FilterFlag
BNE xh
\no filters set
JMP BCD
.xh
\we have some filters
LDY #BOTTOMWindow
JSR Selectwindow
JSR initcatdat
JSR InitFilterResults
JSR TerminateFilterArray
\terminate filter array
\main loop
		.Nextcat		
		JSR loadnextcatdat
		CMP #1
		BEQ wehavefile
		\check catdatx exists
		\show filter results
		.pg
		JSR printKeyBtmText
		LDY #MAINWindow
		JSR Selectwindow
		LDA FILTERResultsStartAddress
		\do we have any records?
		BNE DisplayfilterResults
		JSR nosearchresults
		JMP dfs
		.DisplayfilterResults
		JSR TerminateFilterArray
		JSR InitFilterResults
		JSR InitdisplayFilterResults
		\JSR InitdisplayFilterResults
		JSR CopyAptrtoPreviousRecordset
		\LDA APtr+1
		\STA PreviousRecordset+1
		\LDA APtr
		\STA PreviousRecordset
		JMP browseresults
		\JSR gns
		\JSR getinput
		\JSR PostGeneralSelection
		\JMP lcr		
		.wehavefile
		{
		\print green . in btm window and reset to white
		LDA #TELETEXTgreentext
		\JSR OSASCI
		JSR OSWRCH
		LDA #'.'
		\JSR OSASCI
		JSR OSWRCH
		LDA #TELETEXTwhitetext
		\JSR OSASCI
		JSR OSWRCH
		LDA Filtersomething
		STA AFilterPointer
		LDA Filtersomething+1
		STA AFilterPointer+1
		}
\-------------------
\Newcode!
\do we have filter using bits
	
		.initfilter
		{
		IF __DEBUG
			{
			LDX #4
			.aa
			LDA Filterbits,X
			STA a,X
			LDA FilterMask,X
			STA b,X
			DEX
			BPL aa
			LDA FilterFlag
			STA c
			}
		ENDIF
		\descripton search setup
		LDA FilterFlag
		AND #FILTERdescription%
		BEQ ac
		LDX #&FF
		.aa
		INX
		LDA SEARCHtext,X
		STA WORKINGStrA,X
		CMP #&D
		BEQ ac
		BNE aa
		.ac
		STX StrAlen
		}
		.StartForEachRecord
		{
		LDA FilterFlag 
		AND #&F
		\only descripton search?
		BEQ MatchedFilters
		.Startmaskchecks
		LDY #0
		LDA (APtr),Y
		BNE ab
		\end recordset
		\Check for overflow
		\BEQ Nextcat out of range
		\Check for OVERFLOW
			.Checkforoverflow
			{
			LDA Filterpage
			CMP #HI(CATLoadStartAddress)
			BCS pe
			\BCC Nextcat \out of range
			JMP Nextcat
			.pe
			JSR totalreccount
			LDY #overflowend-overflow
			.pf
			LDA overflow,Y
			STA(APtr),Y
			DEY
			BPL pf
			JMP DisplayfilterResults
			}
		\JMP Nextcat
		.ab
		JSR GetEndDescription
		\Y now points to first of the 4 bytes to filter on
		DEY
		LDX #&FF
		.Filterloop
		INY
		INX
		CPX #4 \3+1
		BEQ MatchedFilters
		LDA Filterbits,X
		\Can move to the next if no mask set
		BEQ Filterloop
		AND (APtr),Y
		EOR FilterMask,X
		\IF zero have a match
		BEQ Filterloop
		BNE nomatch
		.MatchedFilters
		LDA FilterFlag 
		AND #FILTERdescription%
		\no description set?
		BEQ copyrec
		\JSR SortStr
		JSR SearchSingleRecord
		BEQ nomatch
		.copyrec
		JSR CopyRecordfromAptrtoFilterA
		LDA #'.'
		JSR OSASCI
		.nomatch
		\LDA #'.'
		\JSR OSASCI
		JSR NextRecord
		LDY #0
		LDA (APtr),Y
		BNE StartForEachRecord
		BEQ Checkforoverflow
		}
	
\--------------------
.dh
RTS

\getsearchtxt (description) getsearchtxt
		.getsearchtxt
		{
		LDX #searchdescription%
		STX tempx
		JSR DisplayEnterText
		JSR EnterSearchText
		CPY #2
		BCC getsearchtxt \2 or more chars
		.ak
		LDA WORKINGStrA,Y
		STA SEARCHtext,Y
		DEY
		BPL ak
		\LDA #4
		\STA c
		LDA #FILTERdescription%
		JSR Setfilter
		\LDA e
		\ORA #&10
		\STA e
		LDY StrAlen
		LDA #' '
		STA WORKINGStrA,Y
		LDX #4
		JMP lwtf
		}\rts

\Browse catdat BCD
		
		.BCD
		JSR HardInitmenu		
		.bcd
		{
\set exten record 
		INC comprecstore
		JSR initcatdat
\print top window stuff
		.printHelpTopText
		{
		LDY #TOPWindow
		JSR Selectwindow
		LDX #1
		.aa \start of double height print
		LDY #&FF
		.bj
		INY
		LDA helptxt,Y
		BEQ bk
		JSR OSASCI
		BNE bj
		.bk
		DEX
		BPL aa
		LDY #&FF
		.cj
		INY
		LDA helptxt1,Y
		BEQ ac
		JSR OSASCI
		BNE cj
		.ac
		}
		JSR sco
		\print btm window stuff
		JSR printKeyBtmText
		\select main window
		LDY #MAINWindow
		JSR Selectwindow
		JSR loadnextcatdat
		CMP #1
		BNE dh
		\LDA #0
		\STA resultvar
		\display filter results re-entry
		}
		.browseresults
		{
		JSR generalselection
		JSR getinput
		CPY #9 \tab
		BNE ka
		JSR dfs
		.ka
		CPY #' '
		BNE kb
		JMP spa
		.kb
		CPY #'?'
		BNE kc
		JMP straighthelp
		.kc
		\JMP que
		CPY #&D \return key
		BEQ lcr
		\should not be here?
		RTS
		}

\.XXoe
\JSR dfs
\JMP 
\Launch current record lcr
\X filename disctitle drive
\put X% dinno u%=catno
\Need to convert catno-filename
\need to convert dinno to disctitle



		.lcr
		{
		JSR PostGeneralSelection
		JSR CopyPreviousRecordSettoAptr
		JSR mrzeroz
		}
		JSR GetEndDescription
		INY
		LDA (APtr),Y
		STA zeroz
		\STA x
		INY
		LDA (APtr),Y
		AND #7
		\STA x+1
		STA zeroz+1
		\U% cat number
		LDA (APtr),Y
		ROR A
		ROR A \added
		ROR A
		AND #&1F
		STA u

\---------------------------------
		.launchu
		{
		LDA #0
		JSR DriveSelect
		\ set drive to 0
		\LDY #&5C
		\LDY #('X'-'A')*4
		\JSR cizeroz
		\LDA FilterMaskDiskLow
		\STA zeroz
		\LDA FilterMaskDiskHigh3Catno5
		\AND #7
		\STA zeroz+1
		JSR Loaddin
		JSR mrzeroz
		JSR copyAptrTostrA
		LDA WORKINGStrA,Y
		AND #&7F
		STA WORKINGStrA,Y
		INY
		LDA #&D
		STA WORKINGStrA,Y
		LDA #' '
		STA WORKINGStrA-1
		LDA #'1'
		STA WORKINGStrA-2
		LDA #' '
		STA WORKINGStrA-3
		LDA #'U'
		STA WORKINGStrA-4
		LDX #LO(WORKINGStrA-4)
		LDY #HI(WORKINGStrA-4)
		JMP OSCLI \RTS
		}

\---------------------------------

\PrintStringX psx 
		\.psx
		.PrintStringX
		{
		LDX tempx
		LDY #&FF
		.ju
		\CPX #0
		DEX 
		BNE nxtrec
		\on correct record 
		.jv
		INY
		LDA ptxt,Y 
		\CMP #&80
		\BCS aa
		BMI aa
		JSR OSASCI
		BPL jv
		.aa
		AND #&7F
		JMP OSASCI \RTS
		.nxtrec
		INY
		LDA ptxt,Y
		\CMP #&80
		\BCC nxtrec
		BPL nxtrec
		BMI ju
		\BCS ju
		}
\Writetofilterscreen wtf
		\.wtf
		.Writetofilterscreen
		JSR copyAptrTostrA
\copy aptr to string
		.lwtf
		{
		JSR clearzeroz
		STX zeroz
		\LDA c
		\STA zeroz
		JSR expandStrAtoFiltercharlength
		JSR InitFilterstring
		JSR mrzeroz
		JSR copystrToArray
		JMP Initmenu \rts
		}
\.ret
\RTS
\.que
\JMP straighthelp
		.spa
		{
		JSR HardInitmenu
		JSR getsearchtxt
		JMP applyfilters \RTS
		} 
\ret on char selected or control keys (tab space ? )
\-------------------------------------------------------------
		
		\getinput waits for a character to be pressed
\get input		
		.getinput
		.mks
		{
		.aa
		LDA #&91
		LDX#0
		JSR OSBYTE
		BCS aa
		}

		
\now have key value in y
		\ ?
		{
		CPY #'?'
		BEQ aa
		\space
		CPY #' '
		BEQ aa
		\tab
		CPY #9 \tab
		BEQ aa
		\ret
		CPY #&D \return key
		BEQ aa
		
		CPY #&8F
		BEQ up
		CPY #&8E
		BEQ down
		CPY #&8E
		BEQ down
		CPY #&8C
		BEQ left
		CPY #&8D
		BEQ right
		CPY #'A'
		BCC mks
		CPY lastline
		BCS getinput
		\Move cursor to letter (we know its btn A and lastline!
		TYA \letter
		TAX	\letter
		\remove red bar
		JSR cursorclear
		\Set cursor to start of screen
		JSR Initmenu
		\Current letter
		LDA #'A'
		STA CurrentCursorLetter
		CPX CurrentCursorLetter
		BEQ mn
		.mm
		JSR cursordown
		CPX CurrentCursorLetter
		BNE mm
		.mn
		JSR cursorset
		.ab
		JMP getinput
		.aa
		RTS 
		}


\Makeselection mks ret A

\OR cursor
		.down
		{
		LDX lastline
		DEX
		CPX CurrentCursorLetter
		BEQ mks
		JSR cursordown
		JMP mks
		}
		.up
		{
		LDA CurrentCursorLetter
		CMP #'A'
		BEQ mks
		JSR cursorup
		JMP mks
		}
		.right
		{
		LDY #0
		LDA (APtr),Y
		BEQ endofcatfile
		JSR generalselection
		JMP mks
		}
		.left
		{
		LDA lastline
		SEC
		SBC #'A'\65
		\asc("A")
		STA a
		LDA sno
		SEC
		SBC a
		STA a
		LDA sno+1
		SBC #0
		STA a+1
		LDX #0

		.chizeroz
		LDA a,X
		CLC
		ADC a+1,X
		\ADC a+2,X
		\ADC a+3,X
		BEQ startrecfile
		LDA a
		SEC
		SBC #MAXmenuitems 
		STA zeroz
		LDA a+1
		SBC #0
		STA zeroz+1
		JSR CopyPreviousRecordSettoAptr
		JSR mrzeroz
		JSR generalselection
		}
		.bf
		JMP mks
		


\are at start of record file
.startrecfile
LDA comprecstore
BEQ bf
\e+1 = flag for BCD mode
\does previous file exist?
JSR LoadPreviouscatdat
\CMP #1
\BNE bg

\load catfile
\JSR LoadCatfile
JSR totalreccount
LDA sno
SEC
SBC #MAXmenuitems
STA zeroz
LDA sno+1
SBC #0
STA zeroz+1
JSR CopyPreviousRecordSettoAptr
JSR mrzeroz
JSR generalselection
JMP mks
\RTS

\previous file does not exist

\.bg
\INC catdat+6
\.bf
\JMP mks
.endofcatfile
		{
		LDA comprecstore
		BNE bc
		JMP mks
		.bc
		JSR loadnextcatdat
		CMP #1
		BNE bd
		JMP Generalselectcommon
		.bd
		JMP mks
		}

\cursor routines
		.cursorclear
		{
		LDY #0
		LDA #CURSORCancelSelect
		STA (CurrentCursorAddress),Y
		RTS
		}

		.cursordown
		{
		INC CurrentCursorLetter
		JSR cursorclear
		CLC
		LDA #&28 \40 chars
		ADC CurrentCursorAddress
		STA CurrentCursorAddress
		LDA #0
		ADC CurrentCursorAddress+1
		STA CurrentCursorAddress+1
		JMP cursorset \rts
		}

		.cursorup
		{
		DEC CurrentCursorLetter
		JSR cursorclear
		SEC
		LDA CurrentCursorAddress
		SBC #&28 \40 chars
		STA CurrentCursorAddress
		LDA CurrentCursorAddress+1
		SBC #0
		STA CurrentCursorAddress+1
		JMP cursorset \rts
		}


\cursorset
		.cursorset
		{
		LDY #0
		LDA #CURSORCancelSelect+1
		STA (CurrentCursorAddress),Y
		RTS
		}

\DisplayStartLine sl
		.DisplayStartLine
		{ 
		LDA #CURSORSelectColour
		JSR OSASCI
		LDA #CURSORCancelSelect
		JSR OSASCI
		LDA comprec
		BEQ aa
		JSR isfav
		BEQ aa
		LDA #TELETEXTwhitetext
		BNE ab
		.aa
		LDA #LETTERColour
		.ab
		JSR OSASCI
		LDA lastline
		JSR OSASCI
		INC lastline
		LDA #TELETEXTyellowtext
		JMP OSASCI \rts
		}

\printKeyBtmText tt btm window
		.printKeyBtmText
		{
		LDY #BOTTOMWindow
		JSR Selectwindow
		LDY #&FF
		.ol
		INY
		LDA keytxt,Y
		BEQ om
		JSR OSASCI
		BNE ol
		.om
		RTS
		}

\printHelpTopText window text
		\.pht
 \printselection
		.printselection
		{
		LDY tempy
		.mf
		LDA FILTERDisplaySettings,Y
		\CMP #&80
		\BCS mg
		BMI mg
		JSR OSASCI
		INY
		BNE mf
		.mg
		AND #&7F
		JSR OSASCI
		\LDA #&D
		\JSR OSASCI
		JSR OSNEWL
		INY
		STY tempy
		RTS
		}

\DisplayPrintEntry pre
		.DisplayPrintEntry
		{
		LDY #&FF
		.mb
		INY
		LDA (APtr),Y
		BMI bi
		CMP #'#'
		BNE aa
		.ad
		LDA #TELETEXTmagentatext
		\BNE mc
		.aa
		\CMP #&80
		\BCS bi
		
		\CPY #0
		\BEQ mc
		\JSR cvc
		.mc
		\JSR OSASCI
		JSR OSWRCH
		BNE mb
		.bi
		AND #&7F
		\JSR cvc
		.ab
		\JSR OSASCI
		JSR OSWRCH
		LDA comprec
		BNE ExtendedPrintentry
		\light blue
		LDA #TELETEXTcyantext
		JSR OSASCI
		.md
		CPY #FILTERTxtLen%
		BCS me
		LDA #' '
		\JSR OSASCI
		JSR OSWRCH
		INY
		BNE md
		.me
		RTS
		}

\ExtendedPrintentry
		.ExtendedPrintentry
		{
		\white
		LDA #TELETEXTwhitetext
		\JSR OSASCI
		JSR OSWRCH
		JSR GetEndDescription
		TYA
		CLC
		ADC #5
		STA CurrentlineLengh
		LDA (APtr),Y
		STA zeroz
		INY
		INY
		INY
		LDA (APtr),Y
		AND #3
		STA zeroz+1
		LDA (APtr),Y
		ROR A
		ROR A
		ROR A
		ROR A
		AND #&F
		TAY
		LDA type,Y
		\JSR OSASCI
		JSR OSWRCH
		LDA #TELETEXTcyantext
		\JSR OSASCI
		JSR OSWRCH
		\have pub in zeroz
		LDA #HI(INDEXfileloadAddress)
		STA Apub+1
		LDA #LO(INDEXfileloadAddress)
		STA Apub
		.on
		LDA zeroz+1
		BEQ op
		DEC zeroz+1
		LDX #0
		.oq
		LDY #0
		.ou
		LDA (Apub),Y
		\CMP #&80
		\BCS or
		BMI or
		INY
		BNE ou
		.or
		INY
		CLC
		TYA
		ADC Apub
		STA Apub
		LDA #0
		ADC Apub+1
		STA Apub+1
		DEX
		BNE oq
		BEQ on
		.op
		INC CurrentlineLengh
		LDX zeroz
		BEQ ov
		LDA #0
		STA zeroz
		BEQ oq
		.ov
		LDY #0
		.ot
		LDA (Apub),Y
		\CMP #&80
		\BCS os
		BMI os
		\JSR OSASCI
		JSR OSWRCH
		INC CurrentlineLengh
		LDA CurrentlineLengh
		CMP #PRINTLineLength
		BCS na
		INY
		BNE ot
		.os
		AND #&7F
		\
		JSR OSWRCH
		\JSR OSASCI
		.na
		RTS
		.type
		EQUS"ACGSMPUZ"
		}



\Selectwindow slw TAKES Y TOPWindow,btmw%,mainW%
		.Selectwindow
		{
		LDX #5
		LDA #28
		.mj
		JSR OSASCI
		LDA window,Y
		INY
		DEX
		BNE mj
		LDA #12
		JMP OSASCI \rts
		}

\copyAptrTostrA
		.copyAptrTostrA
		{
		LDY #&FF
		.mq
		INY
		LDA (APtr),Y
		STA WORKINGStrA,Y
		\CMP #&80
		\BCC mq
		BPL mq
		STY StrAlen
		RTS
		}
\CopyFromStrAtoStrB

\	\.cab
\	.CopyFromStrAtoStrB
\	{
\	LDY #&FF
\	.mq
\	INY
\	LDA WORKINGStrA,Y
\	STA WORKINGStrB,X
\	INX
\	CMP #&80
\	BCC mq
\	RTS
\	}

\copy from WORKINGStrB to WORKINGStrA 
\	.cba
\	{
\	LDX #0
\	.mq
\	LDA WORKINGStrB,X
\	STA WORKINGStrA,X
\	INX
\	CMP #&80
\	BCC mq
\	RTS
\	}

\expandStrAtoFiltercharlength
		.expandStrAtoFiltercharlength
		{
		LDY StrAlen
		CPY #FILTERCharlength
		BCS mh
		LDA WORKINGStrA,Y
		AND #&7F
		STA WORKINGStrA,Y
		LDA #' '
		.mw
		INY
		STA WORKINGStrA,Y
		CPY #FILTERCharlength
		BNE mw
		BEQ mr
		.mh
		LDY #FILTERCharlength
		LDA WORKINGStrA,Y
		.mr
		ORA #&80
		STA WORKINGStrA,Y
		STY StrAlen
		RTS
		}

\Generalselectcommon
		.Generalselectcommon
		{
		JSR generalselection
		JSR getinput
		CPY #&D
		BEQ aa
		RTS
		.aa
		JSR PostGeneralSelection
		JSR CopyPreviousRecordSettoAptr
		JMP mrzeroz \rts
		} 

\general selection gns
		.generalselection 
		{
		\select main window
		JSR Initmenuscreen
		LDY #0
		LDA (APtr),Y
		BEQ mzeroz
		\Cursor pointer
		JSR Initmenu
		JMP fc
		.my
		\LDA #&D
		\JSR OSASCI
		JSR OSNEWL
		.fc
		JSR DisplayStartLine
		JSR DisplayPrintEntry
		JSR NextRecord
		LDY #0
		LDA (APtr),Y
		BEQ mzeroz
		LDA lastline 
		CMP #MAXmenuletter
		BNE my
		.mzeroz
		JMP cursorset \RTS
		}
	
\PostGeneralSelection	
		.PostGeneralSelection
		\get count back TODO streamline
		{
		LDA lastline
		SEC
		SBC CurrentCursorLetter
		\apply count back
		STA tempx
		LDA sno
		SEC
		SBC tempx
		STA sno
		LDA sno+1
		SBC #0
		STA sno+1
		\select search no into Z
		JSR CopySearchNumbertoZeroZ
		LDA #&D
		RTS
		}

\CopystrToArray
		.copystrToArray
		{
		LDY #&FF
		.mx
		INY
		LDA WORKINGStrA,Y
		STA (APtr),Y
		\CMP #&80
		\BCC mx
		BPL mx
		RTS
		}
		
\CopySnintoXinteger
		IF __DEBUG
			.CopySnintoXinteger
			{
			LDA sno+1
			\LDX #('Y'-'A')*4
			STA a+1,X
			LDA sno
			STA a,X
			RTS
			}
		ENDIF
\SetSoftwareFilterMask		
		.SetSoftwareFilterMask
		{
		LDA sno
		STA FilterMaskSoftwarelow
		LDA FilterMaskSoftwarehigh3Fav1GameType3
		ORA sno+1
		STA FilterMaskSoftwarehigh3Fav1GameType3
		LDA #&FF
		STA FilterbitsSoftwarelow
		LDA #&3
		ORA FilterbitsSoftwarehigh3Fav1GameType3
		STA FilterbitsSoftwarehigh3Fav1GameType3
		LDA #FILTERpublish%
		JMP Setfilter \RTS
		}
		
\SetDiskFilterMask		
		.SetDiskFilterMask
		{
		LDA sno
		STA FilterMaskDiskLow
		LDA FilterMaskDiskHigh3Catno5
		ORA sno+1
		STA FilterMaskDiskHigh3Catno5
		LDA #&FF
		STA FilterbitsDiskLow
		LDA #&3
		ORA FilterbitsDiskHigh3Catno5
		STA FilterbitsDiskHigh3Catno5
		LDA #FILTERdisk%
		JMP Setfilter \RTS		
		}
\-----------------------
\Init section
\-----------------------

\initreccount
		.initreccount
		{
		LDA #0
		STA sno
		STA sno+1
		RTS
		}

\InitFilterstring
		.InitFilterstring
		{
		LDA #HI(FILTERDisplaySettings)
		STA APtr+1
		LDA #LO(FILTERDisplaySettings)
		STA APtr
		JMP initreccount \rts
		}

\Initmenuscreen
		.Initmenuscreen
		{
		LDY #MAINWindow
		JSR Selectwindow
		LDA #'A'
		STA CurrentCursorLetter
		STA lastline
		JMP Initmenu \rts
		}

\EnterSearchNo esn
\		\.esn
\		.EnterSearchNo
\		{
\		LDX #LO(numip)
\		LDY #HI(numip)
\		LDA #0
\		JSR OSWORD
\		STY StrAlen
\		RTS
\		}

\EQUW numip
\		.numip\
\		{
\		EQUB LO(WORKINGStrA)
\		EQUB HI(WORKINGStrA)
\		EQUB 3 \Length
\		EQUB '0'\min ascii value
\		EQUB '9'\max ascii value
\		}

\EnterSearchText est
		.EnterSearchText
		{
		LDX #LO(textinputparms)
		LDY #HI(textinputparms)
		LDA #0
		JSR OSWORD
		STY StrAlen
		RTS 
		.textinputparms
		EQUB LO(WORKINGStrA)
		EQUB HI(WORKINGStrA)
		EQUB 12 \max length
		EQUB '0'\min ascii value
		EQUB 'Z'\max ascii value
		}
\CopyAptrtoPreviousRecordset
		.CopyAptrtoPreviousRecordset
		{
		LDA APtr+1
		STA PreviousRecordset+1
		LDA APtr
		STA PreviousRecordset
		RTS
		}
\InitprogTypeText iptt
\		\.iptt
\		.InitprogTypeText
\		{
\		LDA #HI(prtt)
\		STA APtr+1 
\		LDA #LO(prtt)
\		STA APtr
\		JSR CopyAptrtoPreviousRecordset
\		JMP initreccount
\		}\rts

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
\HardInitmenu HardInitmenu him
\real startof prog
		

	.HardInitmenu
	{
		JSR Loadpublisher 
		LDA#0
		\\clear a% to zeroz% inline as not used elsewhere
		IF __DEBUG
			.cazeroz
			{
			LDY #INTatozLen
			.zerozy
			STA INTatozStart,Y
			DEY
			BPL zerozy
			}
		ENDIF
		.ClearFilterMask \CFM
		{
		\LDA #0 done above
		LDX #3
		.aa
		STA FilterMask,X
		STA Filterbits,X
		DEX 
		BPL aa
		}
		.Zeropageclear
		\LDA #0 done above
		STA FilterFlag
		STA catdrive
		\set Drive for catdat0 file
		\need to see if catdat0 file exists 
		\\on drive 0 if so all catdat files
		\are on drive 0
		\LDA #0 not needed as done above
		\JSR DriveSelect \do we need to initate catdat no
		{
		JSR initcatdat
		\JSR CheckCatfileExists
		\CMP #1
		\BNE nocatfile
		\LDA #0
		\BEQ ab
		.nocatfile
		\LDA #1
		.ab
		\STA catdrive
		\INC catdrive
		}
		IF __DEBUG AND __CATDATTEST
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
			EQUS "TESTING CATDAT drive="
			EQUB &D
			LDA catdrive 
			CLC
			ADC #'0'
			JSR OSASCI
			.ab
			JSR gti	
			}
		ENDIF
		
		
\set Aptr to selectiontext
		{
		LDA #HI(selectiontext)
		STA APtr+1
		LDA #LO(selectiontext)
		STA APtr
		LDX#0
		STX comprec
		}
\Expand and copy into FILTERDisplaySettings
		.ExpandandcopyintoDisplay
		{
		.ms
		LDY #0
		LDA (APtr),Y
		BEQ Initmenu
		JSR copyAptrTostrA
		JSR expandStrAtoFiltercharlength
		LDY #0
		.mu
		LDA WORKINGStrA,Y
		STA FILTERDisplaySettings,X
		\CMP #&80
		\BCS mv
		BMI mv
		INY
		INX
		BNE mu
		.mv
		JSR NextRecord 
		INX
		CLC
		BCC ms
		}
	}
\Initmenu 
		.Initmenu
		{
		LDA #HI(CURSORInit)
		STA CurrentCursorAddress+1
		LDA #LO(CURSORInit)
		STA CurrentCursorAddress
		RTS \end of HardInitmenu
		}
\InitdisplayFilterResults idf
		.InitdisplayFilterResults
		{
		LDA #HI(FILTERResultsStartAddress)
		STA APtr+1
		LDA #LO(FILTERResultsStartAddress)
		STA APtr
		JMP initreccount \rts
		}
\InitFilterResults ifr
		.InitFilterResults
		{
		LDA #HI(FILTERResultsStartAddress)
		STA AFilterPointer+1
		LDA #LO(FILTERResultsStartAddress)
		STA AFilterPointer
		RTS
		}

\InitFilterPtr ifp
\		\.ifp
\		.InitFilterPtr
\		{
\		LDA #HI(filttxt%)
\		STA APtr+1
\		LDA #LO(filttxt%)
\		STA APtr
\		JMP initreccount
\		}\rts

\InitFileSoftrecArrayPtr ifsp
		.InitFileSoftrecArrayPtr
		{
		LDA #HI(INDEXfileloadAddress)
		STA APtr+1
		LDA #LO(INDEXfileloadAddress)
		STA APtr
		JSR CopyAptrtoPreviousRecordset
		JMP initreccount \rts
		}

\InitFilecatdatAPtr ifcp
		.InitFilecatdatAPtr
		{
		LDA #HI(CATLoadStartAddress)
		STA APtr+1
		LDA #LO(CATLoadStartAddress)
		STA APtr
		JSR CopyAptrtoPreviousRecordset
		JMP initreccount \rts
		}
		
\CopyPreviousRecordSettoAptr cda
		.CopyPreviousRecordSettoAptr
		{
		LDA PreviousRecordset
		STA APtr
		LDA PreviousRecordset+1
		STA APtr+1
		JMP initreccount \rts
		}
		
\set filter
		.Setfilter
		{
		ORA FilterFlag
		STA FilterFlag
		RTS
		}
\isfilter
		.isfav	
		{
		LDY #0
		LDA (APtr),Y
		BEQ aa
		JSR GetEndDescription
		INY
		INY
		INY
		LDA (APtr),Y
		AND #8
		.aa
		RTS
		}

\--------------------------
\Data
\--------------------------
.overflow
EQUS"..OUT OF MEMORY."
EQUB &AE
EQUB 0
EQUB 0
EQUB 0
EQUB 0
EQUB 0
EQUB 0
.overflowend


.cat \NB will overwrite 2 pages below but only used 
\at when about to launchU


\.erradd
.err
EQUS"NO RECORD"
EQUB &80+'S'
EQUB 0

.ptxt
searchdisktitle=1
EQUS"Enter disk title"
EQUB &80+':'
searchpublisher=2
EQUS"Enter publisher"
EQUB &80+':'
searchdescription%=3
EQUS"Enter description"
EQUB &80+':'

 .window
 \left X, bottom Y, right X and top Y
 \top
EQUB 0
EQUB TOPLines   
EQUB 39
EQUB 0
 \btm
EQUB 0
EQUB 24        
EQUB 39
EQUB 24-BOTTOMLines
 \main
EQUB 0
EQUB 24-BOTTOMLines
EQUB 39
EQUB TOPLines

.fav
EQUS"O"
EQUB &80+'n'

.selectiontext

\A
EQUS "Of",&80+'f'
\B
EQUS "Of",&80+'f'
\C
EQUS "Of",&80+'f'
\D
EQUS "Of",&80+'f'
\E
EQUS"        "
EQUB &80
\F
EQUB &80
\G
EQUB &80
\H
EQUB &80
\I
EQUB &80
\J
EQUB &80
\K
EQUB &80
\L
EQUB &80
\M
EQUB &80
\N
EQUB &80
\O
\EQUB &80
EQUB 0

\commands
\Browse cat

\.dinadd
.dinrec
EQUS"dinrec"
EQUB &D

\.pubadd
.pubrec
EQUS"softrec"
EQUB &D

\.catdatadd
.catdat
EQUS"catdat0"
EQUB &D

.filttxt%
\--------------------------------
\NB keep below 255 chars  zero ternminated
EQUS"BY DISK NAM"
EQUB &80+'E'
EQUS"BY FAVORIT"
EQUB &80+'E'
EQUS"BY PUBLISHE"
EQUB &80+'R'
EQUS"BY TYP"
EQUB &80+'E'
EQUS"BY DESCRIPTIO"
EQUB &80+'N'
EQUS"SEARCH PUBLISHE"
EQUB &80+'R'
EQUS"SEARCH DISK NAM"
EQUB &80+'E'
EQUS"DISPLAY RESULT"
EQUB &80+'S'
EQUS"CLEAR ALL FILTER"
EQUB &80+'S'
EQUS"SOUND OF"
EQUB &80+'F'
EQUS"TV25"
EQUB &80+'5'
EQUS"LAUNCH DIS"
EQUB &80+'K'
EQUS"DISPLAY GAME HEL"
EQUB &80+'P'
EQUS"DISPLAY MENU HEL"
EQUB &80+'P'
\EQUS"BY FAVORIT"
\EQUB &80+'E'
EQUB 0
\--------------------------------

\-------------------------------
.helptxt1
\-------------------------------
\NB keep below 255 chars zero ternminated
EQUS "Search"
EQUB TELETEXTgreentext
EQUS "SPACE"
EQUB TELETEXTwhitetext
EQUS "Advanced"
EQUB TELETEXTgreentext
EQUS "TAB"
EQUB TELETEXTwhitetext
EQUS "Help"
EQUB TELETEXTgreentext
EQUS "?"
EQUB 0
\-------------------------------

\"„ACGSMPUZ"\

.keytxt
\-------------------------------
\NB keep below 255 chars zero ternminated
EQUB 13
EQUS"A"
EQUB TELETEXTyellowtext
EQUS"dvent"
EQUB TELETEXTwhitetext
EQUS "C"
EQUB TELETEXTyellowtext
EQUS"heat"
EQUB TELETEXTwhitetext
EQUS "G"
EQUB TELETEXTyellowtext
EQUS "ame"
EQUB TELETEXTwhitetext
EQUS "Z"
EQUB TELETEXTyellowtext
EQUS"unknwn"
EQUB TELETEXTwhitetext
EQUS "P"
EQUB TELETEXTyellowtext
EQUS"ic"
EQUB TELETEXTwhitetext
EQUS "U"
EQUB TELETEXTyellowtext
EQUS"til"
EQUS"S"
EQUB TELETEXTyellowtext
EQUS "trat"
EQUB TELETEXTmagentatext
EQUS "i"
EQUB TELETEXTyellowtext
EQUS"nvulnerable"
EQUB TELETEXTmagentatext
EQUS "2"
EQUB TELETEXTyellowtext
EQUS "playr"
EQUB TELETEXTmagentatext
EQUS "p"
EQUB TELETEXTyellowtext
EQUS "ass"
EQUB TELETEXTmagentatext
EQUS "j"
EQUB TELETEXTyellowtext
EQUS"oys"
EQUB TELETEXTmagentatext
EQUS "e"
EQUB TELETEXTyellowtext
EQUS "lectron"
EQUB TELETEXTmagentatext
EQUS "l"
EQUB TELETEXTyellowtext
EQUS "vl"
EQUB TELETEXTmagentatext
EQUS "X"
EQUB TELETEXTyellowtext
EQUS "life"
EQUB TELETEXTmagentatext
EQUS "s"
EQUB TELETEXTyellowtext
EQUS"peed"
EQUB TELETEXTwhitetext
EQUS"A/S fav" 
EQUB 0
\-------------------------------
.prtt
\-------------------------------
\NB keep below 255 chars zero ternminated
\ACGSMPUZ
EQUS"TEXT ADVENTUR"
EQUB &80+'E'
EQUS"CHEAT"
EQUB &80+'S'
EQUS"GAM"
EQUB &80+'E'
EQUS"STRATEG"
EQUB &80+'Y'
EQUS"MUSI"
EQUB &80+'C'
EQUS"PICTUR"
EQUB &80+'E'
EQUS"UTILIT"
EQUB &80+'Y'
EQUS"UNKNOW"
EQUB &80+'N'
EQUB 0
\-------------------------------
\.blockadd
\EQUW(block)
.block
EQUW 0
EQUB LO(INDEXfileloadAddress)
EQUB HI(INDEXfileloadAddress)
EQUW 0
EQUW 0
EQUD 0
.end

SAVE "mnudisp", start, end,startexec

\\cd d
\bbc/beebasm

\cd D
\GitHub\beebyams\beebasm

\beebasm -i .\mnudisp\mnudisp.asm -do .\mnudisp\mnudisp.ssd -boot x -v -title mmudisp

\cd C
\GitHub\beebyams

\ ./tools/beebasm/beebasm.exe -i ./MMUDISP.asm -do ./build/MMUDISP.ssd -boot MMUDISP -v -title MMUDISP

\ 