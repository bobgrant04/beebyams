\** beebyams by RG

\** OS CONSTANTS

\zeropage
OScurrentDrive%=&CF
BPtr1Flag=&FF
OSTextPointer%=&F2
EscapeFlag =&FF

\oscalls

OSRDRM=&FFB9
GSINIT=&FFC2
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
GSREAD=&FFC5
\	On Entry:
\		   Address for string stored at .stringInputBufferAddressLow/High
\		   Y = offset into string
\	 On Exit:
\		   A = character read
\		   X is preserved
\		   Y = index of next character to be read
\		   Carry is set if end of string reached
\		   Overflow (V flag) is set if the character read was interpreted as a control code
OSFIND=&FFCE
		\A=
		OSFINDCloseChannel% =&00 	 \Close channel
		OSFINDOpenChannelforInput% =&40 	 \Open for input
		OSFINDOpenChannelforOutput% =&80 	 \Open for output
		OSFINDOpenChannelInAndOut% =&C0 	 \Open for update
OSGBPB=&FFD1
\A=
\=1	 \Write bytes using new pointer
\=2	 \Write bytes ignoring new pointer
\=3	 \Read bytes using new pointer
\=4	 \Read bytes ignoring new pointer
		OSGBPBTitleAndboot% =5	 \Get media title of CSD disk and boot option
			\&00  	length of title (n)
			\&01  	title in ASCII characters
			\&01+n  	startup option
			\&02+n  	drive number
			\&03+n 
		OSGBPBGetDirectoryName%=6	 \Get currently selected directory name
			\&00  	length of drive identity (n)
			\&01  	ASCII drive identity (drive number)
			\&01+n  	length of directory name (m)
			\&02+n  	directory name in ASCII characters
			\&02+n+m  	ownership: &00 - owner, &FF - public
			\&03+n+m 
		OSGBPBGetLibraryName%=7	 \Get current library name.
			\&00  	length of drive identity (n)
			\&01  	ASCII drive identity (drive number)
			\&01+n  	length of library name (m)
			\&02+n  	library name in ASCII characters
			\&02+n+m  	ownership: &00 - owner, &FF - public
			\&03+n+m 		
\=8	 \Read filenames from current directory
\=9	 \Reads work/login filename, command line tail or entries from specified directory
\=10	 \Read entries and information from specified directory
\=11	 \Read entries and extended information from specified directory

OSBPUT=&FFD4

OSBGET=&FFD7

OSARGS=&FFDA
\	On entry,
\		X points to a four byte zero page control block.
\		Y contains the file handle as provided by OSFIND, or
\		zero.
\		The accumulator contains a number specifying the action
\		required.
\	If Y is zero:
\		A=0 Returns the current filing system in A:
\			0 No filing system currently selected.
\			1 1200 baud cassette
\			2 300 baud cassette
\			3 ROM filing system
\			4 Disc filing system
\			5 Econet filing system
\			6 Telesoftware system
\           ........    
\	A=1 Returns the address of the rest of the command line in the base page control block
\	    This gives access to the parameters passed with *RUN or *command.
\	A=&FF Update all files onto the media, ie ensure that the latest copy of the 
\	      memory buffer is saved.
\	If Y is not zero:
\		A=0 Read sequential pointer of file (BASIC PTR#)
\		A=1 Write sequential pointer of file
\		A=2 Read length of file (BASIC EXT#)
\		A=&FF Update this file to media
OSFILE=&FFDD
	\A=....
	OSFILEReadFileSystemInfo%=&FD 	\Read file system information (Internal Name)		 
	OSFILEVerifyFile% =&FE 	 		\Verify file	 
	OSFILELoadFile% =&FF 	 		\Load file
	OSFILESaveFile% =0	 			\Save file
		\00 LSB address
		\01 MSB address
		\02-05 load address
		\06-09 execute address
		\&0A - &D start address to save from
		\&0E - &11 end address +1 to save from
		\LSB first
	OSFILEReadFileAttibutes% = 1	\Write load, exec, attrs
	OSFILEWriteLoadAddress% = 2	 	\Write load address
	OSFILEWriteExecutionAddress% =3	\Write execution address
	OSFILEWriteAttributes% =4	 	\Write attributes
	OSFILEReadFileInfo% =5	 		\Read object information
		\00 LSB address
		\01 MSB address
		\02-05 load address
		\06-09 execute address
		\&0A - &D length
		\&0E 0 = unlocked &A locked
	OSFILELocked% =&A
		\LSB first
	OSFILEdelete%	=6 				\Delete object
	OSFILECreateFile% =7	 		\Create empty file
	OSFILECreateADirectory%	=8	 	\Create a directory
	\Errors
	OSFILEReturnExecuteOnly% =&FF 	\Execute-only file
	OSFILEReturnObjectNotFound%=&00 \Object not found
	OSFILEReturnFileFound% =&01 	\File found
	OSFILEReturnDirecoryNotFound% =&02 \Directory found
	OSFILEReturnImageFileFound% =&03 \Image file found (file accessible as a directory)
	OSFILEReturnUnresolvedLink%=&04 \Unresolved symbolic link found
	\00 LSB address
	\01 MSB address
	\02-05 load address
	\06-09 execute address
	\&0A - &D start address to save from
	\&0E - &11 end address +1 to save from
	\LSB first
	
OSBYTE=&FFF4
\\\&00 (Acorn MOS 0.10)
\    OS Version Number Report
\    X=0 Report version number as an error
\    X=1 Return machine type in X
\        On exit X=0 Electron/OS 1.00
\                X=1 BBC OS 1.20/American BBC
\                X=2 BBC B+
\                X=3 Master 128
\                X=4 Master ET
\                X=5 Master Compact
\                X=6 ARM based machine
\                X=7 ARM Springboard
\&01 (Acorn MOS 1.00)
\    Write User Flag (exits with X=old value)
\    On entry X=value to write
\ On exit X=old value
\    This flag is unused by the OS,and is simply there to provide an
\    OSByte location without the user needing to write OSByte
\    decoding code
\&02 (Acorn MOS 1.00)
\    Specify Input Stream (exits with X=b0 of old value)
\    X=0 Use the keyboard for input
\    X=1 Use the serial circuit for input
\    X=2 Use the keyboard for input,but listen to the serial port too
\        such that bytes are accepted and simply buffered for later 
\        inspection
\&03 (Acorn MOS 1.00)
\    Specify Output Stream(s) (exits with X=old value)
\    X=b0=1 enable serial driver
\      b1=1 disable VDU driver
\      b2=1 disable VDU printer stream
\      b3=1 enable printer (regardless of VDU2/VDU3 state)
\      b4=1 disable spooled output
\      b5   unused
\      b6=1 disable printer,unless VDU1 is used
\      b7   unused
\    (RISC OS 1.00)
\      b5=1 calls VDUXV instead of VDU drivers
\    Notes b1 is not the same as issuing VDU21,as the printer remains
\          active throughout.
\          b3 is not the same as issuing VDU2,as all bytes except the
\          printer ignore character are put in the printer stream.Of course
\          b2 and b6 must also be clear!
\&04 (Acorn MOS 0.10)
\    Define action of cursor editing keys (exits with X=old value)
\    X=0 Cursor keys have editing effect (default)
\    X=1 Cursor keys return ASCii values 135-139
\    X=2 Cursor keys become soft keys 11-15
\    (Acorn MOS 5.00 only)
\    X=3 Cursor keys emulate the joystick (with copy acting as 'FIRE')
\&05 (Acorn MOS 0.10)
\    Printer Driver Type (exits with X=old value)
\    X=0 Null printer (sink)
\    X=1 Parallel printer
\    X=2 Serial printer
\    X=3 User printer driver
\    X=4 Net printer
\    X>4 Unused
\&06 (Acorn MOS 0.10)
\    Printer Ignore Character (exits with X=old value)
\    X=character number not to print or 0 to print all characters
\&07 (Acorn MOS 0.10)
\    RS423 Baud Receive rate
\    X=0 9600 (default) 
\    X=1 75             
\    X=2 150            
\    X=3 300            
\    X=4 1200
\    X=5 2400
\    X=6 4800  
\    X=7 9600    
\    X=8 19200

\&08 (Acorn MOS 0.10)
\    RS423 Baud Transmit Rate
\    X=0 9600 (default) 
\    X=1 75             
\    X=2 150            
\    X=3 300            
\    X=4 1200
\    X=5 2400
\    X=6 4800  
\    X=7 9600    
\    X=8 19200
\    On exit X=old ULA setting
\&09 (Acorn MOS 0.10)
\    First Color Duration (exits with X=old value)
\    X=duration of first flash colour in cs,or 0 to hold still
\&0A (Acorn MOS 0.10)
\    Second Color Duration (exits with X=old value)
\    X=duration of second flash colour in cs,or 0 to hold still
\&0B (Acorn MOS 0.10)
\    Auto Repeat Delay (exits with X=old value)
\    X=delay before keys start to autorepeat in cs,or 0 for default
\&0C (Acorn MOS 0.10)
\    Auto Repeat Period (exits with X=old value)
\    X=delay between key repeats in cs,or 0 for default
\&0D (Acorn MOS 1.00)
\    Disable Event (exits with X=old value) Y=0
DisableOutputBufferEmptyEvent% =0\     X=0 output buffer empty event
\        X=1 input buffer full
\        X=2 character entering buffer
\        X=3 ADC conversion complete
\        X=4 vsync event
\        X=5 interval timer crossed 0
\        X=6 ESCAPE pressed event
\        X=7 RS423 error
\        X=8 network error
\        X=9 user event

\    This call decrements the respective count for the event.When it finally 
\    reaches zero the event is stopped.
\&0E (Various)
\    Enable Event (exits with X=old value)
\    This call increments the count for the chosen event.Non zero count means
\    that the event will be enabled.
\&0F (Acorn MOS 0.10)
\    Flush all buffers/input buffer
\    X=0 Flushes all buffers
\    X=1 Flushes just the input buffer
\&10 (Acorn MOS 0.10)
\    Set maximum number of ADC chanel (exits with X=old value)
\    X=0 no ADC sampling takes place
\    X=1..4 sets the maximum channel number to sample
\&11 (Acorn MOS 1.00)
\    Force an ADC conversion (exits with X=channel chosen)
\    X=channel number to start conversion on
\&12 (Acorn MOS 1.00)
\    Reset F-key definitions
\&13 (Acorn MOS 1.00)
\    Wait for Vertical Retrace
\    This call returns when the electron beam starts drawing another field
\&14 (Acorn MOS 1.00)
\    Explode user defined character font RAM (exits with X=new value of OSHWM)
\    X=0 characters &80 to &9F only are exploded (default)
\    X=1 characters &A0 to &BF are exploded
\    X=2 characters &C0 to &DF are exploded
\    X=3 characters &E0 to &FF are exploded
\    X=4 characters &20 to &3F are exploded
\    X=5 characters &40 to &5F are exploded
\    X=6 characters &60 to &7F are exploded
\    Notes If a Tube coprocessor is fitted then all fonts are exploded
\          If an attempt is made to redefine a character that is not exploded
\          then the definition of a corresponding character in a section of
\          font that is exploded is changed and the character will then map to 
\          several places within the font
\    (Acorn MOS 3.20)
\    Reset to standard user defined character set
\    X=0 resets to the ROM font
\&15 (Acorn MOS 1.00)
			\    Flush Selected Buffer
			OSBYTEFlushSelectedBuffer% =&15
			\x=
			OSBYTEXKeyboardBuffer% =0 			\Keyboard
			OSBYTEXSerialInBuffer% =1 			\Serial input
			OSBYTEXSerialOutBuffer% =2 			\Serial output
			OSBYTEXPrinterBuffer% =3 			\Printer
			OSBYTEXSoundChannelBuffer0% =4 	\Sound channel 0
			OSBYTEXSoundChannelBuffer1% =5 	\Sound channel 1
			OSBYTEXSoundChannelBuffer2% =6 	\Sound channel 2
			OSBYTEXSoundChannelBuffer3% =7 	\Sound channel 3
			OSBYTEXSpeechBuffer%  =8 			\Speech
\    (RISC OS 1.00)
\    X=9 Mouse
\&16 (Electron OS & Acorn MOS 3.20 only)
\    Increment Polling Semaphore
\    This call increments a counter,which if non zero will cause 100 service
\    calls (type &15) per second to be sent the paged ROMs.This allows a way 
\    for ROMs to poll hardware which doesn't offer interrupts.
\&17 (Electron OS & Acorn MOS 3.20 only)
\    Decrement Polling Semaphore
\    This call decrements a counter,which when zero will stop the (type &15)
\    polling calls from being sent to ROMs at 100Hz.
\&18 (Electron OS only)
\    Select external sound system.
\    This call enters with 'some parameter' in X which will be used to wake up
\    additional sound hardware on the Electron.
\&19 (Acorn MOS 3.20)
\    Reset a group of font definitions
\    X=0 resets 32-255
\    X=1 resets 32-63
\    X=2 resets 64-95
\    X=3 resets 96-127
\    X=4 resets 128-159
\    X=5 resets 160-191
\    X=6 resets 192-223
\    X=7 resets 224-255
\&20 (Watford 32K shadow RAM)
\    Read base of display RAM
\    As per OSByte &84, except the value returned takes into account the RAM
\    board being active.
\&21 (Watford 32K shadow RAM)
\    Read base of display RAM for a given mode
\    As per OSByte &85, except the value returned takes into account the RAM
\    board being active.
\&22 (Watford 32K shadow RAM)
\    Switch shadow RAM region
\    This permits the shadow RAM region to be manually paged out so that user
\    programs can access the RAM, though the routine calling this OSByte must
\    itself be below &3000 otherwise it will also be paged out.
\    X=b0=0 to select BBC motherboard RAM
\        =1 to select the shadown RAM board
\      b6=0 to write the current state
\        =1 to read the current state (returned in X)
\      b7=0 force the setting
\        =1 use the internal 8 deep stack (b6 determines whether to push/pull)
\&23 (Watford 32K shadow RAM)
\    Return location of support firmware workspace
\    X & Y contain the address below PAGE.
\&27 (Watford 32K shadow RAM)
\
\    Set buffer number 
\    The new buffer number = (old number AND Y) EOR X, to select which buffer 
\    will use the remaining 12K of the shadow RAM board as an extended operating
\    system buffer. See OSByte &15 for buffer numbers.
\&32 (NFS 3.34)
\    Poll transmission of Econet operation
\    On exit X=b7 set if still in progress
\              b6 set if failed
\              b5 set to zero
\              b4-b0 error code if applicable
\    Only one transmit operation can be outstanding so no parameters are 
\    required on entry,and X=0 if successful.
\    The defined error codes are
\              &40=line jammed
\              &41=some part of the 4 way handshake failed
\              &42=no scout acknowledge in the 4 way handshake
\              &43=no clock
\              &44=bad transmit control block
\&33 (NFS 3.34)
\    Poll reception of Econet operation
\    This call checks the status of the Econet receive block whose handle is
\    passed in X.
\    If the call returns with bit 7 of X set a complete block has been 
\    received.
\&34 (NFS 3.34)
\    Delete an Econet receive control block
\    This call deletes the pending Econet receive block whose handle is 
\    passed in X.
\&35 (NFS 3.34)
\    Terminate a *REMOTE session.
\    Taking no parameters,this is directly equivalent to *ROFF.
\&44 (Acorn MOS 2.00)
\    Test sideways RAM presence
  \  On exit X=b0 set if slot 4 is RAM
 \             b1 set if slot 5 is RAM
 \             b2 set if slot 6 is RAM
 \             b3 set if slot 7 is RAM
\&45 (Acorn MOS 2.00)
\    Test PSEUDO/Absolute usage
\    Sideways RAM can either be allocated as holding ROM images or as extended
\    memory using pseudo addressing.This call identifies RAM useage:
\    On exit X=b0 set if slot 4 is being used as pseudo RAM
\              b1 set if slot 5 is being used as pseudo RAM
\              b2 set if slot 6 is being used as pseudo RAM
\              b3 set if slot 7 is being used as pseudo RAM
\    (???)
\    Terminal Function
\&46 (RISC OS 1.00)

\&47 (RISC OS 1.00)

\&60 (Terminal 1.20)
\    Used for communication with service code residing in the I/O processor.
\    X=b7     set for INSV/REMV vector operation (b0 set to install, clear to remove)
\    X=0      turn off receive flow control
\    X=1      turn on receive flow control
\    X=2      turn off transmit flow control
\    X=3      turn on transmit flow control
\    X=4..127 aliases of commands 2 and 3
\&6A (RISC OS 1.00)
\    Select pointer/activate mouse (on exit X=old value)
\    X=b0..2 select pointer defined by OSWord 21 (or 0 for off)
\    X=b7    unlink visible pointer from mouse if set
\&6B (Acorn MOS 3.20 & Acorn MOS 5.10 only)
\    External/Internal 1MHz Bus (on exit X is preserved)
\    Y=0 X=0 select external bus running at 2MHz
\        X=1 select internal bus running at 1MHz
\    This call allows the selection of either the external cartridge slot style
\    of '1MHz' bus,or the internal 1MHz bus under the keyboard.In the case of
\    the Master Compact X=1 has no effect as it has no connectors under the
\    keyboard
\&6C (Acorn MOS 3.20)
\    Main/Shadow RAM Usage
\    Y=0 X=0 Main memory appears from &3000 to &7FFF
\        X=1 Shadow memory appears from &3000 to &7FFF
\    This has immediate effect and allows the user to make use of the 20k of
\    extra RAM for other purposes.
\&6D (Acorn MOS 3.20)
\    Make Temporary FS permanent (no parameters)
\    This may be necessary if the action the temporary filing system wants to
\    perform requires it to (for example) claim NMIs,which only the current FS
\    may do.
\&6E (Watford DFS pre 1.43 and DDFS pre 1.53)
\    Set Double step mode for drives,allowing allows a 40 track disc to be 
\    read in an 80 track drive.
\    (NB. Double Step mode should not be used to write to a 40 track disc
\    as the results could be unpredictable when the disc is subsequently
\    read on a 40 track drive.)
\    Y=0   X=<drivenum>   Single Step
\    Y=&FF X=<drivenum>   Double Step.
\    This was later withdrawn in favour of *OPT40 and *OPT80 commands
\&6F (Watford DFS post 1.43 and DDFS post 1.53)
\    Read last drive used for *LOAD or *RUN operations
\    X=<drivenum> on exit
\&70 (Acorn MOS 3.20)
\    Select Main/Shadow for VDU access
\    Y=0 X=0 Use whatever the default for the current mode is
\        X=1 Use main memory
\        X=2 Use shadow memory
\    (RISC OS 1.00)
\    The value of X can be greater than 2 as well,and instructs the VDU
\    drivers to use the bank at screenbase+(X*modesize)
\&71 (Various)
\    Select Main/Shadow for Display hardware
\    Y=0 X=as per OSByte &70
\    The value of X defines which bank the hardware will output
\&72 (Acorn MOS 1.20)
\    Write to Shadow/Main toggle
\    Y=0 X=0 force use of shadow memory on future mode changes
\        X=1 only use shadow memory if mode number is > 127
\&73 (Electron OS only)
\    Blank/restore palette
\    X=0  restores the palette
\    X<>0 sets the whole palette to black if is high resolution mode
\    Software using NMIs in high res modes can prevent snow appearing on the
\    screen during NMIs (due to ULA reuse) by blanking the palette
\&74 (Electron OS only)
\    Reset internal sound system
\    This call enters with 'some parameter' in X which resets the built in sound
\    system
\&75 (RISC OS 1.00)

\&76 (Acorn MOS 1.20)
\   Reflect keyboard status in LEDs
\   If the keyboard status byte (CAPs lock etc...) is written to with
\    OSByte 202 then the LEDs should be updated by using this call.Under
\    normal circumstances the LEDs look after themselves
\    (Acorn MOS 2.00 only)
\    Read ctrl/Shift keys
\    Returns with processor status C=1=CTRL key pressed
\                                  N=1=SHIFT key pressed
\&77 (Acorn MOS 1.20)
\    Close all Spool/Exec files
\&78 (Acorn MOS 1.20)
\    Key Pressed Data
\    X=1st key pressed (internal number)
\    Y=2nd key pressed (internal number)
\    This writes the rollover key numbers,but will not normally cause 
\    any keys to be inserted in the buffer as it does not affect the 
\    rollover counter
\    (RISC OS 1.00)
\    X=0 Y=0 locks the rollover mechanism until all keys are released
\&79 (Acorn MOS 1.20)
\    Keyboard Scan
\    Y=0 X=internal keynumber EOR&80 for single key check
\    On exit X<0 if the key was being pressed
\    Y=0 X=lowest internal keynumber to start at (for a range of keys) 
\    On exit X=earliest keynumber being pressed or &FF for none
\&7A (Acorn MOS 1.20)
\    Keyboard Scan from &10
\    Simply performs OSByte &79 with X=16
\&7B (Acorn MOS 1.20)
\    Printer Dormancy Warning
\    X=3 informs the OS that the printer driver has gone dormant and
\        any future characters being printed will wake it up again
\&7C (Acorn MOS 0.10)
\    Clear ESCAPE Condition informing Tube if necessary
\&7D (Acorn MOS 0.10)
\    Set ESCAPE conditon
\    This call simulates pressing the ESCAPE key,informing the Tube if
\    necessary but does not cause an ESCAPE event
\&7E (Acorn MOS 0.10)
\    Acknowledge ESCAPE Condition
\    This call tries to clear any ESCAPE condition,and (if enabled with
\    OSByte 230) appropriate side effects.
\    On exit X=255 successfully cleared condition
\            X=0   the ESCAPE condition was not cleared (or no ESCAPE condition)
\&7F (Acorn MOS 0.10)
\    Check for EOF 
\    X=file handle
\\\    On exit X=0 it the EOF has not been reached,otherwise it has.
\&80 (Acorn MOS 0.10)
\    Read ADC Channel/Buffer status
\    X=0 returns X=b0 fire button status
\                  b1 fire button
\                Y=last ADC channel number read
\    X=1..4 returns X=low byte of ADC channel X
\                   Y=high byte of ADC channel X
\    Y=255 X=255 Keyboard buffer level
\          X=254 Serial input buffer level
\          X=253 Serial output buffer level
\          X=252 Printer buffer level
\          X=251 Sound channel 0 buffer level
\          X=250 Sound channel 1 buffer level
\          X=249 Sound channel 2 buffer level
\          X=248 Sound channel 3 buffer level
\          X=247 Speech buffer level
\    (VFS)
\    X=5 maximum mouse X threshold (where the pointer changes shape)
\    X=6 maximum mouse Y threshold (where the pointer changes shape)
\    X=7 buffered mouse X position
\    X=8 buffered mouse Y position
\    X=9 mouse buttons b0=left b1=centre b2=right
\    (RISC OS 1.00)
\    X=7 buffered mouse X position
\    X=8 buffered mouse Y position
\    Y=255 X=246 Mouse buffer level
\&81 (Acorn MOS 0.10)
\    Read Key with Time Limit (do INKEY)
\    Action: Scan for any key within time limit
\     X=0..255
\     Y=0..127
\     On exit Y=0   C=0 means X contains ASCii value of the character read
\             Y=255 C=1 timed out
\             Y=27  C=1 ESCAPE was pressed
 \   Action: Read OS version
 \    X=0
\     Y=255
\     On exit X=value identifying OS
\             X=0   BBC B with MOS 0.10
\             X=1   Acorn Electron MOS
\             X=244 Master 128 MOS 3.26
\             X=245 Compact
\             X=247 Master ET
\             X=250 Acorn ABC
\             X=251 BBC B+ 64/128 (MOS2.00)
\             X=252 BBC Micro (West German MOS)
\             X=253 Master 128 MOS 3.20
\             X=254 BBC Micro (American MOS 1.10)
\             X=255 BBC Micro OS1.00/1.20
\             X=&A0 Arthur 1.20
\             X=&A1 RISC OS 2.00
\             X=&A2 RISC OS 2.01
\             X=&A3 RISC OS 3.00
\             X=&A4 RISC OS 3.10 and 3.11
 \            X=&A5 RISC OS 3.50
 \            X=&A6 RISC OS 3.60
\             X=&A7 RISC OS 3.70
\             X=&A8 RISC OS 3.80 (publically released as 4.0x)
\             X=&A9 RISC OS 4 Select
\             X=&AA RISC OS 5.0X
\    Action: Scan for a range of keys
\     X=1..127 lowest internal key number to start at EOR&7F
\     Y=255
\     On exit X=internal key number pressed (or 255 for none)
\    Action: Scan for a particular key
\     X=128..255 internal key number to scan for EOR&80
\     Y=255
\     On exit X=Y=0 for not pressed
\             X=Y=255 the key was being pressed
\&82 (Acorn MOS 0.10)
\    Read High Order Address
\    Returns X=lo byte of 32 bit address of this machine
\            Y=hi byte of 32 bit address of this machine
\    ie.this machine's 32 bit address is &YYXX0000 upwards
\&83 (Acorn MOS 0.10)
\    Read OSHWM
\    This returns the value of 'PAGE' in X and Y
\&84 (Acorn MOS 0.10)
\    Read base of display RAM
\    On exit X and Y point to the first byte of screen RAM
\&85 (Acorn MOS 0.10)
		ReadBaseAddressXMode% =&85
\    X=mode number 
\    On exit X and Y point to the first byte of screen RAM if MODE X were chosen
\&86 (Acorn MOS 0.10)
\    Text cursor position
\    Returns X and Y of the current cursor position (or input cursor if in
\    editing mode due to cursor keys)
\&87 (Acorn MOS 0.10)
		OSBYTEScreenModeYCurrentCharX%= &87
\    Character at text cursor and screen MODE
\    On exit X=character at current cursor position (or 0 if unreadable)
\            Y=current mode number (shadow modes DO NOT return with bit 7 set)
\&88 (Acorn MOS 1.00)
\    Perform *CODE
\    The call performs a JSR to the current location of USERV,with X and Y
\    set to whatever the OSByte was called with
\&89 (Acorn MOS 0.10)
\    Cassete Motor Control
\    X=0 relay turned off 
\    X=1 relay turned off
\    The default tape filing system enters with Y=0 for write operations and Y=1
\    for read operations.Hence,a machine could be adapted to have seperate read
\    and write drives.
\&8A (Acorn MOS 1.00)
			\Place character into buffer
			OSBYTEPlaceCharacterIntoBuffer% =&8A
			\X=buffer number defined &15!
			\OSBYTEXKeyboardBuffer% =0 			\Keyboard
			\OSBYTEXSerialInBuffer% =1 			\Serial input
			\OSBYTEXSerialOutBuffer% =2 			\Serial output
			\OSBYTEXPrinterBuffer% =3 			\Printer
			\OSBYTEXSoundChannelBuffer0% =4 	\Sound channel 0
			\OSBYTEXSoundChannelBuffer1% =5 	\Sound channel 1
			\OSBYTEXSoundChannelBuffer2% =6 	\Sound channel 2
			\OSBYTEXSoundChannelBuffer3% =7 	\Sound channel 3
			\OSBYTEXSpeechBuffer%  =8 			\Speech
			\Y=character to place
\&8B (Acorn MOS 0.10)
\    Set filing system attributes (do *OPT)
\    This call is a direct equivalent to *OPTx,y
\&8C (Acorn MOS 0.10)
\    Select Tape FS at 1200/300 baud (do *TAPE)
\    X=0 perform *TAPE and select default speed (1200)
\    X=3 perform *TAPE at 300 baud
\    X=12 perform *TAPE at 1200 baud
\&8D (Acorn MOS 1.00)
\    Select RFS (do *ROM)
\&8E (Acorn MOS 1.00)
\    Enter Langauge ROM
\    X=socket number that the language ROM is in
\    If the Tube is active the ROM will be copied across to the coprocessor
\    The call does not return as the language resets the stack
\    (Acorn MOS 3.20)
\    If the ROM has been unplugged this will have no effect,or if the ROM is not
\    a language ROM the error 'This is not a language' will be raised
 \   (Acorn MOS 3.50)
\    If called with X=64+socket number then the ROM will not be relocated when
\    being transferred to the Tube and there is a relocation table present.
\&8F (Acorn MOS 1.00)
\    Issue SWR Service Request (on exit Y=response to request if appropriate)
\    X=request number
\    Y=parameter to pass (varies depending on the request number)
\&90 (Acorn MOS 0.10)
\    Set TV offset and interlacing (do *TVx,y)
\    X=vertical screen shift
\    Y=0/1 to turn off/on interlacing
\    On exit X and Y contain the old value.The settings will be effected on the
\    next MODE change
\&91 (Acorn MOS 1.00)
			OSBYTEReadCharacterFromBuffer% =&91
			\X=buffer number defined &15!
			\OSBYTEXKeyboardBuffer% =0 			\Keyboard
			\OSBYTEXSerialInBuffer% =1 			\Serial input
			\OSBYTEXSerialOutBuffer% =2 			\Serial output
			\OSBYTEXPrinterBuffer% =3 			\Printer
			\OSBYTEXSoundChannelBuffer0% =4 	\Sound channel 0
			\OSBYTEXSoundChannelBuffer1% =5 	\Sound channel 1
			\OSBYTEXSoundChannelBuffer2% =6 	\Sound channel 2
			\OSBYTEXSoundChannelBuffer3% =7 	\Sound channel 3
			\OSBYTEXSpeechBuffer%  =8 			\Speech
			\On exit Y=character got,or C=1 if the buffer was empty

\&92 (Acorn MOS 1.00)
\    Read FRED
\    X=offset within page &FC.On exit Y=byte read
\&93 (Acorn MOS 1.00)
\    Write FRED
\    X=offset within page &FC and Y=byte to write
\&94 (Acorn MOS 1.00)
\    Read JIM
\    X=offset within page &FD.On exit Y=byte read
\&95 (Acorn MOS 1.00)
\    Write JIM
\    X=offset within page &FD and Y=byte to write
\&96 (Acorn MOS 1.00)
\    Read SHELIA
\    X=offset within page &FE.On exit Y=byte read
\&97 (Acorn MOS 1.00)
\    Write SHELIA
\    X=offset within page &FE and Y=byte to write
\&98 (Acorn MOS 1.20)
\    Examine Buffer Status
\    X=buffer number
\    On exit C=0 Y=offset from address held at &FA to the next byte to get
\            C=1 buffer empty
\    (Acorn MOS 2.00)
\    The Y register actually contains the next value,not just an offset as with
\    the earlier OS.
\    Note Interrupts should be disabled during this call to ensure the interrupt
\         routine doesn't alter the buffer while you're reading it
\         This OSByte doesn't actually remove the byte
\         No range checking is performed on the buffer number and non existant
\         buffer numbers have undefined results
\&99 (Acorn MOS 1.20)
\    Write character into input buffer checking for ESCAPE
\    X=buffer number
\    Y=byte to insert
\    On exit C=1=buffer was full
\    If Y is the ESCAPE character,then no keyboard event will happen as an
\    ESCAPE condition (hence ESCAPE event) are in progress.
\&9A (Acorn MOS 1.20)
\    Write to Video ULA control register and RAM copy
\    This call places X into register 0 of the 6845,and updates the RAM copy
\    (Electron OS only)
\    Reset flashing colours
\    This call forces the ULA to set any flashing colours back to the first of
\    the two (the 'mark' colour)
\&9B (Acorn MOS 1.20)
\    Write to Video ULA palette register and RAM copy
\    This call places X into register 1 of the 6845,and updates the RAM copy
\    (Electron OS only)
\    Completely ignored,performing an RTS immediately
\&9C (Acorn MOS 1.20)
\    Read/write ACIA registers
\    Y=255 to read
\    X=b0..1 0=use basic baud rate
\            1=use chosen baud rate/16
\            2=use chosen baud rate/64
\            3=reset transmit,receive,control registers
\      b2..4 0=7 bit,even parity,2 stop bits (7E2)
\            1=7 bit,odd parity,2 stop bits (7O2)
\            2=7 bit,even parity,1 stop bits (7E1)
\            3=7 bit,odd parity,1 stop bit (7O1)
\            4=8 bit,no parity,2 stop bits (8N2)
\            5=8 bit,no parity,1 stop bits (8N1)
\            6=8 bit,even parity,1 stop bits (8E1)
\            7=8 bit,odd parity,1 stop bit (8O1)
\      b5..6 0=RTS low,transmit interrupt disabled
\            1=RTS low,transmit interrupt enabled
\            2=RTS high,transmit interrupt disabled
\            3=RTS low,transmit interrupt disabled,break level on transmit data
\      b7    0=receive interrupt disabled
\            1=receive interrupt enabled
\    Y=0 to write
\    X=as above
\    (RISC OS 1.00)
\    X=b0..1 0=no effect
\            1=no effect
\            2=no effect
\    (Electron OS only)
\    Passed as an unknown osbyte to the paged ROMs  
\&9D (Acorn MOS 1.20)
\    Fast Tube BPUT
\    X=byte to write Y=file handle
\    In OS 1.20 this call simply passes through the normal OSBPUT routine
\&9E (Acorn MOS 1.20 & Acorn MOS 2.00 only)
\    Read from Speech Processor
\    Either Y=speech chip status register
\           Y=byte read from PHROM if a 'read command' was previously written
\    (Electron OS only)
\    Passed as an unknown osbyte to the paged ROMs 
\&9F (Acorn MOS 1.20 & Acorn MOS 2.00 only)
\    Write to Speech Processor
\    Y=data to write
\    (Electron OS only)
\    Passed as an unknown osbyte to the paged ROMs 
\&A0 (Acorn MOS 1.20)
\    Read VDU Variable
\    This call returns variable number X in registers X and Y
\    In OS 1.20 the data starts at &300,but this is machine dependant
\    (Electron OS only)
\    Undefined action
\&A1 (Acorn MOS 3.20)
\    Read CMOS RAM
\    X=byte to read and on exit Y=byte read
\    On the Master Compact calling with X=255 returns the EEPROM device size
\    in Y=0,127,or 255. This represents no EEPROM,128,or 256 byte fitted.
\&A2 (Acorn MOS 3.20)
\    Write CMOS RAM
\    X=byte to read with Y=byte to write 
\&A3 (Various)
\    Reserved for applications software
\    (Acornsoft GXR 1.20)
\    X=242
\    Y=0     resets the dot-dash pattern & length to defaults
\    Y=1..64 set dot dash pattern repeat length
\    Y=65    return status returns X=b0..5 current dot dash pattern repeat 
\                                          length (0 means 64 though)
\                                    b6    if set flood fill is always active
\                                    b7    if set GXR ROM is turned on
\                                  Y=number of pages allocated to sprites
\    Y=66    return info on current sprite returns X=pixel width 
\                                                  Y=pixel height
\            if X=Y=0 then the ROM is not fitted,or no sprite is selected
\    (RISC OS 1.00)
\    X=242
\    Y=0     resets the dot-dash pattern & length to defaults
\    Y=1..64 set dot dash pattern repeat length
\    Y=65    return status returns X=b0..5 current dot dash pattern repeat 
\                                          length (0 means 64 though)
\                                    b6    if set flood fill is always active
\                                    b7    if set sprites are always active
\    Y=66    return info on current sprite returns X=pixel width 
\                                                  Y=pixel height 
\&A4 (Acorn MOS 3.20)
\    Check Processor Type
\    X and Y point to the code to check
\    If the value at offset &07 is not a language ROM the error 'This is not a
\    language' is raised
\    If the value at offset &08 (bits 0..3) is not 6502 code or BASIC then the 
\    error 'I cannot run this code' is raised
\&A5 (Acorn MOS 3.20)
\    Read output Cursor Position
\    On exit X and Y are the output cursor position used during cursor editing
\&A6 (Acorn MOS 1.20)
\    Read Start of MOS variables
\    On exit X and Y point to the start of the OS variables
\&A7 (Acorn MOS 1.20)
\    Read Start of MOS variables
\    On exit X=the high byte of OSByte &A6
\&A8 (Acorn MOS 1.20)
\    Read address of extended vector table
\    On exit X and Y point to the start of the extended vectors for ROMs
\&A9 (Acorn MOS 1.20)
\    Read address of extended vector table
\    On exit X=the high byte of OSByte &A8
\&AA (Acorn MOS 1.20)
\    Read address of ROM info table
\    On exit X and Y point to the 16 ROM type bytes
\&AB (Acorn MOS 1.20)
\    Read address of ROM info table
\    On exit X=the high byte of OSByte &AA
\&AC (Acorn MOS 1.20)
\    Read address of keyboard table
\    On exit X and Y point to a table mapping from internal to ASCii key numbers
\    The shape and layout of the table is of course hardware specific,so this 
\    call should be used with caution
\&AD (Acorn MOS 1.20)
\    Read address of keyboard table
\    On exit X=the high byte of OSByte &AC
\&AE (Acorn MOS 1.20)
\    Read address of VDU variables
\    On exit X and Y point to the base of VDU variables for this machine
\&AF (Acorn MOS 1.20)
\    Read address of VDU variables
\    On exit X=the high byte of OSByte &AE
\&B0 (Acorn MOS 1.20)
\    Read/Write Tape Timeout
\    This location is decremented on every vsync (50 times per second) and is 
\    used with OSByte 19 and to time interblock gaps.
\    (RISC OS 1.00)
\    This location is decremented on every vsync (not necessarily 50 times a 
\    second depending on MODE and monitor).
\&B1 (Acorn MOS 1.20)
\    Read/write input device
\    This returns X=input stream (ie.0 or 1 as defined by OSByte 2).Do not write
\    to this location.
\&B2 (Acorn MOS 1.20)
\    Enable/Disable Keyboard interrupts
\    A value of 0 disables the keyboard
\               255 enables the keyboard
\    (Electron OS & RISC OS 3.00)
\    Undocumented
\&B3 (Acorn MOS 1.20)
\    Read/Write primary OSHWM
\    This value contains the page number of OSHWM ignoring any font implosions
\    and explosions
\    (Acorn MOS 3.20)
\    Read/Write ROM polling semaphore
\    This is the value adjusted by *FX22 and *FX23
\&B4 (Acorn MOS 1.20)
\    Read/Write OSHWM
\    This value contains the page number of OSHWM taking into account any font
\    implosions and explosions
\&B5 (Acorn MOS 1.20)
\    Read/Write RS423 interpretation
\    A value of 1 (the default) means that RS423 input is taken as raw data
\               0 means that RS423 is treated as though from the keyboard so 
\                 that ESCAPE and soft keys are acted on (with their respective
\                 events if enabled)
\&B6 (Acorn MOS 1.20 and Electron OS)
\    Read Font Explosion
\    This value is as set by *FX20 for font implosion/explosion
\    (Acorn MOS 3.20)
\    Read NOIGNORE Status
\    Contains the IGNORE character b7=1=no ignore character
\                                  b7=0=value is the ignore character
\&B7 (Acorn MOS 1.20)
\    Read/Write TAPE/ROM switch
\    If 0 then the TAPE filing system is selected
\       2 then the ROM filing system is selected
\&B8 (Acorn MOS 1.20)
\    Read MOS copy of Video ULA control register
\    (Electron OS)
\    Undefined
\&B9 (Acorn MOS 1.20)
\    Read MOS copy of palette register
\    (Electron OS)
\    Read/Write ROM polling semaphore
\    This is the value adjusted by *FX22 and *FX23
\&BA (Acorn MOS 1.20)
\    Read/Write ROM active on last BRK
\    The last ROM which caused a BRK is recorded so that the current language
\    ROM can extract the error text (using OSReadROM) if the error text resided
\    in ROM.Since the language ROM would cause the error message to be paged out
\    they should make a RAM copy of the message instead.
\&BB (Acorn MOS 1.20) 
\    Read/Write ROM number of BASIC 
\&BC (Acorn MOS 1.20)
\    Read current ADC channel number
\&BD (Acorn MOS 1.20)
\    Highest ADC channel number
\&BE (Acorn MOS 1.20)
\    Read/Write ADC type
\    A value of 0=the default resolution
\               8=use only 8 bit resolution (faster)
\               12=use 12 bit resolution
\    Note The ADC value is scaled to fit 16 bits,it is the resolution which is
\         being set not the range
\&BF (Acorn MOS 1.20)
\    Read/Write RS423 busy flag
\    Contains 0 for RS423 busy (ie.cassette filing system should not use it)     
\             128 for RS423 free
\    (RISC OS 1.00)
\    Contains no useful information
\&C0 (Acorn MOS 1.20)
\    Read ACIA control register
\&C1 (Acorn MOS 1.20)
\    Read/Write flash counter
\    This location is decremented to zero every vsync,when zero the colours are
\    swapped and the next period is entered and decrements until it is zero
\&C2 (Acorn MOS 1.20)
\    Read/Write first colour duration
\&C3 (Acorn MOS 1.20)
\    Read/Write second colour duration
\&C4 (Acorn MOS 1.20)
\    Read/Write auto Repeat Delay
\&C5 (Acorn MOS 1.20)
\    Read/Write auto Repeat Period
\&C6 (Acorn MOS 1.20)
\    Read/Write *EXEC file handle
\    A value of zero implies no EXECing is happening
\&C7 (Acorn MOS 1.20)
\    Read/Write *SPOOL file handle
\    A value of zero implies no SPOOLing is happening
\&C8 (Acorn MOS 1.20)
\    Read/Write BREAK/ESCAPE effect
\    Two bits define the action b0=1 Normal ESCAPE effect
\                                 =0 Escape disabled (except via OSByte 125)
\                               b1=1 Memory cleared on next reset
\                                 =0 Normal reset effect
\&C9 (Acorn MOS 1.20)
\    Read/Write keyboard Enable/Disable
\    A value of 0 here enables the keyboard,and non zero disables it.The 
\    keyboard is still active (see OSByte &B2) but the bytes get thrown away.
\    This is used to implement *REMOTE on the Econet system.
\&CA (Acorn MOS 1.20)
\    Read/Write Keyboard Status
\    This byte determines the current state of the LOCK keys
\    b0=reserved
\    b1=reserved
\    b2=reserved
\    b3=0=shift not pressed
\    b4=0=caps lock on
\    b5=0=shift lock on
\    b6=0=control not pressed
\    b7=0=shift enable
\    Note With caps lock on and shift enable off,shift has no effect on the 
\         letters.But with shift enable on,you get lowercase.This cannot be
\         achieved at the keyboard and the OSByte must be used.
\    (Electron OS)
\    b4=0=caps lock on
\    b5=0=FN key not pressed
\    b6=0=shift not pressed
\    b7=0=control not pressed
\    (RISC OS 1.00)
\    b1=0=scroll lock off
\    b2=0=num lock on
\    b5=reserved
\&CB (Acorn MOS 1.20)
\    Read/Write RS423 in buffer minimum
\    This is the value the value below which the serial hardware will set the
\    RTS line to stop further characters entering the buffer.Its default is 9 
\    and should be set to match the responsiveness of the software to the speed
\    of the communications
\&CC (Acorn MOS 1.20)
\    Read/Write RS423 ignore flag
\    A value of zero lets serial data enter the input buffer
\           non zero stops data entering the buffer but will still cause events
\    (Electron OS)
\    Read/Write user key string pointer
\    This points to the currently selected firm key which is being expanded into
\    the input stream.
\&CD (Acorn MOS 1.20)
\    Read/Write RS423 destination
\    A zero sends data to the RS423 port,and a value of one to the cassette port
\    (Electron OS)
\    Read/Write user key string length
\    The current firm key being expanded into the input stream has this many
\    characters remaining to be sent.Setting it to zero cancels the expansion.
\    Firm keys are the text shortcuts stamped on the side of the keyboard and
\    which are used in conjunction with the FN key.
\&CE (Acorn MOS 1.20)
\    Read/Write ECONET call intepretation
\    Known OSByte and OSWords are handled by the OS if this value is zero.If
\    set to 128 calls are indirected to the Econet vector instead.
\&CF (Acorn MOS 1.20)
\    Read/Write ECONET input intepretation
\    Requests to OSReadCharacter are handled by the OS if this value is zero.If
\    set to 128 calls are indirected to the Econet vector instead.
\&D0 (Acorn MOS 1.20)
\    Read/Write ECONET output intepretation
\    Requests to OSWriteCharacter are handled by the OS if this value is zero.If
\    set to 128 calls are indirected to the Econet vector instead.
\&D1 (Acorn MOS 1.20)
\    Read/Write speech supression status
\    An &50 here (opcode for 'speak') enables the speech upgrade,or &20 ('nop')
\    will disable it
\&D2 (Acorn MOS 1.20)
\    Read/Write sound supression flag
\    A value of zero lets the sound system function as normal
\           non zero disables any sound commands
\&D3 (Acorn MOS 1.20)
\    Read/Write channel for BELL
\&D4 (Acorn MOS 1.20)
\    Read/Write volume/ENVELOPE For BELL
\    To set the BELL character to use an envelope,use (envelope-1)*8
\    To set the BELL volume,and not use envelopes,use 256+((volume-1))*8
\    The value &90 is *CONFIGURE LOUD and &D0 is *CONFIGURE QUIET
\    (Electron OS)
\    The unexpanded sound system has fixed amplitude.
\&D5 (Acorn MOS 1.20)
\    Read/Write frequency for BELL
\&D6 (Acorn MOS 1.20)
\    Read/Write duration for BELL
\&D7 (Acorn MOS 1.20)
\    Enable/Disable Startup Message
\    The Tube system replaces the startup computer message,and this call is
\    used to do this.It can only be acted on by a paged ROM,since no other
\    software has had a chance to load,only 2 bits are defined:
\    b0=0=supress startup message
\      =1=message as normal
\    b7=0=computer hangs if there's a !Boot file error in the ROM filing system
\      =0=computer hangs if there's a !Boot file error in the DISC filing system
\&D8 (Acorn MOS 1.20)
\    Read/Write user key string length
\    The current soft key being expanded into the input stream has this many
\    characters remaining to be sent.Setting it to zero cancels the expansion
\&D9 (Acorn MOS 1.20)
\    Read/Write paged line count
\    This is the number of lines written since the last paged mode lock occured.
\    Paged mode activates when around 75% of the screen has been scrolled
\&DA (Acorn MOS 1.20)
\    Read/Write VDU Queue length
\    Minus the number of bytes need to complete this VDU command are held in 
\    this location.So a command expecting 2 more parameters would have 254 here.
\    Setting this to zero would (for example) clear the queue,preventing an
\    error message having its first few characters lost
\&DB (Acorn MOS 1.20)
\    Read/Write ASCii code for TAB
\    If the value is between 128 and 143 then TAB will act as a softkey
\    (RISC OS 1.00)
\    If the value is between 128 and 255 inclusive and TAB is used in conjuction
\    with control or shift its value is
\     SHIFT'd returns code EOR16
\     CTRL'd  returns code EOR32
 \   (Electron OS only)
\    Read/Write external sound semaphore
\    Determines whether SOUND and ENVELOPE trigger unknown OSWord service calls
\    to the paged ROMs to allow extra sound hardware to be added.
\&DC (Acorn MOS 1.20)
\    Read/Write ASCii for ESCAPE
\&DD (Acorn MOS 1.20)
\    Read/Write Intrepretation ASCii 197-207
\    A value of 0 discards the keycode
\    A value of 1 expands the key as soft key number (keycode MOD16)
\    A value from 2 to 255 causes chosenvalue + (keycode MOD16)
\    (Acorn MOS 3.50)
\    A value of 2 preceeds the keycode with an ASCii null
\&DE (Acorn MOS 1.20)
\    Read/Write Interpretation ASCii 208-223
\    See OSByte &DD
\&DF (Acorn MOS 1.20)
\    Read/Write Interpretation ASCii 224-239
\    See OSByte &DD
\&E0 (Acorn MOS 1.20)
\    Read/Write Interpretation ASCii 240-255
\    See OSByte &DD
\    (Acorn MOS 1.00 and Acorn MOS 2.00 only)
\    Cancel VDU queue
\    Only works with X=Y=0 on entry (ie.writes a zero)
\&E1 (Acorn MOS 0.10)
\    Read/Write Interpretation of F-Keys
\&E2 (Acorn MOS 0.10)
\    Read/Write Interpretation of Shift-F-Keys
\&E3 (Acorn MOS 0.10)
\    Read/Write Interpretation of Ctrl-F-Keys
\&E4 (Acorn MOS 0.10)
\    Read/Write Interpretation of Ctrl-Shift-Fkeys
\&E5 (Acorn MOS 1.00)
\    Read/Write ESCAPE key status
 \   A zero here causes ESCAPE to cause ESCAPE conditions,a value of 1 however
\    causes it to simply insert it's ASCii value (usually 27) into the input
\    buffer
\&E6 (Acorn MOS 1.00)
\    Read/Write ESCAPE effects
\    A zero causes the default ESCAPE effects,ie.when it is acknowledged the
\    active output buffers are flushed,any *EXEC files are closed,the VDU queue
\    is emptied,any pending soft key expansion is cancelled,and the paged mode
\    scroll count is zeroed.A non zero value stops all these effects.
\&E7 (Acorn MOS 1.00)
\    Read/Write 6522 User IRQ Mask
\&E8 (Acorn MOS 1.00)
\    Read/Write 6850 IRQ Mask

\&E9 (Acorn MOS 1.20)
\    Read/Write 6522 System IRQ Mask
\&EA (Acorn MOS 1.20)
\    Read/Write Tube present flag
\    The value 255 indicates the Tube is present
\                0 indicates it is not
\    Writing to this value is not recommended
\&EB (Acorn MOS 1.20)
\    Read/Write speech processor presence
\    The value 255 indicates the TMS5220 is fitted
\                0 indicates it is not
\    Writing to this value is not recommended
\&EC (Acorn MOS 1.20) 
\    Read/Write character output device status
\    This is the location altered by *FX3
\&ED (Acorn MOS 1.20)
\    Read/Write Cursor Edit State
\    This is the location altered by *FX4
\&EE (Acorn MOS 3.20)
\    Read/Write base of numeric pad
\    The keypad usually generates codes based on offsets from 48 (character 0)
\    This value can be changed with this call
\&EF (Acorn MOS 3.20)
\    Read/Write shadow state
\    This is a readable/writeable equivalent to OSByte 114
\&F0 (Acorn MOS 3.20 & Electron OS only)
\    Read Country flag
\    A value of 0=UK
\               1=USA
\    (RISC OS 1.00)
\    Values of 1 UK
\              2 Master
\              3 Compact
\              4 Italy      10 Greece     16 Iceland   22 Ireland     28 LatinAm
\              5 Spain      11 Sweden     17 Canada1   23 Hong Kong   48 USA
\              6 France     12 Finland    18 Canada2   24 Russia
\              7 Germany    13 Unused     19 Canada    25 Russia2
\              8 Portugal   14 Denmark    20 Turkey    26 Israel
\              9 Esperanto  15 Norway     21 Arabic    27 Mexico
\&F1 (Acorn MOS 1.20)
\    Read/Write value written by *FX1
\&F2 (Acorn MOS 1.20)
\    Read OS copy of serial ULA register
\    b0..2=determine the receive baud rate
\    b3..5=determine the transmit baud rate
\    b6   =1=RS423 using serial system (instead of cassette)
\    b7   =1=cassette relay on
\    Value 0=19200 baud 
\          1=1200 baud
\          2=4800 baud
\          3=150 baud
\          4=9600 baud
\          5=300 baud
\          6=2400 baud
\          7=75 baud
\    (Electron OS only)
\    Read OS copy of location &FE07
\    (RISC OS 1.00)
\    b6 and b7 are used to make up the 4th bit of the transmit and receive
\    baud rates,expanding the range of values:
\    Value 9=134.5
\          10=1800 baud
\          11=50 baud
\          12=3600 baud
\          13=110 baud
\          14=600 baud
\          15=undefined
\&F3 (Acorn MOS 1.20)
\    Read/Write offset to current TIME value
\    A value of X=5 means that TIME copy 1 is being updated
\    A value of X=10 means that TIME copy 2 is being updated
\    Two copies of TIME are required in case the TIME update interrupt occurs
\    part way through a read of TIME - leading to inconsistant values.
\&F4 (Acorn MOS 1.20)
\    Read/Write soft key consistency flag
\    A zero here indicates the soft key buffer is 'consistant' - ie.it's not
\    currently being updated due to a new soft key being assigned.
\    If a non zero value is present here at reset,the soft keys are cleared.
\&F5 (Acorn MOS 1.20)
\    Read/Write printer Type
\    This returns the printer number set by *FX5.If written to it does not
\    wait for the current printer to become inactive.
\&F6 (Acorn MOS 1.20)
\    Read/Write printer Ignore character set by *FX6
\&F7 (Acorn MOS 1.20)
\    Intercept BREAK
\    If this location is set to &4C (ie.a JMP instruction) then when reset
\    occurs the address written by OSByte &F8 and &F9 is jumped to
\    (RISC OS 1.00)
\    Define action of BREAK key  
\    b0..b1 define action of 'break' alone
\    b2..b3 define action of 'shift break'
\    b4..b5 define action of 'ctrl break'
\    b6..b7 define action of 'ctrl shift break'
\    Each two bit value can be 00=act as a reset
\                              01=act as the ESCAPE key
\                              10=no effect
\                              11=undefined
\    Writing to this value will also update the CMOS copy too
\&F8 (Acorn MOS 1.20)
\    LSB BREAK intercepter jump address
\&F9 (Acorn MOS 1.20)
\    MSB BREAK intercepter jump address
\&FA (Acorn MOS 3.20)
\    Read/Write RAM used for VDU access
\    As per OSByte &70.Do not use this for writing
\    (Watford 32K shadow RAM)
\    Read/Write shadow RAM board status
\    b0=1=RAM board active
\    b1=1=buffer active
\    b2=1=small buffer
\    b3=1=large buffer
\    b4=1=buffer purging disabled
\    b5=1=NMI in use
\    b6=1=workspace at fixed location
\    b7=1=ROM claims workspace on next BREAK
\&FB (Acorn MOS 3.20)
\    Read/Write RAM used for Display hardware
\    As per OSByte &71.Do not use this for writing
\&FC (Acorn MOS 1.20)
\    Read/Write current language ROM Number
\    This is the ROM which will be restarted if the machine is soft/hard reset
\&FD (Acorn MOS 1.20)
\    Read Last Reset Type
\    A value 0=soft reset 
\            1=power on reset
\            2=hard reset
\&FE (Acorn MOS 1.20)
\    Read/Write available RAM
\    These bits refer to 16k/32k machine:
\    When read &40=16k
\              &80=32k
\    (Electron OS)
\    This value returns 0 and is otherwise undefined
\    (Acorn MOS 2.00)
\    This value returns 1 and is otherwise undefined
\    (Acorn MOS 3.20)
\    Read/Write effect of shift on Numeric pad
\    A zero in this location makes SHIFT-keypad presses act like their main
\    keyboard counterparts.A non zero value means shift is ignored.
\    (RISC OS 1.00)
\    A zero in this location enables both SHIFT and CTRL-keypad presses:
\    For keys 128 and above (ie.the base has been altered with OSByte 238)
\       CTRL-keypad gives keypad key EOR&20
\       SHIFT-keypad gives keypad key EOR&10
\    For keys below 128
\       CTRL and SHIFT are ignored
\&FF (Acorn MOS 1.20)
\    Read/Write startup Options
\    This is a copy of the keyboard links taken at last hard reset.
\    Note that the switch numbers printed on the circuit board are numbered
\    backwards (so switch 8 is b0, switch 7 is b1, etc...). By default the 
\    keyboard has no switch fitted and the links read back as all 1's ('open').
\    b0..2=select screen mode
\    b3   =if clear then the action of SHIFT/BREAK is reversed
\    b4..5=define disc drive speed  step time  settle time  head load
\                               00: 4ms        16ms         0ms
\                               01: 6ms        16ms         0ms
\                               10: 6ms        50ms         32ms
\                               11: 24ms       20ms         64ms
\    b6=reserved
\    b7=when both Econet and disc hardware are installed DNFS checks this bit.
\       If clear NFS will be selected instead of DFS, and vice versa.
\    (Acorn MOS 3.20)
\   Only b3 is of use,the rest of the settings are now in CMOS RAM
\    (Electron OS)
\    Only b0..3 are of use,since the unexpanded Electron has no disc interface
OSRDCH=&FFE0
		\Write a byte to screen
OSASCI=&FFE3
		\Send an ascii sequence to output stream
OSNEWL=&FFE7
		\Send a newline sequence to output stream
OSWRCH=&FFEE
		\write character VDU command
		\A, X and Y are preserved.
		\C, N, V and Z are undefined.
		\The interrupt status is preserved (though it may be
		\enabled during a call)
OSWORD=&FFF1
OSCLI =&FFF7
		\Execute a command
\Vectors
OSFSC=&21E


USERV =&200	\reserved
BRKV=&202	\break vector
IRQ1V = &204	\all IRQ vector
IRQ2V = &206	\unrecognised IRQ
CLIV = &208	\interpret command line given
BYTEV = &20A	\miscellaneous OS operations (register parameters)
WORDV = &20C	\miscellaneous OS operations (control block parameters)
WRCHV =&20E	\write character to screen from A
RDCHV =&210 \read character to A from keyboard
FILEV =&212	\load or save file
ARGSV =&214	\load or save data on file
BGETV =&216	\load byte to A from file
BPUTV =&218	\save byte to file from A
GBPBV =&21A	\load or save block of memory to file
FINDV =&21C	\open or close file
FSCV =&21E	\file system control entry
EVNTV =&220	\event interrupt
UPTV =&220	\user print routine

FUNCTIONkey0% =128
FUNCTIONkey1% =129
FUNCTIONkey2% =130
FUNCTIONkey3% =131
FUNCTIONkey4% =132
FUNCTIONkey5% =133
FUNCTIONkey6% =134
FUNCTIONkey7% =135
FUNCTIONkey8% =136
FUNCTIONkey9% =137
FUNCTIONkey10% =138
FUNCTIONkey11% =139

CopyKey% =&8B
LeftCursorKey%=&8C


