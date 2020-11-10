;***************************************************************************
;*
;* Title: bcd_to_hex_mux_intr
;* Author:	Judah Ben-Eliezer
;* Version:	1.0
;* Last updated:	11/10/2020
;* Target:			;ATmega4809 @3.3MHz
;*
;* DESCRIPTION
;* This program polls the flag associated with pushbutton 1. This flag is
;* connected to PE0. If the flag is set, the contents of the array bcd_entries
;* is shifted left and the BCD digit set on the least significant 4 bits of
;* PORTA_IN are stored in the least significant byte of the bcd_entries array.
;* Then the corresponding segment values for each digit in the bcd_entries
;* display are written into the led_display. Note: entry of a non-BCD value
;* is ignored.
;*
;* This program also continually multiplexes the display so that the digits
;* entered are constantly seen on the display. Before any digits are entered
;* the display displays 0000.
;*
;* This program also polls the flag associated with pushbutton 2. This flag
;* is connected to PE2. If the flag is set, the digits in the bcd_entries
;* array are read and passed to the prewritten subroutine BCD2bin16. This
;* subroutine performs a BCD to binary conversion. The binary result is
;* partitioned into hexadecimal and placed into the array hex_results. The
;* contents of the hex_results array is converted to seven segment values
;* and placed into the led_display array. The multiplexing then causes
;* the hexadecimal equivalent of the BCD value entered to be displayed in
;* hexadecimal.
;*
;* VERSION HISTORY
;* 1.0 Original version
;***************************************************************************

.nolist
.include "m4809def.inc"
.list

.equ PERIOD_EXAMPLE_VALUE = 325

.dseg
bcd_entries: .byte 4
led_display: .byte 4
digit_num: .byte 1
hex_results: .byte 4

.cseg

.org TCA0_OVF_vect
	jmp mux_display_ISR		;vector for all TCA0_OVF pin change IRQs

.org PORTE_PORT_vect
	jmp porte_ISR		;vector for all PORTE pin change IRQs

start:
	cbi VPORTE_DIR, 0
	cbi VPORTE_DIR, 2
	ldi r16, $00
	out VPORTA_DIR, r16
	com r16
	out VPORTD_DIR, r16
	out VPORTC_DIR, r16
	ldi XH, HIGH(bcd_entries)
	ldi XL, LOW(bcd_entries)
	ldi YH, HIGH(led_display)
	ldi YL, LOW(led_display)
	com r16
	st X+, r16
	st X+, r16
	st X+, r16
	st X, r16
	ldi XL, LOW(bcd_entries)

	;Configure interrupts
	lds r16, PORTE_PIN0CTRL	;set ISC for PE0 to pos. edge
	ori r16, 0x02		;set ISC for rising edge
	sts PORTE_PIN0CTRL, r16

	lds r16, PORTE_PIN2CTRL	;set ISC for PE2 to pos. edge
	ori r16, 0x02		;set ISC for rising edge
	sts PORTE_PIN2CTRL, r16

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

	lds r16, TCA0_SPLIT_INTCTRL
	ori r16, 0x01
	sts TCA0_SPLIT_INTCTRL, r16

	sei			;enable global interrupts

main_loop:
	nop
	rjmp main_loop

;Interrupt service routine for any PORTE pin change IRQ
porte_ISR:
	push r16		;save r16 then SREG
	in r16, CPU_SREG
	push r16
	cli				;clear global interrupt enable

	;Determine which pins of PORTE have IRQs
	lds r16, PORTE_INTFLAGS	;check for PE0 IRQ flag set
	sbrc r16, 0
	rcall PB1_sub			;execute subroutine for PE0

	lds r16, PORTE_INTFLAGS	;check for PE2 IRQ flag set
	sbrc r16, 2
	rcall PB2_sub			;execute subroutine for PE2
	

	pop r16			;restore SREG then r16
	out CPU_SREG, r16
	pop r16
	reti			;return from PORTE pin change ISR

;Interrupt service routine for any overflow of counter
mux_display_ISR:
	push r16
	in r16, CPU_SREG
	push r16

	rcall multiplex_display		;multiplexes display

	ldi r16, TCA_SINGLE_OVF_bm	;clear OVF flag
	sts TCA0_SINGLE_INTFLAGS, r16

	pop r16			;restore SREG then r16
	out CPU_SREG, r16
	pop r16
	reti

pb1_sub:
	rcall reverse_bits
	cpi r17, $0A
	brsh non_bcd
	rcall shift_bcd_entries
	rcall bcd_to_led
	ldi r16, PORT_INT0_bm	;clear IRQ flag for PE0
	sts PORTE_INTFLAGS, r16
	ret

non_bcd:
	reti

pb2_sub:
	ldi XH, HIGH(bcd_entries)
	ldi XL, LOW(bcd_entries)
	ldi r18, $00
	ld r17, X+
	swap r17
	ld r19, X+
	or r17, r19
	ld r16, X+
	swap r16
	ld r19, X
	or r16, r19
	rcall BCD2bin16

	;load_to_hex_results
	ldi XH, HIGH(hex_results)
	ldi XL, LOW(hex_results)
	ldi r19, $00
	or r19, tbinH
	andi r19, $F0
	swap r19
	st X+, r19
	ldi r19, $00
	or r19, tbinH
	andi r19, $0F 
	st X+, r19
	ldi r19, $00
	or r19, tbinL
	andi r19, $F0
	swap r19
	st X+, r19
	ldi r19, $00
	or r19, tbinL
	andi r19, $0F
	st X+, r19

	;load to led_display
	ldi XH, HIGH(led_display)
	ldi XL, LOW(led_display)
	ldi r18, $00
	or r18, tbinH
	andi r18, $F0
	swap r18
	rcall hex_to_7seg
	st X+, r18
	ldi r18, $00
	or r18, tbinH
	andi r18, $0F 
	rcall hex_to_7seg
	st X+, r18
	ldi r18, $00
	or r18, tbinL
	andi r18, $F0
	swap r18
	rcall hex_to_7seg
	st X+, r18
	ldi r18, $00
	or r18, tbinL
	andi r18, $0F
	rcall hex_to_7seg
	st X+, r18
	ldi r16, PORT_INT2_bm	;clear IRQ flag for PE2
	sts PORTE_INTFLAGS, r16
	ret

;***************************************************************************
;* 
;* "reverse_bits" - Reverse Bits
;*
;* Description: Reverses the bit positions in a byte passed in. Bit 0
;* becomes bit 7, bit 6 becomes bit 1, and so on.
;*
;* Author:					Judah Ben-Eliezer
;* Version:					1.0
;* Last updated:			101120
;* Target:					ATmega4809
;* Number of words:			8
;* Number of cycles:
;* Low registers modified:	r16, r17, r18
;* High registers modified:	none
;*
;* Parameters: r16: byte to be reversed.
;* Returns: r16: reversed byte
;*
;* Notes: 
;*
;***************************************************************************
	
reverse_bits:
	ldi r18, $08
loop_8:
	ror r16
	rol r17
	dec r18
	brne loop_8
	ret

shift_bcd_entries:
	ldi r18, $03
shift_loop:
	ldi XH, HIGH(bcd_entries)
	ldi XL, LOW(bcd_entries)
	dec r18
	add XL, r18
	ld r19, X+
	st X, r19
	brne shift_loop
	ret

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
	ldi XL, LOW(bcd_entries)
	ldi XH, HIGH(bcd_entries)
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
	ldi r22, $04
	ldi r23, $00
	sts digit_num, r23
loop_4:
	ldi YL, LOW(led_display)
	lds r17, digit_num
	lds r20, digit_num
	andi r17, $03
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
	dec r22
	brne loop_4
	ret

;***************************************************************************
;*
;* "BCD2bin16" - BCD to 16-Bit Binary Conversion
;*
;* This subroutine converts a 5-digit packed BCD number represented by
;* 3 bytes (fBCD2:fBCD1:fBCD0) to a 16-bit number (tbinH:tbinL).
;* MSD of the 5-digit number must be placed in the lowermost nibble of fBCD2.
;*
;* Let "abcde" denote the 5-digit number. The conversion is done by
;* computing the formula: 10(10(10(10a+b)+c)+d)+e.
;* The subroutine "mul10a"/"mul10b" does the multiply-and-add operation
;* which is repeated four times during the computation.
;*
;* Number of words	:30
;* Number of cycles	:108
;* Low registers used	:4 (copyL,copyH,mp10L/tbinL,mp10H/tbinH)
;* High registers used  :4 (fBCD0,fBCD1,fBCD2,adder)	
;*
;***************************************************************************

;***** "mul10a"/"mul10b" Subroutine Register Variables

.def	copyL	=r12		;temporary register
.def	copyH	=r13		;temporary register
.def	mp10L	=r14		;Low byte of number to be multiplied by 10
.def	mp10H	=r15		;High byte of number to be multiplied by 10
.def	adder	=r19		;value to add after multiplication	

;***** Code

mul10a:	;***** multiplies "mp10H:mp10L" with 10 and adds "adder" high nibble
	swap	adder
mul10b:	;***** multiplies "mp10H:mp10L" with 10 and adds "adder" low nibble
	mov	copyL,mp10L	;make copy
	mov	copyH,mp10H
	lsl	mp10L		;multiply original by 2
	rol	mp10H
	lsl	copyL		;multiply copy by 2
	rol	copyH		
	lsl	copyL		;multiply copy by 2 (4)
	rol	copyH		
	lsl	copyL		;multiply copy by 2 (8)
	rol	copyH		
	add	mp10L,copyL	;add copy to original
	adc	mp10H,copyH	
	andi	adder,0x0f	;mask away upper nibble of adder
	add	mp10L,adder	;add lower nibble of adder
	brcc	m10_1		;if carry not cleared
	inc	mp10H		;	inc high byte
m10_1:	ret	

;***** Main Routine Register Variables

.def	tbinL	=r14		;Low byte of binary result (same as mp10L)
.def	tbinH	=r15		;High byte of binary result (same as mp10H)
.def	fBCD0	=r16		;BCD value digits 1 and 0
.def	fBCD1	=r17		;BCD value digits 2 and 3
.def	fBCD2	=r18		;BCD value digit 5

;***** Code

BCD2bin16:
	andi	fBCD2,0x0f	;mask away upper nibble of fBCD2
	clr	mp10H		
	mov	mp10L,fBCD2	;mp10H:mp10L = a
	mov	adder,fBCD1
	rcall	mul10a		;mp10H:mp10L = 10a+b
	mov	adder,fBCD1
	rcall	mul10b		;mp10H:mp10L = 10(10a+b)+c
	mov	adder,fBCD0		
	rcall	mul10a		;mp10H:mp10L = 10(10(10a+b)+c)+d
	mov	adder,fBCD0
	rcall	mul10b		;mp10H:mp10L = 10(10(10(10a+b)+c)+d)+e
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
;* High registers modified:		r16, r18, ZL, ZH
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
    ldi r16, $00                ;add offset to Z pointer
    add ZL, r18
    adc ZH, r16
    lpm r18, Z                  ;load byte from table pointed to by Z
	ret

    ;Table of segment values to display digits 0 - F
    ;!!! seven values must be added - verify all values
hextable: .db $01, $4F, $12, $06, $4C, $24, $20, $0F, $00, $04, $08, $60, $31, $42, $30, $38