	.def arg = r16
	.equ speed = 4 /// Every step is 10ms, speed = 2 => 20 ms
	.equ char_space = 3
	.equ morse_space = 1
	.equ word_space = 7
	.equ morse_short = 1
	.equ morse_long = 3
	.equ ascii_space = $20


	jmp COLD


STRING:
	.db		"MARKA MARKA MARKA",0

BTAB:
	.db		$60,$88,$A8,$90,$40,$28,$D0,$08,$20,$78,$B0,$48,$E0,$A0,$F0,$68,$D8,$50,$10,$C0,$30,$18,$70,$98,$B8,$C8,0	



COLD:
	sbi DDRB,4
	//Set stack pointer
	ldi		r16, HIGH(RAMEND)
	out		SPH, r16
	ldi		r16, LOW(RAMEND)
	out		SPL, r16
	clr r16

	call SET_Z_STRING // set Z pointer to STRING position

char_loop:
	call	GET_CHAR // sets char to the ascii for char
	cpi		arg,0	// Look for stop bit
	breq	DONE
	cpi		arg,ascii_space
	breq	space
	call	LOOK_UP
	call	SEND_char
	jmp		continue
space:
	call	SEND_space
	jmp		continue
continue:
	jmp		char_loop


DONE:
	jmp DONE

SEND_char:
	call BEEP_MORSE
	ret

SEND_space:
	push	arg 
	ldi		arg, word_space-char_space
	call	WAIT
	pop		arg
	ret


BEEP_MORSE:
morse_loop:
	lsl		arg
	brcs	LONG // is carry 1?
	brcc	SHORT // is carry 0?
SHORT:
	call	BEEP_short // beep!
	call	NOBEEP_space // quiet
	jmp		morse_loop // keep going!
LONG:
	cpi		arg,0 // is the rest empty?
	breq	FINISH // yes? We're done
	call	BEEP_long // no? Beep!
	call	NOBEEP_space // quiet
	jmp		morse_loop // keep going!
FINISH:
	call	NOBEEP_char // beep char space
	ret

BEEP_short:
	push	arg
	ldi		arg, morse_short
	call	BEEP
	pop		arg
	ret

BEEP_long:
	push	arg
	ldi		arg, morse_long
	call	BEEP
	pop		arg
	ret

NOBEEP_space:
	push	arg
	ldi		arg,morse_space
	call	NO_BEEP
	pop		arg
	ret

NOBEEP_char:
	push	arg
	ldi		arg,char_space-morse_space // Since NOBEEP_space always is called before, we compensate for that
	call	NO_BEEP
	pop		arg
	ret

GET_CHAR:
	lpm		arg, Z+
	ret

SET_Z_STRING:
	ldi		ZH, HIGH(STRING*2)
	ldi		ZL, LOW(STRING*2)
	ret

LOOK_UP:
	push	ZH
	push	ZL

	subi	arg,$41
	call	SET_Z_BTAB
	add		ZL, arg
	lpm		arg, Z

	pop		ZL
	pop		ZH
	ret


SET_Z_BTAB:
	ldi		ZH, HIGH(BTAB*2)
	ldi		ZL, LOW(BTAB*2)
	ret


BEEP:
	sbi PORTB,4
	// arg is passed to delay
	call WAIT
	ret

NO_BEEP:
	// arg is passed to delay
	cbi PORTB,4
	call WAIT
	ret


DELAY: //arg
	push r19
	ldi r19,speed
	push r17
	push r18
D_3:
	ldi		r17,0
D_2:
	ldi		r18,208 // 208 seems to make the delay be about 10ms
D_1:
	dec		r18
	brne	D_1
	dec		r17
	brne	D_2
	dec		r19
	brne	D_3

	pop r18
	pop r17
	pop r19
	ret


WAIT:
	push arg
wait_loop:
	call DELAY
	dec arg
	brne wait_loop
	pop arg
	ret
	