\…Variables
NoSpecials%=1:\"offset from 1
EndSpecial%=&FF-NoSpecials%
\ZERO page
\IntA &2A -&2D

\&2E TO &35 basic float
strptr=&2E
APtr=&30
exeadd=&32
erradd=&34
\&3B to &42 basic float
\single bytes
tempy=&3B
matchlen=&3C
tempx=&3D
ypush=&3E
highestbyte=&3F
noofbytes=&40
quiet =&41
basic=&42

\&70 to &8F reserved for user
block=&70
blockstart=&70:load=blockstart+2:exe=blockstart+6:size=blockstart+&A


\&F8-F9 UNUSED BY OS

\end zero page
\&400 A%-Z% INT
 a=&404:b=&408:c=&40C:d=&410:e=&414:f=&418:g=&41C:h=&420:i=&424:j=&428
 k=&42C:l=&430:m=&434:n=&438:o=&43C:p=&440:q=&444:r=&448:s=&44C:t=&450
 u=&454:v=&458:w=&45C:x=&460:y=&464:z=&468
\&600 String manipulation
strB%=&640
strA%=&6A0
\&900 rs232/cassette o/p buffer envelope buffer
rawdat=&900:\output for file read
\&A00 RS232 & cassette
countpg=&A00:\page for count's

\&1100-7C00 main mem


\os calls
osasci=&FFE3:osbyte=&FFF4:oswrch=&FFEE:osnewl=&FFE7:osgbpb=&FFD1:osfile=&FFDD
osargs=&FFDA:osbget=&FFD7:osbput=&FFD4:osbpb=&FFD1:osfind=&FFCE:osrdch=&FFE0
oscli=&FFF7:osfsc=&21E:osword=&FFF1

\Consts
comprec=4

ORG &900
GUARD &AFF

.start


  cl%=&1900
    \…Zero Page
  \IntA &2A -&2D
  \&2E TO &35 BASIC FLOATING
  
  \‚&404 -&407 A% &468 -&46B Z%
  
 
 \AlignSoftwareRecords ADR
 \"„Assumes lookuptable in 2 bytes  „1 starting 1100 the other 1500 ending  „1900
 \"„load catfile, walkthrough recs  „alter SW,save catfile repeat til done
 .startexec
 .ADR
 {
 LDA#48: STA catdat+6:.md: JSR cce
 CMP#1: BNE ma: JSR lcf
 JSR prsd : JSR scf: JMP md
 .ma : RTS
 }
 \Check cat files exits cce
 .cce
 {
 INC catdat+6
 LDA #LO(catdat): STA block: LDA #HI(catdat): STA block+1
 JSR sbf
 LDA #5: JMP osfile:\rts
 }
 \"„SaveCatdatFile scf
 .scf
 {
 LDA#131: JSR osasci: LDA#(ASC(".")): JSR osasci
 JSR rtb:LDA #&19:STA block+&B:
 CLC : LDA APtr : ADC #1 : STA block+&E : LDA #0: ADC APtr+1 : STA block+&F:
 JSR sbf: LDA#0: JMP osfile:\RTS
 }
 \"„ResetBlock rtb
 .rtb
 {
 LDY#(&11-6) : LDA#0:.me: STA block+6,Y : DEY : BPL me:RTS
 }
 \"„Process recs disk prsd
 .prsd
 {
 LDY#0: LDA (APtr),Y: BNE aa : RTS :.aa
 LDA#(ASC(".")): JSR osasci
 
 .ab: INY : LDA (APtr),Y : CMP#&80: BCC ab:
 STY tempy: INY : INY : LDA (APtr),Y : STA w
 INY : LDA (APtr),Y : AND #3: STA w+1
 LDA#&11: CLC : ADC w+1: STA strptr+1
 LDA#0: STA strptr
 LDY w : LDA (strptr),Y : STA y
 LDA#&15: CLC : ADC w+1 : STA strptr+1
 LDA (strptr),Y: STA y+1
 LDY tempy: INY : LDA y: STA (APtr),Y
 INY : INY : LDA (APtr),Y: AND #&7D: CLC : ADC y+1: STA (APtr),Y
 JSR Nextrecord
 JMP prsd
 }

 \Next rec
 .Nextrecord
 {
 LDA tempy : CLC : ADC #comprec: ADC APtr: STA APtr: LDA #0: ADC APtr+1: STA APtr+1
 RTS
 }
 \"„LoadCatFile lcf
 .lcf
 {
 LDA #130: JSR osasci: LDA#(ASC(".")): JSR osasci
 LDA #LO(cl%): STA APtr: STA block+2
 LDA #HI(cl%): STA APtr+1: STA block+3
 LDA #LO(catdat): STA block: LDA #HI(catdat): STA block+1  
 JSR sbf
 LDA #&FF: JMP osfile:\rts
 }
 \"„SetBlockFile sbf
 .sbf
 {
 LDX #LO(block):LDY #Hi(block):RTS
 }
 .catdat:EQUS"catdat0":EQUB&D
 
 
 .end


SAVE "ADR", start, end,startexec
\cd C:\GitHub\beebyams\beebasm
\beebasm -i .\ADR\ADR.asm -do .\ADR\ADR.ssd -boot ADR -v -title ADR
\beebasm -i .\ADR\ADR.asm -di .\ADR\ADR-dev.ssd -do .\ADR\ADR.ssd -v LO