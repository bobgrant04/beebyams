# beebyams
BBC model B mmc Menu system
This project attempts to build on the mmc dfs (disk filing system) that allows owners of BBC micros and emulators to have up to 510 disk images available for mounting virtually from the command line.
With this flexabilty comes the problem of using the system for a games system allowing for rapid selection of a game or program.
The Stairway to Hell archive had a good solution with their menu system however a number of changes will enable other collections to be added.  With this in mind a number of processes and programs will generate the required files to allow a more generic menu system

the start of the process requires TAB delimiated files in the following format:-
publisher:- name of publisher only have 1024 so try to limit
long title:- needs to be below 240 chars but for display needs to be less than 30
filename:- assumes $ dir needs to be less than 10 characters if dir specifeid or less than 8 if not
execute type :- crle chain run load execute uppper of lower case
page number :- should be the true page required
game type :-acgsmpuz adventure cheat game strategy music picture util z=unkown
favorate :- Y/N based on https://stardot.org.uk/forums/viewtopic.php?f=1&t=8259

these are available for:-
1 stairway to hell originl menu system https://www.stairwaytohell.com/bbc/sthcollection.html
2 public domain
3 Roms
4 Cheats - this needs updating
5 Disc User http://8bs.com/catalogue/tdu.htm
6 A & B computing http://8bs.com/catalogue/a&b.htm
7 The micro user 
8 the micro user games
9 30 years games archive based on https://stardot.org.uk/forums/viewtopic.php?f=32&t=8270&hilit=disc+114
