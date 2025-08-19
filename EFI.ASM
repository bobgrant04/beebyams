

INCLUDE "VERSION.asm"
INCLUDE "SYSVARS.asm"			; OS constants
INCLUDE "BEEBINTS.asm"			; A% to Z% as a ... z
\INCLUDE "TELETEXT.asm"

blockstart=&70
load=blockstart+2
exe=blockstart+6
EFIAptr=&80

ORG &6800
GUARD &7C00

.start
INCLUDE "MAGIC_SOURCE.asm"		\magic configuration
.startexec
		JSR InitAptrtoMagicData
		.TableScan
		{
		LDY #0
		LDA (EFIAptr),Y
		BNE aa
		.exittablescan
		\no need to check for screens as in magic files
		\need to print *run message
		
		RTS
		.aa
		TAX
		DEX
		BNE Not1
		\1,Offset, nobytes,exec,load ident
		INY
		INY
		LDA (EFIAptr),Y
		CLC
		ADC #4
		JMP displayrec
		.Not1
		DEX
		BNE Not2
		\Entry type 2
		\2,Startrange,Endrange,minvalue,maxvalue,exec,load ident
		LDA #5
		JMP displayrec
		.Not2
		DEX
		BNE Not3
		\Entry type 3 
		\3,loadadd,exec,load,ident
		LDA#3
		JMP displayrec
		.Not3
		DEX
		BNE Not4
		\Entry type 4
		\4,exec,exec,load,ident
		LDA#3
		JMP displayrec
		.Not4
		DEX
		BNE Not5
		\Entry 5
		\5 no of high byte pairs (high,count or higher),exec,load,ident
		INY
		LDA (EFIAptr),Y
		ROL A
		CLC
		ADC #2
		JMP displayrec
		.Not5
		DEX
		BNE Not6
		\Entry 6
		\6,offset,nobytes,check bytes,exec,load,ident
		INY
		INY
		LDA (EFIAptr),Y
		CLC
		ADC #4
		JMP displayrec
		.Not6
		DEX
		BNE Not7
		\Entry 7
		\7,count,no entries,bytes,exec,load,ident
		INY
		INY
		LDA (EFIAptr),Y
		CLC
		ADC #3
		JMP displayrec
		.Not7
		DEX
		BNE Not8
		\8,length,exec,load,ident
		LDA #3
		JMP displayrec
		.Not8
		DEX
		BNE exittablescan
		\9,number of bytes to match anywhere in first Page,exec,load,ident
		INY
		LDA (EFIAptr),Y
		CLC
		ADC #3
		JMP displayrec
		\.exittablescan
		\RTS
		}
		.displayrec
		{
		\for now just display text!
		\check if we are #1 else ignore
		TAX
		CLC
		ADC #4
		TAY
		.ac
		INY
		LDA (EFIAptr),Y
		CMP #'#'
		BNE ac
		INY
		LDA (EFIAptr),Y
		CMP #'1'
		BEQ ad
		JMP NextRec
		.ad
		TXA
		TAY
		JSR CheckZero
		BCS ag
		JSR PrintAddress
		.ag
		JSR CheckZero
		BCS ah
		JSR PrintAddress
		.ah
		.aa
		LDA (EFIAptr),Y
		CMP #'#'
		BNE ab
		JSR OSNEWL
		JMP NextRec
		.ab
		JSR OSWRCH
		INY
		BNE aa
		\.af\printxxx and return toag
		\INY
		\INY
		\BNE ag
		}
		.NextRec
		{
		.aa
		INY
		LDA (EFIAptr),Y
		CMP #13
		BNE aa
		INY
		TYA
		CLC
		ADC EFIAptr
		STA EFIAptr
		LDA #0
		ADC EFIAptr+1
		STA EFIAptr+1
		JMP TableScan
		}
		.CheckZero
		{
		LDA (EFIAptr),Y
		INY
		CLC
		ADC (EFIAptr),Y
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
		
		
		.PrintAddress
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
		LDA (EFIAptr),Y
		\JSR PrHex
		\}
		\ Print A in hex
		\ ==============
		\ Corrupts A
		.PrHex
		\{
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
			JMP OSWRCH
			}
		}
		.InitAptrtoMagicData
		{
		LDA #LO(MagicData)
		STA EFIAptr
		LDA #HI(MagicData)
		STA EFIAptr+1
		RTS
		}
\should not be here
\drop through to screencheck
.end
SAVE "EFI", start, end,startexec



\cd D:\GitHub\beebyams\beebasm
\beebasm -i .\EFI\EFI.asm -do .\EFI\EFI.ssd -boot EFI -v -title EFI

\cd C:\GitHub\beebyams\beebasm


\ ./tools/beebasm/beebasm.exe -i ./EFI.asm -do ./build/EFI.ssd -boot EFI -v -title EFI