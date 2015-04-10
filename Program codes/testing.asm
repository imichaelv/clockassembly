.include "m32def.inc"

.def temp = r16

init:
; set the baud rate, see datahseet p.167
; F_OSC = 11.0592 MHz & baud rate = 19200
; to do a 16-bit write, the high byte must be written before the low byte !
; for a 16-bit read, the low byte must be read before the high byte !
ldi temp, high(35)
out UBRRH, temp
ldi temp, low(35) ; 19200 baud
out UBRRL, temp
; set frame format : asynchronous, parity disabled, 8 data bits, 1 stop bit
ldi temp, (1<<URSEL)|(1<<UCSZ1)|(1<<UCSZ0)
out UCSRC, temp
; enable receiver & transmitter
ldi temp, (1 << RXEN) | (1 << TXEN)
out UCSRB, temp

; init port
ser temp ; tmp = oxff
out DDRB, temp ; Port B is output port
out PORTB, temp ; LEDs uit

displayNull:
	ldi temp, 0x00
	out PORTD, temp
	ret
displayZero:
	ldi temp, 0x77
	out PORTD, temp
	ret
displayOne:
	ldi temp, 0x24
	out PORTD, temp
	ret
displayTwo:
	ldi temp, 0x5D
	out PORTD, temp
	ret
displayThree:
	ldi temp, 0x6D
	out PORTD, temp
	ret
displayFour:
	ldi temp, 0x2E
	out PORTD, temp
	ret
displayFive:
	ldi temp, 0x6B
	out PORTD, temp
	ret
displaySix:
	ldi temp, 0x7B
	out PORTD, temp
	ret
displaySeven:
	ldi temp, 0x25
	out PORTD, temp
	ret
displayEight:
	ldi temp, 0x7F
	out PORTD, temp
	ret
displayNine:
	ldi temp, 0x6F
	out PORTD, temp
	ret

displayNumber:
	cpi temp, 0x5D
	breq displayOne

	cpi temp, 0x6D
	breq displayTwo

	cpi temp, 0x2E
	breq displayThree

	cpi temp, 0x6B
	breq displayFour

	cpi temp, 0x7B
	breq displayFive

	cpi temp, 0x25
	breq displaySix

	cpi temp, 0x7F
	breq displaySeven

	cpi temp, 0x6F
	breq displayEight

	cpi temp, 0x0A
	breq displayNine

	ret


diplayYesAlarm:
	ldi temp, 0b00000111
	out PORTD, temp
displayNoAlarm:
	ldi temp, 0b00000110
	out PORTD, temp
displayNoPointer:
	ldi temp, 0b00000000
	out PORTD, temp
displayBuzzer:
	ldi temp, 0b00001111
	out PORTD, temp
displayNoPointerAlarm:
	ldi temp, 0b00000001
	out PORTD, temp

	ret

splitByte:
	cpi temp, 10
	brge start_split

	start_split:
		subi temp, 10
		inc temp2
		jmp splitBye
	
	ret

displayHour:
	mov temp, hour
	rjmp splitByte

	ret

diplayMinute:
	mov temp, minute
	rjmp splitByte
	
	ret

displaySecond:
	mov temp, second
	rjmp splitByte
	
	ret

