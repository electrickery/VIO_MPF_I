; VIOMON 2.2 - based on disassembled Bardhele ROM

VERSION:EQU    '2.2'

;6545 CRT status register (same address as address register):
;
; 7 6 5 4 3 2 1 0
;   | |  
;   | | 
;   | +----------- 0 - Scan in visable area
;   |              1 - Scan in vertical blanking area
;   +------------- 0 - no LP event since last read of R16 & R17
;                  1 - LP event occurred since last read

; MC6845 register ports
CRTA:	EQU		0f0h
CRTD:	EQU		0f1h

; screen gometry
COLS:	EQU		028h ; 40 char per line
CHROWS:	EQU		014h ; 20 lines

; Video RAM
SCREEN:	EQU		04000h
d45ffh:	EQU		045FFh
SCRNSIZ:EQU     00600h
DISPSIZ:EQU     COLS * CHROWS
VRAMSZ: EQU     07FFh

;Work space
d4600h:	EQU		04600h
AUTOLF:	EQU		04601h	; Flag for Auto Line Feed after Carriage Return

; memory address of cursor
d4602h:  EQU    04602h  ; Updated but never read - sub_a46ah, sub_a486h
d4603h:  EQU    04603h  ; Updated but never read

; position of cursor on screen
COLPOS:  EQU    04604h  ; Updated but never read
ROWPOS:  EQU    04605h  ; Updated but never read
; 
d460ah:	EQU		0460ah	; 460ah & 460bh - sub_a08ah, sub_a0d2h, sub_a111h, la16ah, la19eh (WSINIT)
;
d460ch:	EQU		0460ch	; 460ch & 460dh - sub_a08ah, sub_a0b3h, la19eh (WSINIT)

PBAFLG: EQU     0460Eh  ; Print only ASCII flag. 

DUMPADR:EQU     0461Ah  ; start address for the next memory dump
LINCNT: EQU     0461Eh  ; counter for lines dumped

; Control codes
CRIGHT:	EQU		00h
CLEFT:	EQU		01h
CUP:	EQU		02h
CDOWN:	EQU		03h
BS:		EQU		08h
TAB:    EQU     09h
FF:		EQU		0Ch
LF:		EQU		0Ah
CR:		EQU		0Dh
d062h:	EQU		062h	;	b

ALFVAL:	EQU		0A5h	; auto LF value

; line buffer data
LINEBUF:EQU     04640h ; address of line buffer
ADDRPOS:EQU     00h  ; address section on line, relative to LINEBUF
HEXPOS: EQU     06h  ; hex section on line, relative to LINEBUF
ASCPOS: EQU     1Fh  ; ASCII section on line, relative to LINEBUF
LENDPOS:EQU     24h  ; end of line position, relative to LINEBUF
BYTESLIN:EQU    08h  ; bytes dumped per line

DMPLINES:EQU    10h  ; lines per dump page

	ORG	0A000h

START:
	JP      JCLS
    NOP
	
CINIT:
sub_a004h:			;					init 6845, clear screen, return from call
	jp WSINIT		;a004	c3 9e a1 	. . . workspace init 
	
JINICR:
					;					init 6845, clear screen, jump to 0000h
	jp la1c0h		;a007	c3 c0 a1 	. . . 
	
JCRTCO:
sub_a00ah:			;	(JCRTCO) print character in C, interpret control codes
	jp la1fch		;a00a
	
JCRTOU:
sub_a00dh:			;	(JCRTOU) print character in C, print codes 00h-31h too
	jp la24fh		;a00d
	
JTEXCO:				;	(JTEXCO) print 00h terminated string (start in IY).
	jp la433h		;a010
	
JTEXCLN:			;	(JTEXCNL) print 00h terminated string (start in IY). Add line end: CR LF
	jp la441h		;a013
	
JVIDTE: 			;	writes character set to screen
	jp la1d7h		;a016 
    
REGINIT:
sub_a019h:			;	configure 6845 with register/data table in HL (FFh terminated)
	jp SETREG		;a019

SPLASH_:    
    jp SPASH        ;a01c

MEMDMP_:
    jp  MEMDUMP
    

CRLF:
la106h:
	ld      c, CR		;a106	0e 0d 	. . 
	call    JCRTCO		;a108	cd 0a a0 	. . . 
	ld      c, LF		;a10b	0e 0a 	. . 
	call    JCRTCO		;a10d	cd 0a a0 	. . . 
	ret			;a110	c9 	. 
	
la121h:
	dec hl			;a121	2b 	+ 
	ld bc,00c5dh		;a122	01 5d 0c 	. ] . 	; debug?
	
BANNER:
la125h:
	defb 0ah			;a125	0a 	. 
	defb 0dh		;a126	fe 0d 	. . 
BRBAN1:
	defm 'COPYRIGHTS BY BARDEHLE ELECTRONIC'
BRBAN2:
    defm 'D-4796 SALZKOTTEN '
BRBAN3:
	defm '06 85'
BRBEND:
;    defb 00h
la16ah:     ;	writes character set to screen
	ld      hl, 0460ah		;a16a	21 0a 46 	! . F 
	call    sub_a44dh		;a16d	cd 4d a4 	. M . 
	ld      b, 028h		;a170	06 28 	. ( 
la172h:
	ld      (hl), 020h		;a172	36 20 	6   
	inc     hl			;a174	23 	# 
	djnz    la172h		;a175	10 fb 	. . 
	call    la106h		;a177	cd 06 a1 	. . . 
	ld      hl, 0460ah		;a17a	21 0a 46 	! . F 
	call    sub_a44dh		;a17d	cd 4d a4 	. M . 
	call    sub_a188h		;a183	cd 88 a1 	. . . 
	RST		0 
	
sub_a188h:
	ld hl,00c5dh		;a188	21 5d 0c 	! ] . 
la18bh:
	ld c,(hl)			;a18b	4e 	N 
	ld a,c			;a18c	79 	y 
	cp 00dh		;a18d	fe 0d 	. . 
	jr z,la197h		;a18f	28 06 	( . 
	call JCRTCO		;a191	cd 0a a0 	. . . 
	inc hl			;a194	23 	# 
	jr la18bh		;a195	18 f4 	. . 
	
la197h:
	call la106h		;a197	cd 06 a1 	. . . 
	call la106h		;a19a	cd 06 a1 	. . . 
	ret			;a19d	c9 	. 
	
WSINIT:     ; init 6845, clear screen, return from call
la19eh:
	ld de,0ff04h		;a19e	11 04 ff 	. . . debug ?
	ld bc,0ff2bh		;a1a1	01 2b ff 	. + . debug ?
	ld (0460ah),de		;a1a4	ed 53 0a 46 	. S . F 
	ld (0460ch),bc		;a1a8	ed 43 0c 46 	. C . F 
	ld hl,REGTAB		;a1ac	21 9d a4 	! . . 
	call REGINIT		;a1af	cd 19 a0 	. . . 
	ld c,00ch		;a1b2	0e 0c 	. . 
	call JCRTCO		;a1b4	cd 0a a0 	. . . 
	ld a,ALFVAL		;a1b7	3e a5 	> . 	; Auto LF
	ld (AUTOLF),a		;a1b9	32 01 46 	2 . F 
	ld (04600h),a		;a1bc	32 00 46 	2 . F 
    ld  a, 01h
    LD      (PBAFLG), a
    LD      BC, 00h
    LD      (DUMPADR), BC
	ret			;a1bf	c9 	. 
	
	; init 6845, clear screen, jump to 0000h
	;
la1c0h:
	call WSINIT		;a1c0	cd 9e a1 	. . . 
	jp 00000h		;a1c3	c3 00 00 	. . . 
	
; Load table with register numbers and values into the CRT registers
SETREG:
la1c6h:
	ld c,CRTA		;a1c6	0e f0 	. . 
NEXTREG:
la1c8h:
	ld a,(hl)			;a1c8	7e 	~ 
	cp 0ffh			;a1c9	fe ff 	. . 
	ret z			;a1cb	c8 	. 	; Done NEXTREG
	out (c),a		;a1cc	ed 79 	. y 
	inc hl			;a1ce	23 	# 
	ld a,(hl)			;a1cf	7e 	~ 
	inc c			;a1d0	0c 	. 	; point to CRTD
	out (c),a		;a1d1	ed 79 	. y 
	dec c			;a1d3	0d 	. 	; point to CRTA
	inc hl			;a1d4	23 	# 
	jr NEXTREG		;a1d5	18 f1 	. . 
	
la1d7h:             ;	writes character set to screen
	ld c,00ch		;a1d7	0e 0c 	. . Form feed
	call JCRTCO		;a1d9	cd 0a a0 	. . . 
	ld c,000h		;a1dc	0e 00 	. . 
la1deh:
	call JCRTOU		;a1de	cd 0d a0 	. . . 
	inc c			;a1e1	0c 	. 
	ld a,c			;a1e2	79 	y 
	cp 080h			;a1e3	fe 80 	. . 
	jr nz,la1deh		;a1e5	20 f7 	  next char. 
	ld c,00dh		;a1e7	0e 0d 	. . 
	call JCRTCO		;a1e9	cd 0a a0 	. . . 
	ld c,00ah		;a1ec	0e 0a 	. . 
	call JCRTCO		;a1ee	cd 0a a0 	. . . 
	ld c,080h		;a1f1	0e 80 	. . 
la1f3h:
	call JCRTOU		;a1f3	cd 0d a0 	. . . 
	inc c			;a1f6	0c 	. 
	jr nz,la1f3h		;a1f7	20 fa 	  . next char. 
	jp 00000h		;a1f9	c3 00 00 	. . . Back to monitor
	
la1fch:     ;	(JCRTCO) print character in C, interpret control codes
	push iy			;a1fc	fd e5 	. . 
	push ix			;a1fe	dd e5 	. . 
	push hl			;a200	e5 	. 
	push de			;a201	d5 	. 
	push bc			;a202	c5 	. 
	push af			;a203	f5 	. 
	call sub_a210h		;a204	cd 10 a2 	. . . 
	pop af			;a207	f1 	. 
	pop bc			;a208	c1 	. 
	pop de			;a209	d1 	. 
	pop hl			;a20a	e1 	. 
	pop ix			;a20b	dd e1 	. . 
	pop iy			;a20d	fd e1 	. . 
	ret				;a20f	c9 	. 
	
sub_a210h:      ; search text for control characters in CTRCHR table
	ld a, c			;a210	79 	y 
	ld bc, CCEND - CTRCHR		;a211	01 0a 00 	. . . 
	ld hl, CTRCHR		;a214	21 45 a2 	! E . 
	cpir			;a217	ed b1 	. . 
	jr z, la21eh		;a219	28 03 	( . 
	jp la256h		;a21b	c3 56 a2 	. V . 
	
la21eh:
	ld hl,la22eh		;a21e	21 2e a2 	! . . 
	ld a,c			;a221	79 	y 
	and 00fh		;a222	e6 0f 	. . 
	add a,a			;a224	87 	. 
	ld c,a			;a225	4f 	O 
	ld b,000h		;a226	06 00 	. . 
	add hl,bc			;a228	09 	. 
	ld e,(hl)			;a229	5e 	^ 
	inc hl			;a22a	23 	# 
	ld d,(hl)			;a22b	56 	V 
	ex de,hl			;a22c	eb 	. 
	jp (hl)			;a22d	e9 	. 
	
la22eh:
	sbc a,c			;a22e	99 	. 
	and e			;a22f	a3 	. 
	ld a,d			;a230	7a 	z 
	and e			;a231	a3 	. 
	rla				;a232	17 	. 
	and e			;a233	a3 	. 
	add hl,bc			;a234	09 	. 
	and e			;a235	a3 	. 
	cp 0a2h			;a236	fe a2 	. . 
	ret p			;a238	f0 	. 
	and d			;a239	a2 	. 
	pop de			;a23a	d1 	. 
	and d			;a23b	a2 	. 
	cp b			;a23c	b8 	. 
	and d			;a23d	a2 	. 
	or e			;a23e	b3 	. 
	and d			;a23f	a2 	. 
	sbc a,a			;a240	9f 	. 
	and d			;a241	a2 	. 
	jp la256h		;a242	c3 56 a2 	. V . 
	
la245h:
CTRCHR:
    DEFB        CR
    DEFB        LF
    DEFB        FF
    DEFB        5Fh
    DEFB        00h
    DEFB        01h
    DEFB        02h
    DEFB        03h
    DEFB        TAB
    DEFB        04h        
CCEND:

la24fh:     ; JCRTOU start
	push bc			;a24f	c5 	. 
	ld a,c			;a250	79 	y 
	call la256h		;a251	cd 56 a2 	. V . 
	pop bc			;a254	c1 	. 
	ret				;a255	c9 	. 
	
la256h:
	ld c,a			;a261	4f 	O 
	call sub_a46ah		;a262	cd 6a a4 	. j . 
la265h:
	in a,(CRTA)		;a265	db f0 	. .     ; register not readable; 6545 feature
	rlca			;a267	07 	. 
	jr nc,la265h		;a268	30 fb 	0 . ; wait for ?
	ld (hl),c			;a26a	71 	q 
	call sub_a460h		;a26b	cd 60 a4 	. ` . ; save new cursor position?
	ld a,e			;a26e	7b 	{ 
	inc a			;a26f	3c 	< 
	cp COLS			;a270	fe 28 	. ( 
	jr z,la279h		;a272	28 05 	( . ; skip some code
	ld e,a			;a274	5f 	_ 
la275h:
	call sub_a3cch		;a275	cd cc a3 	. . . 
	ret				;a278	c9 	. 
	
la279h:
	xor a			;a279	af 	. 
	ld e,a			;a27a	5f 	_ 
la27bh:
	ld a,d			;a27b	7a 	z 
	inc a			;a27c	3c 	< 
	ld b,014h		;a27d	06 14 	. . Char rows 14h = 20 ?
	cp b			;a27f	b8 	. 
	jr z,la285h		;a280	28 03 	( . 
	ld d,a			;a282	57 	W 
	jr la275h		;a283	18 f0 	. . 
la285h:
	dec a			;a285	3d 	= 
	ld d,a			;a286	57 	W 
	call sub_a3cch		;a287	cd cc a3 	. . . 
	call sub_a335h		;a28a	cd 35 a3 	. 5 . 
	ret				;a28d	c9 	. 
	
sub_a29fh:
	call sub_a460h		;a29f	cd 60 a4 	. ` . 
	xor a			;a2a2	af 	. 
	ld e,a			;a2a3	5f 	_ 
	ld hl,04606h		;a2a4	21 06 46 	! . F 
la2a7h:
	in a,(CRTA)		;a2a7	db f0 	. . 
	rlca			;a2a9	07 	. 
	jr nc,la2a7h		;a2aa	30 fb 	0 . 
	ld a,(hl)			;a2ac	7e 	~ 
	cp ALFVAL		;a2ad	fe a5 	. . 
	jr z,la27bh		;a2af	28 ca 	( . 
	jr la275h		;a2b1	18 c2 	. . 
	call sub_a460h		;a2b3	cd 60 a4 	. ` . 
	jr la27bh		;a2b6	18 c3 	. . 
	ld hl,SCREEN		;a2b8	21 00 40 	! . @ 
	ld de,SCREEN + 1	;a2bb	11 01 40 	. . @ 
	ld bc,DISPSIZ		;a2be	01 20 03 	.   . 
	ld a, ' '		;a2c1	3e 20 	>   
la2c3h:
	ld (hl),a			;a2c3	77 	w ; space to 04000h
	cp (hl)			;a2c4	be 	. 
	jr nz,la2c3h		;a2c5	20 fc 	  . ; retry if write failed
	call sub_a414h		;a2c7	cd 14 a4 	. . . 
	ld d,000h		;a2ca	16 00 	. . 
	ld e,d			;a2cc	5a 	Z 
	call sub_a3cch		;a2cd	cd cc a3 	. . . 
	ret				;a2d0	c9 	. 
	call sub_a460h		;a2d1	cd 60 a4 	. ` . 
	ld a,e			;a2d4	7b 	{ 
	dec a			;a2d5	3d 	= 
	cp 0ffh			;a2d6	fe ff 	. . 
	jr z,la2ech		;a2d8	28 12 	( . 
	ld e,a			;a2da	5f 	_ 
	call sub_a3cch		;a2db	cd cc a3 	. . . 
	push af			;a2de	f5 	. 
	call sub_a46ah		;a2df	cd 6a a4 	. j . 
	ld d,020h		;a2e2	16 20 	.   
la2e4h:
	in a,(0f0h)		;a2e4	db f0 	. . 
	rlca			;a2e6	07 	. 
	jr nc,la2e4h		;a2e7	30 fb 	0 . 
	ld (hl),d			;a2e9	72 	r 
	pop af			;a2ea	f1 	. 
	ret				;a2eb	c9 	. 
	
la2ech:
	call sub_a32eh		;a2ec	cd 2e a3 	. . . 
	ret				;a2ef	c9 	. 
	call sub_a460h		;a2f0	cd 60 a4 	. ` . 
	ld a,e			;a2f3	7b 	{ 
	inc a			;a2f4	3c 	< 
	cp 028h			;a2f5	fe 28 	. ( 
	jr z,la2ech		;a2f7	28 f3 	( . 
la2f9h:
	ld e,a			;a2f9	5f 	_ 
	call sub_a3cch		;a2fa	cd cc a3 	. . . 
	ret				;a2fd	c9 	. 
	call sub_a460h		;a2fe	cd 60 a4 	. ` . 
	ld a,e			;a301	7b 	{ 
	dec a			;a302	3d 	= 
	cp 0ffh			;a303	fe ff 	. . 
	jr z,la2ech		;a305	28 e5 	( . 
	jr la2f9h		;a307	18 f0 	. . 
	call sub_a460h		;a309	cd 60 a4 	. ` . 
	ld a,d			;a30c	7a 	z 
	dec a			;a30d	3d 	= 
	cp 0ffh			;a30e	fe ff 	. . 
	jr z,la2ech		;a310	28 da 	( . 
la312h:
	ld d,a			;a312	57 	W 
	call sub_a3cch		;a313	cd cc a3 	. . . 
	ret				;a316	c9 	. 
	call sub_a460h		;a317	cd 60 a4 	. ` . 
	ld a,d			;a31a	7a 	z 
	inc a			;a31b	3c 	< 
	cp 014h			;a31c	fe 14 	. . 
	jr z,la2ech		;a31e	28 cc 	( . 
	jr la312h		;a320	18 f0 	. . 
    
sub_a322h:
	ld hl,la4beh		;a322	21 be a4 	! . . 
la325h:
	call la1c6h		;a325	cd c6 a1 	. . . 
	ret				;a328	c9 	. 
	
sub_a329h:
	ld hl,la4c1h		;a329	21 c1 a4 	! . . 
	jr la325h		;a32c	18 f7 	. . 
	
sub_a32eh:
	ld hl,00100h		;a32e	21 00 01 	! . . 
	call 0086eh		;a331	cd 6e 08 	. n . 
	ret				;a334	c9 	. 
	
sub_a335h:
	call sub_a322h		;a335	cd 22 a3 	. " . 
	ld b,013h		;a338	06 13 	. . 
	ld de,SCREEN		;a33a	11 00 40 	. . @ 
	ld hl,04028h		;a33d	21 28 40 	! ( @ 
la340h:
	push bc			;a340	c5 	. 
la341h:
	in a,(CRTA)		;a341	db f0 	. . 
	rlca			;a343	07 	. 
	jr nc,la341h		;a344	30 fb 	0 . ; again1
	in a,(CRTA)		;a346	db f0 	. . 
	rlca			;a348	07 	. 
	jr nc,la341h		;a349	30 f6 	0 . ; again1
	ld b,028h		;a34b	06 28 	. ( 
la34dh:
	ld a,(hl)			;a34d	7e 	~ 
	cp (hl)			;a34e	be 	. 
	jr nz,la34dh		;a34f	20 fc 	  . ; again2
	ex de,hl			;a351	eb 	. 
la352h:
	ld (hl),a			;a352	77 	w 
	cp (hl)			;a353	be 	. 
	jr nz,la352h		;a354	20 fc 	  .  ; again3
	ex de,hl			;a356	eb 	. 
	inc hl			;a357	23 	# 
	inc de			;a358	13 	. 
	djnz la34dh		;a359	10 f2 	. .  ; again2
	pop bc			;a35b	c1 	. 
	djnz la340h		;a35c	10 e2 	. .  ; again4
	push de			;a35e	d5 	. 
	pop hl			;a35f	e1 	. 
	inc de			;a360	13 	. 
	ld bc, COLS		;a361	01 28 00 	. ( . 
	ld b,000h		;a364	06 00 	. . 
	dec c			;a366	0d 	. 
	push af			;a367	f5 	. 
	push bc			;a368	c5 	. 
	ld c,020h		;a369	0e 20 	.   
la36bh:
	in a,(CRTA)		;a36b	db f0 	. . 
	rlca			;a36d	07 	. 
	jr nc,la36bh		;a36e	30 fb 	0 . 
	ld (hl),c			;a370	71 	q 
	pop bc			;a371	c1 	. 
	pop af			;a372	f1 	. 
	call sub_a3f8h		;a373	cd f8 a3 	. . . 
	call sub_a329h		;a376	cd 29 a3 	. ) . 
	ret				;a379	c9 	. 
	call sub_a460h		;a37a	cd 60 a4 	. ` . 
	ld a,e			;a37d	7b 	{ 
	cp 024h			;a37e	fe 24 	. $ 
	ret nc			;a380	d0 	. 
la381h:
	inc a			;a381	3c 	< 
	ld hl,la393h		;a382	21 93 a3 	! . . 
	ld bc,00006h		;a385	01 06 00 	. . . 
	cpir			;a388	ed b1 	. . 
	jr z,la38eh		;a38a	28 02 	( . 
	jr la381h		;a38c	18 f3 	. . 
la38eh:
	ld e,a			;a38e	5f 	_ 
	call sub_a3cch		;a38f	cd cc a3 	. . .  ; calculate and store new cursor address in CRT R14/R15
	ret				;a392	c9 	. 
    
la393h:
	ld b,00ch		;a393	06 0c 	. . 
	ld (de),a			;a395	12 	. 
	jr la3b6h		;a396	18 1e 	. . 
	inc h			;a398	24 	$ 
	ld hl,04606h		;a399	21 06 46 	! . F 
la39ch:
	in a,(CRTA)		;a39c	db f0 	. . 
	rlca			;a39e	07 	. 
	jr nc,la39ch		;a39f	30 fb 	0 . 
	ld a,(hl)			;a3a1	7e 	~ 
	push af			;a3a2	f5 	. 
	push hl			;a3a3	e5 	. 
	ld c,000h		;a3a4	0e 00 	. . 
la3a6h:
	in a,(CRTA)		;a3a6	db f0 	. . 
	rlca			;a3a8	07 	. 
	jr nc,la3a6h		;a3a9	30 fb 	0 . 
	ld (hl),c			;a3ab	71 	q 
	call sub_a29fh		;a3ac	cd 9f a2 	. . . 
	pop hl			;a3af	e1 	. 
	pop bc			;a3b0	c1 	. 
la3b1h:
	in a,(CRTA)		;a3b1	db f0 	. . 
	rlca			;a3b3	07 	. 
	jr nc,la3b1h		;a3b4	30 fb 	0 . 
la3b6h:
	ld (hl),b			;a3b6	70 	p 
	call sub_a46ah		;a3b7	cd 6a a4 	. j . 
	ld c,020h		;a3ba	0e 20 	.   
la3bch:
	in a,(CRTA)		;a3bc	db f0 	. . 
	rlca			;a3be	07 	. 
	jr nc,la3bch		;a3bf	30 fb 	0 . 
	ld (hl),c			;a3c1	71 	q 
	push hl			;a3c2	e5 	. 
	pop de			;a3c3	d1 	. 
	inc de			;a3c4	13 	. 
	ld bc,00027h		;a3c5	01 27 00 	. ' . 
	call sub_a3f8h		;a3c8	cd f8 a3 	. . . 
	ret				;a3cb	c9 	. 
	
sub_a3cch:  ; calculate and store new cursor address in CRT R14/R15
	call sub_a471h		;a3cc	cd 71 a4 	. q . ; store e in 4602h
	ld a,d			;a3cf	7a 	z 
	ld hl,00000h		;a3d0	21 00 00 	! . . 
	or a			;a3d3	b7 	. 
	jr z,la3dfh		;a3d4	28 09 	( . 
	ld bc,COLS		;a3d6	01 28 00 	. ( . 
	ld b,l			;a3d9	45 	E 
la3dah:
	add hl,bc			;a3da	09 	. 
	dec a			;a3db	3d 	= 
	jr nz,la3dah		;a3dc	20 fc 	  . 
	ld d,a			;a3de	57 	W 
la3dfh:
	add hl,de			;a3df	19 	. 
	ld c,CRTA		;a3e0	0e f0 	. . 
	ld a,00eh		;a3e2	3e 0e 	> . ; 
	out (c),a		;a3e4	ed 79 	. y ; select R14 Cursor Address (High)
	inc c			;a3e6	0c 	.       ; CRTD   
	out (c),h		;a3e7	ed 61 	. a ; write h to R14
	dec c			;a3e9	0d 	.       ; CTRA
	inc a			;a3ea	3c 	<       ; 
	out (c),a		;a3eb	ed 79 	. y ; select R15 Cursor Address (Low) 
	inc c			;a3ed	0c 	.       ; CRTD
	out (c),l		;a3ee	ed 69 	. i ; write l to R15
	ld de,SCREEN		;a3f0	11 00 40 	. . @ ; start video ram
	add hl,de			;a3f3	19 	. 
	call sub_a486h		;a3f4	cd 86 a4 	. . . ; store c in 4602h
	ret				;a3f7	c9 	. 
	
sub_a3f8h:
	push af			;a3f8	f5 	. 
	ld b,c			;a3f9	41 	A 
la3fah:
	in a,(CRTA)		;a3fa	db f0 	. . 
	rlca			;a3fc	07 	. 
	jr nc,la3fah		;a3fd	30 fb 	0 . ; try again1
	in a,(CRTA)		;a3ff	db f0 	. . 
	rlca			;a401	07 	. 
	jr nc,la3fah		;a402	30 f6 	0 . ; try again1
la404h:
	ld a,(hl)			;a404	7e 	~ 
	cp (hl)			;a405	be 	. 
	jr nz,la404h		;a406	20 fc 	  .  ; try again2
	ex de,hl			;a408	eb 	. 
la409h:
	ld (hl),a			;a409	77 	w 
	cp (hl)			;a40a	be 	. 
	jr nz,la409h		;a40b	20 fc 	  .  ; try again3
	ex de,hl			;a40d	eb 	. 
	inc hl			;a40e	23 	# 
	inc de			;a40f	13 	. 
	djnz la404h		;a410	10 f2 	. .      ; try again2
	pop af			;a412	f1 	. 
	ret				;a413	c9 	. 
	
sub_a414h:
	push af			;a414	f5 	. 
	ld a,b			;a415	78 	x 
	or c			;a416	b1 	. 
	jr z,la431h		;a417	28 18 	( . ; done
	ld a,b			;a419	78 	x 
	ld b,c			;a41a	41 	A 
	ld c,a			;a41b	4f 	O 
la41ch:
	ld a,(hl)			;a41c	7e 	~ 
	cp (hl)			;a41d	be 	. 
	jr nz,la41ch		;a41e	20 fc 	  . ; try again4
	ex de,hl			;a420	eb 	. 
la421h:
	ld (hl),a			;a421	77 	w 
	cp (hl)			;a422	be 	. 
	jr nz,la421h		;a423	20 fc 	  . ; try again5
	ex de,hl			;a425	eb 	. 
	inc hl			;a426	23 	# 
	inc de			;a427	13 	. 
	djnz la41ch		;a428	10 f2 	. . ; try again4
	ld a,c			;a42a	79 	y 
	or b			;a42b	b0 	. 
	jr z,la431h		;a42c	28 03 	( . ; done
	dec c			;a42e	0d 	. 
	jr la41ch		;a42f	18 eb 	. . try again4
	
la431h:
	pop af			;a431	f1 	. 
	ret				;a432	c9 	. 
	
la433h: ; write buffer to video (JCRTCO) until a 0 is found
	ld a,(iy+000h)		;a433	fd 7e 00 	. ~ . 
	cp 000h			;a436	fe 00 	. . 
	ret z			;a438	c8 	. 				; 00h found, done printing, return from call
	ld c,a			;a439	4f 	O 
	call JCRTCO		;a43a	cd 0a a0 	. . .	; print it
	inc iy			;a43d	fd 23 	. # 		; update cursor pos
	jr la433h		;a43f	18 f2 	. . ; again
	
la441h:
	call la433h		;a441	cd 33 a4 	. 3 . 
	ld iy,la44ah		;a444	fd 21 4a a4 	. ! J . 
	jr la433h		;a448	18 e9 	. . 
	
la44ah:	; table for line end 
	defb	CR, LF, 00h
	
sub_a44dh: ; write de to video memory pointed to by hl.
	push af			;a44d	f5 	. 
	push de			;a44e	d5 	. 
la44fh:
	in a,(CRTA)		;a44f	db f0 	. . 
	rlca			;a451	07 	. 
	jr nc,la44fh		;a452	30 fb 	0 . ; wait for 6545 blank
	ld e,(hl)			;a454	5e 	^ ; write e to LSB
	inc hl			;a455	23 	# 
la456h:
	in a,(CRTA)		;a456	db f0 	. . 
	rlca			;a458	07 	. 
	jr nc,la456h		;a459	30 fb 	0 . ; wait for 6545 blank
	ld d,(hl)			;a45b	56 	V ; write d to MSB
	ex de,hl			;a45c	eb 	. 
	pop de			;a45d	d1 	. 
	pop af			;a45e	f1 	. 
	ret				;a45f	c9 	. 
	
sub_a460h: 
	push hl			;a460	e5 	. 
	ld hl,COLPOS		;a461	21 04 46 	! . F 
	call sub_a44dh		;a464	cd 4d a4 	. M . 
	ex de,hl			;a467	eb 	. 
	pop hl			;a468	e1 	. 
	ret				;a469	c9 	. 
	
sub_a46ah:
	ld hl,04602h		;a46a	21 02 46 	! . F 
	call sub_a44dh		;a46d	cd 4d a4 	. M . 
	ret				;a470	c9 	. 
	
sub_a471h:  ; update COLPOS & ROWPOS with CRT data
	push af			;a471	f5 	. 
	push hl			;a472	e5 	. 
	ld hl,COLPOS		;a473	21 04 46 	! . F 
la476h:
	in a,(CRTA)		;a476	db f0 	. . 
	rlca			;a478	07 	. 
	jr nc,la476h		;a479	30 fb 	0 . ; wait for 6545 blank
	ld (hl),e			;a47b	73 	; write COLPOS
	inc hl			;a47c	23 	# 
la47dh:
	in a,(CRTA)		;a47d	db f0 	. . 
	rlca			;a47f	07 	. 
	jr nc,la47dh		;a480	30 fb 	0 . ; wait for 6545 blank
	ld (hl),d			;a482	72 	; write ROWPOS
	pop hl			;a483	e1 	. 
	pop af			;a484	f1 	. 
	ret				;a485	c9 	. 
	
sub_a486h:  ; ? update 04602h & 04603h with CRT data ?
	push af			;a486	f5 	. 
	push de			;a487	d5 	. 
	ld de,04602h		;a488	11 02 46 	. . F 
	ex de,hl			;a48b	eb 	. 
la48ch:
	in a,(CRTA)		;a48c	db f0 	. . 
	rlca			;a48e	07 	. 
	jr nc,la48ch		;a48f	30 fb 	0 . ; wait for 6545 blank
	ld (hl),e			;a491	73 	s 
	inc hl			;a492	23 	# 
la493h:
	in a,(CRTA)		;a493	db f0 	. . 
	rlca			;a495	07 	. 
	jr nc,la493h		;a496	30 fb 	0 . 
	ld (hl),d			;a498	72 	r 
	ex de,hl			;a499	eb 	. 
	pop de			;a49a	d1 	. 
	pop af			;a49b	f1 	. 
	ret				;a49c	c9 	. 
	
;	org 	0a49dh
REGTAB:
la49dh:
	defb	00h, 03fh	; R0  Horizontal Total
	defb	01h, 028h	; R1  Horizontal Displayed
	defb	02h, 030h	; R2  Horizontal Sync Position
	defb	03h, 005h	; R3  Horizontal Sync Width
	defb	04h, 019h	; R4  Vertical Total
la4a7h:
	defb	05h, 001h	; R5  Vertical Total Adjust
	defb	06h, 014h	; R6  Vertical Displayed
	defb	07h, 016h	; R7  Vertical Sync position
	defb	08h, 000h	; R8  Interlace and Skew
	defb	09h, 00bh	; R9  Maximum Raster Address
	defb	0ah, 060h	; R10 Cursor Start Raster
	defb	0bh, 00bh	; R11 Cursor End Raster
CURRST:
	defb	0ch, 000h	; R12 Display Start Address (High)
	defb	0dh, 000h	; R13 Display Start Address (Low)
	defb	0eh, 000h	; R14 Cursor Address (High)
	defb	0fh, 000h	; R15 Cursor Address (Low) 
	defb	0ffh		; table terminator

CURSOF:
la4beh:
    defb    00ah, 020h  ; cursor off
    defb    0ffh

CRSBLON:    
la4c1h:
    defb    00ah, 060h  ; cursor blink on
    defb    0ffh
    
   
HASHLN:
    defm    '########################################'
    defb    00h
HASHBR:
    defm    '#                                      #'
    defb    00h

CLNBUF:
    ld      hl, LINEBUF
    ld      de, LINEBUF + 1
    ld      bc, COLS
    ld      (hl), ' '
    ldir
    ret
    
SETBOR:
    ld      hl, HASHBR
    ld      de, LINEBUF
    ld      bc, COLS + 1    ; include the 00h
    ldir
    ret
    
SPASH:
;1
    call    CINIT
    ld      iy, HASHLN      ; line with all #' s
    call    JTEXCO
;2
    ld      iy, HASHBR      ; borders of #' s
    call    JTEXCO
;3
    call    SETBOR          ; load borders to LINEBUF
    ld      hl, BRBAN1
    ld      de, LINEBUF + 3
    ld      bc, BRBAN2 - BRBAN1
    ldir
    ld      iy, LINEBUF
    call    JTEXCO
;4
    call    SETBOR
    ld      hl, BRBAN2
    ld      de, LINEBUF + 3
    ld      bc, BRBAN3 - BRBAN2
    ldir
    ld      iy, LINEBUF
    call    JTEXCO
;5
    call    SETBOR
    ld      hl, BRBAN3
    ld      de, LINEBUF + 3
    ld      bc, BRBEND - BRBAN3
    ldir
    ld      iy, LINEBUF
    call    JTEXCO
;6
    call    SETBOR
    ld      iy, LINEBUF
    call    JTEXCO
;7
    ld      hl, MODINF
    ld      de, LINEBUF + 3
    ld      bc, MODIN2 - MODINF
    ldir
    ld      iy, LINEBUF
    call    JTEXCO
;8
    call    SETBOR
    ld      hl, MODIN2
    ld      de, LINEBUF + 2
    ld      bc, MODIN3 - MODIN2
    ldir
    ld      iy, LINEBUF
    call    JTEXCO
;9
    call    SETBOR
    ld      hl, MODIN3
    ld      de, LINEBUF + 3
    ld      bc, MODIEND - MODIN3
    ldir
    ld      iy, LINEBUF
    call    JTEXCO
;10

;    ld      d, 9
;BRLOOP:
    ld      iy, HASHBR      ; borders of #' s
    call    JTEXCO
;    dec     d
;    jr      z, BRLOOP
    ld      iy, HASHBR      ; borders of #' s
    call    JTEXCO
    ld      iy, HASHBR      ; borders of #' s
    call    JTEXCO
    ld      iy, HASHBR      ; borders of #' s
    call    JTEXCO
    ld      iy, HASHBR      ; borders of #' s
    call    JTEXCO
    ld      iy, HASHBR      ; borders of #' s
    call    JTEXCO
    ld      iy, HASHBR      ; borders of #' s
    call    JTEXCO
    ld      iy, HASHBR      ; borders of #' s
    call    JTEXCO
    ld      iy, HASHBR      ; borders of #' s
    call    JTEXCO

   
;20
    ld      iy, HASHLN      ; line with all #' s
    call    JTEXCO

    rst     0


MODINF:
    defm 'VIOMON '
    defm 'v 2.2'
MODIN2:
    defm 'http://www.electrickeryl.nl/comp/mpf1'
MODIN3:
    defm '2022-02-07'
MODIEND:
	defb	00h
	rst 38h			;a4d0	ff 	. 
	rst 38h			;a4d1	ff 	. 
  
  
MEMDUMP:
        CALL    CRLF        ; start at a new line
        LD      A, DMPLINES
        LD      (LINCNT), A
            
MDNXT:            
        CALL    CLNBUF
        LD      BC, (DUMPADR)
        CALL    NXTLIN      ; 
        LD      A, BYTESLIN
        CALL    ADDSOME
        LD      (DUMPADR), BC
            
        LD      A, (LINCNT)
        DEC     A
        JR      Z, DONEDMP
        LD      (LINCNT), A
        JR      MDNXT
            
DONEDMP:
        RST     0
            
ADDSOME:
; Add A to BC
        PUSH    HL
        LD      L, A
        LD      A, C
        ADD     A, L
        LD      C, A
        JR      NC, MDNBI
        INC     B
MDNBI:
        POP     HL
        RET

NXTLIN:

; Write address to line buffer
; init: BC contains the address
;       IX contains the start address for the dump
; exit:
; destroys: AF, IX
;
        PUSH    BC
        PUSH    DE
        PUSH    HL
        PUSH    IX
        PUSH    IY
        LD      IX, LINEBUF
        LD      A, B
        CALL    BYTE2HEX
        LD      (IX+0), D
        INC     IX
        LD      (IX+0), E
        INC     IX
        LD      A, C
        CALL    BYTE2HEX
        LD      (IX+0), D
        INC     IX
        LD      A, E
        LD      (IX+0), E
        
; Write values to line buffer
; init: IX points to target HEX location MSN
;       IY points to target ASCII location 
;       BC points to source location
;       HL contains the memory bytes to dump per line (H assumed 0)
; exit:
; destroys: DE, HL
;
; 
        LD      L, BYTESLIN
        LD      IX, LINEBUF
        LD      IY, LINEBUF
        
NXTVAL1:
        LD      A, (BC)
        CALL    BYTE2HEX
        LD      (IX+HEXPOS), D
        INC     IX
        LD      (IX+HEXPOS), E
        INC     IX
        INC     IX              ; add space between hex values
;        LD      A, L
;        CP      5
;        JR      NZ, NVNOSP
;        INC     IX              ; extra space between groups of four
;NVNOSP:
        LD      A, (BC)         ; reload the value for ASCII dump
        CALL    PRTBL
        LD      (IY+ASCPOS), A
        INC     IY
        INC     BC
        DEC     L
        LD      A, L
        CP      0h
        JR      NZ, NXTVAL1

DONEVAL:

; Add line terminator
        LD      HL, LINEBUF + COLS -1
        LD      A, 0
        LD      (HL), A

; Call printLine
        LD      IY, LINEBUF
        CALL    JTEXCLN

        POP    IY
        POP    IX
        POP    HL
        POP    DE
        POP    BC
        
        RET     ; NXTLN

; BYTE2HEX - Converts a byte to two ASCII hexadecimal bytes
; init: A  - contains the byte
; exit: DE - contain the hex values
; destroys: AF
BYTE2HEX:
        PUSH    AF
        AND     0F0h
        RRCA
        RRCA
        RRCA
        RRCA

        CALL    NIB2HEX
        LD      D, A
        POP     AF
        AND     0Fh
        CALL    NIB2HEX      
        LD      E, A
        RET
 
; NIB2HEX - converts a nibble to an ASCII hexadecimal char
; init: A  - contains the nibble
; exit: A  - contains the hex char
NIB2HEX:
        ADD     A, '0'
        CP      ':'
        JR      C, N2H1
        ADD     A, 7
N2H1:
        RET

; PRTBL - make character printable; replace < 32 and > 127 by '.'
; init: A  - character to filter
; exit: A  - optionally filtered character
PRTBL:
        PUSH    BC
        LD      C, A
        LD      A, (PBAFLG)
        CP      0
        LD      A, C
        POP     BC
        JR      Z, PBPASS   ; pass all char
        CP      ' '
        JR      C, PRDOT    ; before ' ', 20h
        CP      '~'
        JR      NC, PRDOT   ; after '~', 7Eh
        RET                 ; between 1Fh and 7Fh
PRDOT: 
        LD      A, '.'
        RET
PBPASS:
        RET
 
CLNLNBF:        ; clean line buffer
        PUSH    AF
        PUSH    BC
        PUSH    DE
        PUSH    HL
        LD      A, ' '
        LD      (LINEBUF), A
        LD      HL, LINEBUF
        LD      DE, LINEBUF
        INC     DE
        LD      BC, COLS
        LDIR
        POP     HL
        POP     DE
        POP     BC
        POP     AF
        RET

JCLS:
        LD      A, ' '
        LD      (SCREEN), A
        LD      HL, SCREEN
        LD      DE, SCREEN
        INC     DE
        LD      BC, SCRNSIZ
        LDIR
        LD      HL, CURRST
        JP      SETREG
;        RST     0
