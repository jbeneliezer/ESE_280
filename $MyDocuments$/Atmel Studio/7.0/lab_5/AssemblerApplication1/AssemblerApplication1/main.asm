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
    out VPORTA_DIR, r16
	out VPORTD_DIR, r17
	out VPORTD_OUT, r16
	cbi VPORTE_DIR, 0
	sbi VPORTE_DIR, 1
	ldi r17, $01	; delay = 0.1 * r17

check_flag:
	sbi VPORTE_OUT, 1
	sbic VPORTE_IN, 0
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
	cbi VPORTE_OUT, 1
	rjmp check_flag
