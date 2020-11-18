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

.equ PERIOD_EXAMPLE_VALUE = 25

reset:
	jmp start

.org TCA0_OVF_vect
	jmp toggle_pins_ISR

start:
	;configure PORTC and PORTD and output FF to both
	ldi r16, $FF
	out VPORTD_DIR, r16
	out VPORTC_DIR, r16
	out VPORTD_OUT, r16
	out VPORTC_OUT, r16
	
	;configure TCA0
	ldi r16, TCA_SINGLE_WGMODE_NORMAL_gc	;WGMODE normal
	sts TCA0_SINGLE_CTRLB, r16

	;enable overflow interrupt
	ldi r16, TCA_SINGLE_OVF_bm
	sts TCA0_SINGLE_INTCTRL, r16

	;load period low byte then high byte
	ldi r16, LOW(PERIOD_EXAMPLE_VALUE)
	sts TCA0_SINGLE_PER, r16
	ldi r16, HIGH(PERIOD_EXAMPLE_VALUE)
	sts TCA0_SINGLE_PER + 1, r16

	;set clock and start timer
	ldi r16, TCA_SINGLE_CLKSEL_DIV256_gc | TCA_SINGLE_ENABLE_bm
	sts TCA0_SINGLE_CTRLA, r16

	ldi r16, $00
	out VPORTD_OUT, r16

	sei		;enable global interrupts


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
	ldi r17, $FF
	in r16, VPORTC_OUT
	eor r16, r17
	out VPORTC_OUT, r16
	ret

main_loop:
	nop
	rjmp main_loop

;***************************************************************************
;* 
;* "toggle_pins_ISR" - title
;*
;* Description:		ISR to toggle PORTC pins, called whenever timing buffer TCA0 overflows
;*
;* Author:	Judah Ben-Eliezer
;* Version:	1.0
;* Last updated:	11/17/2020
;* Target:	ATmega4809
;* Number of words:	27
;* Number of cycles:	12
;* Low registers modified:
;* High registers modified:
;*
;* Parameters:	none
;* Returns:	none
;*
;* Notes: 
;*
;***************************************************************************
toggle_pins_ISR:
	push r16
	in r16, CPU_SREG
	push r16
	push r17

	rcall post_display	;call subroutine to toggle display

	ldi r16, TCA_SINGLE_OVF_bm	;clear OVF flag
	sts TCA0_SINGLE_INTFLAGS, r16

	pop r17
	pop r16
	out CPU_SREG, r16
	pop r16
	
	reti
	