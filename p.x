L.
   10*K.1 SAVE"P.X"
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
  260strptr=&2A:Aptr=&2C:tempy=&2E:tempx=&2F
  270switch=&30
  280blockstart=&70:load=blockstart+2:exe=blockstart+6:size=blockstart+&A
  290trueadd=&82
  300basicpage=&8F:filesize=&8E
  310strA%=&6A0
  320code%=&7000
  330PRINT"17/3/2020"
  340PRINT"„P."+prog$
  350PROCassemble
  360PROCtest
  370END:REM"…..........." 
  380DEFPROCassemble
  390osasci=&FFE3:osbyte=&FFF4:oswrch=&FFEE:osnewl=&FFE7:osgbpb=&FFD1:osfile=&FFDD:osargs=&FFDA:osbget=&FFD7:osbput=&FFD4:osbpb=&FFD1:osfind=&FFCE:osrdch=&FFE0:oscli=&FFF7:osfsc=&21E:osword=&FFF1
  400b2run=&BD2C:b1run=&BD14
  410FORi%=0TO2STEP2:P%=code%:[OPT i%
  420\"…"get osargs into blockstart
  430LDX#blockstart:LDY#0:LDA#1:JSRosargs
  440\"„ptr to command into blockstart&70
  450\"„X and Y are preserved osargs
  460LDX#0:TXA:.aa:CMP#&D:BEQcmdend:INY:LDA(blockstart),Y:CMP#32:BNEaa:INX:BNEaa:.cmdend:CPX#2:BNEab:DEX:STXtempx:DEY:STYtempy
  470\"…"Have drive param
  480LDX#NoSpecials%:JSRprepcmd:LDYtempy:LDA(blockstart),Y:STAstrA%,X:INX:LDA#&D:STAstrA%,X
  490DEY:STA(blockstart),Y:STYtempy
  500JSRexecmd
  510LDXtempx:LDYtempy
  520.ab:CPX#1:BCCac
  530\"…"Have DIN param
  540.ad:DEY:LDA(blockstart),Y:CMP#32:BNEad:LDA#&D:STA(blockstart),Y:STYtempy:LDX#NoSpecials%+1:JSRprepcmd:LDYtempy
  550DEX
  560.ae:INY:INX:LDA(blockstart),Y:STAstrA%,X:CMP#&D:BNEae:CMP#&32:BEQae
  570LDA#&D:STAstrA%,X
  580JSRexecmd
  590.ac
  600\"…"Process filename
  610\"„now have blockstart with filename
  620\"…"get file info
  630LDX#blockstart:LDY#0:LDA#5:JSRosfile:CMP#1:BEQal:LDX#2:JMPdiserror:.al
  640\""file not found
  650\"„get file info if A<> 1 not a file
  660\"…"check for specials
  670LDAexe+1:CMP#&7F::BNEromcheck
  680LDA#EndSpecial%:STAswitch:LDX#NoSpecials%
  690LDAexe
  700.ag:CMPswitch:BEQexespecial
  710INCswitch:DEX:BNEag
  720\""Special exe address not coded
  730LDX#3:JMPdiserror:.al
  740\"…"basicorexe
  750.basicorexe
  760LDAload+1:STAbasicpage:CMP#&11:BCSah
  770LDAload:STAtrueadd:LDAload+1:STAtrueadd+1:LDA#00:STAload:LDA#&11:STAload+1:LDAsize+1:STAfilesize
  780\"„"file loaded 
  790LDA#&8C:JSRosbyte:\"„"*tape
  800LDXfilesize:INX:LDA#00:STAload:LDA#&11:STAload+1:LDY#0:.iq1:LDA(load),Y:STA(trueadd),Y:INY:BNEiq1:INCload+1:INCtrueadd+1:DEX:BNEiq1
  810.aj:LDAexe+1:CMP#&80:BNEak:LDAexe:CMP#&23:BNEak
  820\"…"Basic progs
  830LDAbasicpage:STA&18:LDX#NoSpecials%+2
  840LDA#138:.ui:LDYrun:LDX#0:JSRosbyte:INCui+1:BNEui
  850RTS
  860.ak:JMP(exe)
  870\"…"romcheck
  880.romcheck:LDAload+1:CMP#&80:BNEbasicorexe:JMPloadfile
  890\"„"Note jmp will saves RTS!
  900.ah:JSRloadfile:BNEaj
  910\"…"exespecial
  920.exespecial
  930JSRprepcmd:LDY#0:.af:LDA(blockstart),Y:STAstrA%,X:INX:INY:CMP#&D:BNEaf
  940JMPexecmd
  950\"„"Note jmp will saves RTS!
  960\"ƒ"Routines
  970\"…"loadfile  
  980.loadfile:LDA#&FF:JSRosfile:RTS
  990\"…"execmd
 1000.execmd:LDY#strA%DIV256:LDX#strA%MOD256:JSRoscli:RTS
 1010\"…"Prepcmd
 1020\"„"takes x as cmdno ret x ptr to
 1030\"„"strA%
 1040.prepcmd:LDY#0:.ez:DEX:BNEnexcmd:.ey:LDAcmdadd,Y:CMP#&80:BCCam:AND#&7F:STAstrA%,X:INX:RTS
 1050.am:STAstrA%,X:INX:INY:BNEey
 1060.nexcmd:LDAcmdadd,Y:INY:CMP#&80:BCCnexcmd:BCSez     
 1070\"…"Display error
 1080\"„"takes x as strno
 1090.diserror
 1100LDY#0:.ba:DEX:BNEbb:.bc:LDAerradd,Y:CMP#&80:BCCbd:AND#&7F:JSRoswrch:JSRosnewl:RTS
 1110.bd:JSRoswrch:INY:BNEbc
 1111.bb:LDAerradd,Y:INY:CMP#&80:BCCbb:BCSba
 1120\"ƒ"Strings
 1130.cmdadd
 1140\"„"*LDPIC FE
 1150 EQUS"*LDPIC":EQUB ASC(" ")OR&80
 1160\"„"*SCRLOAD FD
 1170 EQUS"*SCRLOA":EQUB ASC("D")OR&80
 1180\"„"*TYPE FC
 1190 EQUS"*TY":EQUB ASC(".")OR&80
 1200\"„"*DUMP FB
 1210 EQUS"*DU":EQUB ASC(".")OR&80
 1220\"„"*EXEC FA
 1230 EQUS"*EX":EQUB ASC(".")OR&80
 1240\"„SPECIALS ABOVE ALTER NoSpecials%
 1250\"„"*DRIVE
 1260EQUS"*DR":EQUB ASC(".")OR&80
 1270\"„"*DIN
 1280EQUS"*DI":EQUB ASC("N")OR&80
 1285.erradd
 1290\"„"usage"
 1300EQUS"Usage <fsp> (<dno>/<dsp>) (<drv>":EQUB ASC(")")OR&80
 1310\"„"file not found
 1320EQUS"file not foun":EQUB ASC("d")OR&80
 1325\"„"exe address invalid
 1326EQUS"Special exe address not code":EQUB ASC("d")OR&80
 1330\"„"RUN
 1340.run
 1350EQUS"RUN":EQUB&D:EQUB0
 1360]:NEXT:PRINT"…";~P%-code%:ENDPROC
 1370DEFPROCtest
 1380OSCLI "SAVE "+prog$+" 7000 "+STR$~(P%)  
 1390ENDPROC
>
