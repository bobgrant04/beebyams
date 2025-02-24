\…Variables
NoSpecials%=1:\"offset from 1
EndSpecial%=&FF-NoSpecials%
\ZERO page
\IntA &2A -&2D

\&2E TO &35 basic float
strptr=&2E
Aptr=&30

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
blockstart=&70:load=blockstart+2:exe=blockstart+6:size=blockstart+&A
cat=&72
codestart=&70
zz=&8E
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
conb=&7B90 :\control block for reading disk

\os calls
osasci=&FFE3:osbyte=&FFF4:oswrch=&FFEE:osnewl=&FFE7:osgbpb=&FFD1:osfile=&FFDD
osargs=&FFDA:osbget=&FFD7:osbput=&FFD4:osbpb=&FFD1:osfind=&FFCE:osrdch=&FFE0
oscli=&FFF7:osfsc=&21E:osword=&FFF1

ORG &900
GUARD &9FF

.start


cl%=&1900
  160code%=&6E00
  170REM"…Zero Page
  180REM IntA &2A -&2D
  190REM &2E TO &35 BASIC FLOATING
  200StrAlen=&2E
  210SNo=&2F
  220comprec=&30
  230flag=&33
  240tempy=&34
  250tempx=&35
  260REM &3B TO &42 BASIC FLOATING
  270APtr=&3B 
  280BPtr=&3D
  290REMDiskRecNo=&3F
  300REM&70 - 8F reserved by basic for users
  310blockstart=&70:load=blockstart+2:exe=blockstart+6:size=blockstart+&A
  320Tokenadd=&70
  330strptr=&72
  340oldptr=&74
  350trueadd=&82
  360Tokenno=&8F
  370basicpage=&8F:filesize=&8E
  380REM&90-&91 reserved for econet
  390REM &B0- &BF FILESYSTEM SCRATCH SPACE
  400REM &F8-F9 unused by os1.2
  410REM"‚&404 -&407 A% &468 -&46B Z%
  
 
 3060\"„NextRecord nxr   
 3070.nxr:LDY#&FF:.qe
 3080INY:LDA(APtr),Y:BEQicn:CMP#&80
 3090BCCqe:INY:TYA:CLC:ADCAPtr:STAAPtr:LDA#0:ADCAPtr+1:STAAPtr+1

 3140\"†AlignSoftwareRecords ASR
 3150\"„Assumes lookuptable in 2 bytes  „1 starting 1100 the other 1500 ending  „1900
 3160\"„load catfile, walkthrough recs  „alter SW,save catfile repeat til done
 3170.catdat:EQUS"catdat0":EQUB&D
 3180.ASR:LDA#48:STA catdat+6:.md:JSRcce
 3190CMP#1:BNEma:JSRlcf
 3192JSRprs:JSRscf:JMPmd
 3195.ma:RTS
 3200\"„SaveCatdatFile scf
 3201.scf:LDA#(ASC("ƒ")):JSRosasci:LDA#(ASC(".")):JSRosasci
 3202JSRrtb:LDA#&19:STAblock+&B:
 3203CLC:LDAAPtr:ADC#1:STA block+&E:LDA#0:ADC APtr+1:STA block+&F:
 3204JSRsbf:LDA#0:JMPosfile:\RTS
 3209\"„ResetBlock rtb
 3210.rtb:LDY#(&11-6):LDA#0:.me:STA block+6,Y:DEY:BPLme:RTS
 3220\"„Process recs sw prs
 3230.prs
 3240.mc:LDY#0:LDA(APtr),Y:BEQmd
 3250JSRged:STYtempy:INY:LDA(APtr),Y:STAw
 3260INY:INY:LDA(APtr),Y:AND#3:STAw+1
 3270LDA#&11:CLC:ADCw+1:STA strptr+1
 3280LDA#0:STA strptr
 3290LDYw:LDA(strptr),Y:STAy
 3300LDA#&15:CLC:ADCw+1:STA strptr+1
 3310LDA(strptr),Y:STAy+1
 3320LDYtempy:INY:LDAy:STA(APtr),Y
 3330INY:INY:LDA(APtr),Y:AND #&7D:CLC:ADCy+1:STA(APtr),Y
 3333RTS
 .ged:INY:LDA(APtr),Y:CMP#&80:BCCged:RTS
 \"„LoadCatFile lcf
 .lcf:LDA#(ASC("‚")):JSRosasci:LDA#(ASC(".")):JSRosasci
 LDA #LO(cl%):STA APtr:STA block+2
 LDA#(cl% DIV256):STA APtr+1:STA block+3
 LDA#(catdat MOD 256):STA block:LDA#(catdat DIV 256):STA block+1  
 JSR sbf
 LDA #&FF:JMPosfile:\rts
 }
 
 .end


SAVE "ASR", start, end,startexec
\cd C:\GitHub\beebyams\beebasm
\beebasm -i .\ASR\ASR.asm -do .\ASR\ASR.ssd -boot ASR -v -title ASR
\beebasm -i .\ASR\ASR.asm -di .\ASR\ASR-dev.ssd -do .\ASR\ASR.ssd -v LO