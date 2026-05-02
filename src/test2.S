#define __SFR_OFFSET 0x00
#include "avr/io.h"
#include "avr/interrupt.h"

.global main
.global PCINT2_vect 

main:
    clr r1

    ; buat serial monitor
    clr R24
    sts UBRR0H, R24
    ldi R24, 103
    sts UBRR0L, R24
    ldi R24, (1<<RXEN0 | 1<<TXEN0)
    sts UCSR0B, R24
    ldi R24, (1<<UCSZ01 | 1<<UCSZ00)
    sts UCSR0C, R24

    sbi DDRD, 2 ; PD2 = DS
    sbi DDRD, 3 ; PD3 = SHCP
    sbi DDRD, 4 ; PD4 = STCP

    cbi DDRD, 5 ; tombol maju satu langkah pemain 1
    sbi PORTD, 5 
    cbi DDRD, 6 ; tombol maju dua langkah pemain 2
    sbi PORTD, 6 

    lds r16, PCICR
    ori r16, (1 << PCIE2)
    sts PCICR, r16

    ; untuk interrupt
    lds r16, PCMSK2
    ori r16, (1 << PCINT21) | (1 << PCINT22)
    sts PCMSK2, r16

    sei

    ldi r23, 0b10000000 ; posisi pemain 1 awal
    ldi r16, 0b01010100 ; posisi jebakan
    mov r2,  r16
    ldi r22, 1

    ldi R30, lo8(message)
    ldi R31, hi8(message)
    rcall send_string

main_loop:
    ; nunggu sampai flag r22 untuk interrupt 
    tst r22
    breq main_loop

    ; jika tombol ditekan, baru mulai game
    clr r22                

    mov r16, r23
    and r16, r2
    breq render_layar       

    rcall tampilkan_game_over
    rcall reset_game
    rjmp main_loop

render_layar:
    rcall update_system
    rjmp main_loop

PCINT2_vect:
    push r16
    in r16, SREG            
    push r16
    push r20
    push r24
    push r25

    rcall delay_short

cek_tombol_1_isr:
    sbic PIND, 5
    rjmp cek_tombol_2_isr  
    mov r16, r23
    andi r16, 0b00000001
    brne selesai_isr        
    ; maju satu langkah
    lsr r23
    ldi r22, 1
    rjmp selesai_isr

cek_tombol_2_isr:
    sbic PIND, 6
    rjmp selesai_isr       

    mov r16, r23
    andi r16, 0b00000011
    brne selesai_isr        
    ; maju dua langkah
    lsr r23
    lsr r23
    ldi r22, 1

selesai_isr:
    ldi r16, (1 << PCIF2)
    sts PCIFR, r16

    pop r25
    pop r24
    pop r20
    pop r16
    out SREG, r16           
    pop r16
    reti                  

update_system:
    clr r21
    rcall shift_8_bit
    clr r21
    rcall shift_8_bit
    mov r21, r2
    rcall shift_8_bit
    mov r21, r23
    rcall shift_8_bit
    
    sbi PORTD, 4
    nop
    cbi PORTD, 4

    ldi R30, lo8(messager23)
    ldi R31, hi8(messager23)
    rcall send_string
    mov R24, r23
    clr R25
    rcall send_uint16
    ret

tampilkan_game_over:
    clr r21
    rcall shift_8_bit
    clr r21
    rcall shift_8_bit
    ldi r21, 0xFF
    rcall shift_8_bit
    clr r21
    rcall shift_8_bit

    sbi PORTD, 4
    nop
    cbi PORTD, 4

    ldi R30, lo8(msg_gameover)
    ldi R31, hi8(msg_gameover)
    rcall send_string
    rcall delay_long
    ret

reset_game:
    ldi r23, 0b10000000
    ldi r16, 0b01010100
    mov r2, r16
    ldi r22, 1

    ldi R30, lo8(msg_restart)
    ldi R31, hi8(msg_restart)
    rcall send_string
    ret

shift_8_bit:
    ldi r18, 8
send_loop:
    lsl r21
    cbi PORTD, 2
    brcc clock_pulse
    sbi PORTD, 2
clock_pulse:
    sbi PORTD, 3
    nop
    cbi PORTD, 3
    dec r18
    brne send_loop
    ret

delay_short:
    push r20
    ldi R20, 5
ds1: ldi R24, lo8(60000)
    ldi R25, hi8(60000)
ds2: sbiw R24, 1
    brne ds2
    dec R20
    brne ds1
    pop r20
    ret

delay_long:
    push r20
    ldi R20, 255
dl1: ldi R24, lo8(60000)
    ldi R25, hi8(60000)
dl2: sbiw R24, 1
    brne dl2
    dec R20
    brne dl1
    pop r20
    ret

send_string:
agn:
    lpm R18, Z+
    cpi R18, 0
    breq send_string_done
l1:
    lds R17, UCSR0A
    sbrs R17, UDRE0
    rjmp l1
    sts UDR0, R18
    rjmp agn
send_string_done:
    ret

send_uint16:
    mov R26, R24
    mov R27, R25
    ldi R22, 0
div_loop:
    ldi R16, 10
    clr R18
    clr R19
    clr R17
    ldi R24, 16
bitloop:
    lsl R26
    rol R27
    rol R18
    cp R18, R16
    brlo no_sub
    sub R18, R16
    inc R26
no_sub:
    dec R24
    brne bitloop
    push R18
    inc R22
    cp R26, R1
    cpc R27, R1
    brne div_loop
print_digit:
    pop R18
    ldi R24, '0'
    add R18, R24
send_chr:
    lds R17, UCSR0A
    sbrs R17, UDRE0
    rjmp send_chr
    sts UDR0, R18
    dec R22
    brne print_digit
    ldi R18, 10
send_nl:
    lds R17, UCSR0A
    sbrs R17, UDRE0
    rjmp send_nl
    sts UDR0, R18
    ldi R18, 13
send_cr:
    lds R17, UCSR0A
    sbrs R17, UDRE0
    rjmp send_cr
    sts UDR0, R18
    ret

message:
    .ascii "WELKAM TO LED DRAG RACE"
    .byte 10, 13
    .ascii "Tekan PD5 untuk geser 1 langkah dan PD6 untuk geser 2 langkah"
    .byte 10, 13
    .ascii "Hindari LED merah!"
    .byte 10, 13, 0

messager23:
    .ascii "posisi Pemain = "
    .byte 0

msg_gameover:
    .byte 10, 13
    .ascii "KENA JEBAKAN!"
    .byte 10, 13, 0

msg_restart:
    .ascii "GAME RESET!"
    .byte 10, 13, 0