	.equ BLGT = 2
	.equ RS = 0
	.equ E = 1
	.equ DISP_ON = 0b00001111
	.equ FN_SET = 0b00101000
	.equ LCD_CLR = 0b00000001
	.equ E_MODE = 0b00000110
	.equ HOME = 0b00000010
	.equ CURSOR_LEFT = 0b00010000
	.equ CURSOR_RIGHT = 0b00010100

	jmp cold

	INTERVALL:
	.db		207,130,82,43,12
	ACTION:
	.db	NONE
	.db	MOVE_CURSOR_LEFT
	.db	NONE
	.db	NONE
	.db	MOVE_CURSOR_RIGHT
	LINE:
	.db	"MARKA727",0


	.dseg
	.org	$0100
CUR_POS: .byte 1

	.cseg


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

COLD:
	ldi		r16, HIGH(RAMEND)
	out		SPH, r16
	ldi		r16, LOW(RAMEND)
	out		SPL, r16
	clr		r16
	setp	Z, CUR_POS
	sti		Z, 0

	call	LCD_INIT
	call	LCD_AUTO_INC_ON
	call	STRING_PRINT_FLASH
MAIN:
	call	SET_CURSOR
	call	KEY_READ
	call	KEY_ACTION
	call	LCD_ERASE
	call	SET_CURSOR
	call	STRING_PRINT_FLASH
	jmp MAIN


KEY:
	call	ADC_READ8
	setp	Z, (INTERVALL*2)
	ldi		r18,-1
KEY_loop:
	inc		r18
	lpm		r17, Z+
	cp		r16,r17
	brlo	KEY_loop
	mov		r16,r18
	ret

KEY_READ:
	call	KEY
	tst		R16
	brne	KEY_READ
KEY_WAIT_FOR_PRESS:
	call	SHORT_WAIT
	call	KEY
	tst		r16
	breq	KEY_WAIT_FOR_PRESS
	ret


KEY_ACTION:
	//This subrutin is a bit advanced, it takes in an argument at r16, calls a label which has to be stored in "ACTION" in flash memory
	// r16 = 1, first label
	// r16 = 3, third label.
	// This is basically a switch
	setp	Z, (ACTION*2)
	dec		r16
	adc		ZL,	r16 // For every r16, you need to increase Z by two steps. So r16 * 2 = r16 + r16.
	adc		ZL,	r16 // Due to a label being two bytes long.
	lpm		r16, Z+
	lpm		r17, Z+
	mov		ZH, r17
	mov		ZL, r16
	icall
	ret


ADC_READ8:
	ldi		r16, (1<<REFS0)|(1<<ADLAR)|0
	sts		ADMUX,r16
	ldi		r16,(1<<ADEN) | 7
	sts		ADCSRA,r16
CONVERT:
	lds		r16, ADCSRA
	ori		r16, (1<<ADSC)
	sts		ADCSRA,r16
ADC_BUSY:
	lds		r16, ADCSRA
	sbrc	r16, ADSC
	jmp		ADC_BUSY
	; omvandlikg klar?
	lds		r16,ADCH
	ret
	

MOVE_CURSOR_RIGHT:
	setp	Z, CUR_POS
	ld		r16, Z
	inc		r16
	cpi		r16, 9
	brne	MOVE_CURSOR_RIGHT_done
	ldi		r16,8
MOVE_CURSOR_RIGHT_done:
	st		Z, r16
	call SET_CURSOR
	ret

MOVE_CURSOR_LEFT:
	setp	Z, CUR_POS
	ld		r16, Z
	dec		r16
	cpi		r16, -1
	brne	MOVE_CURSOR_LEFT_done
	ldi		r16,0
MOVE_CURSOR_LEFT_done:
	st		Z, r16
	call SET_CURSOR
	ret

LCD_COL:
	addi	r16,$80
	call	LCD_COMMAND
	ret

SET_CURSOR:
	push	r16
	lds		r16, CUR_POS
	call	LCD_COL
	pop		r16
	ret


BACKLIGHT_TOGGLE:
	sbi PINB,2
	ret


LCD_AUTO_INC_ON:
	push r16
	ldi r16, 0b00000110
	call LCD_COMMAND
	pop r16
	ret

LCD_AUTO_INC_OFF:
	push r16
	ldi r16, 0b00000100
	call LCD_COMMAND
	pop r16
	ret
	


LETTER_PRINT:
	call	LCD_AUTO_INC_OFF
	call	SET_CURSOR
	call	LCD_ASCII
	ret

NONE:
	nop
	ret


// LCD stuff, from lab 3

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


SHORT_WAIT:
	push	r16
	ldi		r16,$A0
	call	DELAY
	pop		r16
	ret

WAIT:
	push	r16
	ldi		r16,0
	call	DELAY
	pop		r16
	ret

DELAY:
	push	r26
	push	r27
	mov		r27, r16

	ldi		r26,0
	ldi		r27,0
DELAY_loop:
	adiw	r26,1
	brne	DELAY_loop
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


LCD_PRINT_FLASH:
	push ZH
	push ZL
	push r16
LCD_PRINT_FLASH_loop:
	lpm		r16, Z+
	cpi		r16,0
	breq	LCD_PRINT_FLASH_done
	call	LCD_ASCII
	jmp	LCD_PRINT_FLASH_loop
LCD_PRINT_FLASH_done:
	pop		r16
	pop		ZL
	pop		ZH
	ret



STRING_PRINT_FLASH:
	call	LCD_AUTO_INC_ON
	setp	Z, (LINE*2)
	call	LCD_PRINT_FLASH
	ret
