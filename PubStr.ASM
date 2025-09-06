INCLUDE "VERSION.asm"
INCLUDE "SYSVARS.asm"			; OS constants
INCLUDE "BEEBINTS.asm"			; A% to Z% as a ... z


\utility prog
\Takes a string in StrA%
\Updates the String as :-
\Capital first letter any Letter after a # will be Capital
\TO DO expand for roman numerals etc - use magic type format?
\\&600 String manipulation
\Aptr=&70

strA%=&640


ORG &900
GUARD &7C00
.start
		LDY #&FF
		LDX #1
		\LDA #HI(strA%)
		\STA Aptr+1
		\LDA #LO(strA%)
		\STA Aptr
		.loop
		INY
		LDA strA%,Y
		CMP #&D
		BEQ exit
		CMP #'#'
		BEQ hash
		CMP #'A'-1
		BCC loop
		CMP #'z'+1
		BCS loop
		CPX #0
		BNE capitalise
		BEQ lowercase
		.store
		STA strA%,Y
		BVC loop
		.hash
		LDX #1
		BNE loop 
		.exit
		RTS
		
		.capitalise
		{
		LDX #0
		CMP #'Z'+1
		BCC store
		SEC
		SBC #'a'-'A'
		BVC store
		}
		.lowercase
		{
		CMP #'a'
		BCS loop
		CMP #'Z'+1
		BCS loop
		CLC
		ADC #'a'-'A'
		BVC store
		}
.end
SAVE "PubStr", start, end
\  ./tools/beebasm/beebasm.exe -i ./PubStr.asm -do ./build/PubStr.ssd -boot pubstr -v -title PubStr

