;***************************************************************************
;*
;* Title: Enter Digits
;* Author:	Judah Ben-Eliezer
;* Version:	1.0
;* Last updated:	10/28/2020
;* Target:			;ATmega4809 @3.3MHz
;*
;* DESCRIPTION
;* This program polls the flag associated with pushbutton 1. This flag is
;* connected to PE0. If the flag is set, the contents of the array bcd_entries
;* is shifted left and the BCD digit set on the least significant 4 bits of
;* PORTA_IN are stored in the least significant byte of the bcd_entries array.
;* Then the corresponding segment values for each digit in the bcd_entries
;* display are written into the led_display. Note: entry of a non-BCD value
;* is ignored.
;*
;* This program also continually multiplexes the display so that the digits
;* entered are conatantly seen on the display. Before any digits are entered
;* the display displays 0000.
;*
;* VERSION HISTORY
;* 1.0 Original version
;***************************************************************************

.nolist
.include "m4809def.inc"
.list

.dseg
bcd_entries: .byte 4
led_display: .byte 4
digit_num: .byte 1

.cseg

start:
	cbi VPORTE_DIR, 0
	ldi r16, $00
	out VPORTA_DIR, r16
	com r16
	out VPORTD_DIR, r16
	out VPORTC_DIR, r16
	ldi XH, HIGH(bcd_entries)
	ldi XL, LOW(bcd_entries)
	ldi YH, HIGH(led_display)
	ldi YL, LOW(led_display)
	com r16
	st X+, r16
	inc r16
	st X+, r16
	inc r16
	st X+, r16
	inc r16
	st X, r16

reset:
	cbi VPORTE_OUT, 1
	sbi VPORTE_OUT, 1

main_loop:
	ldi XH, HIGH(bcd_entries)
	ldi XL, LOW(bcd_entries)
	sbic VPORTE_IN, 0
	rcall poll_digit_entry
	rjmp main_loop

poll_digit_entry:
	in r16, VPORTA_IN
	ldi r18, $08

reverse_bits:
	ror r16
	rol r17
	dec r18
	brne reverse_bits

	cpi r17, $0A
	brsh reset
	ldi r18, $03
shift_bcd_entries:
	ldi XH, HIGH(bcd_entries)
	ldi XL, LOW(bcd_entries)
	dec r18
	add XL, r18
	ld r19, X+
	st X, r19
	brne shift_bcd_entries

	ldi XL, LOW(bcd_entries)
	ldi XH, HIGH(bcd_entries)
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

	ldi r22, $00
	sts digit_num, r22
	ldi YL, LOW(led_display)
multiplex_display:
	lds r17, digit_num
	lds r20, digit_num
	andi r17, $03
	add XL, r17
	ld r18, Y
	ldi r21, $80
	inc r20
loop:
	lsr r21
	dec r20
	brne loop

	lsl r21
	com r21
	out VPORTC_OUT, r21
	out VPORTD_OUT, r18
	cbi VPORTE_OUT, 1
	sbi VPORTE_OUT, 1
	inc r17
	sts digit_num, r17
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

	
	
	