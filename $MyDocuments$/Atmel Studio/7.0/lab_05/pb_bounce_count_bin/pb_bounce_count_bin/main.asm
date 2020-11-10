;
; pb_bounce_count_bin.asm
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
	ldi r17, $FE

zero_loop:
	in r16, VPORTE_IN
	andi r16, $01
	cpi r16, $01
	breq one_loop
	rjmp zero_loop

one_loop:
	in r16, VPORTE_IN
	cpi r16, $00
	breq increment
	rjmp one_loop

increment:
	inc r17
	rjmp output

output:
	com r17
	out VPORTD_OUT, r17
	com r17
	rjmp zero_loop

    
