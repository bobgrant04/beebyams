\OSARGS 
\provides
\.OSARGSinit
\ need to set :-
\__OSARGSinit
\__OSARGSargXtostrB%
\__OSARGSargcountX
\ we are using semi offical GSINIT,OSARGSread
\It should be noted that this initally point to the whole cmd i.e x myfile 1 din7
\can not use this but can use the zero page vector! OSTextPointer%
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
\OSARGSread=&FFC5
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
		.OSARGSread
		{
		CLC
		LDA (OSTextPointer%),Y
		CMP #&D
		BNE	Exit
		SEC
		RTS
		.Exit
		INY
		CLC
		RTS
		}
		.OSARGSinit
		{
		LDA #0
		IF __OSARGSOptions
			STA OSARGSOptions%
			STA OSARGSbitOptions%
		ENDIF
		TAY
		TAX
		\SEC \od
		\JSR GSINIT
		}
		.startread
		{
		JSR OSARGSread
		BCS endofcmdline\end!
		.ae
		IF __OSARGSOptions
			CMP #'|'
			BEQ switch
		ENDIF
		IF __DEBUG
			JSR OSWRCH
			\PHA
			\JSR PrHex
			\PLA
		ENDIF
		.af
		CMP #' '
		BNE startread	
		INX
		.ad
		JSR OSARGSread
		BCS ag \near end!
		CMP #' '
		BNE ae
		BEQ ad
		.ag
		DEX \have spaces at the end of string !
		.endofcmdline
		STX OSARGSNoofArgs%
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
		IF __OSARGSOptions
			.switch
			{
			STX tempy%
			IF __DEBUG
				{
				JSR OSNEWL
				LDX #&FF
				.aa
				INX
				LDA debugtext,X
				JSR OSASCI
				CMP #&D
				BNE aa
				BEQ ab
				.debugtext
				EQUS " Switch"
				EQUB &D
				.ab
				JSR OSNEWL
				}
			ENDIF
			LDX #&FF
			.aa
			INX
			JSR OSARGSread
			BCS endofcmdline \ignore switch character
			STA OSARGSOptions%,X
			CMP #' '
			BNE aa
			LDA #0
			STA OSARGSOptions%,X
			\will process basic options here
			\use bit switches
			
			\=4 etc
			\will just do caps!
			\LDA #0
			\STA OSARGSbitOptions%
			.ab
			DEX
			LDA OSARGSOptions%,X
			CMP#'Q' \Quiet
			BNE ac
			LDA OSARGSbitOptions%
			ORA #OSARGSbitOptionQuiet%
			STA OSARGSbitOptions%
			.ac
			CMP#'V' \Verbose
			BNE ad
			LDA OSARGSbitOptions%
			ORA #OSARGSbitOptionVerbose%
			STA OSARGSbitOptions%
			.ad
			LDX tempy%
			JMP startread
			}
		ENDIF
		}\rtn
ENDIF
	
	IF __OSARGSargXtoOSARGSStrLenA
		\at start OSARGSStrLenA hould point to place where cmd is to be placed
		\At end OSARGSStrLenA will point to the same string will have a ' ' character at the end
		\if a char is >&80 sub &80 from it this is to allow mnudisp to pass parms to use
		\should not impact anthing else as these are not printable characters?
		.OSARGSargXtoOSARGSStrLenA
		{
		IF __OSARGSOptions
			{
			LDA OSARGSOptions%
			BEQ aa
			INX
			.aa
			}
		ENDIF
		LDY #0
		.aa
		JSR OSARGSread
		BCS ae
		.ag
		CMP #' '
		BNE aa
		DEX
		BEQ ah
		.ad
		JSR OSARGSread
		BCS ac \end!
		CMP #' '
		BEQ ad
		BNE ag
		.ah
		LDX OSARGSStrLenA
		.af
		JSR OSARGSread
		BCS ac \end!
		CMP #' '
		BEQ af
		
		\read into  StrA
		BNE aj
		.ab
		JSR OSARGSread
		BEQ ai
		.aj
		STA OSARGSstrA,X
		CMP #'"' \" ignore ""
		BEQ ab
		CMP #&80
		BCC ak
		SEC
		SBC #&80
		STA OSARGSstrA,X
		INX
		BNE ab
		.ak
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
	
	IF __OSARGSargGetDrive
	\assumes command line is of type filename drive i.e. pram2
	.OSARGSGetDrive
		{
		LDA #0
		STA OSARGSStrLenA
		LDX #2
		JSR OSARGSargXtoOSARGSStrLenA
		
		\sets strlenA
		LDA strA%
		\LDA pram%
		CMP #'0'
		BCC ret
		CMP #'4'
		BCS ret
		STA OSARGSrequesteddrive
		IF __DEBUG
			{
			JSR OSNEWL
			TXA
			CLC
			ADC #'0'-1
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
			EQUS " = Requested drive"
			EQUB &D
			.ab
			JSR OSNEWL
			}
		ENDIF
		LDA #0 
		.ret
		RTS \RTS
		}
	ENDIF
	
	IF __OSARGSFileNameToOSARGSPram
		.OSARGSFileNameToOSARGSPram
		{
		LDX #0
		STX OSARGSStrLenA
		INX
		\LDX #1 \filename
		JSR OSARGSargXtoOSARGSStrLenA
		\filename into StrA%
		\LDX OSARGSStrLenA
		\DEX
		\LDA #&D
		\STA OSARGSpram%,X
		\STX OSARGSStrLenA
		\STX OSARGSpramlen%
		LDX #&FF
		.aa
		INX
		LDA OSARGSstrA,X
		STA OSARGSpram%,X
		CMP #' '
		BNE aa
		LDA #&D
		STA OSARGSpram%,X
		IF __DEBUG
			{
			JSR OSNEWL
			LDX #0
			.ac
			LDA OSARGSpram%,X
			CMP #&D 
			BEQ ad
			JSR OSWRCH
			INX
			BNE ac
			.ad
			LDY #&FF
			.aa
			INY
			LDA debugtext,Y
			JSR OSWRCH
			CMP #&D
			BNE aa
			BEQ ab
			.debugtext
			EQUS " = Filename"
			EQUB &D
			.ab
			JSR OSNEWL
			}
		ENDIF
		RTS
		}
		
	ENDIF