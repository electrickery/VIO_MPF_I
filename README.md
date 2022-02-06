This repository contains the firmware versions for the Bardhele Electronic
VIDEO-MPF-I card. 

More info on my home page: https://www.electrickery.nl/comp/mpf1/doc/index.html


VIO.zip are the hex dumps of the original ROMs that came with the card.


These are the most interesting entry addresses:

* 0a004h:	init 6845, clear screen, return from call
 
* 0a007h:	init 6845, clear screen, jump to 0000h

* 0a00ah:	(JCRTCO) print character in C, interpret control codes

* 0a00dh:	(JCRTOU) print character in C, print codes 00h-31h too

* 0a010h:	(JTEXCO) print 00h terminated string (start in IY)

* 0a013h:	(JTEX??) print 00h terminated string (start in IY) CR = LF

* 0a016h:	writes character set to screen

* 0a019h:   init 6845, clear screen, print banner, rst 0

The hardware is configured for 8 bit wide, 11 bit high characters, 
limiting the screen to 40 x 20 characters (PAL timing).

