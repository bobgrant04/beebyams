L.
   10*K.1 SAVE"P.x"
   20*K.2 *X GIRL
   30*K.3 *X WMAP1
   40*K.4 *X TYPE
   50*K.5 *X DUMP
   60*K.7 *X EXEC
   70*K.8 *X CODE
   80*K.9 *MZAP 6A0
   90OSCLI("DR.0") 
  100prog$="X"
  110REM based on CHe00 by martin mather 14/10/2006 
  120REMUsage <fsp> (<dno>/<dsp>) (<drv>)
  130REM basic progs have exe of 8023
  140REM basic prog load add is correct
  150REM roms have load add of 8000
  160REM ldpic on disk with the file
  170REM ldpic files have exe of 7FFE
  180REM Showpic files exe of 7FFD
  190REM Showpic  on disk
  200REM Files to be typed exe 7FFC
  210REM Files to be dumped exe 7FFB
  220REM Files to be EXEC exe 7FFA
  230REM"…Variables
  240NoSpecials%=6:REM"ƒ"offset from 1
  250EndSpecial%=&FF-NoSpecials%
  260REM"‚"&ZERO page
  270REM"„"IntA &2A -&2D
  280REM"„"&2E TO &35 basic float
  290strptr=&2A
  300Aptr=&2C
  310trueadd=&2E
  320loadadd=&30
  330exeadd=&32
  335erradd=&34
  340REM"„"&3B to &42 basic float
  350REM"„"single bytes
  360filesize=&3B
  370tempx=&3D
  380switch=&3E
  390basic=&3F
  400tempy=&40
  410REM"„"&70 to &8F user
  420blockstart=&70:load=blockstart+2:exe=blockstart+6:size=blockstart+&A
  430codestart=&70
  440REM"„"&F8-F9 UNUSED BY OS
  450REM"‚"&600 String manipulation
  460strA%=&6A0
  470REM"‚"&A00 RS232 & cassette
  480REM"‚"&1100-7C00 main mem
  490code%=&7000
  500PRINT"22/3/2020"
  510PRINT"„P."+prog$
  520PROCassemble
  530PROCtest
  540END:REM"…..........." 
  550DEFPROCassemble
  560osasci=&FFE3:osbyte=&FFF4:oswrch=&FFEE:osnewl=&FFE7:osgbpb=&FFD1:osfile=&FFDD:osargs=&FFDA:osbget=&FFD7:osbput=&FFD4:osbpb=&FFD1:osfind=&FFCE:osrdch=&FFE0:oscli=&FFF7:osfsc=&21E:osword=&FFF1
  570FORi%=0TO2STEP2:P%=code%:[OPT i%
  580\"ƒ"MC start
  590\"…"get osargs into blockstart
  600LDX#blockstart:LDY#0:LDA#1:JSRosargs  
  610\"„ptr to command into blockstart&70
  620\"„X,Y,A are preserved osargs
  630TYA:LDA#0
  640\"„"filesize =0 indicates no shift
  650\"„"basic =0 indicates not basic
  660STAloadadd
  670STAfilesize:STAbasic:TAX:LDA(blockstart),Y:CMP#&D:BNEaa
  675LDX#1:JSRdiserror:LDX#4:JMPdiserror
  676\"„"JMP so end
  680.aa:CMP#&D:BEQcmdend:INY:LDA(blockstart),Y:CMP#32:BNEaa:INX:BNEaa:.cmdend:CPX#2:BNEab:STXtempx:DEY:STYtempy
  690\"…"Have drive param
  700LDX#NoSpecials%:JSRprepcmd:LDYtempy:LDA(blockstart),Y:STAstrA%,X:INX:LDA#&D:STAstrA%,X
  710DEY:STA(blockstart),Y:STYtempy
  720JSRexecmd
  730LDXtempx:LDYtempy
  740.ab:CPX#1:BCCac
  750\"…"Have DIN param
  760.ad:DEY:LDA(blockstart),Y:CMP#32:BNEad:LDA#&D:STA(blockstart),Y:STYtempy:LDX#NoSpecials%+1:JSRprepcmd:LDYtempy
  770DEX
  780.ae:INY:INX:LDA(blockstart),Y:STAstrA%,X:CMP#&D:BNEae:CMP#&32:BEQae
  790LDA#&D:STAstrA%,X
  800JSRexecmd
  810.ac
  820\"…"Process filename
  830\"„now have blockstart with filename
  840\"…"get file info
  850LDX#blockstart:LDY#0:LDA#5:JSRosfile:CMP#1:BEQal:LDX#2:JMPdiserror:.al
  860\""file not found
  870\"„get file info if A<> 1 not a file
  880\"…"check for specials
  890LDAexe+1:CMP#&7F::BNEprepload
  900LDA#EndSpecial%:STAswitch:LDX#NoSpecials%
  910LDAexe
  920.ag:CMPswitch:BNEaw
  930.exespecial:JSRprepcmd:JSRaddparam:JMPexecmd
  940\"„"JMP so end
  950.aw:INCswitch:DEX:BNEag
  960\""Special exe address not coded
  970LDX#3:JSRdiserror:LDX#4:JMPdiserror 
  980\"„"JMP so end
  990\"…"prepload
 1000.prepload
 1010LDAload:STAtrueadd:LDAload+1:STAtrueadd+1
 1020LDX#NoSpecials%+2:JSRprepcmd:JSRaddparam
 1030\"„"now have *lo. FILENAME &D ready
 1040\"„"to execute
 1050LDAload+1:CMP#&11:BCCay
 1060\"…"romcheck 
 1070.romcheck:CMP#&80:BNEbascheck:JMPexecmd
 1080\"„"JMP so end 
 1090.ay
 1100\"„"below &1100 so need to shift
 1110LDA#&11:STAloadadd+1
 1120LDAsize+1:STAfilesize:INCfilesize:DEX:LDY#0
 1130.bv:LDAladd,Y::STAstrA%,X:INX:INY:CMP#&D:BNEbv
 1140\"„"now have *LOAD fname 1100 ready
 1150\"…"bascheck
 1160\"„"if basic put command in kbd buf
 1170\"„"and set basic flag
 1180.bascheck:LDAexe+1:STAexeadd+1:LDAexe:STAexeadd:CMP#&23:BNEax:LDAexeadd+1:CMP#&80:BNEax:LDAtrueadd+1:STA&18:LDA#138:.ui:LDYrun:LDX#0:JSRosbyte:INCui+1:BNEui:INCbasic:.ax
 1190\JMPtest
 1200LDY#codeend-codebegin:.av:LDAcodebegin,Y:STAcodestart,Y:DEY:BPLav
 1210\"„"CODE NOW IN ZERO PAGE
 1220LDY#strA%DIV256:LDX#strA%MOD256
 1230JMPcodestart
 1240.test
 1250\"ƒ"-----------------------
 1260.codebegin
 1270\"„"need to keep code here to min
 1280\"„"loadfile and shift if required
 1290\"„"to save bytes here execmd rets
 1300\"„"Y =0 X=A=filesize
 1310JSRoscli
 1320LDY#0:LDXfilesize:BEQat
 1330.iq1:LDA(loadadd),Y:STA(trueadd),Y:INY:BNEiq1:INCloadadd+1:INCtrueadd+1:DEX:BNEiq1
 1340\"„"JUMP OR RTS
 1350\"„"Note jmp will save RTS!
 1360.at:LDAbasic:BNEbz:JMP(exeadd):.bz:RTS
 1370.codeend
 1380\"ƒ"-----------------------
 1390\"ƒ"Routines
 1400\"…"addparam
 1410.addparam
 1420LDY#0:.af:LDA(blockstart),Y:STAstrA%,X:INX:INY:CMP#&D:BNEaf:RTS
 1430\"…"execmd
 1440.execmd:LDY#strA%DIV256:LDX#strA%MOD256:JSRoscli
 1450LDY#0:LDAfilesize:TAX:RTS
 1460\"…"Prepcmd
 1470\"„"takes x as cmdno ret x ptr to
 1480\"„"strA%
 1490.prepcmd:LDY#0:.ez:DEX:BNEnexcmd:.ey:LDAcmdadd,Y:CMP#&80:BCCam:AND#&7F:STAstrA%,X:INX:RTS
 1500.am:STAstrA%,X:INX:INY:BNEey
 1510.nexcmd:LDAcmdadd,Y:INY:CMP#&80:BCCnexcmd:BCSez     
 1520\"…"Display error
 1530\"„"takes x as strno
 1540.diserror
 1545LDAerraddr:STAerradd:LDAerraddr+1:STAerradd+1
 1550LDY#0:.ba:DEX:BNEbb:.bc:LDA(erradd),Y:CMP#&80:BCCbd:AND#&7F:JSRoswrch:JSRosnewl:RTS
 1560.bd:JSRoswrch:CMP#&D:BNEap:JSRosnewl:.ap:INY:BNEbc
 1570.bb:LDA(erradd),Y:INY:CMP#&80:BCCbb:CLC:TYA:ADCerradd:STAerradd:LDA#0:ADCerradd+1:STAerradd+1:LDY#0:BEQba
 1580\"ƒ"Strings
 1590.cmdadd
 1600\"„"*LDPIC FE
 1610 EQUS"*LDPIC":EQUB ASC(" ")OR&80
 1620\"„"*SCRLOAD FD
 1630 EQUS"*SCRLOAD":EQUB ASC("O")OR&80
 1640\"„"*TYPE FC
 1650 EQUS"*TY":EQUB ASC(".")OR&80
 1660\"„"*DUMP FB
 1670 EQUS"*DU":EQUB ASC(".")OR&80
 1680\"„"*EXEC FA
 1690 EQUS"*EX":EQUB ASC(".")OR&80
 1700\"„SPECIALS ABOVE ALTER NoSpecials%
 1710\"„"*DRIVE
 1720EQUS"*DR":EQUB ASC(".")OR&80
 1730\"„"*DIN
 1740EQUS"*DI":EQUB ASC("N")OR&80
 1750\"„"*LOAD
 1760EQUS"*LO.":EQUB ASC(" ")OR&80
 1770\"„"1100
 1780.ladd
 1790EQUS" 1100":EQUB&D
 1800.erraddr:EQUWerrtxt
 1805.errtxt
 1810\"„" 1 usage"
 1820EQUS"Usage <fsp> (<dno>/<dsp>) (<drv>":EQUB ASC(")")OR&80
 1830\"„" 2 file not found 
 1840EQUS"file not foun":EQUB ASC("d")OR&80
 1850\"„" 3 exe address invalid
 1860EQUS"Special exe add not code":EQUB ASC("d")OR&80
 1870\"„" 4 extended help 
 1880EQUS"Basic progs need exe 8023":EQUB&D
 1885EQUS"Basic progs need correct load":EQUB&D
 1890EQUS"ROM load should be 8000":EQUB&D
 1900EQUS"LDPIC on disk DATA has exe 7FFE":EQUD&D
 1910EQUS"SHOWPIC DATA has exe 7FFD NOT WORKING":EQUD&D
 1920EQUS"Files to be *TYPE exe 7FFC":EQUD&D
 1930EQUS"Files to be *DUMP exe 7FFB":EQUD&D
 1940EQUS"Files to be *EXEC exe 7FFA"
 1945EQUD&8D
 1950\"„"RUN
 1960.run
 1970EQUS"RUN":EQUB&D:EQUB0
 1980]:NEXT:PRINT"…";~P%-code%
 1990PRINT"ƒZERO PAGE CODE= "~codeend-codebegin
 2000ENDPROC
 2010DEFPROCtest
 2020OSCLI "SAVE "+prog$+" 7000 "+STR$~(P%)  
 2030ENDPROC
>
