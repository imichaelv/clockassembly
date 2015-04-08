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

 .def sw0Value		= r25				; Set switch 0 Value to register 14
 .def sw1Value		= r11				; Set switch 1 Value to register 15

 .def temp			= r24				; Set temp   to register 16
 .def saveSR		= r12				; Set saveSR to register 17



 .org 0x0000							;
 rjmp init								;



 .org OC1Aaddr							;
 rjmp CLOCK_CYCLE						;


;#######################################;
;=======================================;
;-----------Initialize data-------------;
;=======================================;
;#######################################;
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
	ld sw0Value,temp
	ld sw1Value,temp
				
					
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
	rcall showDisplay					;	= * How the Display must	=
	out SREG, saveSR					;	=	be shown				=	
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



