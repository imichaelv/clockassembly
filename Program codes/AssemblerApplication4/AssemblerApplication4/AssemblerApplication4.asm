/*
 * ClockPorject.asm
 *
 *  Created: 25-3-2015 11:51:18
 *  Author: Ronald Scholten, Michaël van der Veen
 */ 

 .include "m32def.inc"					;
 
 .data hourT		= r1				; Set hour   Tens to register  1
 .data hourO		= r2				; Set hour   Ones to register  2
 .data minuteT		= r3				; Set minute Tens to register  3
 .data minuteO		= r4				; Set minute Ones to register  4
 .data secondT		= r5				; Set second Tens to register  5
 .data secondO		= r6				; Set second Ones to register  6
 
 .data hourAlarmT	= r7				; Set hourAlarm   Tens to register  7
 .data hourAlarmO	= r8				; Set hourAlarm   Ones to register  8
 .data minuteAlarmT	= r9				; Set minuteAlarm Tens to register  9
 .data minuteAlarmO	= r10				; Set minuteAlarm Ones to register 10

 .data editLevel	= r11				; Set editLevel   to register 11
 .data sw0Counter	= r12				; Set sw0Counter  to register 12
 .data sw1Counter	= r13				; Set sw1Counter  to register 13

 .data sw0Value		= r14				; Set switch 0 Value to register 14
 .data sw1Value		= r15				; Set switch 1 Value to register 15

 .data temp			= r16				; Set temp   to register 16
 .data saveSR		= r17				; Set saveSR to register 17



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
CLOCK_CYLCLE:							;	=============================
	in saveSR, SREG						;	= Checks on every clock		=
	call checkEditLevel					;	= * What Edit level its on  =
	call showDisplay					;	= * How the Display must	=
	out SREG, saveSR					;	=	be shown				=	
	reti								;	=============================
										;
;=======================================;
;--------------END LABEL----------------;
;=======================================;
