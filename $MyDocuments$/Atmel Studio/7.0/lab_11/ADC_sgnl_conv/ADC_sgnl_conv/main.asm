;
; ADC_sgnl_conv.asm
;
; Created: 11/17/2020 2:02:20 PM
; Author : Judah Ben-Eliezer
;

.nolist
.include "m4809def.inc"
.list

.equ PERIOD_EXAMPLE_VALUE = 25

.dseg
led_display: .byte 4
digit_num: .byte 1


.cseg

reset:
	jmp start

.org TCA0_OVF_vect
	jmp post_display_ISR

start:
	;configure inputs and outputs
    cbi VPORTE_DIR, 1
	ldi r16, $FF
	out VPORTC_DIR, r16
	out VPORTD_DIR, r16
	com r16
	out VPORTC_OUT, r16
	out VPORTD_OUT, r16

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

	;set voltage reference
	ldi r16, VREF_ADC0REFSEL_2V5_gc
	sts VREF_CTRLA, r16

	;select PE1/ AIN9
	ldi r16, ADC_MUXPOS_AIN9_gc
	sts ADC0_MUXPOS, r16

	;enable internal reference and set prescaler to div 64
	ldi r16, ADC_PRESC_DIV64_gc | ADC_REFSEL_INTREF_gc
	sts ADC0_CTRLC, r16

	;set resolution to 10 bit and enable adc
	ldi r16, ADC_RESSEL_10BIT_gc | ADC_ENABLE_bm;
	sts ADC0_CTRLA, r16

	;start conversion
	ldi r16, ADC_STCONV_bm;
	sts ADC0_COMMAND, r16

	;enable interrupts
	sei
	jmp wait_for_post

;***************************************************************************
;* 
;* "post_display" - title
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
post_display_ISR:
	push r16
	in r16, CPU_SREG
	push r16
	push r17

	ldi r17, $FF
	in r16, VPORTC_OUT
	eor r16, r17
	out VPORTC_OUT, r16

	;ldi r16, TCA_SINGLE_OVF_bm	;clear OVF flag
	;sts TCA0_SINGLE_INTFLAGS, r16

	pop r17
	pop r16
	out CPU_SREG, r16
	pop r16

	sei
	jmp main_loop

wait_for_post:
	nop
	rjmp wait_for_post

main_loop:
	rcall multiplex_display
	rcall mux_digit_delay
	lds r19, ADC0_INTFLAGS
	sbrc r19, 0
	rcall read
	rjmp main_loop

;***************************************************************************
;* 
;* "read" - title
;*
;* Description: loads ADC0_RES into r17:r16 and calls bin16_to_led
;*
;* Author:	Judah Ben-Eliezer
;* Version:	1.0
;* Last updated:	11/17/2020
;* Target:	ATmega4809
;* Number of words:
;* Number of cycles:
;* Low registers modified:	none
;* High registers modified:		r17:r16
;*
;* Parameters:	ADC0_RES
;* Returns:		r17:r16
;*
;* Notes: 
;*
;***************************************************************************
read:
	lds r17, ADC0_RESH
	lds r16, ADC0_RESL
	rcall bin16_to_led

	;reset interrupt flag
	ldi r16, ADC_RESRDY_bm;
	sts ADC0_INTCTRL, r16

	;restart conversion
	ldi r16, ADC_STCONV_bm;
	sts ADC0_COMMAND, r16

	ret

;***************************************************************************
;* 
;* "multiplex_display" - title
;*
;* Description:	outputs values from led_display array to 7 segment display on PORTD driven by highest two bits of PORTC
;*
;* Author:	Judah Ben-Eliezer
;* Version:	1.0
;* Last updated:	11/10/2020
;* Target:	ATmega4809
;* Number of words:
;* Number of cycles:
;* Low registers modified:
;* High registers modified:
;*
;* Parameters:
;* Returns:
;*
;* Notes: 
;*
;***************************************************************************
multiplex_display:
	ldi YH, HIGH(led_display)
	ldi YL, LOW(led_display)
	lds r17, digit_num
	andi r17, $03
	mov r20, r17
	add YL, r17
	ld r18, Y
	ldi r21, $80
	inc r20
loop:
	lsr r21
	dec r20
	brne loop
	lsl r21
	com r21
	out VPORTC_OUT, r21
	out VPORTD_OUT, r18
	inc r17
	sts digit_num, r17
	ret

;***************************************************************************
;* 
;* "mux_digit_delay" - title
;*
;* Description: delays 0.1 * r23
;*
;* Author:	Judah Ben-Eliezer
;* Version:	1.0
;* Last updated:
;* Target:
;* Number of words:
;* Number of cycles:
;* Low registers modified:
;* High registers modified:
;*
;* Parameters:
;* Returns:
;*
;* Notes: 
;*
;***************************************************************************
mux_digit_delay:
	ldi r23, $08 ; 0.1 * r23 = delay
outer_loop:
	ldi r24, $06
inner_loop:
	dec r24
	brne inner_loop
	dec r23
	brne outer_loop
	ret

;***************************************************************************
;* 
;* "bin16_to_led" - title
;*
;* Description:	Converts bin16 input to 7seg output, from bcd_entries array to led_display array
;*
;* Author:	Judah Ben-Eliezer
;* Version:	1.0
;* Last updated:	11/17/2020
;* Target:	ATmega4809
;* Number of words:
;* Number of cycles:
;* Low registers modified:
;* High registers modified:
;*
;* Parameters:	r17:r16 16 bit binary number.
;* Returns:	none
;*
;* Notes: 
;*
;***************************************************************************

bin16_to_led:
	ldi XH, HIGH(led_display)
	ldi XL, LOW(led_display)
	mov r18, r17
	andi r18, $F0
	swap r18
	rcall hex_to_7seg
	st X+, r18
	mov r18, r17
	andi r18, $0F
	rcall hex_to_7seg
	st X+, r18
	mov r18, r16
	andi r18, $F0
	swap r18
	rcall hex_to_7seg
	st X+, r18
	mov r18, r16
	andi r18, $0F
	rcall hex_to_7seg
	st X, r18
	ret

;***************************************************************************
;* 
;* "hex_to_7seg" - Hexadecimal to Seven Segment Conversion
;*
;* Description: Converts a right justified hexadecimal digit to the seven
;* segment pattern required to display it. Pattern is right justified a
;* through g. Pattern uses 0s to turn segments on ON.
;*
;* Author:						Ken Short
;* Version:						1.0						
;* Last updated:				101620
;* Target:						ATmega4809
;* Number of words:				8
;* Number of cycles:			13
;* Low registers modified:		none		
;* High registers modified:		r19, r18, ZL, ZH
;*
;* Parameters: r18: right justified hex digit, high nibble 0
;* Returns: r18: segment values a through g right justified
;*
;* Notes: 
;*
;***************************************************************************

hex_to_7seg:
	andi r18, 0x0F				;clear ms nibble
    ldi ZH, HIGH(hextable * 2)  ;set Z to point to start of table
    ldi ZL, LOW(hextable * 2)
    ldi r19, $00                ;add offset to Z pointer
    add ZL, r18
    adc ZH, r19
    lpm r18, Z                  ;load byte from table pointed to by Z
	ret

    ;Table of segment values to display digits 0 - F
    ;!!! seven values must be added - verify all values
hextable: .db $01, $4F, $12, $06, $4C, $24, $20, $0F, $00, $04, $08, $60, $31, $42, $30, $38
