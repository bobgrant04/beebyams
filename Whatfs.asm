INCLUDE "VERSION.asm"
INCLUDE "SYSVARS.asm"			; OS constants
INCLUDE "BEEBINTS.asm"			; A% to Z% as a ... z
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

\&600 String manipulation
strA%=&6A0
\&A00 RS232 & cassette
\&1100-7C00 main mem

ORG &7500
GUARD &7C00

.start
\clear %
LDX #(('F'-'A')*4)
JSR clearint

\get OSARGS into blockstart
LDX #blockstart
LDY #0
LDA #1
JSR OSARGS  
\ptr to command into blockstart&70
\X,Y,A are preserved OSARGS

{
LDA (blockstart),Y
CMP #&D
BEQ aa
LDX #1
JSR diserror:
.aa
}
{
LDA#0
TAY
TAX
JSR OSARGS
CMP #4
STA f
BEQ bb
CMP #12
BEQ bc
RTS
.bc
\file type 12
LDA #&83
STA f
JMP printdetail \rts
.bb
}
\ file type 04
{
LDA #0
STA tempx
.cc
INC tempx
LDX tempx
JSR prepcmd
LDA strA%
CMP #&D
BEQ exit
JSR issuecmd
STA a
CMP #254
BEQ cc
}
.cmdok
LDA tempx
CLC
ADC #&80
STA f
.exit
JSR printdetail
RTS
\routines

\print detail
\takes f and prints corrisponding entry in fstxt
		.printdetail
		{
		LDA #LO(fstxt)
		STA aptr
		LDA #HI(fstxt)
		STA aptr+1
		.aa
		LDY #0
		LDA (aptr),Y
		CMP f
		BNE bb
		\print record
		.cc
		INY
		LDA(aptr),Y
		CMP #&80
		BCC bd
		AND #&7F
		JSR OSASCI
		LDA #&D
		JSR OSASCI
		RTS
		.bd
		JSR OSASCI
		BNE cc
		RTS
		.bb:\move next record
		CMP #&FF
		BNE dd
		RTS
		.dd
		INY
		LDA (aptr),Y
		CMP #&80
		BCC dd
		CLC
		TYA
		ADC aptr
		STA aptr
		LDA #0
		ADC aptr+1
		STA aptr+1
		BNE aa
		}

		.issuecmd
		\takes cmdno in
		{
		LDA strA%
		CMP #&D
		BEQ exit
		JSR xos_call
		EQUW execmd
		STA a
		.exit
		RTS
		}


\Prepcmd
\takes x as cmdno ret 
\strA%
		.prepcmd
		{
		LDA #LO(cmdadd)
		STA aptr
		LDA #HI(cmdadd)
		STA aptr+1
		LDY #0
		.ez
		DEX
		BNE nexcmd
		.ey
		LDA (aptr),Y
		STA strA%,X
		CMP #&D
		BNE am
		RTS
		.am
		INX
		INY
		BNE ey
		.nexcmd
		LDA cmdadd,Y
		INY
		CMP #&D
		BNE nexcmd
		BCS ez 
		}

\execmd
		.execmd 
		{
		LDY #HI(strA%)
		LDX #LO(strA%)
		JMP OSCLI \RTS
		}

		.diserror
		{
		LDA #LO(errtxt)
		STA aptr
		LDA #HI(errtxt)
		STA aptr+1

		LDY #0
		.ba
		DEX
		BNE bb
		.bc
		LDA(aptr),Y
		CMP #&80
		BCC bd
		AND #&7F
		JSR OSASCI
		RTS
		.bd
		JSR OSASCI
		INY
		BNE bc
		.bb
		LDA (aptr),Y
		INY
		CMP #&80
		BCC bb
		CLC
		TYA
		ADC aptr
		STA aptr
		LDA #0
		ADC aptr+1
		STA aptr+1
		LDY #0
		BEQ ba
		}
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
    PHA
	TXA
	PHA                     :\ Stack holds X, A, main
    LDA BRKV+1
	PHA
	LDA BRKV+0
	PHA
    LDA oldSP
	PHA
	TSX
	STX oldSP     :\ Stack holds oldSP, oldBRKV, X, A, main
    LDA #error DIV 256
	STA BRKV+1   :\ Redirect BRKV
    LDA #error AND 255
	STA BRKV+0
    LDA #(return-1)DIV 256
	PHA
    LDA #(return-1)AND 255
	PHA      :\ Stack return address
    PHA
	PHA
	PHA
	PHA                 :\ Make space to hold dest and X, A
    LDA zp+1
	PHA
	LDA zp
	PHA
	CLC     :\ Save zp workspace
    LDA &106,X
	STA zp
	ADC #2
	STA &106,X     :\ Get mainline address and step
    LDA &107,X
	STA zp+1
	ADC #0
	STA &107,X   :\ past inline dest address
    TYA
	PHA
	TSX                     :\ Save Y, get new SP
    LDY #2
	LDA (zp),Y
	STA &107,X
    DEY
	LDA (zp),Y
	STA &106,X       :\ Copy inline address to stack
    LDA &10E,X
	STA &105,X           :\ Copy A to top of stack
    LDA &10D,X
	STA &104,X           :\ Copy X to top of stack
    :
    \ Stack holds Y, zp, X, A, dest, return, oldSP, oldBRKV, X, A, main
    :
    PLA
	TAY
	PLA
	STA zp
	PLA
	STA zp+1 :\ Restore Y and zp workspace
    PLA
	TAX
	PLA
	PHP
	RTI             :\ Restore X, A, jump to stacked dest addr
    :
    .return                         :\ Stack holds oldSP, oldBRKV, X, A, main
    PHA
	TXA
	TSX                     :\ Stack A
    STA &105,X
	PLA
	STA &105,X       :\ Copy X, A to top of stack
    PLA
	STA oldSP                   :\ Restore oldSP
    PLA
	STA BRKV+0
	PLA
	STA BRKV+1   :\ Restore BRKV
    PLA
	TAX
	PLA
	RTS                 :\ Get returned X, A and return to main
    .error
    LDX oldSP
	TXS
	PLA
	STA oldSP     :\ Restore oldSP
    PLA
	STA BRKV+0
	PLA
	STA BRKV+1   :\ Restore BRKV
    PLA
	PLA
	LDY #0
	LDA (&FD),Y      :\ Drop X, A, get error number
    BIT P%-1
	RTS                    :\ Set V from inline &FD byte and return
    .oldSP
    EQUB 0                          :\ Saved stack pointer
	}




\strings
.cmdadd

\0 MMC (&81)
EQUS"DIN":EQUB &D
\1 gommc (&82)
EQUS"MMCDisc":EQUB &D
\2 gommc (&82)
EQUS"import":EQUB &D

EQUB &D \indicates end of records


.errtxt
\ 1 usage"
EQUS"outputs FileSystem type no in F%":EQUB &8D




\https://www.sprow.co.uk/bbc/library/fsids.txt
.fstxt

EQUB 0,"0 No current filing syste":EQUB 'm'+&80
EQUB 1,"1 1200 baud cassette filing syste":EQUB 'm'+&80
EQUB 2,"2 300 baud cassette filing syste":EQUB 'm'+&80
EQUB 3,"3 ROM filing system":EQUB 'm'+&80
EQUB 4,"4 Disk filing syste":EQUB 'm'+&80
EQUB 5,"5 Econet network filing syste":EQUB 'm'+&80
EQUB 6,"6 Teletext/Prestel telesoftwar":EQUB 'e'+&80
EQUB 7,"7 IEEE filing syste":EQUB 'm'+&80 
EQUB 8,"8 Acorn ADF":EQUB 'S'+&80
EQUB 9,"9 Host filing syste":EQUB 'm'+&80
EQUB 10,"10 Videodisk filing syste":EQUB 'm'+&80
EQUB 12,"12 RAM filing syste":EQUB 'm'+&80
EQUB 13,"13 Nul":EQUB 'l'+&80
EQUB 14,"14 Printe":EQUB 'r'+&80
EQUB 15,"15 Seria", 'l'+&80
EQUB 16,"16 Harston ADF":EQUB 'S'+&80
EQUB 17,"17 Vd":EQUB 'u'+&80
EQUB 18,"18 RawVd":EQUB 'u'+&80
EQUB 19,"19 Kb":EQUB 'd'+&80
EQUB 20,"20 RawKb":EQUB 'd'+&80
EQUB 21,"21 DeskF":EQUB 'S'+&80
EQUB 22,"22 Computer Concepts RomF":EQUB 'S'+&80
EQUB 23,"23 RamF":EQUB 'S'+&80
EQUB 24,"24 RISCiXF":EQUB 'S'+&80
EQUB 25,"25 Streame":EQUB 'r'+&80
EQUB 26,"26 SCSIF":EQUB 'S'+&80
EQUB 27,"27 Digitise":EQUB 'r'+&80
EQUB 28,"28 Scanne":EQUB 'r'+&80
EQUB 29,"29 MultiF":EQUB 'S'+&80
EQUB 33,"33 NF":EQUB 'S'+&80
EQUB 37,"37 CDF":EQUB 'S'+&80
EQUB 43,"43 DOSF":EQUB 'S'+&80
EQUB 46,"46 ResourceF":EQUB 'S'+&80
EQUB 47,"47 PipeF":EQUB 'S'+&80
EQUB 53,"53 DeviceF":EQUB 'S'+&80
EQUB 54,"54 Paralle":EQUB 'l'+&80
EQUb 55,"55 VCM ne",'t'+&80
EQUB 56," 56 ArcF",'S'+&80
EQUB 57," 57 Nexus prin",'t'+&80
EQUB 58," 58 PI",'A'+&80
EQUB 59,"59RS DO",'S'+&80
EQUB 65,"65 CoProcesso",'r'+&80
EQUB 66,"66 SparkF",'S'+&80
EQUB 86,"86 FontF",'S'+&80
EQUB 91,"91 Memphi",'s'+&80
EQUB 96,"96 AddressDevice (dynamic area filing system",')'+&80
EQUB 99,"99 ShareF",'S'+&80
EQUB 101,"101 Computer Concept's PrintQueue F",'S'+&80
EQUB 102,"102 LanMa",'n'+&80
EQUB 104,"104 OmniPrin",'t'+&80
EQUB 105,"105 AppleF",'S'+&80
EQUB 111,"111 ZipFS (IOMega ZIP drives",')'+&80
EQUB 115,"115 ATAFS (Yellowstone's RapIDE",')'+&80
EQUB 118,"118 CacheF",'S'+&80
EQUB 123,"123 IZipF",'S'+&80


\below specials
EQUB &81,"129 MMC syste",'m'+&80
EQUB &82,"130 GoMMC", 'm'+&80
EQUB &83,"131 RFS",'m'+&80
EQUB 134,"134 FastSpoo",'l'+&80
EQUB 141,"141 BDF",'S'+&80
EQUB 142,"142 raF",'S'+&80
EQUB 145,"145 lprF",'S'+&80
EQUB 148,"148 CDRF",'S'+&80
EQUB 152,"152 ParaF",'S'+&80
EQUB 156,"156 LanMan9",'8'+&80
EQUB 158,"158 CDROMF",'S'+&80
EQUB 205,"205 AudioF",'S'+&80





EQUB &FF


.end


SAVE "whatfs", start, end
\D:\GitHub\beebyams\beebasm
\beebasm -i .\whatfs\whatfs.asm -do .\whatfs\whatfs.ssd -boot whatfs -v -title whatfs
\cd C:\GitHub\beebyams


\ ./tools/beebasm/beebasm.exe -i ./WHATFS.asm -do ./build/WHATFS.ssd -boot WHATFS -v -title WHATFS