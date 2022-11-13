\\ this program started as a conversion from a BBC basic /MC prog
\ as such memory was an issue so three letter routine naming is used
\ this will be changed over time
\ labels are two character unique after conversion again this will not
\be maintained as {} can be used to reuse labels

Tlines%=3
Blines%=3
cinit%=&7C01+(&28*(Tlines%))
Topw%=0
Btmw%=4
Mainw%=8
filterTxtLen=17:

\red
Csel%=129:
\green
Clet%=130:
\black background
Cnsel%=156
mm%=19:maxmnu%= 65+mm% :pll%=37

Nolen=&A0
\…Zero Page
\IntA &2A -&2D
IntA=&2A
\&2E TO &35 BASIC FLOATING
StrAlen=&2E:cll=&2F:comprec=&30
ll=&31:cnl=&32:flag=&33:tempy=&34:tempx=&35:\ ll = lastline
\&3B TO &42 BASIC FLOATING
curadd=&3F:filtA=&41
\&70 - 8F basic for users
z=&74:sti=&76:
Apub=&7B:sno=&7D:APtr=&7F
\&90-&91 econet
 zp=&A8
\&B0- &BF FILESYSTEM SCRATCH
\&F8-F9 unused by os1.2
\&404 -&407 A% &468 -&46B Z%
\b,c,d used
\d Aptr store
\e FILTERS 1=disk 2=PUB 4=type
 \e cont 8=fav A=SearchText
\e+1 browse=1 else=0 for selectiƒon
\f filtA
 a=&404:b=&408:c=&40C:d=&410:e=&414:f=&418:g=&41C:h=&420:i=&424:j=&428:k=&42C:l=&430:m=&434:n=&438:o=&43C:p=&440:q=&444:r=&448:s=&44C:t=&450:u=&454:v=&458:w=&45C:x=&460:y=&464:zz=&468
atozStart%=&404:atozlen%=&68
\PG &600 STRING MANIPULATION
StrA%=&640:Fna%=&6FF-10:stxt%=&620
\PG A00-AFF rs232 and cassette
FS%=&901
fr%=&1100:\Filter results"
cl%=&1900:\catdat
fl%=&6000:\SOFTREC
code%=&6D00
cla%=&19:\cat load address
\MC variables
Dr%=3:\drive to be used to read cat etc
\OS routines
osasci=&FFE3:osbyte=&FFF4:oscli=&FFF7:osfile=&FFDD:osnewl=&FFE7:osword=&FFF1

ORG &6D00
GUARD &7C00

.start
\Primitaive Sub routines
\Set cursor off sco
.sco
{LDA #23:JSR osasci:LDA #1:JSR osasci:LDX #9:LDA #0:.ow:JSR osasci:DEX:BNE ow:RTS}
\Terminate filter Array tfa
.tfa
{ LDA #0:TAY:STA(filtA),Y:LDA filtA+1:STA g:LDA filtA:STA f:LDA filtA+1:STA f+1:STA p:RTS }
\SetToSearchFilterResults ssfr
.ssfr
{JSR tfa:JSR ifr:JMP idf:}\RET
\Copy z to int czi z TO Y
.czi
{:LDA z:STA a,Y:LDA z+1:STA a+1,Y:RTS }
\Copy int to z ciz Y to z
.ciz
{:LDA a,Y:STA z:LDA a+1,Y:STA z+1:RTS }
\clearz clz
.clz
{:LDA #0:STA z:STA z+1:RTS }
\Clearint cli offset from a in X
.clearint
.cli
{:LDA #0:LDY #3:.dx:STA a,X:INX:DEY:BPL dx:RTS }
\StrAlen len of str
\Cap StrA%
.Cap
{:LDY StrAlen:.aa:LDA StrA%,Y:CMP #97:BCC ab:SBC #32:STA StrA%,Y:.ab:DEY:BPL aa:RTS }
\Din command
.din
{:LDX dsadd:LDY dsadd+1:JMP oscli }\RET
.dsadd
 EQUW dinstr:.dinstr:EQUS"DIN   ":EQUB &D 
\CheckLen
\look for nulls and space at end
.CheckLen
{ RTS:LDY StrAlen:.ya:DEY:LDA StrA%,Y:BEQ ya:CMP #32:BEQ ya:INY:STY StrAlen:RTS }
\MovetoRecz mrz
.mrz
{:LDA z:BNE pc:LDA z+1:BEQ pd:DEC z+1:.pc:DEC z:JSR nxr:JMP mrz:.pd:RTS }
\SetLen stl StrAlen from &od
.stl
{:LDY #0:LDA #&0D:.wz:CMP StrA%,Y:BEQ wy:INY:BNE wz:.wy:STY StrAlen:RTS }
\DriveSelect ds Takes ASC drive
\Letter in A
.ds
{:STAdrstr+3:LDX drstradd:LDY drstradd+1:JMP oscli:} \rts
.drstr:EQUS"DR. ":EQUB &D:.drstradd:EQUW drstr
\Set Din Z sdz
.sdz
{:LDY #1:.ja:LDA z,Y:STA IntA,Y:DEY:BPL ja:LDY #0:LDX #48

:.la:DEC IntA+1:BNE lc:LDX #50:LDY #56:.lc:LDA IntA:SEC:
SBC #100:
BCC le:INX:STA IntA:BNE lc:.le:TYA:ADC IntA:STA IntA:SEC:SBC #100 
:BCC lv:INX:STA IntA:.lv:STX dinstr+3
STX StrA%
LDX #48:.lh:LDA IntA:SEC:SBC #10:BCC lj:INX:STA IntA:BNE lh:.lj:STX dinstr+4:STX StrA%+1:LDA #48:ADC IntA:STA dinstr+5:STA StrA%+2:RTS }
\check catfile exists cce
.cce
{:LDA catdatadd:STA block:LDA catdatadd+1:STA block+1:LDA #5:LDX blockadd:LDY blockadd+1:JMP osfile:}\rts
\load catfile lcf
.lcf:
{ JSR ifcp:LDA #4:STA comprec:LDA catdatadd:STA block:LDA catdatadd+1:STA block+1:JMP lf:}\rts
\Loadpub lpub
.lpub
{:JSR ifsp:LDA #0:STA comprec:LDA pubadd:STA block:LDA pubadd+1:STA block+1:JMP lf:} \rts
\Loaddin ldin
.ldin
{:JSR ifcp:LDA #0:STA comprec:LDA dinadd:STA block:LDA dinadd+1:STA block+1:JMP lf:}\rts
\Loadfile lf†Needs Aptr set
.lf
{:LDA APtr:STA block+2:LDA APtr+1:STA block+3:LDA #0:STA block+6:LDA #&FF:LDX blockadd:LDY blockadd+1:JMP osfile:}\rts

\SortStr
.SortStr
{:JSR stl:JSR Cap:JMP CheckLen:}\rts
\Copy Record crd
.crd
{:JSR ged:TYA:CLC:ADC comprec:TAY:TAX:DEY:.dm:LDA (APtr),Y:STA(filtA),Y:DEY:BPL dm:TXA:CLC:ADC filtA:STA filtA:LDA #0:ADC filtA+1:STA filtA+1:LDA #46:JMP osasci:}\rts
\Get end description ged ret Y
.getenddescription
.ged
{:LDY #0:.ga:LDA (APtr),Y:INY:CMP #&80:BCC ga:RTS }
\Get search selection gss
.gss
{:JSR cda:JSR ifr:JSR est:JSR sdt:JSR tfa:LDA fr%:BEQ ij:JSR idf:JSR gns:
JSR getinput
CPY #&D:BEQ aa:RTS:.aa
JSR postgns
JSR idf:JSR mrz:JSR cas:JSR cda:JSR Search:JSR ssn:.ij:RTS }
\Search Description txt sdt
.sdt
:JSR SortStr:.va:JSR Search:BNE vd:RTS:.vd:JSR crd:JSR nxr:CLC:BCC va
.Search
LDX StrA%:STX tempx:LDY #0:.qj:LDA(APtr),Y:BNE vb:RTS:.vb:CMP tempx:BEQ try:CMP #&80:BCS endrec:INY:BNE qj
.try
:LDX #0:STY tempy:.trynext:INX:CPX StrAlen:BNE vc:TXA:RTS:.vc:INY:LDA(APtr),Y:CMP StrA%,X:BEQ trynext:SEC:SBC #&80:CMP StrA%,X:BEQ trynext:LDY tempy:INY:BNEqj
.endrec
:JSR nxr:LDY #0:BEQ qj
\NextRecord nxr
.nxr
:LDY #&FF:.qe:INY:LDA(APtr),Y:BEQ isn:CMP #&80:BCC qe:INY:TYA:CLC:ADC APtr:STA APtr:LDA #0:ADC APtr+1:STA APtr+1:CLC:LDA comprec:ADC APtr:STA APtr:LDA #0:ADC APtr+1:STA APtr+1
\incSearchNo isn
.isn
{:INC sno:BNE pb:INC sno+1:.pb:RTS }
\get total record count trc
.trc
.totalreccount
{:JSR nxr:LDY #0:LDA(APtr),Y:BNE totalreccount:RTS }
\"„Selectsearchno ssn
.ssn
{:LDA sno+1:STA z+1:LDA sno:STA z:RTS }
\Display enter text det
.det
{:LDY #Btmw%:JSR slw:LDA #131:JSR osasci:JSR psx:LDA #Clet%:JMP osasci:}\rts
CLC:ROL v:ROL v:LDA e:ORA #4:STA e:RTS
\Displayfilterscreen DFS dfs
.DFS
:JSR him:
.dfs:LDX #0:STX comprec:STX e+1:JSR ifp:JSR ims:LDY #0:STY tempy:.ma:JSR sl:JSR pre:JSR printselection:JSR nxr:LDY #0:LDA(APtr),Y:BNE ma:JSR cursorset:
.tabscreeninput:JSR getinput
CPY #9:BEQ tabscreeninput
CPY #&D:BEQ xu:RTS
.xu
\selection section
LDA cnl
CMP #65:BNE aaa
\Browse din
JSR ldin:LDA #&5C:STA b:LDA #0:STA c:JSR gsc:JSR wtf:JSR wdn:JMP dfs
.aaa:CMP #66:BNE bbb
\Din by no
JSR gnz:LDY #&5C:JSR ciz:JSR ldin:JSR mrz:LDA #0:STA c:JSR wtf:JSR wdn:JMP dfs
.bbb:CMP #67:BNE ccc
\publisher
JSR lpub:LDA #&60:STA b:LDA #2:STA c:JSR gsc:JSR wtf:LDA e:ORA #2:STAe:JMP dfs
.ccc:CMP #68:BNE ddd
\progtype
.stt:LDA e:ORA #4:STA e:JSR itm:JSR iptt:JSR ims:.mo:JSR sl:JSR pre:LDA #&D:JSR osasci:JSR nxr:LDY #0:LDA(APtr),Y:BNE mo:JSR cursorset:JSR getinput:CPY #&D:BEQ xx:RTS:.xx:LDY #&54:JSR clearint:JSR cda:LDA cnl:SEC:SBC #65:STA z:STA tempx
 CLC:ROL A:ROL A:STA v:JSR mrz:LDA #3:STA c:JSR wtf:JMP dfs
.ddd:CMP #69:BNE eee
\favorate
.tlf
:LDX #0:LDA w:EOR #&40:STA w:BNE jy:LDX #0:.jx:INX:LDA fav,X:CMP #&80:BCC jx:INX:.jy:LDA e:EOR #8:STA e:LDY #0:.jw:LDA fav,X:STA StrA%,Y:INY:INX:CMP #&80:BCC jw:DEY:JSR esa:JSR itfs:JSR clz:LDA #4:STA z
JSR mrz:JSR copystrToArray:JSR itm:JMP dfs
.eee:CMP #70:BNE fff
\Search desc
.ox:JSR getsearchtxt:JMP dfs
.fff:CMP #71:BNE ggg
\Search pub
LDX #2:STX c:STX tempx:JSR det:JSR lpub:JSR gss:LDA fr%:BNE iy:JSR nsr:JMP dfs:.iy:LDY #&60:JSR czi:JSR lwtf:LDA e:ORA #2:STA e:JMP dfs
.ggg:CMP #72:BNE hhh
\Search din
LDX #0:STX c:STX tempx:JSR det:JSR ldin:JSR gss:LDA fr%:BNE oy:JSR nsr:JMP dfs:.oy:LDY #&5C:JSR czi:JSR wtf:JSR wdn:JMP dfs
.hhh:CMP #73:BNE iii:JMP afs:\Apply filter  results
.iii:CMP #74:BNE jjj:JMP DFS:\Clear filters      
.jjj:CMP #75:BNE kkk:.snd:LDA #210:LDX #1:JSR osbyte:\"„Sound off
.kkk:CMP #76:BNE lll:.tv:LDX #&FF:LDY #0:LDA #&90:JSR osbyte:JMP dfs:\TV255
.lll:CMP #77:BNE mmm
LDA e:AND #1:BEQ ooo:JSR ddc:LDY #0:.ae:LDA boot,Y:STA StrA%,Y:INY:CPY #8:BNE ae:LDX #0:.ag:LDA dinstr+3,X:STA StrA%,Y:INY:INX:CPX #3:BNE ag:RTS:.boot:EQUS"X !BOOT "
.mmm:CMP #78:BNE nnn:BEQ hlp
.nnn:CMP #79:BNE ooo
\Launch help
.hlp:STA hlpcmd:LDX hlpadd:LDY hlpadd+1:JMP oscli:.hlpadd:EQUW hlpcmd:.hlpcmd:EQUS"?":EQUB &D
.ooo:RTS

\no search results nsr
.nsr
{:LDX #0:STX comprec:STX e+1:LDA erradd:STA APtr:LDA erradd+1:STA APtr+1:JSR gns:JMP getinput:}\rts
\apply filters afs
.applyfilters
.afs
\are any filters set?
:LDA e:BNE xh:JMP BCD:.xh
:LDY #Btmw%:JSR slw:JSR icd:JSR ifr:JSR tfa
.xa:INC catdat+6:JSR cce:CMP #1:BEQ xb
\show filter results
.pg:JSR pkt:LDY #Mainw%:JSR slw:LDA fr%:
\do we have any records?
BNE oz:JSR nsr:JMP dfs:.oz:
JSR idf:LDA APtr+1:STA d+1:LDA APtr:STA d:
JMP browseresults
\JSR gns:JSR getinput:JSR postgns:JMP lcr
.xb:LDA #130:JSR osasci:LDA #46:JSR osasci:JSR lcf:LDA f:STA filtA:LDA f+1:STA filtA+1:LDA e:AND #1:BEQ xc
\Filter by diskno fbd
.fbd
 LDY #0:LDA(APtr),Y:BEQ oa:JSR ged:INY:LDA(APtr),Y:CMP x:BNE dn:INY:LDA(APtr),Y:AND #3:CMP x+1:BNE dn:JSR crd:.dn:JSR nxr:JMP fbd:.oa:JSR ssfr
.xc:LDA e:AND #2:BEQ xd
\Filter by pub fbp
.fbp
LDY #0:LDA(APtr),Y:BEQ ob::JSRged:LDA(APtr),Y:CMP y:BNE du:INY:INY:INY:LDA(APtr),Y:AND #3:CMP y+1:BNE du:JSR crd:.du:JSR nxr:JMP fbp:.ob:JSR ssfr
.xd:LDA e:AND #4:BEQ xe
\Filter by type fbt
.fbt:LDY #0:LDA(APtr),Y:BEQ oc::JSR ged:INY:INY:INY:LDA(APtr),Y:AND #&1C:CMP v:BNE dy:JSR crd:.dy:JSR nxr:JMP fbt:.oc:JSR ssfr
 .xe:LDA e:AND #8:BEQ xf
\Filter by fav fbf
.fbf:JSR isfav:BEQ dt:JSR crd:.dt:JSR nxr:JMP fbf:.od:JSR ssfr
.xf:LDA e:AND #16:BEQ xg
\Filter by searchtext fbs
.fbs:LDY #0:.dq:LDA stxt%,Y:STA StrA%,Y:CMP #&D:BEQ zs:INY:BNE dq:.zs:JSR sdt:JSR ssfr
\Check for OVERFLOW
.xg:LDA p:CMP #cla%:BCS pe:JMP xa
.pe
JSR totalreccount:LDY #21:.pf:LDA overflow,Y:STA(APtr),Y:DEY:BPL pf
JMP pg
.overflow:EQUS"..OUT OF MEMORY.":EQUB &AE:EQUB 0:EQUB 0:EQUB 0:EQUB 0:EQUB 0:EQUB 0
.dh:RTS
\isfav
\rets 1 in A if current rec is fav
.isfav
{:LDY #0:LDA(APtr),Y:BEQ od:JSR ged:INY:INY:INY:LDA(APtr),Y:AND #&40:RTS }
\getsearchtxt (description) getsearchtxt
.getsearchtxt
{:LDX #3:STX tempx:JSR det:JSR est:CPY #2:BCC getsearchtxt:.ak:LDA StrA%,Y:STA stxt%,Y:DEY:BPL ak:LDA #5:STA c:LDA e:ORA #&10:STA e:LDY StrAlen:LDA #32:STA StrA%,Y:JMP lwtf:}\rts
\Browse catdat BCD
.startexec
.BCD:JSR him
.bcd
\set exten record 
INC e+1
JSR icd
\print top window stuff
JSR pht:JSR sco
\print btm window stuff
JSR pkt
\select main window
\LDY #Mainw%:JSR slw:

INC catdat+6:JSR cce:CMP #1:BNE dh:JSR lcf:LDA #0:STA b:
\display filter results re-entry
.browseresults

JSR gns
JSR getinput

{CPY #9:BNE ka:JSR dfs:.ka
CPY #32:BNE kb:JMP spa:.kb
CPY #63:BNE kc:JMP que:.kc
CPY #&D:BEQ lcr:}
\should not be here?
RTS
\.XXoe:JSR dfs:JMP 
\Launch current record lcr
\X filename din
\put X% dinno u%=catno
\Need to convert catno-filename
.lcr
JSR postgns
{:JSR cda:JSR mrz:}
\clear X%
LDX #&5C:JSR clearint
\clear U%
LDX #&50:JSR clearint
\get X% din no
JSR getenddescription:INY:LDA(APtr),Y:STA x:
INY:LDA(APtr),Y:AND #3:STA x+1:
\U% cat number
LDA(APtr),Y:ROR A:ROR A:AND #&1F:STA u
CLC:JSR ddc:
\read catalogue
\ReadCat rac ret 0 OR NOT IN A
{:LDA #&7F:LDX pramadd:LDY pramadd+1:JSR osword:LDA pramadd+10:SBC &10:}
LDA #88:STA StrA%:LDA #32:STA StrA%+1
LDX u:LDA #0:CLC:.oi:ADC #8:DEX:BNE oi:TAY:LDX #0:LDA cat+7,Y:STA StrA%+2:LDA #46:STA StrA%+3
.oj:LDA cat,Y:CMP #32:BEQ rq:STA StrA%+4,X:INY:INX:CPX #7:BNEoj:LDA#32:STA StrA%+4,X:LDY #&FF
.rq:LDY #&FF:.ok:INY:INX:LDA dinstr+3,Y:STAStrA%+4,X:CMP #13:BNE ok
LDA #48:JSR ds
{:LDX #LO(StrA%):LDY #HI(StrA%):JMP oscli:}\RET

\dr/din/cat ddc
.ddc
{:LDA #51:JSR ds:LDY #&5C:JSR ciz:JSR sdz:LDY #2:.og:LDA StrA%,Y:STA dinstr+3,Y:DEY:BPL og:JMP din:} \RET
\PrintString X psx 
.psx
{:LDX tempx:LDY #0:.ju:CPX #0:BEQ jv:.jw:INY:LDA ptxt,Y:CMP #&80:BCC jw:DEX:BNE ju:INY:.jv:LDA ptxt,Y:AND #&7F:JSR osasci:LDA ptxt,Y:INY:CMP #&80:BCC jv:RTS }
\get no in z gnz maX len
.gnz:JSR clz:LDX #1:STX tempx:JSR det:JSR esn:STY tempy:LDY #0:.lm:LDA StrA%,Y:SEC:SBC #48:STA z:STA tempx:INY:TYA:CMP tempy:BEQ iq:.io:JSR mbt:LDA StrA%,Y:SEC:SBC #48:CLC:ADC z:STA z:STA tempx:LDA #0:ADC z+1:STA z+1:INY:TYA:CMP tempy:BNE io:.iq
LDA z+1:CMP #1:BCC ir:BEQ is:BCS gnz:.is:LDA z:CMP #&FF:BCS gnz:.ir:LDY #&5C:JSR czi:LDY tempy:DEY:RTS
\write din no wdn
.wdn
{:LDY #92:JSR ciz:LDY #0:JSR sdz:LDY #2:JSR esa:JSR itfs:JSR clz:LDA #1:STA z:JSR mrz:JSR copystrToArray:JSR itm:LDA e:ORA #1:STA e:RTS }
\Multiply by 10 mbt
.mbt
{:ASL z:ROL z+1:ASL z:ROL z+1:CLC:LDA tempx:ADC z:STA z:LDA #0:ADC z+1:STA z+1:ASL z:ROL z+1:RTS }               
\togglefav tlf


\Write to filterscreen wtf
.wtf
:JSR cas:.lwtf
{JSR esa:JSR itfs:JSR clz:LDA c:STA z:JSR mrz:JSR copystrToArray:JMP itm:}\rts

.ret:RTS
.que:LDA #79:JMP hlp
.spa:JSR getsearchtxt:LDA #&10:STA e:JMP afs
.mksend:RTS
\getinput waits for a character to be pressed
\ret on char selected or control keys (tab space ? )
\-------------------------------------------------------------
.getinput
{.mks
{.aa:LDA #&91:LDX#0:JSR osbyte:BCS aa}
\now have key value in y
\ ?
{:CPY #63:BEQ aa:
\space
CPY #32:BEQ aa:
\tab
CPY #9:BEQ aa:
\ret
CPY #&D:BEQ aa:
CPY #&8F:BEQ up
CPY #&8E:BEQ down
CPY #&8C:BEQ left
CPY #&8D:BEQ right
CPY #65:BCC mks
CPY ll:BCS getinput
\Move cursor to letter
TYA:TAX:JSR cursorclear:JSR itm:
\asc("a")
LDA #65:
STA cnl:CPX cnl:BEQ mn:.mm:JSR cursordown:CPX cnl:BNE mm:.mn:JSR cursorset:.ab:
JMP getinput
.aa:RTS }


\Makeselection mks ret A
\OR cursor
\.mks
\:.gti:LDA #&91:LDX#0:JSR osbyte:BCS gti:TYA::CMP #63:BEQ mksend:CMP #32:BEQ mksend:CMP #9:BEQ mksend:CMP #&D:BEQ mksend:CMP #&8F:BEQ up:CMP #&8E:BEQ down:CMP #&8C:BEQ left:CMP #&8D:BEQ right:CMP #65:BCC mks:CMP ll:BCS mks
\Move cursor to letter
\TAX:JSR cursorclear:JSR itm:LDA #65:STA cnl:CPX cnl:BEQ mn:.mm:JSR cursordown:CPX cnl:BNE mm:.mn:JSR cursorset:JMP mks
\down up right
.down
LDX ll:DEX:CPX cnl:BEQ mks:JSR cursordown:JMP mks:
.up
LDA cnl:CMP #65:BEQ mks:JSR cursorup:JMP mks:
.right
LDY #0:LDA(APtr),Y:BEQ bb:JSR gns:JMP mks
.left
LDA ll:SEC:SBC #65:\asc("A")
STA a:LDA sno:SEC:SBC a:STA a:LDA sno+1:SBC #0:STA a+1:LDX #0:
.chiz:LDA a,X:CLC:ADC a+1,X:ADC a+2,X:ADC a+3,X:BEQ startrecfile
:LDA a:SEC:SBC #mm%:STA z:LDA a+1:SBC #0:STA z+1:JSR cda:JSR mrz:JSR gns:JMP mks
\are at start of record file
.startrecfile
:LDA e+1:BEQ bf
\e+1 = flag for BCD mode
\does previous file exist?
:DEC catdat+6:JSR cce:CMP #1:BNE bg
\load catfile
JSR lcf:
JSR totalreccount
LDA sno:SEC:SBC #mm%:STA z:LDA sno+1:SBC #0:STA z+1:JSR cda:JSR mrz:JSR gns
JMP mks:\RTS
\previous file does not exist
.bg:INC catdat+6:.bf:JMP mks:
.bb:LDA e+1:BNE bc:JMP mks:
.bc:INC catdat+6:JSR cce:CMP #1:BNE bd:JSR lcf:JMP gsc:
.bd:DEC catdat+6:JMP mks
\cursor routines
.cursorclear:
{LDY #0:LDA #Cnsel%:STA(curadd),Y:RTS:}
.cursordown:
 {
 INC cnl:JSR cursorclear:CLC:LDA #&28:ADCcuradd:STA curadd:LDA #0:ADC curadd+1:STA curadd+1:JMP cursorset:}\rts
.cursorup
{:DEC cnl:JSR cursorclear:SEC:LDA curadd:SBC #&28:STA curadd:LDA curadd+1:SBC #0:STA curadd+1:JMP cursorset:}\rts
}
.cursorset:
 {LDY #0:LDA #Cnsel%+1:STA(curadd),Y:RTS:}
\startline sl
.sl
{ 
LDA #Csel%:JSR osasci:
LDA #Cnsel%:JSR osasci
LDA comprec:BEQ aa:JSR isfav: BEQ aa:LDA #135:BNE ab
.aa:LDA #Clet%:.ab
:JSR osasci:LDA ll:JSR osasci:INC ll:LDA #131:JMP osasci:}\rts
\print key text
.pkt
{
LDY #Btmw%:JSR slw:LDY #&FF:.ol:INY:LDA keytxt,Y:BEQ om:JSR osasci:BNE ol:.om:RTS
}
\printhelp text
.pht
{
LDY #Topw%:JSR slw:LDY #&FF:.bj:INY:LDA helptxt,Y:BEQ bk:JSR osasci:BNE bj:.bk:RTS
}
 \printselection ps
.printselection
{:LDY tempy:.mf:LDA FS%,Y:CMP #&80:BCS mg:JSR osasci:INY:BNE mf:.mg:AND #&7F:JSR osasci:LDA #&D:JSR osasci:INY:STY tempy:RTS }
\printentry pre
.pre
{:LDY #&FF:.mb:INY:LDA(APtr),Y:CMP #&80:BCS bi:CPY #0:BEQ mc:JSR cvc:.mc:JSR osasci:BNE mb:.bi:AND #&7F:JSR cvc:JSR osasci:LDA comprec:BNE expre:
\light blue
LDA #134:JSR osasci:.md:CPY #filterTxtLen:BCS me:LDA #&20:JSR osasci:INY:BNE md:.me:RTS }
\extended printentry expre
.expre
\white
:LDA #135:JSR osasci
JSR ged:TYA:CLC:ADC #5:STA cll:LDA(APtr),Y:STA z:INY:INY:INY:LDA(APtr),Y:AND #3:STA z+1:LDA(APtr),Y:ROR A:ROR A:AND #&F:TAY:LDA type,Y:JSR osasci:LDA #134:JSR osasci
\have pub in z
LDA #fl% DIV 256:STA Apub+1:LDA #fl% MOD 256:STA Apub:.on:LDA z+1:BEQ op:DEC z+1:LDX #0:.oq:LDY #0:.ou:LDA(Apub),Y:CMP #&80:BCS or:INY:BNE ou:.or:INY:CLC:TYA:ADC Apub:STA Apub:LDA #0:ADC Apub+1:STA Apub+1:DEX:BNE oq:BEQ on
.op:INC cll:LDX z:BEQ ov:LDA #0:STA z::BEQ oq:.ov:LDY #0:.ot:LDA(Apub),Y:CMP #&80:BCS os:JSR osasci:INC cll:LDA cll:CMP #pll%:BCS na:INY:BNE ot:.os:AND #&7F:JSR osasci
.na:RTS
.type:EQUS"ACGSMPUZ"
\Convert Case cvc
.cvc
{:CMP #35:BEQ ad:CMP #65:BCC bh:ADC #31:.bh:RTS:.ad:LDA #133:RTS }
\Selectwindow slw TAKES Y Topw%,btmw%,mainW%
.slw
{:LDX #5:LDA #28:.mj:JSR osasci:LDA window,Y:INY:DEX:BNE mj:LDA #12:JMP osasci:}\rts
\copy Aptr to str% cas
.cas
{:LDY #&FF::.mq:INY:LDA(APtr),Y:STA StrA%,Y:CMP #&80:BCC mq:STY StrAlen:RTS }
\expand strA esa
.esa
{:CPY #14:BCS mh:LDA StrA%,Y:AND #&7F:STA StrA%,Y:LDA #32:.mw:INY:STA StrA%,Y:CPY #14:BNE mw:.mr:ORA #&80:STA StrA%,Y:RTS 
.mh:LDY #14:LDA StrA%,Y:BNE mr }
\Generalselcommon gsc
.gsc
{:JSR gns:
JSR getinput
CPY #&D:BEQ aa:RTS:.aa
JSR postgns
JSR cda:JMP mrz:} \rts
\general selection gns
.generalselection 
.gns
{
:JSR ims:

LDY #0:LDA(APtr),Y:BEQ mz:JSR itm:JMP fc:.my:LDA #&D:JSR osasci:.fc:JSR sl:

JSR pre:JSR nxr:LDY#0:LDA(APtr),Y:BEQ mz:LDA ll:CMP #maxmnu%:BNE my:.mz:JSR cursorset:RTS
}\JSR mks:RTS :\CMP #&D:BNE gns}

.postgns
\get count back
{:LDA ll:SEC:SBC cnl:
\apply count back
STA tempx:LDA sno:SEC:SBC tempx:STA sno:LDA sno+1:SBC #0:STA sno+1
\select search no into Z
:JSR ssn
:LDA sno+1:LDX b:STA a+1,X:LDA sno:STA a,X:
LDA #&D:.xv:RTS: }
\CopystrToArray copystrToArray
.copystrToArray
{:LDY #&FF:.mx:INY:LDA StrA%,Y:STA(APtr),Y:CMP #&80:BCC mx:RTS }
\Init section
\initreccount initreccount
.initreccount
{:LDA #0:STA sno:STA sno+1:RTS }
\Init Filter string itfs
.itfs
{:LDA #FS% DIV 256:STA APtr+1:LDA #FS% MOD 256:STA APtr:JMP initreccount:}\rts
\Initmenuscreen ims
.ims
{:LDY #Mainw%:JSR slw:LDA #65:STA cnl:STA ll:JMP itm:}\rts
\Enter Search no esn
.esn
{:LDX numadd:LDY numadd+1:LDA #0:JSR osword:STY StrAlen:RTS 
.numadd:EQUW numip:.numip:EQUB StrA% MOD 256:EQUB StrA% DIV 256:EQUB 3:EQUB 48:EQUB 57}
\Enter Search Text est
.est
{:LDX txtadd:LDY txtadd+1:LDA#0:JSR osword:STY StrAlen:RTS 
.txtadd:EQUW txtip:.txtip:EQUB StrA% MOD 256:EQUB StrA% DIV 256:EQUB 12:EQUB 48:EQUB 90 }
\Copy Aptr TO d cad
.cad
{:LDA APtr+1:STA d+1:LDA APtr:STA d:RTS }
\Initcatdat icd
.icd
{:LDA #48:STAcatdat+6:RTS }
\Initprog type text iptt
.iptt
{:LDA #prtt DIV 256:STA APtr+1
STA APtr+1:LDA #prtt MOD 256:STA APtr:JSR cad:JMP initreccount:}\rts
\HardInitmenu him
.him
JSR lpub:.caz:LDY #atozlen%:LDA#0:.zy:STA atozStart%,Y:DEY:BPL zy
LDA #selectiontext DIV 256:STA APtr+1:LDA #selectiontext MOD 256:STA APtr:LDX#0:STX comprec:.ms:LDY #0:LDA(APtr),Y:BEQ itm:JSR cas:JSR esa:LDY #0:.mu:LDA StrA%,Y:STA FS%,X:CMP #&80:bCS mv:INY:INX:BNE mu:.mv:JSR nxr:INX:CLC:BCC ms
\Initmenu itm  
.itm
{:LDA #cinit% DIV 256:STA curadd+1:LDA #cinit% MOD 256:STA curadd:RTS }
\InitdisplayFilterResults idf
.idf
{:LDA# fr% DIV 256:STA APtr+1:LDA #fr% MOD 256:STA APtr:JMP initreccount:}\rts
\InitFilterResults ifr
.ifr
{:LDA #fr% DIV 256:STA filtA+1:LDA #fr% MOD 256:STA filtA:RTS }
\Initfilterptr ifp
.ifp
{:LDA #filttxt% DIV 256:STA APtr+1:LDA #filttxt% MOD 256:STA APtr:JMP initreccount:}\rts
\InitFileSoftrecArrayPtr ifsp
.ifsp:LDA #fl% DIV 256:STA APtr+1:LDA #fl% MOD 256:STA APtr:JSR cad:JMP initreccount:\"ƒrts
\InitFilecatdatArrayPtr ifcp
.ifcp
{:LDA #cl% DIV 256:STA APtr+1:LDA #cl% MOD 256:STA APtr:JSR cad:JMP initreccount:}\rts
\Copy d TO Aptr cda
.cda
{:LDA d:STA APtr:LDA d+1:STA APtr+1:JMP initreccount:}\rts
\Data
.pramadd
EQUW pram:.pram:EQUB Dr%:EQUD cat:EQUB 3:EQUB &53:EQUB 0:EQUB 0:EQUB &22:EQUB 0:.catadd
EQUW cat:.search:.cat:
.erradd
EQUW err:.err:EQUS"NO RECORD":EQUB &D3:EQUB 0
.ptxt
EQUS"Enter disk title":    EQUB &BA:
EQUS"ENTER DIN NO (0-510)":EQUB &BA
EQUS"Enter publisher":     EQUB &BA
EQUS"Enter description":   EQUB &BA
 .window
 \left X, bottom Y, right X and top Y
 \top
 EQUB 0:EQUB Tlines%   :EQUB 39:EQUB 0:
 \btm
 EQUB 0:EQUB 24        :EQUB 39:EQUB 24-Blines%:
 \main
 EQUB 0:EQUB 24-Blines%:EQUB 39:EQUB Tlines%
.fav:EQUS"O":EQUB &EE
.selectiontext
\A
EQUS "Of":EQUB &E6
\B
EQUS "Of":EQUB &E6
\C
EQUS "Of":EQUB &E6
\D
EQUS "Of":EQUB &E6
\E
EQUS "Of":EQUB &E6
\F
EQUS"        ":EQUB &80
\G
EQUB &80
\H
EQUB &80
\I
EQUB &80
\J
EQUB &80
\K
EQUB &80
\L
EQUB &80
\M
EQUB &80
\N
EQUB &80
EQUB 0
\Browse cat
.dinadd:EQUW dinrec:.dinrec:EQUS"dinrec":EQUB &D
.pubadd:EQUW pubrec:.pubrec:EQUS"softrec":EQUB &D
.catdatadd:EQUW catdat:.catdat:EQUS"catdat0":EQUB &D
.filttxt%:EQUS"BY DISK NAM":EQUB &C5
EQUS"BY DISK N":EQUB &CF
EQUS"BY PUBLISHE":EQUB &D2
EQUS"BY TYP":EQUB &C5
EQUS"BY FAVORIT":EQUB &C5
EQUS"SEARCH DESCRIPTIO":EQUB &CE
EQUS"SEARCH PUBLISHE":EQUB &D2
EQUS"SEARCH DISK NAM":EQUB &C5
EQUS"DISPLAY RESULT":EQUB &D3
EQUS"CLEAR AL":EQUB &CC
EQUS"SOUND OF":EQUB &C6
EQUS"TV25":EQUB &B5
EQUS"LAUNCH DIS":EQUB &CB
EQUS"DISPLAY GAME HEL":EQUB &D0
EQUS"DISPLAY MENU HEL":EQUB &D0:EQUB 0
.helptxt :\NB keep below 255 chars (currently v near)
\mode 7
EQUB 22:EQUB 7

EQUB 141:EQUB 135:EQUB 157:EQUB 132:EQUS "  MMC MENU DISPLAY ":EQUS TIME$("%x"):EQUB 13
EQUB 141:EQUB 135:EQUB 157:EQUB 132:EQUS "  MMC MENU DISPLAY ":EQUS TIME$("%x"):EQUB 13
EQUS "Search"
EQUB 130:EQUS "SPACE"
EQUB 135:EQUS "Advanced"
EQUB 130:EQUS "TAB"
EQUB 135:EQUS "Help"
EQUB 130:
EQUS "?"
EQUB 0
\"„ACGSMPUZ"\
.keytxt:
EQUB 13
EQUS"A":EQUB 131:EQUS"dvent"
EQUB 135:EQUS "C":EQUB 131:EQUS"heat"
EQUB 135:EQUS "G":EQUB 131:EQUS "ame"
EQUB 135:EQUS "Z":EQUB 131:EQUS"unknwn"
EQUB 135:EQUS "P":EQUB 131:EQUS"ic"
EQUB 135:EQUS "U":EQUB 131:EQUS"til"
EQUS"S":EQUB 131:EQUS "trat"
EQUB 133:EQUS "i":EQUB 131:EQUS"nvulnerable"
EQUB 133:EQUS "2":EQUB 131:EQUS "playr"
EQUB 133:EQUS "p":EQUB 131:EQUS "ass"
EQUB 133:EQUS "j":EQUB 131: EQUS"oys"
EQUB 133:EQUS "e":EQUB 131:EQUS "lectron"
EQUB 133:EQUS "l":EQUB 131:EQUS "vl"
EQUB 133:EQUS "X":EQUB 131:EQUS "life"
EQUB 133:EQUS "s":EQUB 131:EQUS"peed"
EQUB 135:EQUS"A/S fav" 
EQUB 0
.prtt
EQUS"TEXT ADVENTUR":EQUB &C5
EQUS"CHEAT":EQUB &D3
EQUS"GAM":EQUB &C5
EQUS"STRATEG":EQUB &D9:
EQUS"MUSI":EQUB &C3
EQUS"PICTUR":EQUB &C5
EQUS"UTILIT":EQUB &D9
EQUS"UNKOW":EQUB &CE
EQUB 0
.blockadd:EQUW(block):.block:EQUW 0:EQUB fl% MOD 256:EQUB fl% DIV 256:EQUW 0:EQUW 0:EQUD 0
.end

SAVE "mnudisp", start, end,startexec

\\cd d:\bbc/beebasm
\cd D:\GitHub\beebyams\beebasm
\beebasm -i mnudisp.asm -do mnudisp.ssd -boot x -v -title mmudisp
\\