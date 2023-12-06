# Lab 2

## Lisam
```
Video lät bra nu.



Kod: Bra den släpps igenom. Du kan titta på detta alternativa sätt att skriva BEEP_MORSE: (tillagda är << )




BEEP_MORSE:
    lsl        arg
    <<breq FINISH ty lsl påverkar Z-flaggan
    brcs    LONG // is carry 1?
    ;brcc    SHORT // is carry 0?
    ; du kommer ju hit även utan hoppet ovan
SHORT:
    call    BEEP_short // beep!
    jmp     BEEP2 // keep going!
LONG:
    ;cpi     arg,0 // is the rest empty?
    ;breq    FINISH // yes? We're done
    call    BEEP_long // no? Beep!
BEEP2:
    call    NOBEEP_space // quiet
    jmp        BEEP_MORSE // keep going!
FINISH:
    call    NOBEEP_char // beep char space
    ret


 



(eller till och med: 




BEEP_MORSE:
    lsl arg
    breq FINISH
    brcc SHORT
LONG:
    call BEEP_SHORT
    call BEEP_SHORT
SHORT:
    call BEEP_SHORT
    call NOBEEP_space
    jmp  BEEP_MORSE
FINISH: 
    ret


lite beroende på hur BEEP_SHORT ser ut men du förstår upplägget)
```