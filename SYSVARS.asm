\** beebyams by RG

\** OS CONSTANTS

\zeropage

EscapeFlag=&FF
TextPointer=&F2

\oscalls

OSRDRM=&FFB9
GSINIT=&FFC2
GSREAD=&FFC5
OSFIND=&FFCE
OSGBPB=&FFD1
OSBPUT=&FFD4
OSBGET=&FFD7
OSARGS=&FFDA
OSFILE=&FFDD
OSBYTE=&FFF4
OSRDCH=&FFE0
OSASCI=&FFE3
OSNEWL=&FFE7
OSWRCH=&FFEE
OSWORD=&FFF1
OSCLI =&FFF7

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

FUNCTIONkey0 =128
FUNCTIONkey1 =129
FUNCTIONkey2 =130
FUNCTIONkey3 =131
FUNCTIONkey4 =132
FUNCTIONkey5 =133
FUNCTIONkey6 =134
FUNCTIONkey7 =135
FUNCTIONkey8 =136
FUNCTIONkey9 =137
FUNCTIONkey10 =138
FUNCTIONkey11 =139

