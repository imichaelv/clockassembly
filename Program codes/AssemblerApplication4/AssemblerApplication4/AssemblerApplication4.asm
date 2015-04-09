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

	
	// Init UART
	clr temp;
	out UBRRH, temp
	ldi temp, 35 ; 19200 baud
	out UBRRL, temp
	; set frame format : asynchronous, parity disabled, 8 data bits, 1 stop bit
	ldi temp, (1<<URSEL)|(1<<UCSZ1)|(1<<UCSZ0)
	out UCSRC, temp
	; enable receiver & transmitter
	ldi temp, (1 << RXEN) | (1 << TXEN)
	out UCSRB, temp			
					
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
loop:									;
	rjmp loop							;
										;
;=======================================;
;--------------END LABEL----------------;
;=======================================;





;#######################################;
;=======================================;
;-------------CLOCK_CYCLE---------------;
;=======================================;
;#######################################;
										;
CLOCK_CYCLE:							;	=============================
	in saveSR, SREG						;	= Checks on every clock		=
	rcall checkEditLevel				;	= * What Edit level its on	=
	cpi editLevel,4						;	= * Check if the clock is	=
	brsh incSecond						;	=	running.				=
	out SREG, saveSR					;	=							=	
	reti								;	=============================
										;
;=======================================;
;--------------END LABEL----------------;
;=======================================;





;#######################################;
;=======================================;
;----------Check Edit Level-------------;
;=======================================;
;#######################################;
										;
checkEditLevel:							;	=============================
	cpi editLevel,0
	breq startup
	cpi editLevel,1
	breq setHour
	cpi editLevel,2
	breq setMinute
	cpi editLevel,3
	breq setSecond
	cpi editLevel,4
	breq setAlarmStartup
	cpi editLevel,5
	breq setAlarmHour
	cpi editLevel,6
	breq setAlarmMinute
	cpi editLevel,7
	breq playNoAlarm
	cpi editLevel,8
	breq playYesAlarm
	cpi editLevel,9
	breq playNoAlarmAgain
	ret									;	=============================
										;
;=======================================;
;--------------END LABEL----------------;
;=======================================;










;///////////////////////////////////////;
;=======================================;
;------Check Increment Edit Level-------;
;=======================================;
;///////////////////////////////////////;
checkIncEditLevel:						;
	cpi sw1Counter,6					;
	brsh incEditLevel					;
	cpi sw1Counter,0x00					;
	breq incSW1Counter					;
	brne resetSW1Counter				;
	cpi sw0Counter,2					;
	brsh incSW0Counter					;
	breq resetSW0Counter				;
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
	inc temp							;
	ret									;
										;
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
;----------increment Hour-------------;
;///////////////////////////////////////;
;***************************************;
incHour:
	inc hour
	cpi second,25
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
;------------increment Day--------------;
;///////////////////////////////////////;
;***************************************;
incDayNorm:
	ldi hour,1
	ret									;
										;
;=======================================;
;--------------END LABEL----------------;
;=======================================;







;///////////////////////////////////////;









;##############################################################################;
;==============================================================================;
;---------------------------------Start up-------------------------------------;
;==============================================================================;
;##############################################################################;
										;
startup:								;
	cpi hour,0xff						;
	breq displayNull					;
	breq displayNull					;
	brne displayZero					;
	brne displayZero					;
	cpi minute,0xff						;
	breq displayNull					;
	breq displayNull					;
	brne displayZero					;
	brne displayZero					;
	cpi second, 0xff						;
	breq displayNull					;
	breq displayNull					;
	brne displayZero					;
	brne displayZero					;
	rjmp displayNoAlarm					; NEED_Edit
	com hour							;
	com minute							;
	com second							;
	rjmp checkIncEditLevel				;
	ret									;
;=======================================;
;--------------END LABEL----------------;
;=======================================;





;#######################################;
;=======================================;
;--------------Set Hour-----------------;
;=======================================;
;#######################################;
										;
setHour:								;
	cpi hour,0xff						;
	breq displayNull					;
	breq displayNull
	cpi hour,0x00						;
	breq displayZero					;
	breq displayZero					;
	brne displayHour					;

	rjmp displayZero					; Tens Minute
	rjmp displayZero					; Ones Minute
	rjmp displayZero					; Tens Second
	rjmp displayZero					; Ones Second
	rjmp DisplayNoAlarm					; DisplayDotsAndNoAlarm
	rjmp checkIncEditLevel				;
	cpi	sw0Counter,1					;
	brsh incHour						;
	brne resetSW0Counter				;
	ret									;
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
	rjmp displayHour					;

	cpi minute,0xff						;
	breq displayNull					;
	breq displayNull
	cpi minute,0x00						;
	breq displayZero					;
	breq displayZero					;
	brne displayMinute					;

	rjmp displayZero					; Tens Second
	rjmp displayZero					; Ones Second
	rjmp DisplayNoAlarm					; DisplayDotsAndNoAlarm
	rjmp checkIncEditLevel				;
	cpi	sw0Counter,1					;
	brsh incMinute						;
	brne resetSW0Counter				;
	ret									;
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
	rjmp displayHour					;
	rjmp displayMinute
	cpi second,0xff						;
	breq displayNull					;
	breq displayNull
	cpi second,0x00						;
	breq displayZero					;
	breq displayZero					;
	brne displaySecond					;

	rjmp DisplayNoAlarm					; DisplayDotsAndNoAlarm
	rjmp checkIncEditLevel				;
	cpi	sw0Counter,1					;
	brsh incSecondTens					;
	brne resetSW0Counter				;
	ret									;
;=======================================;
;--------------END LABEL----------------;
;=======================================;





;#######################################;
;=======================================;
;------------setup Alarm----------------;
;=======================================;
;#######################################;
										;
setAlarmStartup:						;
	cpi hour,0xff						;
	breq displayNull					;
	breq displayNull					;
	brne displayZero					;
	brne displayZero					;
	cpi minute,0xff						;
	breq displayNull					;
	breq displayNull					;
	brne displayZero					;
	brne displayZero					;
										;
	rjmp displayNull					;
	rjmp displayNull					;
										;
	rjmp displayYesAlarm				; 
	com hourAlarm						;
	com minuteAlarm						;
	rjmp checkIncEditLevel				;
	ret									;
;=======================================;
;--------------END LABEL----------------;
;=======================================;





;#######################################;
;=======================================;
;-----------Set Hour Alarm--------------;
;=======================================;
;#######################################;
										;
setAlarmHour:							;
	cpi hourAlarm,0xff					;
	breq displayNull					;
	breq displayNull
	cpi hourAlarm,0x00					;
	breq displayZero					;
	breq displayZero					;
	brne displayHourAlarm				;

	rjmp displayZero					; Tens Minute
	rjmp displayZero					; Ones Minute
	rjmp displayNull					; Tens Second
	rjmp displayNull					; Ones Second
	rjmp DisplayYesAlarm				; DisplayDotsAndNoAlarm
	rjmp checkIncEditLevel				;
	cpi	sw0Counter,1					;
	brsh incHourAlarm					;
	brne resetSW0Counter				;
	ret									;
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
	rjmp displayHourAlarm				;

	cpi minute,0xff						;
	breq displayNull					;
	breq displayNull
	cpi minute,0x00						;
	breq displayZero					;
	breq displayZero					;
	brne displayMinute					;

	rjmp displayZero					; Tens Second
	rjmp displayZero					; Ones Second
	rjmp DisplayYesAlarm				; DisplayDotsAndNoAlarm
	rjmp checkIncEditLevel				;
	cpi	sw0Counter,1					;
	brsh incMinuteAlarm					;
	brne resetSW0Counter				;
	ret									;
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
	rjmp checkIncEditLevel				;
	cpi	sw0Counter,1					;
	brsh showAlarm						;
	brne showTime						;				;
	ldi temp,0x00						;
	cp alarmHour,hour					;
	breq checkSame						;
	cp alarmMinute,minute				;
	breq checkSame						;
	cpi temp,0x02						;
	breq playAlarm						;
	brne displayYesAlarm				;
	ret									;
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
	rjmp displayHour					;
	rjmp displayMinute					;
	rjmp displaySecond					;
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
	rjmp displayHourAlarm				;
	rjmp displayMinuteAlarm				;
	rjmp displayNull					;
	rjmp displayNull					;
	ret									;
;=======================================;
;--------------END LABEL----------------;
;=======================================;

