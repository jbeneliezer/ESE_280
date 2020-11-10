;
; FourBitComparator.asm
;
; Created: 9/23/2020 7:39:07 AM
; Author : hp
;

.nolist
.include "m4809def.inc"
.list


; Replace with your application code
start:
    ldi r16, 0x00
	out VPORTA_DIR, r16
	ldi r16, 0xFF
	out VPORTD_DIR, r16
	ldi r16, 0x00
	out VPORTD_OUT, r16

main:
	in r16, VPORTA_IN
	mov r17, r16
	mov r18, r16
	andi r17, 0xF0
	andi r18, 0x0F
	lsr r17
	lsr r17
	lsr r17
	lsr r17
	cpc r17, r18
	breq equal
	brsh greater
	brlo less

equal:
	ldi r19, 0x40
	com r19
	out VPORTD_OUT, r19
	rjmp main

greater:
	ldi r19, 0x80
	com r19
	out VPORTD_OUT, r19
	rjmp main

less:
	ldi r19, 0x20
	com r19
	out VPORTD_OUT, r19
	rjmp main


