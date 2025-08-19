.MagicData
\all entrys of the type
\entrytype,xxxxxxx,exec,load ident
\where xxxx has different code to be run
\note order is important as a rom and basic can have characteristics of text
\

\9,number of bytes to match anywhere in first Page,exec,load,ident
EQUS 9,5,"<>&E00",&23,&80,0,&0E,"Basic page=&E00 #1",13
EQUS 9,6,"<>&1100",&23,&80,0,&11,"Basic page=&1100 #1",13
\Entry 6
\6,offset,nobytes,check bytes,exec,load,ident
EQUS 6,7,3,0,"(C)",&CD,&D9,0,&80,"Rom #1",13
\Entry type 1
\Offset, nobytes,exec,load ident
\1,Offset -number of bytes in to read then use content of this to checkfrom, nobytes,exec,load ident
\EQUS 1,4,7,&E7,&90,"<>&E00",&23,&80,0,&E,"relocation to E00 #1",13 \superceeded by entry 9
EQUS 1,0,1,&10,&80,&FE,&7F,0,0,"Ldpic #1",13
EQUS 1,0,1,&60,&40,&FE,&7F,0,0,"Ldpic #2",13
EQUS 1,0,1,&10,0,&FE,&7F,0,0,"Ldpic #3",13
EQUS 1,0,1,&0D,00,&23,&80,0,0,"Basic #1",13
EQUS 1,1,2,&30,0,&30,&F8,&7F,0,0,"DEC compressed picture #1",13

\Entry type 2
\2,Startrange,Endrange,minvalue,maxvalue,exec,load ident
EQUS 2,&66,&78,0,&20,&F9,&7F,0,&11,"TYB music samples #6",13
\Entry type 3 
\3,loadadd,exec,load,ident
EQUS 3,&E0,&31,&F6,&7F,0,0,"Repton 3 screen #1",13
\Entry type 4
\4,exec,exec,load,ident
EQUS 4,&23,&80,&23,&80,0,0,"Basic #2",13
EQUS 4,&1F,&80,&23,&80,0,0,"Basic #3",13
EQUS 4,&2B,&80,&23,&80,0,0,"Basic #4",13
EQUS 4,&7,&7F,&7,&7F,0,&7C,"Mode 7 screen #1",13
EQUS 4,&6,&7F,&6,&7F,0,&60,"Mode 6 screen #1",13
EQUS 4,&5,&7F,&5,&7F,0,&58,"Mode 5 screen #1",13
EQUS 4,&4,&7F,&4,&7F,0,&7C,"Mode 4 screen #1",13
EQUS 4,&3,&7F,&3,&7F,0,&40,"Mode 3 screen #1",13
EQUS 4,&2,&7F,&2,&7F,0,&30,"Mode 2 screen #1",13
EQUS 4,&1,&7F,&1,&7F,0,&30,"Mode 1 screen #1",13
EQUS 4,&0,&7F,&0,&7F,0,&7C,"Mode 0 screen #1",13
\see DecodingRepton.pdf
\8,length,exec,load,ident
EQUS 8,&30,&25,&F4,&7F,0,0,"Repton Infinity screen #1",13
EQUS 8,&20,&26,&F6,&7F,&E0,&31,"Repton 3 screen #2",13

\Entry 5
\5 no of high byte pairs (high,count or higher),exec,load,ident
EQUS 5,1,&77,&7,&F9,&7F,0,&11,"TYB music samples #1",13
EQUS 5,1,&76,&B,&F9,&7F,0,&11,"TYB music samples #2",13
EQUS 5,1,&66,&7,&F9,&7F,0,&11,"TYB music samples #3",13
EQUS 5,1,&68,&7,&F9,&7F,0,&11,"TYB music samples #4",13
EQUS 5,1,&67,&7,&F9,&7F,0,&11,"TYB music samples #5",13
EQUS 5,1,01,&40,0,0,&F5,&7F,"ScrLoad #1",13
EQUS 5,1,&FF,&A0,0,0,&F5,&7F,"ScrLoad #2",13
EQUS 5,2,' ',0,'e',0,&FC,&7F,0,0,"text/word #1",13
EQUS 5,2,' ',0,'E',0,&FC,&7F,0,0,"text/word #2",13
\EQUS 5,3,0,1,&80,1,&2E,1,&F7,&7F,0,0,"viewsheet #1",13

\https://en.wikipedia.org/wiki/Letter_frequency
\counts above 5%
\'a','e','h','i','n','o','r','s','t' =45% 
\allow for spaces commas full stops etc
\Entry 7
\7,count,no entries,bytes,exec,load,ident
EQUS 7,110,8,'a','e','h','i','n','o','r','s','t',&FC,&7F,0,0,"text/word #3",13
EQUS 7,110,8,'A','E','H','I','N','O','R','S','T',&FC,&7F,0,0,"text/word #4",13

\marks end of block
EQUS 0

\10 20 3dsurfa
\10 80 cow daffy guards nfl quaza
\10 00 arnee wwolf
\60 40 shape sail root03 mand01 mand02 mand04 root01 root02
\20 40 mand03
\section for Magic tables