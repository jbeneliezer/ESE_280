;
; pb_sftwe_debounce_count_bin.asm
;
; Created: 10/6/2020 5:50:12 PM
; Author : hp
;

.nolist
.include "m4809def.inc"
.list


; Replace with your application code
start:
	ldi r16, $00
	ldi r17, $FF
	out VPORTE_DIR, r16
	out VPORTD_DIR, r17
	out VPORTD_OUT, r16
	ldi r17, $00
	ldi r18, $01	; delay = 0.1 * r18, set r18 to desired delay

zero_loop:
	in r16, VPORTE_IN
	andi r16, $01
	cpi r16, $01
	breq one_loop
	rjmp zero_loop

one_loop:
	in r16, VPORTE_IN
	cpi r16, $00
	breq outer_loop
	rjmp one_loop

outer_loop:
	ldi r19, 110

inner_loop:
	dec r19
	brne inner_loop
	dec r18
	brne outer_loop

output:
	com r17
	out VPORTD_OUT, r17
	com r17
	rjmp zero_loop