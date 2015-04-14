/*
 * ClockPorject.asm
 *
 *  Created: 25-3-2015 11:51:18
 *  Author: Ronald Scholten, Michaël van der Veen
 */ 

 .include "m32def.inc"					;
 
 .def hour			= r16				; Set hour   Tens to register  1
 .def minute		= r17				; Set minute Tens to register  3
 .def second		= r18				; Set second Tens to register  5
 
 .def hourAlarm		= r19				; Set hourAlarm   Tens to register  7
 .def minuteAlarm	= r20				; Set minuteAlarm Tens to register  9

 .def editLevel		= r21				; Set editLevel   to register 11
 .def sw0Counter	= r22				; Set sw0Counter  to register 12
 .def sw1Counter	= r23				; Set sw1Counter  to register 13



 .def temp			= r24				; Set temp   to register 16
 .def temp2			= r25				; Set temp2  to register 25
 .def saveSR		= r12				; Set saveSR to register 17



 .org 0x0000							;
 rjmp init								;



 .org OC1Aaddr							;
 rjmp CLOCK_CYCLE						;












;&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&;
;////////////////////////////////////////////////////////////////////////////////////////;
;-----------------------------------Initialize data--------------------------------------;
;////////////////////////////////////////////////////////////////////////////////////////;
;&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&;
 init:									;
	;******initiaze starting values*****;
	ldi hour,0xff
	ldi minute,0xff
	ldi second,0xff
	ldi hourAlarm,0xff
	ldi minuteAlarm,0xff
	ldi editLevel,0
	ldi sw0Counter,0x00
	ldi sw1Counter,0x00
	ldi temp,0x00

	
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
	clr temp ; tmp = oxff
	out DDRA, temp ; Port B is output port
					
										;
	;******initiaize stack pointer******;	=============================
	ldi temp, high(RAMEND)				;	=							=
	out SPH, temp						;	=	   load stackpointer    =
	ldi temp, low(RAMEND)				;	=							=
	out SPL, temp						;	=============================
										;
	;*initiaize output compare register*;	=============================
	ldi temp, high(21600)				;	= setting the kristal to do =
	out OCR1AH, temp					;	= an interupt every half	=
	ldi temp, low(21600)				;	= second  (1 second = 43200)=
	out OCR1AL, temp					;	=============================
										;
										;	=============================
	ldi temp, (1<<CS12) | (1 << WGM12)	;	= set prescaler to 256 &	=
	out TCCR1B, temp					;	= set timer in CTC-mode		=
										;	=============================
										;
	ldi temp,(1<<OCIE1A)				;	=============================
	out TIMSK, temp						;	=	  enable interupts		=
										;	=============================
										;
	ser temp							;	=============================
	out DDRB, temp						;	= port output, NEED_EDIT	= 
	out PORTB, temp						;	=============================
										;
	sei									;	= enable interupts			= 
										;
;=======================================;
;--------------END LABEL----------------;
;=======================================;





;#######################################;
;=======================================;
;--------------Loop label---------------;
;=======================================;
;#######################################;
										;
loop:							;
	rjmp loop							;
										;
;=======================================;
;--------------END LABEL----------------;
;=======================================;


/*TEST:
	cpi temp2, 0x00
	breq CLEAR_SCREEN
	brne SET_SCREEN
CLEAR_SCREEN:
	ldi temp, 0x81
	out UDR, temp
	rcall SEND_BYTE
	ldi temp2, 0x55
	ret
SET_SCREEN:
	ldi temp, 0x77
	rcall SEND_BYTE
	rcall SEND_BYTE
	rcall SEND_BYTE
	rcall SEND_BYTE
	rcall SEND_BYTE
	rcall SEND_BYTE
	ldi temp, 0x07
	rcall SEND_BYTE
	ldi temp2, 0x00
	ret */
SEND_BYTE:
	sbis UCSRA, UDRE
	rjmp SEND_BYTE
	out UDR, temp
	ret
;#######################################;
;=======================================;
;-------------CLOCK_CYCLE---------------;
;=======================================;
;#######################################;
										;
CLOCK_CYCLE:							;	=============================
	in saveSR, SREG						;	= Checks on every clock		=
	rcall swcheck
	rcall checkEditLevel				;	= * What Edit level its on	=
	cpi editLevel,4						;	= * Check if the clock is	=
	brsh incSeconda
	jmp CLOCK_CYCLE2
CLOCK_CYCLE2:										;	=	running.				=
	out SREG, saveSR					;	=							=	
	reti								;	=============================

incSeconda:
	rcall incSecond
	jmp CLOCK_CYCLE2										;
;=======================================;
;--------------END LABEL----------------;
;=======================================;

swcheck:
	in temp, PINA
	com temp
	cpi temp,0x00
	brne swpouched
	ldi sw0Counter,0
	ldi sw1Counter,0
	ret

	swpouched: 
		sbrc temp,PA0
		rjmp sw0pouched
		sbrc temp,PA1
		rjmp sw1pouched
		ret
		
		sw0pouched:
		inc sw0Counter
		ret

		sw1pouched:
		inc sw1Counter
		ret




;#######################################;
;=======================================;
;----------Check Edit Level-------------;
;=======================================;
;#######################################;
										;
checkEditLevel:							;	=============================
	cpi editLevel,0
	breq startupa
	cpi editLevel,1
	breq setHoura
	cpi editLevel,2
	breq setMinutea
	cpi editLevel,3
	breq setSeconda
	cpi editLevel,4
	breq setAlarmStartupa
	cpi editLevel,5
	breq setAlarmHoura
	cpi editLevel,6
	breq setAlarmMinutea
	cpi editLevel,7
	breq playNoAlarma
	cpi editLevel,8
	breq playYesAlarma
	cpi editLevel,9
	brsh playNoAlarmAgaina
	ret									;	=============================
										;
;=======================================;
;--------------END LABEL----------------;
;=======================================;


startupa:
	rcall startup
	ret
setHoura:
	rcall setHour
	ret
setMinutea:
	rcall setMinute
	ret
setSeconda:
	rcall setSecond
	ret
setAlarmStartupa:
	rcall setAlarmStartup
	ret
setAlarmHoura:
	rcall setAlarmHour
	ret
setAlarmMinutea:
	rcall setAlarmMinute
	ret
playNoAlarma:
	rcall playNoAlarm
	ret
playYesAlarma:
	rcall playYesAlarm
	ret
playNoAlarmAgaina:
	rcall playNoAlarmAgaina
	ret







;///////////////////////////////////////;
;=======================================;
;------Check Increment Edit Level-------;
;=======================================;
;///////////////////////////////////////;
checkIncEditLevel:						;
	cpi sw1Counter,3					;
	brsh incEditLevel					;
	;cpi sw0Counter,2					;
	;brsh incSW0Counter					;
	;clr sw0Counter						;XXXX
	ret									;
;=======================================;
;--------------END LABEL----------------;
;=======================================;



;///////////////////////////////////////;
;=======================================;
;---------Increment Edit Level----------;
;=======================================;
;///////////////////////////////////////;
incEditLevel:							;
	inc editLevel						;
	clr sw1Counter						;
	ret									;
										;
;=======================================;
;--------------END LABEL----------------;
;=======================================;





;///////////////////////////////////////;
;=======================================;
;--------Increment SW0  counter---------;
;=======================================;
;///////////////////////////////////////;
incSW0Counter:							;
	inc sw0Counter						;
	ret									;
										;
;=======================================;
;--------------END LABEL----------------;
;=======================================;





;///////////////////////////////////////;
;=======================================;
;----------reset SW0  counter-----------;
;=======================================;
;///////////////////////////////////////;
resetSW0Counter:						;
	clr sw0Counter						;
	ret									;
										;
;=======================================;
;--------------END LABEL----------------;
;=======================================;




;///////////////////////////////////////;
;=======================================;
;--------Increment SW1  counter---------;
;=======================================;
;///////////////////////////////////////;
incSW1Counter:							;
	inc sw1Counter						;
	ret									;
										;
;=======================================;
;--------------END LABEL----------------;
;=======================================;





;///////////////////////////////////////;
;=======================================;
;----------reset SW1  counter-----------;
;=======================================;
;///////////////////////////////////////;
resetSW1Counter:						;
	clr sw1Counter						;
	ret									;
										;
;=======================================;
;--------------END LABEL----------------;
;=======================================;




;///////////////////////////////////////;
;=======================================;
;--------------Check same---------------;
;=======================================;
;///////////////////////////////////////;
checkSame:								;
	cp hour,hourAlarm
	breq checkSame2
	ret									;
checkSame2:
	cp minute, minuteAlarm
	breq checkSame3
	ret

checkSame3:
	ldi temp,1
	ret										;
;=======================================;
;--------------END LABEL----------------;
;=======================================;









;***************************************;
;///////////////////////////////////////;
;----------increment second-------------;
;///////////////////////////////////////;
;***************************************;
incSecondTens:
	inc second
	inc second
	inc second
	inc second
	inc second
	inc second
	inc second
	inc second
	inc second
	inc second
	inc second

	cpi second,61
	brsh setZeroSecond 
	ret									;
										;
;=======================================;
;--------------END LABEL----------------;
;=======================================;


;***************************************;
;///////////////////////////////////////;
;----------Set Zero Second--------------;
;///////////////////////////////////////;
;***************************************;
setZeroSecond:
	ldi second,1
	ret	
;=======================================;
;--------------END LABEL----------------;
;=======================================;s


;***************************************;
;///////////////////////////////////////;
;----------increment second-------------;
;///////////////////////////////////////;
;***************************************;
incSecond:
	inc second
	cpi second,61
	brsh incMinuteNorm 
	ret									;
										;
;=======================================;
;--------------END LABEL----------------;
;=======================================;






;***************************************;
;///////////////////////////////////////;
;----------increment Minute-------------;
;///////////////////////////////////////;
;***************************************;
incMinute:
	inc minute
	cpi minute,61
	brsh incHourNorm 
	ret									;
										;
;=======================================;
;--------------END LABEL----------------;
;=======================================;


;***************************************;
;///////////////////////////////////////;
;-------increment Minute Norm-----------;
;///////////////////////////////////////;
;***************************************;
incMinuteNorm:
	inc minute
	ldi second,1
	cpi minute,61
	brsh incHourNorm 
	ret									;
										;
;=======================================;
;--------------END LABEL----------------;
;=======================================;


;***************************************;
;///////////////////////////////////////;
;-------increment Minute Alarm----------;
;///////////////////////////////////////;
;***************************************;
incMinuteAlarm:
	inc minuteAlarm
	cpi minuteAlarm,61
	brsh incHourAlarmNorm 
	ret									;
incHourAlarmNorm:
	ldi minuteAlarm,1
	ret									;
;=======================================;
;--------------END LABEL----------------;
;=======================================;





;***************************************;
;///////////////////////////////////////;
;----------increment Hour-------------;
;///////////////////////////////////////;
;***************************************;
incHour:
	inc hour
	cpi hour,25
	brsh incDayNorm 
	ret									;
										;
;=======================================;
;--------------END LABEL----------------;
;=======================================;


;***************************************;
;///////////////////////////////////////;
;-------increment Hour Norm-----------;
;///////////////////////////////////////;
;***************************************;
incHourNorm:
	inc hour
	ldi minute,1
	cpi hour,25
	brsh incDayNorm 
	ret									;
										;
;=======================================;
;--------------END LABEL----------------;
;=======================================;


;***************************************;
;///////////////////////////////////////;
;------increment HourAlarm Norm---------;
;///////////////////////////////////////;
;***************************************;
incHourAlarm:
	inc hourAlarm
	cpi hour,25
	brsh incDayAlarmNorm 
	ret									;
										;
;=======================================;
;--------------END LABEL----------------;
;=======================================;



;***************************************;
;///////////////////////////////////////;
;------------increment Day--------------;
;///////////////////////////////////////;
;***************************************;
incDayNorm:
	ldi hour,1
	ret
incDayAlarmNorm:
	ldi hourAlarm,1
	ret									;
										;
;=======================================;
;--------------END LABEL----------------;
;=======================================;
















;##############################################################################;
;==============================================================================;
;---------------------------------Start up-------------------------------------;
;==============================================================================;
;##############################################################################;
										;
startup:								;
	rcall startup1
	rcall startup2						;
	rcall startup3
	rcall displayNoAlarm				
	com hour							;
	com minute							;
	com second							;
	rcall checkIncEditLevel
	ret
	
displayNull2:
	call displayNull
	call displayNull
	ret
displayZero2:
	call displayZero
	call displayZero
	ret	
	
	startup1:
		cpi hour,0xff						;
		breq displayNull2					;
		brne displayZero2

	startup2:
		cpi minute,0xff						;
		breq displayNull2					;
		brne displayZero2					;
	
	startup3:
		cpi second, 0xff					;
		breq displayNull2
		brne displayZero2					;
;=======================================;
;--------------END LABEL----------------;
;=======================================;





;#######################################;
;=======================================;
;--------------Set Hour-----------------;
;=======================================;
;#######################################;
										;
setHour:
	ldi hour,2		;xxxx
	rcall setHour1
	rcall displayZero2					;
	rcall displayZero2					;
	rcall displayNoAlarm				;

	rcall checkIncEditLevel				;
	cpi	sw0Counter,1					;xxxx
	brsh incHour2						;
	;rcall resetSW0Counter				;
	ret									;
	 incHour2:
		rcall incHour
		ret

	setHour1:
		
		cpi hour,0xff					;
		breq displayNullHour2inv		;
		cpi hour,0x00					;
		breq displayZeroHour2inv		;					
		rcall displayHour				;
		ret

	displayNullHour2inv:
		com hour
		call displayNull2
		ret
	displayZeroHour2inv:
		com hour
		call displayZero2
		ret

	
;=======================================;
;--------------END LABEL----------------;
;=======================================;





;#######################################;
;=======================================;
;-------------Set Minute----------------;
;=======================================;
;#######################################;
										;
setMinute:								;
	rcall displayHour					;
	rcall setMinute1
	rcall displayZero2
	rcall displayNoAlarm
	rcall checkIncEditLevel

	cpi	sw0Counter,1					;
	brsh incMinute2						;
	rcall resetSW0Counter				;
	ret									;

	setMinute1:
		cpi minute,0xff					;
		breq displayNullMinute2inv		;
		cpi minute,0x00					;
		breq displayZeroMinute2inv		;
		rcall displayMinute				;

	incMinute2:
		rcall incMinute
		ret
	
	displayNullMinute2inv:
		com minute
		call displayZero2
		ret
	displayZeroMinute2inv:
		com minute
		call displayZero2
		ret
	
;=======================================;
;--------------END LABEL----------------;
;=======================================;





;#######################################;
;=======================================;
;-------------Set second----------------;
;=======================================;
;#######################################;
										;
setSecond:								;
	rcall displayHour					;
	rcall displayMinute
	rcall setSecond1
	rcall displayNoAlarm

	rcall checkIncEditLevel
	cpi	sw0Counter,1					;
	brsh incSecondTens2					;
	rcall resetSW0Counter				;
	ret									;

	setSecond1:
		cpi second,0xff						;
		breq displayNullSecond2inv		;
		cpi second,0x00						;
		breq displayZeroSecond2inv			;
		rcall displaySecond					;
		ret

	
	incSecondTens2:
		rcall incSecondTens
		ret

		displayNullSecond2inv:
		com second
		call displayZero2
		ret
	displayZeroSecond2inv:
		com second
		call displayZero2
		ret
;=======================================;
;--------------END LABEL----------------;
;=======================================;





;#######################################;
;=======================================;
;------------setup Alarm----------------;
;=======================================;
;#######################################;
										;
setAlarmStartup:								;
	rcall alarmSetup1
	rcall alarmSetup2
	rcall displayNull2
	rcall displayYesAlarm
	com hourAlarm							;
	com minuteAlarm							;
	rcall checkIncEditLevel
	ret
	
	
	alarmSetup1:
		cpi hourAlarm,0xff						;
		breq displayNull3					;
		brne displayZero3

	Alarmsetup2:
		cpi minuteAlarm,0xff						;
		breq displayNull3					;
		brne displayZero3					;

		displayNull3:
			call displayNull
			call displayNull
			ret
		displayZero3:
			call displayZero
			call displayZero
			ret	
	
;=======================================;
;--------------END LABEL----------------;
;=======================================;





;#######################################;
;=======================================;
;-----------Set Hour Alarm--------------;
;=======================================;
;#######################################;
										;
setAlarmHour:
	rcall setAlarmHour1
	rcall displayZero2					;
	rcall displayNull2					;
	rcall displayYesAlarm				;

	call checkIncEditLevel				;
	cpi	sw0Counter,1					;
	brsh incHourAlarm2						;
	rcall resetSW0Counter				;
	ret									;
	 incHourAlarm2:
		rcall incHourAlarm
		ret

	setAlarmHour1:
		
		cpi hourAlarm,0xff					;
		breq displayNullHourAlarm2inv		;
		cpi hourAlarm,0x00					;
		breq displayZeroHourAlarm2inv		;					
		rcall displayHourAlarm				;
		ret

	displayNullHourAlarm2inv:
		com hourAlarm
		call displayZero2
		ret
	displayZeroHourAlarm2inv:
		com hourAlarm
		call displayZero2
		ret

;=======================================;
;--------------END LABEL----------------;
;=======================================;





;#######################################;
;=======================================;
;----------Set Minute Alarm-------------;
;=======================================;
;#######################################;
										;
setAlarmMinute:								;
	rcall displayHourAlarm					;
	rcall setMinuteAlarm1
	rcall displayZero3
	rcall displayYesAlarm
	rcall checkIncEditLevel

	cpi	sw0Counter,1					;
	brsh incMinuteAlarm2						;
	rcall resetSW0Counter				;
	ret									;

	setMinuteAlarm1:
		cpi minuteAlarm,0xff					;
		breq displayNullMinuteAlarm2inv				;
		cpi minuteAlarm,0x00					;
		breq displayZeroMinuteAlarm2inv					;
		rcall displayMinuteAlarm				;

	incMinuteAlarm2:
		rcall incMinuteAlarm
		ret
	
	displayNullMinuteAlarm2inv:
		com minuteAlarm
		call displayZero2
		ret
	displayZeroMinuteAlarm2inv:
		com minuteAlarm
		call displayZero2
		ret
	
;=======================================;
;--------------END LABEL----------------;
;=======================================;






;#######################################;
;=======================================;
;------------Play No Alarm--------------;
;=======================================;
;#######################################;
										;
playNoAlarm:							;
	rjmp checkIncEditLevel				;
	cpi	sw0Counter,1					;
	brsh showAlarm						;
	brne showTime						;
	rjmp displayNoAlarm					;
	ret									;
;=======================================;
;--------------END LABEL----------------;
;=======================================;





;#######################################;
;=======================================;
;------------Play Yes Alarm--------------;
;=======================================;
;#######################################;
										;
playYesAlarm:							;
	rcall checkIncEditLevel				;
	rcall checkDisplay
	rcall checkAlarmSound
	ret

	checkDisplay:
	cpi	sw0Counter,1					;
	brsh showAlarm						;
	brne showTime
	
	checkAlarmSound:			;				;
	ldi temp,0x00						;
	call checkSame
	cpi temp,0x00
	breq displayYesAlarm2
	brne displayBuzzer2
							;
displayYesAlarm2:
	call displayYesAlarm
	ret
displayBuzzer2:
	call displayBuzzer
	ret
;=======================================;
;--------------END LABEL----------------;
;=======================================;


;#######################################;
;=======================================;
;------------Play No Alarm--------------;
;=======================================;
;#######################################;
playNoAlarmAgain:
	ldi editLevel,7
	ret
;=======================================;
;--------------END LABEL----------------;
;=======================================;




;#######################################;
;=======================================;
;--------------Show Time----------------;
;=======================================;
;#######################################;
showTime:								;
	rcall displayHour					;
	rcall displayMinute					;
	rcall displaySecond					;
	ret									;
;=======================================;
;--------------END LABEL----------------;
;=======================================;





;#######################################;
;=======================================;
;--------------Show Alarm----------------;
;=======================================;
;#######################################;
showAlarm:								;
	rcall displayHourAlarm				;
	rcall displayMinuteAlarm				;
	rcall displayNull					;
	rcall displayNull					;
	ret									;
;=======================================;
;--------------END LABEL----------------;
;=======================================;





displayNull:
	ldi temp, 0x00
	rcall SEND_BYTE
	ret
displayZero:
	ldi temp, 0x77
	rcall SEND_BYTE
	ret
displayOne:
	ldi temp, 0x24
	rcall SEND_BYTE
	ret
displayTwo:
	ldi temp, 0x5D
	rcall SEND_BYTE
	ret
displayThree:
	ldi temp, 0x6D
	rcall SEND_BYTE
	ret
displayFour:
	ldi temp, 0x2E
	rcall SEND_BYTE
	ret
displayFive:
	ldi temp, 0x6B
	rcall SEND_BYTE
	ret
displaySix:
	ldi temp, 0x7B
	rcall SEND_BYTE
	ret
displaySeven:
	ldi temp, 0x25
	rcall SEND_BYTE
	ret
displayEight:
	ldi temp, 0x7F
	rcall SEND_BYTE
	ret
displayNine:
	ldi temp, 0x6F
	rcall SEND_BYTE
	ret

displayNumber:
	cpi temp, 0x01
	breq displayZero
	
	cpi temp, 0x02
	breq displayOne

	cpi temp, 0x03
	breq displayTwo

	cpi temp, 0x04
	breq displayThree

	cpi temp, 0x05
	breq displayFour

	cpi temp, 0x06
	breq displayFive

	cpi temp, 0x07
	breq displaySix

	cpi temp, 0x08
	breq displaySeven

	cpi temp, 0x09
	breq displayEight

	cpi temp, 0x0A
	breq displayNine

	ret


displayYesAlarm:
	ldi temp, 0b00000111
	rcall SEND_BYTE
	ret
displayNoAlarm:
	ldi temp, 0b00000110
	rcall SEND_BYTE
	ret
displayNoPointer:
	ldi temp, 0b00000000
	rcall SEND_BYTE
	ret
displayBuzzer:
	ldi temp, 0b00001111
	rcall SEND_BYTE
	ret
displayNoPointerAlarm:
	ldi temp, 0b00000001
	rcall SEND_BYTE
	ret

splitByte:    ;xxxxx
	clr temp2
	jmp splitByte2

	splitByte2:
	cpi temp, 10
	brsh splitByteYes
	brlo splitByteNo

	splitByteYes:
		cpi temp,10
		brsh start_split
		brlo sendtens

	start_split:
		subi temp, 10
		inc temp2
		jmp splitByte2
	
	ret

	splitByteNo:
		rcall displayZero
		rcall displayNumber
		ret

	sendtens:
		rcall displayNumber
		mov temp, temp2
		rcall displayNumber
		ret
		

displayHour:
	mov temp, hour
	rjmp splitByte

	ret

displayMinute:
	mov temp, minute
	rjmp splitByte
	
	ret

displaySecond:
	mov temp, second
	rjmp splitByte
	
	ret

displayHourAlarm:
	mov temp, hourAlarm
	rjmp splitByte

	ret

displayMinuteAlarm:
	mov temp, minuteAlarm
	rjmp splitByte
	
	ret