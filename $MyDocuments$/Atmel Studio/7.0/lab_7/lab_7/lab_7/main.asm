;
; segment_and_digit_test.asm
;
; Created: 10/20/2020 6:49:26 PM
; Author : Judah Ben-Eliezer
;

.nolist
.include "m4809def.inc"
.list


start:
	ldi r16, $FF
	out VPORTD_DIR, r16
	out VPORTC_DIR, r16
	ldi r16, $00
	ldi r17, $7F
	ldi r18, $FF
	out VPORTD_OUT, r16
	out VPORTC_OUT, r17

main_loop:
	sbrs r17, 3		; sets mask to first bit 7 only if bit 3 is set
	ldi r17, $7F
	out VPORTC_OUT, r17

delay_1_s:		; not sure yet if 1 s
outer_outer_loop:
	ldi r20, $16
outer_loop:
	ldi r19, $FF
inner_loop:
	dec r19
	brne inner_loop
	dec r20
	brne outer_loop
	dec r18
	brne outer_outer_loop

ror_r17:
	ror r17
	rjmp main_loop

