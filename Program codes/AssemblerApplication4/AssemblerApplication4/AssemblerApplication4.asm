/*
                                                           
                                                           
     000000000          000000000             CCCCCCCCCCCCClllllll                                      kkkkkkkk    
   00:::::::::00      00:::::::::00        CCC::::::::::::Cl	 l                                      k	   k
 00:::::::::::::00  00:::::::::::::00    CC:::::::::::::::Cl	 l                                      k	   k 
0:::::::000:::::::00:::::::000:::::::0  C:::::CCCCCCCC::::Cl	 l                                      k	   k     
0::::::0   0::::::00::::::0   0::::::0 C:::::C       CCCCCC l	 l    ooooooooooo       cccccccccccccccc k	   k    kkkkkkk
0:::::0     0:::::00:::::0     0:::::0C:::::C               l	 l  oo			 oo   cc			   c k	   k   k	 k
0:::::0     0:::::00:::::0     0:::::0C:::::C               l	 l o			   o c				   c k	   k  k		k
0:::::0 000 0:::::00:::::0 000 0:::::0C:::::C               l    l o     ooooo     oc       cccccc     c k     k k     k
0:::::0 000 0:::::00:::::0 000 0:::::0C:::::C               l    l o    o     o    oc      c     ccccccc k      k     k 
0:::::0     0:::::00:::::0     0:::::0C:::::C               l    l o    o     o    oc     c              k           k 
0:::::0     0:::::00:::::0     0:::::0C:::::C               l    l o    o     o    oc     c              k           k
0::::::0   0::::::00::::::0   0::::::0 C:::::C       CCCCCC l    l o    o     o    oc      c     ccccccc k      k     k 
0:::::::000:::::::00:::::::000:::::::0  C:::::CCCCCCCC::::Cl      lo     ooooo     oc       cccccc     ck      k k     k 
 00:::::::::::::00  00:::::::::::::00    CC:::::::::::::::Cl      lo               o c                 ck      k  k     k
   00:::::::::00      00:::::::::00        CCC::::::::::::Cl      l oo           oo   cc               ck      k   k     k
     000000000          000000000             CCCCCCCCCCCCCllllllll   ooooooooooo       cccccccccccccccckkkkkkkk    kkkkkkk



 * ClockPorject.asm
 *
 * Project: 00C(lock)
 *
 *  Created: 25-3-2015 11:51:18
 *  Author: Ronald Scholten, Michaël van der Veen
 */ 

;&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&;
;///////////////////////////////////////////////////////////////////////////////////////////;
;----------------------------------------Directives-----------------------------------------;
;///////////////////////////////////////////////////////////////////////////////////////////;
;&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&;
																							;
 .include "m32def.inc"																		;
																							;
 .def hour			= r16																	; <- Set hour   Tens		to register  16
 .def minute		= r17																	; <- Set minute Tens		to register  17
 .def second		= r18																	; <- Set second Tens		to register  18
 																							;
 .def hourAlarm		= r19																	; <- Set hourAlarm   Tens	to register  19
 .def minuteAlarm	= r20																	; <- Set minuteAlarm Tens	to register  20
																							;
 .def editLevel		= r21																	; <- Set editLevel			to register 21
 .def sw0Counter	= r22																	; <- Set sw0Counter			to register 22
 .def sw1Counter	= r23																	; <- Set sw1Counter			to register 23
																							;
 .def temp			= r24																	; <- Set temp				to register 24
 .def temp2			= r25																	; <- Set temp2				to register 25
 .def saveSR		= r12																	; <- Set saveSR				to register 12
 .def halfSecond	= r26																	; <- Set HalfSecond			to register 26
 																							;
 .org 0x0000																				; <- On reset go to program row 0x0000
 rjmp init																					; <- Relative jump to init
 																							;
 .org OC1Aaddr																				; <- On interupt go to next line
 rjmp CLOCK_CYCLE																			; <- Relative jump to CLOCK_CYCLE
;===========================================================================================;
;----------------------------------------END LABEL------------------------------------------;
;===========================================================================================;





;&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&;
;///////////////////////////////////////////////////////////////////////////////////////////;
;------------------------------------Initialize data----------------------------------------;
;///////////////////////////////////////////////////////////////////////////////////////////;
;&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&;
 init:																						;
	;******initiaze starting values*****;													;	=========================================
	ldi hour,0xff																			;	= Initialize the registers with values	=
	ldi minute,0xff																			;	=										=
	ldi second,0xff																			;	= hour,minute,second,hourAlarm,			=
	ldi hourAlarm,0xff																		;	= minuteAlarm and halfSecond will 		=
	ldi minuteAlarm,0xff																	;	= be set to 0xff						=
	ldi editLevel,0																			;	= editLevel will be set to 0			=
	ldi sw0Counter,0x00																		;	=										=
	ldi sw1Counter,0x00																		;	= sw0Counter, sw1Counter and temp will 	=
	ldi temp,0x00																			;	= be set to 0x00						=
	ldi halfSecond,0xff																		;	=========================================	
																							;	
	; set the baud rate, see datahseet p.167												;	
	; F_OSC = 11.0592 MHz & baud rate = 19200												;
	; to do a 16-bit write, the high byte must be written before the low byte !				;
	; for a 16-bit read, the low byte must be read before the high byte !					;
	ldi temp, high(35)																		;
	out UBRRH, temp																			;
	ldi temp, low(35) ; 19200 baud															;
	out UBRRL, temp																			;
	; set frame format : asynchronous, parity disabled, 8 data bits, 1 stop bit				;
	ldi temp, (1<<URSEL)|(1<<UCSZ1)|(1<<UCSZ0)												;
	out UCSRC, temp																			;
	; enable receiver & transmitter															;
	ldi temp, (1 << RXEN) | (1 << TXEN)														;
	out UCSRB, temp																			;
																							;
	; init port																				;
	clr temp ; tmp = oxff																	;
	out DDRA, temp ; Port B is output port													;
																							;
																							;
	;******initiaize stack pointer******													;	=============================
	ldi temp, high(RAMEND)																	;	=							=
	out SPH, temp																			;	=	   load stackpointer    =
	ldi temp, low(RAMEND)																	;	=							=
	out SPL, temp																			;	=============================
																							;
	;*initiaize output compare register*													;	=============================
	ldi temp, high(21600)																	;	= setting the kristal to do =
	out OCR1AH, temp																		;	= an interupt every half	=
	ldi temp, low(21600)																	;	= second  (1 second = 43200)=
	out OCR1AL, temp																		;	=============================
																							;
																							;	=============================
	ldi temp, (1<<CS12) | (1 << WGM12)														;	= set prescaler to 256 &	=
	out TCCR1B, temp																		;	= set timer in CTC-mode		=
																							;	=============================
																							;
	ldi temp,(1<<OCIE1A)																	;	=============================
	out TIMSK, temp																			;	=	  enable interupts		=
																							;	=============================
																							;
	ser temp																				;	=============================
	out DDRB, temp																			;	= port output, NEED_EDIT	= 
	out PORTB, temp																			;	=============================
																							;
	sei																						; <- enable interupts
																							;
;===========================================================================================;
;--------------------------------------------END LABEL--------------------------------------;
;===========================================================================================;





;#######################################;
;=======================================;
;--------------Loop label---------------;
;=======================================;
;#######################################;
										;	=====================
loop:									;	=					=
	rjmp loop							;	=    infinite loop	=
										;	=					=
;=======================================;	=====================
;--------------END LABEL----------------;
;=======================================;





;###########################################################################################;
;===========================================================================================;
;----------------------------------CLOCK_CYCLE----------------------------------------------;
;===========================================================================================;
;###########################################################################################;
																							;
CLOCK_CYCLE:																				;	=============================
	in saveSR, SREG																			;	= Checks on every clock		=
	com halfSecond																			;	= * invert halfSecond		=
	rcall swcheck																			;	= * check if buttons are	=
	rcall checkEditLevel																	;	= 	pouched					=
	cpi editLevel,4																			;	= * What Edit level its on	=
	brsh incSeconda																			;	= * Check if the clock is	=
	jmp CLOCK_CYCLE2																		;	= * running.				=
CLOCK_CYCLE2:																				;	= * check if the seconds may=
	out SREG, saveSR																		;	=	increment				=	
	reti																					;	=============================
																							;
incSeconda:																					;	=============================
	cpi halfSecond,0xff																		;	= on every second, increment=
	breq incSecondB																			;	= the seconds				=
	rjmp CLOCK_CYCLE2																		;	=============================
																							;
	incSecondB:																				;
		rcall incSecond																		;
		jmp CLOCK_CYCLE2																	;
;===========================================================================================;
;----------------------------------------END LABEL------------------------------------------;
;===========================================================================================;



;#######################################;
;=======================================;
;---------Check button Puched-----------;
;=======================================;
;#######################################;
										;
swcheck:								;	=================================
	in temp, PINA						;	=	Check if one of the buttons =
	com temp							;	= is pouched into.				=
	cpi temp,0x00						;	= If a button is pouched, the	= 
	brne swpouched						;	= program will compair the		=
	ldi sw0Counter,0					;	= results that are made and		=
	ldi sw1Counter,0					;	= will increment the one that	= 
	ret									;	= is pouched into.				=
										;	= the one that isnt pouched		=
	swpouched: 							;	= into will be set to 0.		=
		sbrc temp,PA0					;	=================================
		rjmp sw0pouched					;
		sbrc temp,PA1					;
		rjmp sw1pouched					;
		ret								;
										;
		sw0pouched:						;
		inc sw0Counter					;
		ret								;
										;
		sw1pouched:						;
		inc sw1Counter					;
		ret								;
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
	cpi editLevel,0						;	= Check on what level the	=
	breq startupa						;	= Program is.				=
	cpi editLevel,1						;	= For every level, there is =
	breq setHoura						;	= an lable to run the		=
	cpi editLevel,2						;	= program.					=
	breq setMinutea						;	=============================
	cpi editLevel,3						;
	breq setSeconda						;
	cpi editLevel,4						;
	breq setAlarmStartupa				;
	cpi editLevel,5						;
	breq setAlarmHoura					;
	cpi editLevel,6						;
	breq setAlarmMinutea				;
	cpi editLevel,7						;
	breq playNoAlarma					;
	cpi editLevel,8						;
	breq playYesAlarma					;
	cpi editLevel,9						;
	brsh playNoAlarmAgaina				;
	ret									;	
										;
startupa:								;
	rcall startup						;
	ret									;
setHoura:								;
	rcall setHour						;
	ret									;
setMinutea:								;
	rcall setMinute						;
	ret									;
setSeconda:								;
	rcall setSecond						;
	ret									;
setAlarmStartupa:						;
	rcall setAlarmStartup				;
	ret									;
setAlarmHoura:							;
	rcall setAlarmHour					;
	ret									;
setAlarmMinutea:						;
	rcall setAlarmMinute				;
	ret									;
playNoAlarma:							;
	rcall playNoAlarm					;
	ret									;
playYesAlarma:							;
	rcall playYesAlarm					;
	ret									;
playNoAlarmAgaina:						;
	rcall playNoAlarmAgain				;
	ret									;
										;
;=======================================;
;--------------END LABEL----------------;
;=======================================;






;///////////////////////////////////////;
;=======================================;
;------Check Increment Edit Level-------;
;=======================================;
;///////////////////////////////////////;
checkIncEditLevel:						;	=============================
	cpi sw1Counter,2					;	= Check if the editLevel	=
	breq incEditLevel					;	= needs to be incremented	=
	ret									;	=============================
;=======================================;
;--------------END LABEL----------------;
;=======================================;



;///////////////////////////////////////;
;=======================================;
;---------Increment Edit Level----------;
;=======================================;
;///////////////////////////////////////;
incEditLevel:							;	=============================
	inc editLevel						;	= Increments the editlevel	=
	ret									;	=============================
										;
;=======================================;
;--------------END LABEL----------------;
;=======================================;





;///////////////////////////////////////;
;=======================================;
;--------Increment SW0  counter---------;
;=======================================;
;///////////////////////////////////////;
incSW0Counter:							;	=============================
	inc sw0Counter						;	= Increments the sw0Counter =
	ret									;	=============================
										;
;=======================================;
;--------------END LABEL----------------;
;=======================================;





;///////////////////////////////////////;
;=======================================;
;----------reset SW0  counter-----------;
;=======================================;
;///////////////////////////////////////;
resetSW0Counter:						;	=============================
	clr sw0Counter						;	= Reset the sw0Counter		=
	ret									;	=============================
										;
;=======================================;
;--------------END LABEL----------------;
;=======================================;




;///////////////////////////////////////;
;=======================================;
;--------Increment SW1  counter---------;
;=======================================;
;///////////////////////////////////////;
incSW1Counter:							;	=============================
	inc sw1Counter						;	= Increment the sw1Counter	=
	ret									;	=============================
										;
;=======================================;
;--------------END LABEL----------------;
;=======================================;





;///////////////////////////////////////;
;=======================================;
;----------reset SW1  counter-----------;
;=======================================;
;///////////////////////////////////////;
resetSW1Counter:						;	=============================
	clr sw1Counter						;	= Reset the sw1Counter		=
	ret									;	=============================
										;
;=======================================;
;--------------END LABEL----------------;
;=======================================;




;///////////////////////////////////////;
;=======================================;
;--------------Check same---------------;
;=======================================;
;///////////////////////////////////////;
checkSame:								;	=============================
	cp hour,hourAlarm					;	= check if the time is		=
	breq checkSame2						;	= equal to the alarm time	=
	ret									;	=							=
checkSame2:								;	= If the hours are same		=
	cp minute, minuteAlarm				;	= the program will check	=
	breq checkSame3						;	= the minutes				=
	ret									;	=							=
										;	= if both are the same, the	=
checkSame3:								;	= temp register would be	=
	ldi temp,1							;	= set to 1, as for its true	=
	ret									;	=============================
;=======================================;
;--------------END LABEL----------------;
;=======================================;









;*******************************************************************************************;
;///////////////////////////////////////////////////////////////////////////////////////////;
;-----------------------------------increment ten second------------------------------------;
;///////////////////////////////////////////////////////////////////////////////////////////;
;*******************************************************************************************;
incSecondTens:																				;	=============================
	cpi second,0xff																			;	= Increment the seconds with=
	breq setZeroSecond																		;	= steps of 10				=
	inc second																				;	=============================
	inc second																				;
	inc second																				;
	inc second																				;
	inc second																				;
	inc second																				;
	inc second																				;
	inc second																				;
	inc second																				;
	inc second																				;
																							;
	cpi second,61																			;
	brsh setZeroSecond 																		;
	ret																						;
																							;
;===========================================================================================;
;---------------------------------------END LABEL-------------------------------------------;
;===========================================================================================;


;***************************************;
;///////////////////////////////////////;
;----------Set Zero Second--------------;
;///////////////////////////////////////;
;***************************************;
setZeroSecond:							;	=============================
	ldi second,1						;	= set the seconds back to 0	=
	ret									;	=============================
;=======================================;
;--------------END LABEL----------------;
;=======================================;


;***************************************;
;///////////////////////////////////////;
;----------increment second-------------;
;///////////////////////////////////////;
;***************************************;
incSecond:								;	=============================
	inc second							;	= increments the second		=
	cpi second,61						;	= if the seconds are higher	=
	brsh incMinuteNorm					;	= than register value 61	=
	ret									;	= then the program would	=
										;	= increment the minute		=
;=======================================;	=============================
;--------------END LABEL----------------;
;=======================================;






;***************************************;
;///////////////////////////////////////;
;----------increment Minute-------------;
;///////////////////////////////////////;
;***************************************;
incMinute:								;	=============================
	cpi minute,0xff						;	= increments the minute		=
	breq incHourSetting					;	= if the minutes are higher	=
	inc minute							;	= than register value 61	=
	cpi minute,61						;	= than the program would	=
	brsh incHourSetting 				;	= set the minute back to 	=
	ret									;	= register value 1			=
										;	=							=
	incHourSetting:						;	=============================
		ldi minute,1					;
		ret								;
;=======================================;
;--------------END LABEL----------------;
;=======================================;


;***************************************;
;///////////////////////////////////////;
;-------increment Minute Norm-----------;
;///////////////////////////////////////;
;***************************************;	=============================
incMinuteNorm:							;	= reset the seconds to 1 and=
	inc minute							;	= increments the minute		=
	ldi second,1						;	= if the minutes are higher =
	cpi minute,61						;	= than register value 61	=
	brsh incHourNorm 					;	= than the program would	=
	ret									;	= increment the hour		=
										;	=============================
;=======================================;
;--------------END LABEL----------------;
;=======================================;


;***************************************;
;///////////////////////////////////////;
;-------increment Minute Alarm----------;
;///////////////////////////////////////;
;***************************************;
incMinuteAlarm:							;	=============================
	cpi minuteAlarm,0xff				;	= increment the minutes of	=
	breq incHourAlarmNorm				;	= the alarm.				=
	inc minuteAlarm						;	= if the register value is  =
	cpi minuteAlarm,61					;	= same or higher than 61	=
	brsh incHourAlarmNorm 				;	= then the value resets to 1=
	ret									;	=============================
incHourAlarmNorm:						;
	ldi minuteAlarm,1					;
	ret									;
;=======================================;
;--------------END LABEL----------------;
;=======================================;





;***************************************;
;///////////////////////////////////////;
;-----------increment Hour--------------;
;///////////////////////////////////////;
;***************************************;
incHour:								;	=============================
	cpi hour,0xff						;	= increments the hour		=
	breq incDayNorm						;	= if the hour register is	=
	inc hour							;	= same or higher than 25	=
	cpi hour,25							;	= then the program reset to	=
	brsh incDayNorm						;	= register value 1			=
	ret									;	=============================
										;
;=======================================;
;--------------END LABEL----------------;
;=======================================;


;***************************************;
;///////////////////////////////////////;
;--------increment Hour Norm------------;
;///////////////////////////////////////;
;***************************************;
incHourNorm:							;	=============================
	inc hour							;	= increment the hour and	=
	ldi minute,1						;	= reset the minutes to value=
	cpi hour,25							;	= one.						=
	brsh incDayNorm 					;	= if the hour is same or	=
	ret									;	= greater than 25, reset the=
										;	= hours back to 1.			=
;=======================================;	=============================
;--------------END LABEL----------------;
;=======================================;


;***************************************;
;///////////////////////////////////////;
;------increment HourAlarm Norm---------;
;///////////////////////////////////////;
;***************************************;
incHourAlarm:							;	=============================
	cpi hourAlarm,0xff					;	= increment the hour alarm	=
	breq incDayAlarmNorm				;	= and if its same or greater=
	inc hourAlarm						;	= than 25, reset the value	=
	cpi hourAlarm,25					;	= back to 1.				=
	brsh incDayAlarmNorm 				;	=============================
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
incDayNorm:								;	=============================
	ldi hour,1							;	= reset the hour back to 1	=
	ret									;	=							=
incDayAlarmNorm:						;	=							=
	ldi hourAlarm,1						;	= reset the hour alarm to 1	=
	ret									;	=============================
										;
;=======================================;
;--------------END LABEL----------------;
;=======================================;





;###############################################################################;
;===============================================================================;
;----------------------------------Start up-------------------------------------;
;===============================================================================;
;###############################################################################;
																				;
startup:																		;	=============================
	rcall startup1																;	= Makes the hour,minute,	=
	rcall startup2																;	= seconds blink every half	=
	rcall startup3																;	= second.					=
	rcall displayNoAlarm														;	=============================
	com hour																	; 
	com minute																	;
	com second																	;
	rcall checkIncEditLevel														;
	ret																			;
																				;
displayNull2:																	; <- display two times nothing
	call displayNull															;
	call displayNull															;
	ret																			;
displayZero2:																	; <- display two times a Zero
	call displayZero															;
	call displayZero															;
	ret																			;
																				;
	startup1:																	;
		cpi hour,0xff															;
		breq displayNull2														;
		brne displayZero2														;
																				;
	startup2:																	;
		cpi minute,0xff															;
		breq displayNull2														;
		brne displayZero2														;
																				;
	startup3:																	;
		cpi second, 0xff														;
		breq displayNull2														;
		brne displayZero2														;
;===============================================================================;
;------------------------------------END LABEL----------------------------------;
;===============================================================================;





;#######################################;
;=======================================;
;--------------Set Hour-----------------;
;=======================================;
;#######################################;
										;
setHour:								;	=============================
	rcall checkIncEditLevel				;	= blinks the hour* ones		= 
	rcall updateHour					;	= every half second when	=
	rcall setHour1						;	= there are no buttons		=
										;	= pouched.					=
	rcall displayZero2					;	= when sw0Counter is higher	=
	rcall displayZero2					;	= than 2, then the hour*	=
	rcall displayNoAlarm				;	= would increment.			=
	ret									;	=============================
										;
	updateHour:							;
	cpi	sw0Counter,2					;
	brsh incHour2						;
	cpi editLevel,2						;
	breq checkNullHour					;
	ret									;
	 incHour2:							;
		rcall incHour					;
		ret								;
										;
	setHour1:							;
										;
		cpi hour,0xff					;
		breq displayNullHour2inv		;
		cpi hour,0x00					;
		breq displayZeroHour2inv		;
		cpi halfSecond,0x00				;
		breq checkBlinkHour				;
										;
		rcall displayHour				;
		ret								;
										;
		checkBlinkHour:					;
			sbrc temp,PA0				;
			rjmp displayHour			;
			rcall displayNull2			;
			ret							;
										;
	displayNullHour2inv:				;
		com hour						;
		call displayNull2				;
		ret								;
	displayZeroHour2inv:				;
		com hour						;
		call displayZero2				;
		ret								;
										;
		checkNullHour:					;
			cpi hour,0x00				;
			breq setHourNull			;
			cpi hour,0xff				;
			breq setHourNull			;
			ret							;
										;
		setHourNull:					;
			ldi hour,1					;
										;
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
	rcall checkIncEditLevel				;
	rcall updateMinute					;
	rcall displayHour					;
	rcall setMinute1					;
	rcall displayZero2					;
	rcall displayNoAlarm
	ret
	
	updateMinute:
	cpi	sw0Counter,2					;
	brsh incMinute2						;
	cpi editLevel,3
	breq checkNullMinute
	ret									;

	setMinute1:
		cpi minute,0xff					;
		breq displayNullMinute2inv		;
		cpi minute,0x00					;
		breq displayZeroMinute2inv		;
		cpi halfSecond, 0xff
		breq checkBlinkMinute
		rcall displayMinute				;
		ret

		checkBlinkMinute:
			sbrc temp,PA0
			rjmp displayMinute
			rcall displayNull2
			ret

	incMinute2:
		rcall incMinute
		ret
	
	displayNullMinute2inv:
		com minute
		call displayNull2
		ret
	displayZeroMinute2inv:
		com minute
		call displayZero2
		ret

		checkNullMinute:
			cpi minute,0x00
			breq setMinuteNull
			cpi minute,0xff
			breq setMinuteNull
			ret

		setMinuteNull:
			ldi Minute,1
	
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
	rcall checkIncEditLevel				;
	rcall updateSecond					;
	rcall displayHour					;
	rcall displayMinute					;
	rcall setSecond1					;
	rcall displayNoAlarm				;
	ret									;
										;
	updateSecond:						;
	cpi	sw0Counter,2					;
	brsh incSecondTens2					;
	cpi editLevel,4						;
	breq checkNullSecond				;
	ret									;
										;
	setSecond1:							;
		cpi second,0xff					;
		breq displayNullSecond2inv		;
		cpi second,0x00					;
		breq displayZeroSecond2inv		;
		cpi halfSecond,0xff				;
		breq checkBlinkSecond			;
		rcall displaySecond				;
		ret								;
										;
		checkBlinkSecond:				;
			sbrc temp,PA0				;
			rjmp displaySecond			;
			rcall displayNull2			;
			ret							;
										;
	incSecondTens2:						;
		rcall incSecondTens				;
		ret								;
										;
		displayNullSecond2inv:			;
		com second						;
		call displayNull2				;
		ret								;
	displayZeroSecond2inv:				;
		com second						;
		call displayZero2				;
		ret								;
										;
		checkNullSecond:				;
			cpi second,0x00				;
			breq setSecondNull			;
			cpi second,0xff				;
			breq setSecondNull			;
			ret							;
										;
		setSecondNull:					;
			ldi second,1				;
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
	rcall alarmSetup1
	rcall alarmSetup2
	rcall displayNull2
	rcall displaySetAlarm
	com hourAlarm						;
	com minuteAlarm						;
	rcall checkIncEditLevel
	ret
	
	
	alarmSetup1:
		cpi hourAlarm,0xff				;
		breq displayNull3				;
		brne displayZero3

	Alarmsetup2:
		cpi minuteAlarm,0xff			;
		breq displayNull3				;
		brne displayZero3				;

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
	rcall checkIncEditLevel
	rcall updateAlarmHour
	rcall setAlarmHour1
	rcall displayZero2					;
	rcall displayNull2					;
	rcall displaySetAlarm				;
	ret
		
	updateAlarmHour:			;
	cpi	sw0Counter,2					;
	brsh incHourAlarm2						;
	cpi editLevel,6
	breq checkNullAlarmHour
	ret									;
	 incHourAlarm2:
		rcall incHourAlarm
		ret

		checkBlinkAlarmHour:
			sbrc temp,PA0
			rjmp displayHourAlarm
			rcall displayNull2
			ret

	setAlarmHour1:
		
		cpi hourAlarm,0xff					;
		breq displayNullHourAlarm2inv		;
		cpi hourAlarm,0x00					;
		breq displayZeroHourAlarm2inv		;	
		cpi halfSecond,0xff
		breq checkBlinkAlarmHour				
		rcall displayHourAlarm				;
		ret

	displayNullHourAlarm2inv:
		com hourAlarm
		call displayNull2
		ret
	displayZeroHourAlarm2inv:
		com hourAlarm
		call displayZero2
		ret

		checkNullAlarmHour:
			cpi hourAlarm,0x00
			breq setHourAlarmNull
			cpi hourAlarm,0xff
			breq setHourAlarmNull
			ret

		setHourAlarmNull:
			ldi hourAlarm,1
;=======================================;
;--------------END LABEL----------------;
;=======================================;





;#######################################;
;=======================================;
;----------Set Minute Alarm-------------;
;=======================================;
;#######################################;
										;
setAlarmMinute:							;
	rcall checkIncEditLevel
	rcall updateAlarmMinute
	rcall displayHourAlarm				;
	rcall setMinuteAlarm1
	rcall displayNull2
	rcall displaySetAlarm
	ret

	updateAlarmMinute:
	cpi	sw0Counter,1					;
	brsh incMinuteAlarm2						;
	cpi editLevel,7
	breq checkNullAlarmMinute				;
	ret									;

	setMinuteAlarm1:
		cpi minuteAlarm,0xff					;
		breq displayNullMinuteAlarm2inv				;
		cpi minuteAlarm,0x00					;
		breq displayZeroMinuteAlarm2inv					;
		cpi halfSecond,0xff
		breq checkBlinkAlarmMinute
		rcall displayMinuteAlarm				;
		ret

		checkBlinkAlarmMinute:
			sbrc temp,PA0
			rjmp displayMinuteAlarm
			rcall displayNull2
			ret

	incMinuteAlarm2:
		rcall incMinuteAlarm
		ret
	
	displayNullMinuteAlarm2inv:
		com minuteAlarm
		call displayNull2
		ret
	displayZeroMinuteAlarm2inv:
		com minuteAlarm
		call displayZero2
		ret

		checkNullAlarmMinute:
			cpi minuteAlarm,0x00
			breq setminuteAlarmNull
			cpi minuteAlarm,0xff
			breq setminuteAlarmNull
			ret

		setminuteAlarmNull:
			ldi minuteAlarm,1
	
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
	rcall checkIncEditLevel				;
	cpi	sw0Counter,1					;
	brsh showAlarm2						;
	brne showTime2						;

	showAlarm2:
		rcall showAlarm
		rjmp playNoAlarm2

	showTime2:
		rcall showTime
		rjmp playNoAlarm2
	playNoAlarm2:
	rcall displayNoAlarm				;
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
	rcall playNoAlarm
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
	ldi temp2, 0x00
	rcall SEND_BYTE
	ret
displayZero:
	ldi temp2, 0x77
	rcall SEND_BYTE
	ret
displayOne:
	ldi temp2, 0x24
	rcall SEND_BYTE
	ret
displayTwo:
	ldi temp2, 0x5D
	rcall SEND_BYTE
	ret
displayThree:
	ldi temp2, 0x6D
	rcall SEND_BYTE
	ret
displayFour:
	ldi temp2, 0x2E
	rcall SEND_BYTE
	ret
displayFive:
	ldi temp2, 0x6B
	rcall SEND_BYTE
	ret
displaySix:
	ldi temp2, 0x7B
	rcall SEND_BYTE
	ret
displaySeven:
	ldi temp2, 0x25
	rcall SEND_BYTE
	ret
displayEight:
	ldi temp2, 0x7F
	rcall SEND_BYTE
	ret
displayNine:
	ldi temp2, 0x6F
	rcall SEND_BYTE
	ret

displayNumber:
	cpi temp2, 0x00
	breq displayZero
	
	cpi temp2, 0x01
	breq displayOne

	cpi temp2, 0x02
	breq displayTwo

	cpi temp2, 0x03
	breq displayThree

	cpi temp2, 0x04
	breq displayFour

	cpi temp2, 0x05
	breq displayFive

	cpi temp2, 0x06
	breq displaySix

	cpi temp2, 0x07
	breq displaySeven

	cpi temp2, 0x08
	breq displayEight

	cpi temp2, 0x09
	breq displayNine

	ret


displayYesAlarm:
	ldi temp2, 0b00000111
	rcall SEND_BYTE
	ret
displaySetAlarm:
	ldi temp2, 0b00000101
	rcall SEND_BYTE
	ret
displayNoAlarm:
	ldi temp2, 0b00000110
	rcall SEND_BYTE
	ret
displayNoPointer:
	ldi temp2, 0b00000000
	rcall SEND_BYTE
	ret
displayBuzzer:
	ldi temp2, 0b00001111
	rcall SEND_BYTE
	ret
displayNoPointerAlarm:
	ldi temp2, 0b00000001
	rcall SEND_BYTE
	ret

splitByte:    ;xxxxx
	clr temp2
	dec temp
	rjmp splitByte2

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
			rjmp splitByteYes
	
	ret

	splitByteNo:
		rcall displayZero
		mov temp2, temp
		rcall displayNumber
		ret

	sendtens:
		rcall displayNumber
		mov temp2, temp
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

SEND_BYTE:
	sbis UCSRA, UDRE
	rjmp SEND_BYTE
	out UDR, temp2
	ret