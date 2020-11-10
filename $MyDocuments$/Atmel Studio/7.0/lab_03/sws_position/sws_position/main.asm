;
; sws_positions.asm
;
; Created: 9/16/2020 7:20:07 AM
; Author : hp
;


; Replace with your application code
start:
    ldi r16, 0xFF
	out VPORTD_DIR, r16
	ldi r16, 0x00
	out VPORTA_DIR, r16

again:
	in r16, VPORTA_IN
	com r16
	out VPORTD_OUT, r16
	rjmp again
