	.equ BLGT = 2
	.equ RS = 0
	.equ E = 1
	.equ DISP_ON = 0b00001111
	.equ FN_SET = 0b00101000
	.equ LCD_CLR = 0b00000001
	.equ E_MODE = 0b00000110
	.equ HOME = 0b00000010
	.equ TIME_SEPARATOR = $3A
	.equ SECOND_TICKS = 62500 - 1
	.equ CLOCK_LIMIT = $24 -1 // Could change it to 12 hour clock


	jmp cold

	.dseg
	.org	$0100
TIME: .byte 6
STRING: .byte 8

	.cseg

	.org	OC1Aaddr
	jmp	TIME_TICK


// Store immedieate
.macro sti ; @0 constant, @1 pointer
	push	r16
	ldi		r16,@1
	st		@0, r16
	pop		r16
.endmacro

// Add immediate, macros seemed cool, just a test
.macro addi ; @0 register, @1 constant
	subi	@0,-@1
.endmacro

//Set pointer, haha yes, I am that lazy :D
.macro setp ;@0 pointer, @1 constant
	ldi		@0H, HIGH(@1)
	ldi		@0L, LOW(@1)
.endmacro

.macro push_state
	push r16
	in	r16, SREG
	push ZH
	push ZL
	push r17
	push r16
	
.endmacro

.macro pop_state
	pop r16
	pop r17
	pop ZL
	pop ZH
	out	SREG, r16
	pop r16
.endmacro	

COLD:
	ldi		r16, HIGH(RAMEND)
	out		SPH, r16
	ldi		r16, LOW(RAMEND)
	out		SPL, r16
	clr		r16
	sei

	call LCD_INIT  // Initialize display
	call TIME_INIT // Initialize clock
MAIN:
	call TIME_FORMAT // Format time
	call TIME_PRINT // Print time
	jmp MAIN



LCD_INIT:
	call wait

	ldi r16,$FF
	out DDRB, r16
	out DDRD, r16
	call INIT_4BIT

	ldi r16, FN_SET
	call LCD_COMMAND

	ldi r16, DISP_ON
	call LCD_COMMAND

	call LCD_ERASE

	ldi r16, E_MODE
	call LCD_COMMAND

	call BACKLIGHT_ON	

	ret

INIT_4BIT:
	push	r16
	ldi		r16, $30
	call	LCD_WRITE4
	call	LCD_WRITE4
	call	LCD_WRITE4
	ldi		r16,$20
	call	LCD_WRITE4
	pop		r16
	ret

WAIT:
	push	r26
	push	r27
	ldi		r26,0
	ldi		r27,0
WAIT_loop:
	adiw	r26,1
	brne	wait_loop

	pop		r27
	pop		r26
	ret

BACKLIGHT_ON:
	sbi PORTB, BLGT
	ret

BACKLIGHT_OFF:
	cbi PORTB, BLGT
	ret

LCD_WRITE4:
	sbi		PORTB,E
	out		PORTD, r16
	cbi		PORTB, E
	call	WAIT
	ret

LCD_WRITE8:
	push	r16
	call	LCD_WRITE4
	swap	r16
	call	LCD_WRITE4
	pop		r16
	ret

LCD_ASCII:
	sbi		PORTB, RS
	call	LCD_WRITE8
	ret

LCD_COMMAND:
	cbi		PORTB, RS
	call	LCD_WRITE8
	ret

LCD_ERASE:
	ldi		r16, LCD_CLR
	call	LCD_COMMAND
	ret

LCD_HOME:
	ldi		r16, HOME
	call	LCD_COMMAND
	ret
	
LCD_PRINT:
	push ZH
	push ZL
	push r16
LCD_PRINT_loop:
	ld		r16, Z+
	cpi		r16,0
	breq	LCD_PRINT_done
	call	LCD_ASCII
	jmp	LCD_PRINT_loop
LCD_PRINT_done:
	pop		r16
	pop		ZL
	pop		ZH
	ret

TIME_PRINT:
	call	LCD_HOME
	setp	Z, STRING
	call	LCD_PRINT
	ret

SAMPLE_DATA:
	setp	Z,TIME
	sti		Z+, $05
	sti		Z+, $04
	sti		Z+, $09
	sti		Z+, $05
	sti		Z+, $03
	sti		Z+, $02
	ret

TIME_RESET:
	setp	Z,TIME
	sti		Z+, 0
	sti		Z+, 0
	sti		Z+, 0
	sti		Z+, 0
	sti		Z+, 0
	sti		Z+, 0
	ret

TIME_FORMAT:
	setp	Z, TIME+6
	setp	X, STRING
	ldi		r16,3
TIME_FORMAT_loop:
	call	WRITE_TIME_UNIT
	call	WRITE_TIME_UNIT
	dec		r16
	breq	TIME_FORMAT_done
	sti		X+, TIME_SEPARATOR
	brne	TIME_FORMAT_loop
TIME_FORMAT_done:
	sti		X+, 0
	ret

WRITE_TIME_UNIT:
	push	r16
	ld		r16, -Z
	addi	r16, $30
	st		X+,	r16
	pop		r16
	ret

TIME_TICK:
	push_state
	setp	Z,TIME
    ldi        r17,10
	CLT
loop: //The loop is almost like recursion, but not really
    ld        r16, Z //Load time
    inc        r16 // Increase by one
    cp        r16,r17 // Look for top
    breq    TIME_TICK_carry //If the number has gotten the same as it's limit
	st        Z,r16
	//Checking if the hours are 24 every second seems unnecessary
TIME_TICK_done:
	pop_state
    reti
TIME_TICK_carry:
	cpi		r17,10 // was it 10?
	breq	TIME_TICK_10 //yes
	brne	TIME_TICK_6 // no it was 6
TIME_TICK_carry_continue:
	sti		Z+,0
    jmp loop
TIME_TICK_6:
	ldi		r17,10 //If the limit was 6, load it with 10
	brts	TIME_TICK_24check
	/*
		If we're about to set the flag, and it's already set, that means the flag has been set twice.
		Since we only set the flag when we set the limit to 10, that means we already done one iteration with 6 as limit,
		so if the flag gets set twice, that means the limit has been 6 two times. Therefore we are now doing computation on the hours.
		Therefore, we will only do the 24check every hour, not every second, which will reduce the amount of clocks to compute each second.
	*/ 
	SET
	jmp		TIME_TICK_carry_continue
TIME_TICK_10:
	ldi		r17,6 // If the limit was 10, load it with 6
    jmp		TIME_TICK_carry_continue
TIME_TICK_24check:
	push r16
	push r17
	lds		r16, TIME+4
	lds		r17, TIME+5
	swap	r17
	or		r16,r17
	cpi		r16, CLOCK_LIMIT
	pop r16
	pop r17
	brne	TIME_TICK_carry_continue
	call	TIME_RESET
	jmp TIME_TICK_done

TIME_INIT:
	call SAMPLE_DATA
	call TIMER1_INIT
	ret

TIMER1_INIT :
	push r16
	ldi r16 ,(1<<WGM12 )|(1<<CS12 ) ; CTC , prescale 256
	sts TCCR1B , r16
	ldi r16 , HIGH ( SECOND_TICKS )
	sts OCR1AH , r16
	ldi r16 , LOW ( SECOND_TICKS )
	sts OCR1AL , r16
	ldi r16 ,(1<<OCIE1A ) ; allow to interrupt
	sts TIMSK1 , r16
	pop r16
	ret
