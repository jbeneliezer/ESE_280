;
; three_to_eight_decoder.asm
;
; Created: 9/23/2020 9:29:18 AM
; Author : user38x
;

.nolist
.include "m4809def.inc"
.list

; Replace with your application code

start:
    ldi r16, 0x00
	ldi r17, 0xFF
	out VPORTD_DIR, r17
	out VPORTA_DIR, r16
	out VPORTD_OUT, r17

main:
	in r16, VPORTA_IN
	ldi r18, 0x00
	ldi r19, 0x01
	ldi r20, 0x00
	andi r16, 0x1C
	cpi r16, 0x10
	brne output
	in r16, VPORTA_IN
	mov r17, r16
	swap r17
	lsr r17
	andi r17, 0x07
	cpi r17, 0x00
	breq zero
	cpi r17, 0x01
	breq one
	cpi r17, 0x02
	breq two
	cpi r17, 0x03
	breq three
	cpi r17, 0x04
	breq four
	cpi r17, 0x05
	breq five
	cpi r17, 0x06
	breq six
	cpi r17, 0x07
	breq seven

zero:
	ldi r20, 0x01
	rjmp output
one:
	ldi r20, 0x02
	rjmp output
two:
	ldi r20, 0x04
	rjmp output
three:
	ldi r20, 0x08
	rjmp output
four:
	ldi r20, 0x10
	rjmp output
five:
	ldi r20, 0x20
	rjmp output
six:
	ldi r20, 0x40
	rjmp output
seven:
	ldi r20, 0x80
	rjmp output

output:
	com r20
	out VPORTD_OUT, r20
	rjmp main
