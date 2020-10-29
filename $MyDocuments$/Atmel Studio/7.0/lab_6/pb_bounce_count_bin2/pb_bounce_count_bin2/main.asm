;
; pb_bounce_count_bin2.asm
;
; Created: 10/6/2020 5:50:12 PM
; Author : hp
;

.nolist
.include "m4809def.inc"
.list


; Replace with your application code
start:
	ldi r16, $FF
	out VPORTD_DIR, r16
	cbi VPORTE_DIR, 0
	out VPORTD_OUT, r16
	ldi r17, $00

zero_loop:
	sbic VPORTE_IN, 0
	rjmp increment
	rjmp zero_loop

one_loop:
	sbis VPORTE_IN, 0
	rjmp zero_loop
	rjmp one_loop

increment:
	inc r17
	rjmp output

output:
	com r17
	out VPORTD_OUT, r17
	com r17
	rjmp one_loop