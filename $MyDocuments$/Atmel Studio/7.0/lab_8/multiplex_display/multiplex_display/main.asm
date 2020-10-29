;***************************************************************************
;*
;* Title: multiplex_display.asm
;* Author: Judah Ben-Eliezer
;* Version: 1.0
;* Last updated: 10/27/2020
;* Target: ATMega4809
;*
;* DESCRIPTION
;* 
;* 
;*
;*
;* VERSION HISTORY
;* 1.0 Original version
;***************************************************************************


.nolist
.include "m4809def.inc"
.list


.dseg

led_display: .byte 4
digit_num: .byte 1


.cseg

start:
	ldi r16, $FF
	ldi r17, $00
	out VPORTD_DIR, r16
	out VPORTC_DIR, r16
	sts digit_num, r17
	
	ldi YH, HIGH(led_display)
	ldi YL, LOW(led_display)
	ldi r16, 0x01
	std Y+0, r16
	ldi r16, 0x4f
	std Y+1, r16
ldi r16, 0x12
	std Y+2, r16
ldi r16, 0x06
	std Y+3, r16

main_loop:
	;ldi YH, HIGH(led_display)
	;ldi YL, LOW(led_display)
	rcall multiplex_display
	rjmp main_loop

;***************************************************************************
;* 
;* "multiplex_display" - Multiplex the Four Digit LED Display
;*
;* Description: Updates a single digit of the display and increments the 
;*  digit_num to the value of the digit position to be displayed next.
;*
;* Author:	Judah Ben-Eliezer
;* Version:	1.0
;* Last updated:	10/27/2020
;* Target:						;ATmega4809 @ 3.3MHz
;* Number of words:	39
;* Number of cycles: 30
;* Low registers modified:	none
;* High registers modified:	none
;*
;* Parameters:
;* led_display: a four byte array that holds the segment values
;*  for each digit of the display. led_display[0] holds the segment pattern
;*  for digit 0 (the rightmost digit) and so on.
;* digit_num: a byte variable, the least significant two bits provide the
;* index of the next digit to be displayed.
;*
;* Returns: Outputs segment pattern and turns on digit driver for the next
;*  position in the display to be turned ON in the multiplexing sequence.
;*
;* Notes: 
;*
;***************************************************************************


multiplex_display:
	lds r17, digit_num
	andi r17, $03
	cpi r17, $00
	breq zero
	cpi r17, $01
	breq one
	cpi r17, $02
	breq two
	cpi r17, $03
	breq three
	rjmp main_loop

zero:
	ldi r19, $7F
	ldd r18, Y+0
	rjmp display

one:
	ldi r19, $BF
	ldd r18, Y+1
	rjmp display

two:
	ldi r19, $DF
	ldd r18, Y+2
	rjmp display

three:
	ldi r19, $EF
	ldd r18, Y+3

display:
	rcall hex_to_7seg
	out VPORTC_OUT, r19
	out VPORTD_OUT, r18
	
	inc r17
	sts digit_num, r17
	ret
	



;***************************************************************************
;* 
;* "hex_to_7seg" - Hexadecimal to Seven Segment Conversion
;*
;* Description: Converts a right justified hexadecimal digit to the seven
;* segment pattern required to display it. Pattern is right justified a
;* through g. Pattern uses 0s to turn segments on ON.
;*
;* Author:						Ken Short
;* Version:						1.0						
;* Last updated:				101620
;* Target:						ATmega4809
;* Number of words:				8
;* Number of cycles:			13
;* Low registers modified:		none		
;* High registers modified:		r16, r18, ZL, ZH
;*
;* Parameters: r18: right justified hex digit, high nibble 0
;* Returns: r18: segment values a through g right justified
;*
;* Notes: 
;*
;***************************************************************************

hex_to_7seg:
	andi r18, 0x0F				;clear ms nibble
    ldi ZH, HIGH(hextable * 2)  ;set Z to point to start of table
    ldi ZL, LOW(hextable * 2)
    ldi r16, $00                ;add offset to Z pointer
    add ZL, r18
    adc ZH, r16
    lpm r18, Z                  ;load byte from table pointed to by Z
	ret

    ;Table of segment values to display digits 0 - F
    ;!!! seven values must be added - verify all values
hextable: .db $01, $4F, $12, $06, $4C, $24, $20, $0F, $00, $04, $08, $60, $31, $42, $30, $38
	