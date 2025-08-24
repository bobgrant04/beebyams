\OSARGS 
\provides
\.OSARGSinit
\ need to set :-
\__OSARGSinit
\__OSARGSargXtostrB%
\__OSARGSargcountX
\ we are using semi offical GSINIT,GSREAD
\It should be noted that this initally point to the whole cmd i.e x myfile 1 din7
\GSINIT=&FFC2
\	On Entry:
\       Address for string stored at .stringInputBufferAddressLow/High
\       Y = offset into string
\       C = 0: string is terminated by a space (used for filename parsing)
\       C = 1: otherwise (used e.g. for defining a soft key with *KEY)
\	On Exit:
\       .stringInputOptions bit 7 = double-quote character found at start
\                           bit 6 = don't stop on space character\
\       Y = offset of the first non-blank character
\       A = first non-blank character
\       Z is set if string is empty
\GSREAD=&FFC5
\	On Entry:
\		   Address for string stored at .stringInputBufferAddressLow/High
\		   Y = offset into string
\	 On Exit:
\		   A = character read
\		   X is preserved
\		   Y = index of next character to be read
\		   Carry is set if end of string reached
\		   Overflow (V flag) is set if the character read was interpreted as a control code

\\get OSARGS into blockstart ret x no of args
IF __OSARGSinit
		.OSARGSinit
		{
		LDA #0
		TAY
		TAX
		SEC \od
		JSR GSINIT
		.aa
		JSR GSREAD
		BCS ac \end!
		.ae
		IF __DEBUG
			JSR OSWRCH
		ENDIF
		CMP #' '
		BNE aa	
		INX
		.ad
		JSR GSREAD
		BCS af \end!
		CMP #' '
		BNE ae
		BEQ ad
		.af
		DEX \have spaces at the end of string !
		.ac
		IF __DEBUG
			{
			JSR OSNEWL
			TXA
			CLC
			ADC #'0'
			JSR OSWRCH
			LDY #&FF
			.aa
			INY
			LDA debugtext,Y
			JSR OSASCI
			CMP #&D
			BNE aa
			BEQ ab
			.debugtext
			EQUS " = No of OSargs"
			EQUB &D
			.ab
			JSR OSNEWL
			}
		ENDIF
		\do not inc X as cmd contains filename that launched it!
		RTS
		}\rtn
ENDIF
	
	IF __OSARGSargXtoOSARGSStrLenA
		\at start OSARGSStrLenA hould point to place where cmd is to be placed
		\At end OSARGSStrLenA will point to the same string will have a ' ' character at the end
		.OSARGSargXtoOSARGSStrLenA
		{
		LDY #0
		.aa
		JSR GSREAD
		BCS ae
		.ag
		CMP #' '
		BNE aa
		DEX
		BEQ ah
		.ad
		JSR GSREAD
		BCS ac \end!
		CMP #' '
		BEQ ad
		BNE ag
		.ah
		LDX OSARGSStrLenA
		.af
		JSR GSREAD
		BCS ac \end!
		CMP #' '
		BEQ af
		
		\read into  StrA
		BNE aj
		.ab
		JSR GSREAD
		BCS ai
		.aj
		STA OSARGSstrA,X
		CMP #'"' \" ignore ""
		BEQ ab
		INX
		CMP #' '
		BNE ab
		.ac
		\INX
		STX OSARGSStrLenA
		.ae \end reached before count
		RTS
		.ai
		LDA #' '
		STA OSARGSstrA,X
		BNE ac
		}
	ENDIF