\Get input 
	IF __DEBUG
		.gti
		{
		LDA #OSBYTEReadCharacterFromBuffer%
		LDX #OSBYTEXKeyboardBuffer%
		JSR OSBYTE
		BCS gti \no character
		RTS
		}
	ENDIF	
		.getcurrentdrive
		{
		\see https://stardot.org.uk/forums/viewtopic.php?p=30012&hilit=assembler+selected+drive#p30012
		\lDA #OSGBPBGetLibraryName%
		\LDX #LO(conb)
		\LDY #HI(conb)
		\JSR OSGBPB
		\Hack
		LDA OScurrentDrive%
		CLC
		ADC #'0'
		IF __DEBUG
			{
			LDA OScurrentDrive%
			CLC
			ADC #'0'
			JSR OSASCI
			LDX #&FF
			.aa
			INX
			LDA debugtext,X
			JSR OSASCI
			CMP #&D
			BNE aa
			BEQ ab
			.debugtext
			EQUS " = Currentdrive "
			EQUB &D
			.ab
			JSR gti
			}
		ENDIF
		\LDA osgbpbdata%+1
		LDA OScurrentDrive%
		CLC
		ADC #'0'		
		RTS \RTS
		}
		.setrequesteddrive
		{
		LDX #dricmd%
		JSR initprepcmd
		LDA RequestedDrive%
		STA strA%+3
		JMP execmd \RTS
		}
		
		.execmd
		{
		IF __DEBUG
			{
			LDY #&FF
			.aa
			INY
			LDA strA%,Y
			JSR OSASCI
			CMP #&D
			BNE aa
			JSR gti 
			}
		ENDIF
		LDY #HI(strA%)
		LDX #LO(strA%)
		JMP OSCLI \RTS
		}
		
		.initprepcmd
		{
		LDA #0
		STA strAoffset 
		}
		.prepcmd
		{
		JSR MoveToRec
		LDX strAoffset
		LDY #0
		.ey
		LDA (TextAdd),Y
		CMP #&80
		BCC am
		AND #&7F
		STA strA%,X
		INX
		STX strAoffset
		LDA #&D
		STA strA%,X
		RTS
		.am
		STA strA%,X
		INX
		INY
		BNE ey
		}
		.diserror
		{
		JSR MoveToRec
		JMP PrintRecord
		}
		.PrintRecord
		{
		IF __OSARGSOptions = TRUE
			{
			LDA OptionBit%
			AND #OSARGSbitOptionQuiet%
			BEQ cont
			RTS
			.cont
			}
		ENDIF
		LDY #0
		.bc
		LDA (TextAdd),Y
		CMP #&80
		BCC bd
		AND #&7F
		JMP OSASCI \RTS
		RTS
		.bd
		JSR OSASCI
		INY
		BNE bc
		}
		.MoveToRec
		{
		LDA #LO(CommandAndText)
		STA TextAdd
		LDA #HI(CommandAndText)
		STA TextAdd+1
		LDY #0
		.ba
		DEX
		BNE bb
		RTS
		.bb
		LDA (TextAdd),Y
		INY
		CMP #&80
		BCC bb
		CLC
		TYA
		ADC TextAdd
		STA TextAdd
		LDA #0
		ADC TextAdd+1
		STA TextAdd+1
		LDY #0
		BEQ ba
		}

\---------------------------		
		.startexec
\---------------------------		
		{
		\set current drive
		JSR getcurrentdrive
		STA RequestedDrive%
		JSR OSARGSinit
		\ X has no of arguments
		\as has OSARGSNoofArgs%
		CPX #1
		BCS havecommands
		LDX #usage%
		JMP diserror \RTS
		.havecommands
		JSR OSARGSFileNameToOSARGSPram
		LDX OSARGSNoofArgs%
		CPX #2
		BCC Justfilename
		JSR OSARGSGetDrive \parm 2
		LDX OSARGSNoofArgs%
		CPX #3
		\issues din cmd
		LDX #dincmd%
		JSR initprepcmd
		LDX #2
		JSR OSARGSargXtoOSARGSStrLenA
		LDX #3
		JSR OSARGSargXtoOSARGSStrLenA
		LDX strAoffset
		\DEX
		LDA #&D
		STA strA%,X 
		JSR execmd
		.Justfilename
		JSR setrequesteddrive
		}
		