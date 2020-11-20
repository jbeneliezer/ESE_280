;
; post_display.asm
;
; Created: 11/17/2020 11:13:12 AM
; Author : Judah Ben-Eliezer
;


; Replace with your application code

.nolist
.include "m4809def.inc"
.list

start:
	;configure PORTC and PORTD and output FF to both
	ldi r16, $FF
	out VPORTD_DIR, r16
	out VPORTC_DIR, r16
	out VPORTD_OUT, r16
	out VPORTC_OUT, r16

	rcall post_display

	rjmp main_loop


;***************************************************************************
;* 
;* "post_display"
;*
;* Description: toggles value for all PORTC pins.  Since PORTC is used to multiplex the led display, this will
;*	turn the LED display on and off
;* Author:	Judah Ben-Eliezer
;* Version:	1.0
;* Last updated:	11/17
;* Target:	ATmega4809
;* Number of words:	13
;* Number of cycles:	6
;* Low registers modified:	
;* High registers modified:
;* Parameters:	none
;* Returns:		none
;*
;* Notes: 
;*
;***************************************************************************
post_display:
	ldi r16, $00
	out VPORTC_OUT, r16
	rcall delay_1s
	ldi r16, $FF
	out VPORTC_OUT, r16
	ret

main_loop:
	nop
	rjmp main_loop

delay_1s:
	ldi r19, $FF
outer_outer_loop:
	ldi r18, $FF
outer_loop:
	ldi r17, $09
inner_loop:
	dec r17
	brne inner_loop
	dec r18
	brne outer_loop
	dec r19
	brne outer_outer_loop
	ret
