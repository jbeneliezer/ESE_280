;
; conditional_input_sftwe.asm
;
; Created: 10/6/2020 6:38:10 PM
; Author : hp
;

.nolist
.include "m4809def.inc"
.list


; Replace with your application code
start:
	ldi r16, $00
	ldi r17, $FF
	ldi r18, $FE
    out VPORTA_DIR, r16
	out VPORTD_DIR, r17
	out VPORTD_OUT, r16
	out VPORTE_DIR, r18
	ldi r17, $01	; delay = 0.1 * r17

check_flag:
	ldi r20, $02
	out VPORTE_OUT, r20
	in r18, VPORTE_IN
	andi r18, $01
	cpi r18, $01
	breq outer_loop
	rjmp check_flag

outer_loop:
	ldi r19, 110

inner_loop:
	dec r19
	brne inner_loop
	dec r17
	brne outer_loop
	
sw_led_io:
	in r16, VPORTA_IN
	com r16
	out VPORTD_OUT, r16
	ldi r20, $00
	out VPORTE_OUT, r20
	rjmp check_flag
