;
; table_lookup_seg_check.asm
;
; Created: 10/20/2020 7:48:20 PM
; Author : hp
;

.nolist
.include "m4809def.inc"
.list

start:
	ldi r16, $00
	ldi r17, $FF
	out VPORTA_DIR, r16
	out VPORTD_DIR, r17
	sbi VPORTC_DIR, 4
	cbi VPORTC_OUT, 4

main_loop:
	in r16, VPORTA_IN
	out VPORTD_OUT, r17
	ldi r17, $00
	ldi r18, $08

reverse_bits:
	ror r16
	rol r17
	dec r18
	brne reverse_bits

check_r17:
	nop

hex_to_7seg:
	andi r17, 0x0F				;clear ms nibble
    ldi ZH, HIGH(hextable * 2)  ;set Z to point to start of table
    ldi ZL, LOW(hextable * 2)
    ldi r16, $00                ;add offset to Z pointer
    add ZL, r17
    adc ZH, r16
    lpm r17, Z                  ;load byte from table pointed to by Z
	rjmp main_loop

    ;Table of segment values to display digits 0 - F
    ;!!! seven values must be added - verify all values
hextable: .db $01, $4F, $12, $06, $4C, $24, $20, $0F, $00, $04, $08, $60, $31, $42, $30, $38