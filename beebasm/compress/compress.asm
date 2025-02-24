firstpage%=1
page14%=2
parge15%=3


\&2E - &35 FLOATING POINT WORK AREA A
pramlen=&2E
highnibble=&2F
page=&30
strA%=&620
pram%=&680

\takes a 80+char terminated string in StrA%
\returning an encoded string in pram%
\with parmlen% set
\assumes capitalisation etc has been done

ORG &6800
GUARD &7C00
.start
.startexec
.encodestrA
{
	\will just load param with nibbles one per byte first
	LDX #0:STX pramlen:STX highnibble
	DEX
	.aa:INX:LDA strA%,X:CMP #13:BEQ done
	LDY #0:.ab:INY:CPY #(16+16+14)
	BEQ invalidchar:CMP firstpage,Y:BNE ab
	\have a character which page?
	TYA
	CMP #14:BCS ac
	\firstpage
	JSR storeApram:BVC aa
	.ac
	CMP #(14+16):BCS ad
	PHA
	LDA #14:JSR storeApram
	PLA
	SEC:SBC #14:JSR storeApram:BVC aa
	.ad
	PHA
	LDA #15:JSR storeApram
	PLA
	SEC:SBC #(14+16):JSR storeApram:BVC aa
	.done
	LDA #0:JMP storeApram
}
.storeApram
{
	PHA
	LDA highnibble:EOR #&FF:STA highnibble:BEQ aa
	PLA
	LDY pramlen:STA pram%,Y:RTS
	.aa
	PLA 
	CLC:ROL A:ROL A:ROL A:ROL A
	LDY pramlen:ORA pram%,Y:STA pram%,Y:INY:STY pramlen:RTS
}
.invalidchar
BRK:EQUS 0,"invalid character unable to encode",0
.decodepram
{
	\get nibble
	LDX #0:STX pramlen:LDA #&F0:STA highnibble
	DEX
	.ac:LDA highnibble:EOR #&FF:STA highnibble
	INX:LDA pram%,X:AND highnibble:BEQ done
	CMP #&10:BCC ab
	CLC:ROR A:ROR A:ROR A:ROR A
	.ab
	CMP #14:BCS aa
	\single nibble
	TAY:LDA firstpage,Y:
	LDY pramlen:STA strA%,Y:INY:STY pramlen:BVC ac
	.aa:\2 nibbles
	CMP #14:BNE ae
	LDA #16:BVC af
	.ae
	LDA #32
	.af
	STA page
	LDA #&F:AND highnibble:BEQ ad
	\high nibble - low nibble
	INX:LDA pram%,X:AND #&F
	CLC:ADC page
	LDY pramlen:STA strA%,Y:INY:STY pramlen:INX:BVC ac
	.ad
	\low nibble high nibble
	LDA pram%,X:AND #&F0
	CLC:ADC page
	LDY pramlen:STA strA%,Y:INY:STY pramlen:INX:BVC ac
	
}

\freqs from \https://www3.nd.edu/~busiforc/handouts/cryptography/letterfrequencies.html
.firstpage:\0 is EOF,14 and 15 for page 14 and page 15
EQUS 0,' ','E','A','R','I','O','T','N','S','L','C','D','P'
.page14
EQUS 0,'M','H','G','B','F','Y','W','K','V','X','Z','J','Q','&',','
.page15
EQUS 0,'0','1','2','3','4','5','6','7','8','9','#','.','>','<',':'

.end
SAVE "compres", start, end,startexec

\cd D:\GitHub\beebyams\beebasm
\beebasm -i .\compress\compress.asm -do .\compress\compres.ssd -boot compress -v -title compress