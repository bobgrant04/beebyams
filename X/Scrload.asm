L00A8           = $00A8
L00A9           = $00A9
L00AA           = $00AA
L00AB           = $00AB
L00FF           = $00FF
L0360           = $0360
L0A5D           = $0A5D
L0A5E           = $0A5E
L0A5F           = $0A5F
L0A60           = $0A60
L0A61           = $0A61
L0A62           = $0A62
L0A63           = $0A63
L0A64           = $0A64
L0A66           = $0A66
OSFIND          = $FFCE
OSBPUT          = $FFD4
OSBGET          = $FFD7
OSARGS          = $FFDA
OSFILE          = $FFDD
OSRDCH          = $FFE0
OSASCI          = $FFE3
OSNEWL          = $FFE7
OSWRCH          = $FFEE
OSWORD          = $FFF1
OSBYTE          = $FFF4
OSCLI           = $FFF7

                org     $0900

.Start          LDA     #$01
                LDY     #$00
                LDX     #$A8
                JSR     OSARGS

                LDA     L00A8
                STA     L0A5D
                LDA     L00A9
                STA     L0A5E
                LDX     #$5D
                LDY     #$0A
                LDA     #$05
                JSR     OSFILE

                CMP     #$00
                BNE     L0931

                BRK
                EQUB    $D6

                EQUS    "File not found",$00

.L0931          LDA     #$87
                JSR     OSBYTE

                LDA     L0A64
                LSR     A
                LSR     A
                LSR     A
                LSR     A
                STA     L00AA
                CPY     L00AA
                BEQ     L094D

                LDA     #$16
                JSR     OSWRCH

                LDA     L00AA
                JSR     OSWRCH

.L094D          LDA     #$85
                LDSCRload     L00AA
                JSR     OSBYTE

                TXA
                PHA
                TYA
                PHA
                LDA     L0A66
                BEQ     L097C

                STX     L0A5F
                STY     L0A60
                LDA     #$FF
                STA     L0A61
                STA     L0A62
                LDA     #$00
                STA     L0A63
                LDX     #$5D
                LDY     #$0A
                LDA     #$FF
                JSR     OSFILE

                JMP     L09BE

.L097C          STX     L00AA
                STY     L00AB
                LDX     L0A5D
                LDY     L0A5E
                LDA     #$40
                JSR     OSFIND

.L098B          PHA
                BIT     L00FF
                BMI     L09B7

                TAY
                JSR     OSBGET

                BCS     L09B7

                PHA
                JSR     OSBGET

                BCS     L09B6

                TAX
                PLA
                LDY     #$00
.L09A0          STA     (L00AA),Y
                INY
                DEX
                BNE     L09A0

                DEY
                TYA
                SEC
                ADC     L00AA
                STA     L00AA
                LDA     L00AB
                ADC     #$00
                STA     L00AB
                PLA
                BNE     L098B

.L09B6          PLA
.L09B7          PLA
                TAY
                LDA     #$00
                JSR     OSFIND

.L09BE          PLA
                STA     L00A9
                PLA
                STA     L00A8
                LDA     L0A63
                STA     L00AA
                LDA     L0A64
                STA     L00AB
                LDX     #$00
                LDY     L0360
.L09D3          JSR     L0A49

                LDA     L00AA
                AND     #$07
                JSR     OSWRCH

                JSR     L0A52

                JSR     L0A3C

                INX
                CPX     #$08
                BEQ     L09FA

                CPX     #$04
                BNE     L09F6

                LDA     L0A5F
                STA     L00AA
                LDA     L0A60
                STA     L00AB
.L09F6          DEY
                BPL     L09D3

                RTS

.L09FA          DEY
                BMI     L0A3B

                DEX
                LDY     #$00
.L0A00          INX
                JSR     L0A49

                LDA     (L00A8),Y
                AND     #$0F
                JSR     OSWRCH

                JSR     L0A52

                INX
                JSR     L0A49

                LDA     (L00A8),Y
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
                ADC     L00A8
                STA     L00AA
                LDA     #$00
                ADC     L00A9
                STA     L00AB
                TYA
                ASL     A
                TAY
                DEY
.L0A34          LDA     (L00AA),Y
                STA     (L00A8),Y
                DEY
                BPL     L0A34

.L0A3B          RTS

.L0A3C          ROR     L00AB
                ROR     L00AA
                ROR     L00AB
                ROR     L00AA
                ROR     L00AB
                ROR     L00AA
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
.BeebDisEndAddr
SAVE "./SCRload/Scrload.bin",start,end
\ ./tools/beebasm/beebasm.eSCRloade -i ./SCRload.asm -do ./build/SCRload.ssd -boot SCRload -v -title SCRload


