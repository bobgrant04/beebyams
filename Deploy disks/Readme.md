X-files disk 
this is where programs that X requires reside
These are modified to enable "side loading" to be made as simple as possible
Ldpic
tyb sample player are inbedded in x so are not required
At present this is just for Repton 3 and Infinity
Process
contains files needed to produce catdat files 
MMCmenu
comtains files needed to run mmcmenu system
rawcat
contains csv files for collection/s on this mmc


# beebyams
BBC model B mmc Menu system
This project attempts to build on the mmc dfs (disk filing system) that allows owners of BBC micros and emulators to have up to 510 disk images available for mounting virtually from the command line.
With this flexabilty comes the problem of using the system for a games system allowing for rapid selection of a game or program.
The Stairway to Hell archive had a good solution with their menu system however a number of changes will enable other collections to be added.  With this in mind a number of processes and programs will generate the required files to allow a more generic menu system

the start of the process requires TAB delimiated files in the following format:-
publisher:- name of publisher only have 1024 so try to limit
long title:- needs to be below 240 chars but for display needs to be less than 30 use the #character to denote joysticks etc
filename:- assumes $ dir needs to be less than 10 characters if dir specified or less than 8 if not
execute type :- crles chain run load execute special upper of lower case 
page number :- should be the true page required only required for basic or the lSB for specials
game type :-acgsmpuz adventure cheat game strategy music picture util z=unknown
favorite :- Y/N based on https://stardot.org.uk/forums/viewtopic.php?f=1&t=8259

these includeinal menu system https://www.stairwaytohell.com/bbc/sthcollection.html
The Yorkshire boys (PD) http://8bs.com/catalogue/tyb.htmalogue/tyb.htm
 Roms
 Cheats
Disc User http://8bs.com/catalogue/tdu.htm
 A & B computing http://8bs.com/catalogue/a&b.htm
 The micro user 
cbm http://bbcmicro.co.uk/  30 years games archive based on https://stardot.org.uk/forums/viewtopic.php?f=32&t=8270&hilit=disc+114
This is based on the released disks and then a seperate naming system for those not released.


programs used
X - Usage <fsp> (<dno>/<dsp>) (<drv>) a launcher program that takes a filename selects din and drive (defaults to current drive.  uses the exe details (as per *info command) to select any special processing (from 7F00 up) will re allocate code anywhere as relocation code runs in zero page.  Will use disc setting for !boot

Magic - Usage <fsp> (<dno>/<dsp>) (<drv>) a program for analysing program to accertain type does some magic byte checks via embedded look up tables. sets E% for exe address and L% for load.  will do some rudamentry PAGE=&E00 checks for basic programs

Alter - Usage <fsp> (<dno>/<dsp>) (<drv>) used for executing results of magic or in the future process

P.Process - SLOW program consumes TAB deiminated files.  A number of switches are available:- sort publisher requires 2 pass, verify used to clean TAB deiminated files.  generates a number of catdat files which will be in the order of the TAB deiminated files, DINREC index of disk titles and SOFTREC index of publishers. This program uses MCPROC the entry points are shared via PROCVAR. Will change exe details if both magic and Special and page fields agree. uses magic and alter

mnuhelp - displays program details use cursors or letters to move and ret to select.  allows filtering of display
uses files N O for help X to launch program CATDATx files SOFTREC, DINREC.

P.RECMMC - records catalogues of multiple disks with crc value

Usage

download mmc file to see if you are interested in system! please let me know of your experience esp if you just dive straight in (trying to make system drive by friendly for museum)

In order to create a new collection - below assumes you are familiar with MMC files and how to add and remove disks from them

create a new beeb.mmb

add mmcmenu,process,rawdat,x-files
type *magic on disk process to see  supported special file types use these with S and last last hex byte

add required disks

optional rename disks using p.dinren on process this is good as makes a collection easily identifiable and prevents name clashes

take any of the existing $.XXX.csv files
use as a template 

select the first disk - look at !boot to see the structure
record the launch file for into csv file
If a game has a generic title then its fine to add two entries for the same game (i.e. snapper and pac-man) do this in preference to (pac-man) as there is little horizontal screen real estate)
repeat until complete

save csv AS A TAB DELIMINATED FILE (sorry to shout!)

add newly created file to rawdat

run p.processs on disk process with newly created csv using the 'V' option -this will ensure that you have a clean data set
correct CSV file as required (i.e. - or _)

run p.process on disk process with newly created csv using the 'M' option 
run p.process on disk process with newly created csv using the 'MF' option to force use of csv details (will ask for each one)

run p.process with T option
Add details to collections.xlsx
run mmcmenu to see results (scan through to see if happy)

copy modified collection files into the disc collection directory (not mmcmenu,process,rawdat,x-files)

DONE!

Creating an MMC for use

In order to create an MMC with multiple collections
look at collections.xlsx decide on collections to use
create a new MMC with mmcmenu,process,rawdat,x-files disks on it
Copy the collection disks onto MMC - note you do not have to have complete collections!
create new spreadsheet ($.mmc,csv) open first collection csv and add to file sort in order you want them displayed
repeat until your collections are all added
N.B.  for an MMC containing the CBM collection,cheats,roms I would combine CBM and cheats sort by title then add roms added in its own order so roms will show at the end otherwise dfs stuff will appear near defender




