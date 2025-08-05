INCLUDE "VERSION.asm"
INCLUDE "SYSVARS.asm"			; OS constants
INCLUDE "BEEBINTS.asm"			; A% to Z% as a ... z
INCLUDE "TELETEXT.asm"
APtr           = $00A8
\APtr+1           = $00A9
BPtr           = $00AA
\BPtr+1           = $00AB
\EscapeFlag     = $00FF
L0360           = $0360
FilenameLo      = $0A5D
FilenameHi      = $0A5E
LoadAddressLow  = $0A5F
LoadAddressHigh = $0A60
L0A61           = $0A61
L0A62           = $0A62
L0A63           = $0A63
ExecHiByte      = $0A64
L0A66           = $0A66


                org     $0900

.Start          LDA     #$1  \commandline tail
                LDY     #$00
                LDX     #$A8
                JSR     OSARGS \return address in A8 A9

                LDA     APtr
                STA     FilenameLo
                LDA     APtr+1
                STA     FilenameHi
                LDX     #$5D
                LDY     #$0A
                LDA     #OSFILEReadFileInfo% \controlblock &A5D
                JSR     OSFILE

                CMP     #OSFILEReturnObjectNotFound%
                BNE     HaveAFile

                BRK
                EQUB    $D6

                EQUS    "File not found",$00

.HaveAFile      LDA     #OSBYTEScreenModeYCurrentCharX%
                JSR     OSBYTE

                LDA     ExecHiByte
                LSR     A	\hi nibble to low nibble -wmap =&E!
                LSR     A
                LSR     A
                LSR     A
                STA     BPtr
                CPY     BPtr	\mode from osbytecall
                BEQ     currentmodeok \so can externally set pallet?

                LDA     #$16 \mode
                JSR     OSWRCH

                LDA     BPtr	\setmode
                JSR     OSWRCH

.currentmodeok  LDA     #ReadBaseAddressXMode%
                LDX     BPtr  \mode no
                JSR     OSBYTE

                TXA 			\mode lowbite
                PHA
                TYA				\mode hibyte
                PHA
                LDA     L0A66
                BEQ     L097C

                STX     LoadAddressLow
                STY     LoadAddressHigh \so ignores load address!
                LDA     #$FF
                STA     L0A61 \set for load
                STA     L0A62 \set for load
                LDA     #$00
                STA     L0A63 
                LDX     #$5D
                LDY     #$0A
                LDA     #OSFILELoadFile% \fileblock 0A5D
                JSR     OSFILE

                JMP     L09BE

.L097C          STX     BPtr
                STY     BPtr+1
                LDX     FilenameLo
                LDY     FilenameHi
                LDA     #OSFINDOpenChannelforInput%
                JSR     OSFIND

.readfileloop   PHA				\file handle
                BIT     EscapeFlag \Bit 7 is set if an unserviced escape is pending
                BMI     waitloop \

                TAY				\Y = file handle
                JSR     OSBGET \getbytefromopenfile

                BCS     waitloop

                PHA
                JSR     OSBGET

                BCS     L09B6

                TAX
                PLA
                LDY     #$00
.L09A0          STA     (BPtr),Y
                INY
                DEX
                BNE     L09A0

                DEY
                TYA
                SEC
                ADC     BPtr
                STA     BPtr
                LDA     BPtr+1
                ADC     #$00
                STA     BPtr+1
                PLA
                BNE     readfileloop

.L09B6          PLA
.waitloop       PLA
                TAY
                LDA     #OSFINDCloseChannel%
                JSR     OSFIND

.L09BE          PLA
                STA     APtr+1
                PLA
                STA     APtr
                LDA     L0A63
                STA     BPtr
                LDA     ExecHiByte
                STA     BPtr+1
                LDX     #$00
                LDY     L0360
.L09D3          JSR     L0A49

                LDA     BPtr
                AND     #$07
                JSR     OSWRCH

                JSR     L0A52

                JSR     L0A3C

                INX
                CPX     #$08
                BEQ     L09FA

                CPX     #$04
                BNE     L09F6

                LDA     LoadAddressLow
                STA     BPtr
                LDA     LoadAddressHigh
                STA     BPtr+1
.L09F6          DEY
                BPL     L09D3

                RTS

.L09FA          DEY
                BMI     L0A3B

                DEX
                LDY     #$00
.L0A00          INX
                JSR     L0A49

                LDA     (APtr),Y
                AND     #$0F
                JSR     OSWRCH

                JSR     L0A52

                INX
                JSR     L0A49

                LDA     (APtr),Y
                LSR     A
                LSR     A
                LSR     A
                LSR     A
                JSR     OSWRCH

                JSR     L0A52

                INY
                CPX     L0360
                BCC     L0A00

                TYA
                CLC
                ADC     APtr
                STA     BPtr
                LDA     #$00
                ADC     APtr+1
                STA     BPtr+1
                TYA
                ASL     A
                TAY
                DEY
.L0A34          LDA     (BPtr),Y
                STA     (APtr),Y
                DEY
                BPL     L0A34

.L0A3B          RTS

.L0A3C          ROR     BPtr+1
                ROR     BPtr
                ROR     BPtr+1
                ROR     BPtr
                ROR     BPtr+1
                ROR     BPtr
                RTS

.L0A49          LDA     #$13
                JSR     OSWRCH

                TSX
                JMP     OSWRCH

.L0A52          LDA     #$00
                JSR     OSWRCH

                JSR     OSWRCH

                JMP     OSWRCH
.end

\A5D lo of OSArgs filename
\A5E hi of OSArgs filename
\A5F-A63 load address
\A64-A68 exec address
\A69-A6C Length

		\00 LSB address
		\01 MSB address
		\02-05 load address
		\06-09 execute address
		\&0A - &D length
		\&0E 0 = unlocked &A locked

.BeebDisEndAddr
SAVE "Scrload",Start,end
\ ./tools/beebasm/beebasm.exe -i ./SCRload.asm -do ./build/SCRload.ssd -boot SCRload -v -title SCRload


