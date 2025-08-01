\OSARGS 
\provides
\.OSARGSinit
\ need to set :-
\__OSARGSinit
\__OSARGSargXtostrB%
\__OSARGSargcountX


\\get OSARGS into blockstart
IF __OSARGSinit
	.OSARGSinit
	{
	LDX #OSARGSptr
	LDY #0
	LDA #1
	JMP OSARGS 
	}\rtn
ENDIF
\\ptr to command into blockstart
\\X,Y,A are preserved OSARGS
IF __OSARGSargcountX
	.OSARGSargcountX
	\retuns count in X
	{
	LDX #0
	LDY #&FF
	.aa
	INY
	LDA (OSARGSptr),Y
	\.ad
	CMP #&D
	BEQ ab
	CMP #' '
	BEQ aa
	\have a command
	INX
	.cmd
	INY
	LDA (OSARGSptr),Y
	CMP #&D
	BEQ ab
	CMP #' '
	BEQ aa
	BNE cmd
	.ab
	RTS
	}
ENDIF

IF __OSARGSargXtoOSARGSstrB
	.OSARGSargXtoOSARGSstrB
	{
	LDY #&FF
	.aa
	INY
	LDA (OSARGSptr),Y
	CMP #' '
	BEQ aa
	DEX
	BNE ab
	\now have cmd put it in strB%
	LDX#0
	.ac
	STA OSARGSstrB,X
	INY
	LDA (OSARGSptr),Y
	INX
	CMP #' '
	BEQ ret
	CMP #&D
	BEQ ret
	BNE ac
	.ab \discard command
	INY
	LDA (OSARGSptr),Y
	CMP #' '
	BNE ab
	BEQ aa
	.ret
	LDA #&D
	STA OSARGSstrB,X
	RTS
	}
ENDIF

IF __OSARGSallcmdintoOSARGSstrAoffsetX
	.OSARGSallcmdintoOSARGSstrAoffsetX
	{
	LDY #0
	.ac
	LDA (OSARGSptr),Y
	STA OSARGSstrA,X
	INX
	INY
	CMP #&0D
	BNE ac
	RTS
	}
ENDIF