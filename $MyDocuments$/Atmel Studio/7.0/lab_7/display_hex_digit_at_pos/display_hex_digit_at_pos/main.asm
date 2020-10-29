;
; display_hex_digit_at_pos.asm
;
; Created: 10/20/2020 8:30:20 PM
; Author : hp
;

.nolist
.include "m4809def.inc"
.list

start:
	ldi r16, $00
	ldi r17, $FF
	out VPORTA_DIR, r16
	out VPORTD_DIR, r17
	out VPORTC_DIR, r17
	out VPORTD_OUT, r17

main_loop:
	in r16, VPORTA_IN
	cp r17, r16
	cp r18, r16
	andi r17, $C0
	andi r16, $0F
	cpi r17, $00
	breq zero
	cpi r17, $40
	breq one
	cpi r17, $80
	breq two
	cpi r17, $C0
	breq three
	rjmp main_loop

zero:
	cbi VPORTC_OUT, 7
	rjmp hex_to_7seg

one:
	cbi VPORTC_OUT, 6
	rjmp hex_to_7seg

two:
	cbi VPORTC_OUT, 5
	rjmp hex_to_7seg

three:
	cbi VPORTC_OUT, 4



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
	rjmp output

    ;Table of segment values to display digits 0 - F
    ;!!! seven values must be added - verify all values
hextable: .db $01, $4F, $12, $06, $4C, $24, $20, $0F, $00, $04, $08, $60, $31, $42, $30, $38

output:
	com r18
	out VPORTD_OUT, r18
	rjmp main_loop