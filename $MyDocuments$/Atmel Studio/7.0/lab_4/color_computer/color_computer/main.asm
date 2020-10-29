;
; color_computer.asm
;
; Created: 9/23/2020 11:00:26 AM
; Author : user38x
;

.nolist
.include "m4809def.inc"
.list


; Replace with your application code
start:
	ldi r16, 0x00
	ldi r17, 0xFF
    out VPORTA_DIR, r16
	out VPORTD_DIR, r17
	out VPORTD_OUT, r17
	out VPORTC_DIR, r17
	out VPORTC_OUT, r16

main:
	in r16, VPORTA_IN
	out VPORTC_OUT, r16
	com r16
	out VPORTD_OUT, r16
	rjmp main
