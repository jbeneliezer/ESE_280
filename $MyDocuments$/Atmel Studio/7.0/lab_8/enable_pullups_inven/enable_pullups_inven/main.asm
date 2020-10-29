;;***************************************************************************
;*
;* Title: enable_pullups_inven.asm
;* Author: Judah Ben-Eliezer
;* Version: 1.0
;* Last updated: 10/27/2020
;* Target: 
;*
;* DESCRIPTION
;* 
;* 
;*
;*
;* VERSION HISTORY
;* 1.0 Original version
;***************************************************************************


.nolist
.include "m4809def.inc"
.list


; Replace with your application code
start:
	ldi r16, $00
    out VPORTA_DIR, r16
	ldi XH, HIGH(PORTA_PIN0CTRL)
	ldi XL, LOW(PORTA_PIN0CTRL)
	ldi r17, 8

main_loop:
	rcall pullups
	rjmp main_loop

;***************************************************************************
;* 
;* "pullups" - title
;*
;* Description:
;*
;* Author:	Judah Ben-Eliezer
;* Version:	1.0
;* Last updated:	10/27/2020
;* Target:	AtMega4809
;* Number of words:
;* Number of cycles:
;* Low registers modified:
;* High registers modified:
;*
;* Parameters: none
;* Returns:	none
;*
;* Notes: 
;*
;***************************************************************************

pullups:
	ld r16, X
	ori r16, $88
	st X+, r16
	dec r17
	brne pullups
	rjmp main_loop

	
 

