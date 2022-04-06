
; Application routines on top of VIO_MPF.asm

; ************ MEMDUMP ************
		; Dump 128 bytes to display in hex and ascii. Start address is from DUMPADR
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

; subroutines for MEMDUMP
            
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


; ************ SPLASH ************
		; outlines the display, displays copyrights
SPASH:
;1
    CALL    CRLF
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
    ld      de, LINEBUF + 1
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

    ld      d, 13
BRLOOP:
	push	de
    ld      iy, HASHBR      ; borders of #' s
    call    JTEXCO
    pop		de
    dec     d
    jr      nz, BRLOOP
   
;24
    ld      iy, HASHLN      ; line with all #' s
    call    JTEXCO

    rst     0

		; data and subroutines for SPASH
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
    
; ************ CHRSET ************
		; Clear screen (FormFeed) and write character set to screen
CHRSET:
la1d7h:        
	; clears screen with form feed
	ld c, FF		;a1d7	0e 0c 	. . insert Form feed
	call JCRTCO		;a1d9	cd 0a a0 	. . . 
	; standard characters
	ld c,000h		;a1dc	0e 00 	. . 
CHRS1:             ; iterate from 00h to 07Fh
	call JCRTOU		;a1de	cd 0d a0 	. . . 
	inc c			;a1e1	0c 	. 
	ld a,c			;a1e2	79 	y 
	cp 080h			;a1e3	fe 80 	. . 
	jr nz, CHRS1		;a1e5	20 f7 	  next char (< 80h). 
    ; inverse characters
	ld c, CR		;a1e7	0e 0d 	. . ;insert CR & LF
	call JCRTCO		;a1e9	cd 0a a0 	. . . 
	ld c, LF		;a1ec	0e 0a 	. . 
	call JCRTCO		;a1ee	cd 0a a0 	. . . 
	ld c,080h		;a1f1	0e 80 	. . 
CHRS2:             ; iterate from 80h to FFh
	call JCRTOU		;a1f3	cd 0d a0 	. . . 
	inc c			;a1f6	0c 	. 
	jr nz, CHRS2		;a1f7	20 fa 	  . next char. 
	jp 00000h		;a1f9	c3 00 00 	. . . Back to monitor
	
NULLN:
	DEFB	00
R12TXT:
	DEFB	'R12 Display Start Addr. (High)', 0
R13TXT:
	DEFB	'R13 Display Start Addr. (Low)', 0
R14TXT:
	DEFB	'R14 Cursor Address (High)', 0
R15TXT:
	DEFB	'R15 Cursor Address (Low)', 0
R16TXT:
	DEFB	'R16 Light Pen Address (High)', 0
R17TXT:
	DEFB	'R17 Light Pen Address (Low)', 0
RSTATTX:
	DEFB	'Status Register', 0
	
REGTXTTBL:
	DEFW	R12TXT
	DEFW	R13TXT
	DEFW	R14TXT
	DEFW	R15TXT
	DEFW	R16TXT
	DEFW	R17TXT
	
FSTVISR:	EQU	00Ch

DMPREGS:		; It would be better to get all registers first and then 
				; dump them, as video-writes will change cursor address.
	CALL    CRLF
	LD		B, FSTVISR
DRNXT:
	LD		A, B
	CALL	GETREG
	CALL	BYTE2HEX
	LD		C, D
	CALL	JCRTCO	
	LD		C, E
	CALL	JCRTCO	
	LD		C, ' '
	CALL	JCRTCO
	; Add some text
	LD		A, B
	SUB		FSTVISR
	RLC		A
	LD		HL, REGTXTTBL
	ADD		A, L
	LD		L, A
	JR		NC, DRLOK
	INC		H
DRLOK:
	LD		E, (HL)
	INC		HL
	LD		D, (HL)
	DEC		HL
	
	LD		IY, 0
	ADD		IY, DE
	
	CALL	JTEXCLN
	
;	CALL	CRLF
	INC		B
	LD		A, 012h
	CP		B
	JR		NZ, DRNXT
	
	LD		C, CRTA
	IN		A, (C)
	CALL	BYTE2HEX
	LD		C, D
	CALL	JCRTCO	
	LD		C, E
	CALL	JCRTCO	
	LD		C, ' '
	CALL	JCRTCO
	LD		IY, RSTATTX
	CALL	JTEXCLN

	RST		0
