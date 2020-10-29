;
; unconditional_input.asm
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

main_loop:
	in r16, VPORTA_IN
	com r16
	out VPORTD_OUT, r16
	rjmp main_loop