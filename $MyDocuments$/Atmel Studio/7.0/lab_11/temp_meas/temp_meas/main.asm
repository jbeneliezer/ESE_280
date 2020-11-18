;
; temp_meas.asm
;
; Created: 11/17/2020 2:02:20 PM
; Author : Judah Ben-Eliezer
;

.nolist
.include "m4809def.inc"
.list

.equ PERIOD_EXAMPLE_VALUE = 25

.dseg
bcd_entries: .byte 4
led_display: .byte 4
digit_num: .byte 1


.cseg

reset:
	jmp start

.org TCA0_OVF_vect
	jmp post_display_ISR

.org ADC0_RESRDY_vect
	jmp read_ISR

start:
	;configure inputs and outputs
    cbi VPORTE_DIR, 3
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
	ldi r16, ADC_MUXPOS_AIN11_gc
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
	rjmp main_loop

;***************************************************************************
;* 
;* "read_ISR" - title
;*
;* Description: loads ADC0_RES into r17:r16 and calls bin16_to_BCD
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
read_ISR:
	push r16
	in r16, CPU_SREG
	push r16
	mov r16, XH
	push r16
	mov r16, XL
	push r16
	mov r16, ZH
	push r16
	mov r16, ZL
	push r16
	push r17
	push r18
	push r19

	ldi r19, $09	;load multiplier 2500 into r19:r18 for multiplication
	ldi r18, $C4
	lds r17, ADC0_RESH
	lds r16, ADC0_RESL
	rcall mpy16u
	lsr r18		;finish division by 1024 by taking middle two bytes and shifting right twice
	ror r17
	lsr r18
	ror r17
	mov r16, r17	; move output to r17:r16
	mov r17, r18
	subi r16, $F4	;subtract 500 from result
	sbci r17, $01
	rcall bin16_to_BCD
	rcall packed_to_bcd_entries
	rcall bcd_to_led

	;reset interrupt flag
	ldi r16, ADC_RESRDY_bm;
	sts ADC0_INTCTRL, r16

	;restart conversion
	ldi r16, ADC_STCONV_bm;
	sts ADC0_COMMAND, r16

	pop r19
	pop r18
	pop r17
	pop r16
	mov ZL, r16
	pop r16
	mov ZH, r16
	pop r16
	mov XL, r16
	pop r16
	mov XH, r16
	pop r16
	out CPU_SREG, r16
	pop r16

	reti

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
;* "packed_to_bcd_entries" - title
;*
;* Description:	Converts bcd input to 7seg output, from bcd_entries array to led_display array
;*
;* Author:
;* Version:
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
packed_to_bcd_entries:
	ldi XH, HIGH(bcd_entries)
	ldi XL, LOW(bcd_entries)
	mov r19, r23
	andi r19, $F0
	swap r19
	st X+, r19
	mov r19, r23
	andi r19, $0F
	st X+, r19
	mov r19, r22
	andi r19, $F0
	swap r19
	st X+, r19
	mov r19, r22
	andi r19, $0F
	st X, r19


;***************************************************************************
;* 
;* "bcd_to_led" - title
;*
;* Description:	Converts bcd input to 7seg output, from bcd_entries array to led_display array
;*
;* Author:
;* Version:
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

bcd_to_led:
	ldi XH, HIGH(bcd_entries)
	ldi XL, LOW(bcd_entries)
	st X, r17
	ldi r20, $04
conversion_loop:
	dec r20
	ldi XH, HIGH(bcd_entries)
	ldi XL, LOW(bcd_entries)
	ldi YH, HIGH(led_display)
	ldi YL, LOW(led_display)
	add XL, r20
	add YL, r20
	ld r18, X
	rcall hex_to_7seg
	st Y, r18
	cpi r20, $00
	brne conversion_loop
	ret

;***************************************************************************
;* 
;* "bin16_to_BCD" - 16-bit Binary to BCD Conversion
;*
;* Description: Converts a 16-bit unsigned binary number to a five digit
;* packed BCD number. Uses subroutine div16u from Atmel application note AVR200
;*
;* Author:					Ken Short
;* Version:					0.0
;* Last updated:			111320
;* Target:					ATmega4809
;* Number of words:
;* Number of cycles:
;* Low registers modified:	r14, r15
;* High registers modified: r16, r17, r18, r19, r20, r22, r23, r24
;*
;* Parameters: r17:r16 16-bit unsigned right justified number to be converted.
;* Returns:		r24:r23:r22 five digit packed BCD result.
;*
;* Notes: 
;* Subroutine uses repeated division by 10 to perform conversion.
;***************************************************************************
bin16_to_BCD:
	ldi r19, 0			;high byte of divisor for div16u
	ldi r18, 10			;low byte of the divisor for div16u

	rcall div16u		;divide original binary number by 10
	mov r22, r14		;result is BCD digit 0 (least significant digit)
	rcall div16u		;divide result from first division by 10, gives digit 1 
	swap r14			;swap digit 1 for packing
	or r22, r14			;pack

	rcall div16u		;divide result from second division by 10, gives digit 2
	mov r23, r14		;place in r23
	rcall div16u		;divide result from third division by 10, gives digit 3 
	swap r14			;swap digit 3 for packing
	or r23, r14			;pack

	rcall div16u		;divide result from fourth division by 10, gives digit 4
	mov r24, r14		;place in r24

	ret


;Subroutine div16u is from Atmel application note AVR200

;***************************************************************************
;*
;* "div16u" - 16/16 Bit Unsigned Division
;*
;* This subroutine divides the two 16-bit numbers 
;*# "dd16uH:dd16uL" (dividend) and "dv16uH:dv16uL" (divisor). 
;* The result is placed in "dres16uH:dres16uL" and the remainder in
;* "drem16uH:drem16uL".
;*  
;* Number of words	:19
;* Number of cycles	:235/251 (Min/Max)
;* Low registers used	:2 (drem16uL,drem16uH)
;* High registers used  :5 (dres16uL/dd16uL,dres16uH/dd16uH,dv16uL,dv16uH,
;*			    dcnt16u)
;*
;***************************************************************************

;***** Subroutine Register Variables

.def	drem16uL=r14
.def	drem16uH=r15
.def	dres16uL=r16
.def	dres16uH=r17
.def	dd16uL	=r16
.def	dd16uH	=r17
.def	dv16uL	=r18
.def	dv16uH	=r19
.def	dcnt16u	=r20

;***** Code

div16u:	clr	drem16uL	;clear remainder Low byte
	sub	drem16uH,drem16uH;clear remainder High byte and carry
	ldi	dcnt16u,17	;init loop counter
d16u_1:	rol	dd16uL		;shift left dividend
	rol	dd16uH
	dec	dcnt16u		;decrement counter
	brne	d16u_2		;if done
	ret			;    return
d16u_2:	rol	drem16uL	;shift dividend into remainder
	rol	drem16uH
	sub	drem16uL,dv16uL	;remainder = remainder - divisor
	sbc	drem16uH,dv16uH	;
	brcc	d16u_3		;if result negative
	add	drem16uL,dv16uL	;    restore remainder
	adc	drem16uH,dv16uH
	clc			;    clear carry to be shifted into result
	rjmp	d16u_1		;else
d16u_3:	sec			;    set carry to be shifted into result
	rjmp	d16u_1

;***************************************************************************
;*
;* "mpy16u" - 16x16 Bit Unsigned Multiplication
;*
;* This subroutine multiplies the two 16-bit register variables 
;* mp16uH:mp16uL and mc16uH:mc16uL.
;* The result is placed in m16u3:m16u2:m16u1:m16u0.
;*  
;* Number of words	:14 + return
;* Number of cycles	:153 + return
;* Low registers used	:None
;* High registers used  :7 (mp16uL,mp16uH,mc16uL/m16u0,mc16uH/m16u1,m16u2,
;*                          m16u3,mcnt16u)	
;*
;***************************************************************************

;***** Subroutine Register Variables

.def	mc16uL	=r16		;multiplicand low byte
.def	mc16uH	=r17		;multiplicand high byte
.def	mp16uL	=r18		;multiplier low byte
.def	mp16uH	=r19		;multiplier high byte
.def	m16u0	=r18		;result byte 0 (LSB)
.def	m16u1	=r19		;result byte 1
.def	m16u2	=r20		;result byte 2
.def	m16u3	=r21		;result byte 3 (MSB)
.def	mcnt16u	=r22		;loop counter

;***** Code

mpy16u:	clr	m16u3		;clear 2 highest bytes of result
	clr	m16u2
	ldi	mcnt16u,16	;init loop counter
	lsr	mp16uH
	ror	mp16uL

m16u_1:	brcc	noad8		;if bit 0 of multiplier set
	add	m16u2,mc16uL	;add multiplicand Low to byte 2 of res
	adc	m16u3,mc16uH	;add multiplicand high to byte 3 of res
noad8:	ror	m16u3		;shift right result byte 3
	ror	m16u2		;rotate right result byte 2
	ror	m16u1		;rotate result byte 1 and multiplier High
	ror	m16u0		;rotate result byte 0 and multiplier Low
	dec	mcnt16u		;decrement loop counter
	brne	m16u_1		;if not done, loop more
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
