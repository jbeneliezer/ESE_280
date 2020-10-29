;***************************************************************************
;* 
;* "poll_digit_entry" - Polls Pushbutton 1 for Conditional Digit Entry
;*
;* Description:
;* Polls the flag associated with pushbutton 1. This flag is connected to
;* PE0. If the flag is set, the contents of the array bcd_entries is shifted
;* left and the BCD digit set on the least significant 4 bits of PORTA_IN are 
;* stored in the least significant byte of the bcd_entries array. Then the
;* corresponding segment values for each digit in the bcd_entries display are
;* written into the led_display. Note: entry of a non-BCD value is ignored.
;* Author:	Judah Ben-Eliezer
;* Version:	1.0
;* Last updated:	10/28/2020
;* Target:	ATmega4809
;* Number of words:
;* Number of cycles:
;* Low registers modified:
;* High registers modified:
;*
;* Parameters: 
;* Returns:
;*
;* Notes: 
;*
;***************************************************************************

.nolist
.include "m4809def.inc"
.list

.dseg
bcd_entries: .byte 4
led_display: .byte 4

.cseg

start:
	ldi r16, $00
	out VPORTA_DIR, r16
	out VPORTE_DIR, r16
	ldi XH, HIGH(bcd_entries)
	ldi XL, LOW(bcd_entries)
	ldi YH, HIGH(led_display)
	ldi YL, LOW(led_display)
	st X+, r16
	inc r16
	st X+, r16
	inc r16
	st X+, r16
	inc r16
	st X, r16
	

main_loop:
	ldi XH, HIGH(bcd_entries)
	ldi XL, LOW(bcd_entries)
	sbic VPORTE_IN, 0
	rcall poll_digit_entry
	rjmp main_loop

poll_digit_entry:
	in r17, VPORTA_IN
	cpi r17, $0A
	brsh main_loop
	ldi r18, $03
shift_bcd_entries:
	ldi XH, HIGH(bcd_entries)
	ldi XL, LOW(bcd_entries)
	dec r18
	add XL, r18
	ld r19, X+
	st X, r19
	brne shift_bcd_entries

	ldi XH, HIGH(bcd_entries)
	ldi XL, LOW(bcd_entries)
	st X, r17
	ldi r20, $04
bcd_to_led:
	dec r20
	ldi XH, HIGH(bcd_entries)
	ldi XL, LOW(bcd_entries)
	ldi YH, HIGH(led_display)
	ldi YL, LOW(led_display)
	add XL, r20
	add YL, r20
	ld r18, X
	rcall hex_to_7seg
	st Y, r18
	cpi r20, $00
	brne bcd_to_led
	ret


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

	