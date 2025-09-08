\TELETEXT.asm
\TELETEXT taken from https://mdfs.net/Info/Comp/Teletext/Controls
\Teletext characters are 7-bit bytes, but it is conventional to refer to the
\control codes as &80-&9F and the display characters as &20-&7F.
TELETEXTblacktext%= 				&80 \ [Black text]            
TELETEXTredtext%=  				&81 \Red text               
TELETEXTgreentext% = 			&82 \Green text             
TELETEXTyellowtext% =  			&83 \Yellow text            
TELETEXTbluetext%= 				&84 \Blue text              
TELETEXTmagentatext% = 			&85 \Magenta text          
TELETEXTcyantext% =  			&86 \Cyan text              
TELETEXTwhitetext% =  			&87 \*White text             
TELETEXTflashon% =  				&88 \Flash On               
TELETEXTflashiff%= 				&89 \*Flash Off              
TELETEXTendbox%=  				&8A \End box                
TELETEXTstartbox%=  				&8B \Start box              
TELETEXTnormalheight% = 			&8C \*Normal height 1x1      
TELETEXTDoubleheight% = 			&8D \Double height 1x2      
TELETEXTdoublewidth% = 			&8E \[Double width 2x1]      
TELETEXTdoublesize% =            &8F \[Double size 2x2]       

TELETEXTblackgraphics%   =       &90 \[Black graphics]
TELETEXTredgraphics%    =        &91 \Red graphics
TELETEXTgreengraphics%   =       &92 \Green graphics
TELETEXTyellowgraphics% =        &93 \Yellow graphics
TELETEXTbluegraphics%    =       &94 \Blue graphics
TELETEXTmagentagraphics% =       &95 \ Maganta graphics
TELETEXTcyangraphics%   =        &96 \Cyan graphics
TELETEXTwhilegraphics%  =        &97 \White graphics
TELETEXTconceadisplay% =         &98 \Conceal display
TELETEXTcontinousgraphics% =     &99 \*Continuous graphics
TELETEXTseparatedgraphics% =     &9A \Separated graphics
TELETEXTtogglebetweencharsets%= &9B \[Toggle between G0 character sets]
TELETEXTblackbackground% =      &9C \*Black background
TELETEXTnewbackground%=			&9D \New background
TELETEXTholdgraphics%  =		&9E \ Hold graphics
TELETEXTreleasegraphics%  = 	&9F \*Release graphics


\ *State at start of each line