
		\A=0 Full print
		MAGICHELPFullprint =0
		\A=1 match exe only
		MAGICHELPMatchexe =1
		\A=2 match load only
		MAGICHELPMatchLoad =2
		\A=3 Match either exe and or load
		MAGICHELPMatchEitherLoadOrExe =3





IF __MAGICHELPPRINT = TRUE		
		.MAGICHELPPRINT
		IF __MAGICHELPPRINTSELECTED = TRUE
			STA MAGICHELPPrintType%
		ENDIF
		.MAGICHELPPRINTInitAptrtoMagicData
		{
		LDA #LO(MagicData)
		STA MAGICHELPAptr
		LDA #HI(MagicData)
		STA MAGICHELPAptr+1
		}
		.MAGICHELPPRINTTableScan
		{
		LDY #0
		LDA (MAGICHELPAptr),Y
		BEQ exittablescan
		

		\no need to check for screens as in magic files
		\need to print *run message
		\EQUS"Version ": BUILD_VERSION
		
		.aa
		TAX
		CMP #&FF
		BNE Notff
		LDA #1
		JMP MAGICHELPdisplayrec
		.Notff
		DEX
		BNE Not1
		\1,Offset, nobytes,exec,load ident
		INY
		INY
		LDA (MAGICHELPAptr),Y
		CLC
		ADC #4
		JMP MAGICHELPdisplayrec
		.Not1
		DEX
		BNE Not2
		\Entry type 2
		\2,Startrange,Endrange,minvalue,maxvalue,exec,load ident
		LDA #5
		JMP MAGICHELPdisplayrec
		.Not2
		DEX
		BNE Not3
		\Entry type 3 
		\3,loadadd,exec,load,ident
		LDA#3
		JMP MAGICHELPdisplayrec
		.Not3
		DEX
		BNE Not4
		\Entry type 4
		\4,exec,exec,load,ident
		LDA#3
		JMP MAGICHELPdisplayrec
		.Not4
		DEX
		BNE Not5
		\Entry 5
		\5 no of high byte pairs (high,count or higher),exec,load,ident
		INY
		LDA (MAGICHELPAptr),Y
		ROL A
		CLC
		ADC #2
		JMP MAGICHELPdisplayrec
		.Not5
		DEX
		BNE Not6
		\Entry 6
		\6,offset,nobytes,check bytes,exec,load,ident
		INY
		INY
		LDA (MAGICHELPAptr),Y
		CLC
		ADC #4
		JMP MAGICHELPdisplayrec
		.Not6
		DEX
		BNE Not7
		\Entry 7
		\7,count,no entries,bytes,exec,load,ident
		INY
		INY
		LDA (MAGICHELPAptr),Y
		CLC
		ADC #3
		JMP MAGICHELPdisplayrec
		.Not7
		DEX
		BNE Not8
		\8,length,exec,load,ident
		LDA #3
		JMP MAGICHELPdisplayrec
		.Not8
		DEX
		BNE exittablescan
		\9,number of bytes to match anywhere in first Page,exec,load,ident
		INY
		LDA (MAGICHELPAptr),Y
		CLC
		ADC #3
		JMP MAGICHELPdisplayrec
		}
		.exittablescan
		RTS
		
		.MAGICHELPdisplayrec
		{
		IF __MAGICHELPPRINTSELECTED = TRUE
			LDX MAGICHELPPrintType%
			BNE entrymatching
		ENDIF
		
		TAX
		CLC
		ADC #4
		TAY
		}
		.matchprintrec
		{
		.ac
		INY
		LDA (MAGICHELPAptr),Y
		CMP #'#'
		BNE ac
		INY
		LDA (MAGICHELPAptr),Y
		CMP #'1'
		BEQ printthisrec
		JMP MAGICHELPNextRec
		}
		.printthisrec
		{
		TXA
		TAY
		JSR MAGICHELPcheckzero
		BCS ag
		JSR MAGICHELPPrintAddress
		.ag
		JSR MAGICHELPcheckzero
		BCS aa
		JSR MAGICHELPPrintAddress
		.aa
		LDA (MAGICHELPAptr),Y
		CMP #'#'
		BNE ab
		JSR OSNEWL
		IF __MAGICHELPPRINTSELECTED = TRUE
			LDX MAGICHELPPrintType%
			BNE exittablescan
		ENDIF
		JMP MAGICHELPNextRec \exit
		.ab
		JSR OSWRCH
		INY
		BNE aa
		}
		IF __MAGICHELPPRINTSELECTED = TRUE
			.entrymatching
			{
			TAX
			\IF __DEBUG
			\	LDY #0
			\	LDA (MAGICHELPAptr),Y
			\	JSR PrHex
			\	TXA
			\ENDIF
			TAY
			LDA MAGICHELPPrintType%
			AND #MAGICHELPMatchexe
			BEQ loadcheck
			LDA (MAGICHELPAptr),Y
			INY
			CLC
			ADC (MAGICHELPAptr),Y
			BEQ loadcheck
			LDA (MAGICHELPAptr),Y
			CMP MAGICHELPexe%+1
			BNE nomatch
			DEY
			LDA (MAGICHELPAptr),Y
			CMP MAGICHELPexe%
			BNE nomatch
			\Exe matches
			.exematch
			
			\JMP matchprintrec
			\JMP printthisrec
			.aa
			\0000 for exe
			.loadcheck
			LDA MAGICHELPPrintType%
			AND #MAGICHELPMatchLoad
			BEQ noloadcheck
			TXA
			TAY
			INY
			INY
			LDA (MAGICHELPAptr),Y
			INY
			CLC
			ADC (MAGICHELPAptr),Y
			BEQ loadzero
			LDA (MAGICHELPAptr),Y
			CMP MAGICHELPload%+1
			BNE nomatch
			DEY
			LDA (MAGICHELPAptr),Y
			CMP MAGICHELPload%
			BNE nomatch
			.noloadcheck
			.loadzero
			JMP printthisrec 
			.nomatch
			TXA
			CLC
			ADC #4
			TAY
			JMP MAGICHELPNextRec \exit
			}
		ENDIF
		
		.MAGICHELPNextRec
		{
		.aa
		INY
		LDA (MAGICHELPAptr),Y
		CMP #13
		BNE aa
		INY
		TYA
		CLC
		ADC MAGICHELPAptr
		STA MAGICHELPAptr
		LDA #0
		ADC MAGICHELPAptr+1
		STA MAGICHELPAptr+1
		JMP MAGICHELPPRINTTableScan
		}
		.MAGICHELPcheckzero
		{
		LDA (MAGICHELPAptr),Y
		INY
		CLC
		ADC (MAGICHELPAptr),Y
		BEQ xxxx
		DEY
		CLC
		RTS
		.xxxx
		LDX #4
		LDA #'X'
		.aa
		JSR OSWRCH
		DEX
		BNE aa
		LDA #' '
		INY
		JSR OSWRCH \RTS
		SEC
		RTS
		}
		
		
		.MAGICHELPPrintAddress
		{
		INY
		JSR PrintHex
		DEY
		JSR PrintHex
		LDA #' '
		JSR OSWRCH
		INY
		INY
		RTS
		}
		
		.PrintHex
		{
		LDA (MAGICHELPAptr),Y
		\JSR PrHex
		\}
		\ Print A in hex
		\ ==============
		\ Corrupts A
		}
		.PrHex
		{
		PHA
		LSR A
		LSR A
		LSR A
		LSR A
		JSR PrNybble
		PLA
			.PrNybble
			{
			AND #15
			CMP #10
			BCC PrDigit
			ADC #6
			}
			.PrDigit
			{
			ADC #'0'
			JMP OSWRCH \RTS
			}
		}
		
ENDIF