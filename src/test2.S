#define __SFR_OFFSET 0x00
#include "avr/io.h"
#include "avr/interrupt.h"

; DEKLARASI FUNGSI GLOBAL
.global main
.global PCINT2_vect 
.global PCINT0_vect
.global TIMER1_COMPA_vect

; INISIALISASI PROGRAM UTAMA DAN REGISTER
main:
    clr r1
    clr r8  
    clr r9  
    clr r10 
    clr r11 
    clr r12 
    clr r13 
    clr r14 
    clr r15 
    clr r4  
    clr r5
    clr r7  

    clr R24
    sts UBRR0H, R24
    ldi R24, 103
    sts UBRR0L, R24
    ldi R24, (1<<RXEN0 | 1<<TXEN0)
    sts UCSR0B, R24
    ldi R24, (1<<UCSZ01 | 1<<UCSZ00)
    sts UCSR0C, R24

    sbi DDRD, 2
    sbi DDRD, 3
    sbi DDRD, 4

    cbi DDRD, 5 
    sbi PORTD, 5 
    cbi DDRD, 6 
    sbi PORTD, 6 
    cbi DDRB, 0 
    sbi PORTB, 0
    cbi DDRB, 1 
    sbi PORTB, 1

    ldi r16, hi8(2499)
    sts OCR1AH, r16
    ldi r16, lo8(2499)
    sts OCR1AL, r16
    ldi r16, (1 << WGM12) | (1 << CS11) | (1 << CS10)
    sts TCCR1B, r16
    lds r16, TIMSK1
    ori r16, (1 << OCIE1A)
    sts TIMSK1, r16

    lds r16, PCICR
    ori r16, (1 << PCIE2) | (1 << PCIE0)
    sts PCICR, r16
    lds r16, PCMSK2
    ori r16, (1 << PCINT21) | (1 << PCINT22)
    sts PCMSK2, r16
    lds r16, PCMSK0
    ori r16, (1 << PCINT0) | (1 << PCINT1)
    sts PCMSK0, r16

    ldi r16, 0x3F 
    out DDRC, r16
    rcall lcd_init
    sei

    ldi r16, 0x5A    
    mov r0, r16 
    
    rcall reset_game 

; LOOP UTAMA GAME
main_loop:
    tst r22
    brne proses_input
    rjmp check_end

proses_input:
    clr r22
    
    tst r7
    brne game_sedang_jalan
    
    ldi r16, 1
    mov r7, r16     
    clr r8          
    clr r9
    cli
    clr r16         
    sts TCNT1H, r16
    sts TCNT1L, r16
    sei

game_sedang_jalan:
    rcall update_system

    tst r12
    breq proses_p1
    rjmp check_p2

; LOGIKA PERGERAKAN P1
proses_p1:
    mov r16, r23
    and r16, r2
    breq p1_check_win

    ldi r16, 2
    mov r12, r16
    clr r14
    clr r15
    ldi R30, lo8(msg_gameover_p1)
    ldi R31, hi8(msg_gameover_p1)
    rcall send_string
    tst r28
    brne lompat_ke_p2
    ldi r16, 2
    mov r28, r16
    inc r5
    ldi R30, lo8(msg_p2_win)
    ldi R31, hi8(msg_p2_win)
    rcall send_string
    ldi r16, 2
    mov r13, r16
    clr r10
    clr r11
    rjmp check_end
lompat_ke_p2:
    rjmp check_p2

p1_check_win:
    cpi r23, 1
    breq p1_won
    cpi r23, 0
    breq p1_won
    rjmp check_p2

p1_won:
    ldi r16, 1
    mov r12, r16
    mov r14, r8
    mov r15, r9
    cpi r28, 0
    brne skip_p1_msg
    ldi R30, lo8(msg_p1_win)
    ldi R31, hi8(msg_p1_win)
    rcall send_string
    ldi r16, 1
    mov r28, r16
    inc r4
skip_p1_msg:
    rcall update_leds_only
    rjmp check_p2

; LOGIKA PERGERAKAN P2
check_p2:
    tst r13
    breq proses_p2
    rjmp check_end

proses_p2:
    mov r16, r6
    and r16, r3
    breq p2_check_win

    ldi r16, 2
    mov r13, r16
    clr r10
    clr r11
    ldi R30, lo8(msg_gameover_p2)
    ldi R31, hi8(msg_gameover_p2)
    rcall send_string
    tst r28
    brne lompat_ke_end
    ldi r16, 1
    mov r28, r16
    inc r4
    ldi R30, lo8(msg_p1_win)
    ldi R31, hi8(msg_p1_win)
    rcall send_string
    ldi r16, 2
    mov r12, r16
    clr r14
    clr r15
    rjmp check_end
lompat_ke_end:
    rjmp check_end

p2_check_win:
    ldi r16, 1      
    cp r6, r16      
    breq p2_won
    ldi r16, 0      
    cp r6, r16      
    breq p2_won
    rjmp check_end

p2_won:
    ldi r16, 1
    mov r13, r16
    mov r10, r8
    mov r11, r9
    cpi r28, 0
    brne skip_p2_msg
    ldi R30, lo8(msg_p2_win)
    ldi R31, hi8(msg_p2_win)
    rcall send_string
    ldi r16, 2
    mov r28, r16
    inc r5
skip_p2_msg:
    rcall update_leds_only
    rjmp check_end

; EVALUASI AKHIR GAME
check_end:
    tst r12
    breq end_loop_jump
    tst r13
    breq end_loop_jump

    clr r7 
    rcall cetak_hasil
    rcall selebrasi_kuning
    rcall reset_game

end_loop_jump:
    rjmp main_loop

; ROUTINE CETAK HASIL PERBANDINGAN WAKTU
cetak_hasil:
    ldi R30, lo8(msg_p1_time)
    ldi R31, hi8(msg_p1_time)
    rcall send_string
    mov R24, r14
    mov R25, r15
    rcall print_time
    
    ldi R30, lo8(msg_p2_time)
    ldi R31, hi8(msg_p2_time)
    rcall send_string
    mov R24, r10
    mov R25, r11
    rcall print_time
    
    ldi R30, lo8(msg_s_nl)
    ldi R31, hi8(msg_s_nl)
    rcall send_string
    
    ldi R30, lo8(msg_p1_best)
    ldi R31, hi8(msg_p1_best)
    rcall send_string

    mov R24, r14
    mov R25, r15
    ldi r17, 0 
    rcall update_best_time
    ldi r16, 0xFF
    cp R24, r16
    cpc R25, r16
    brne print_best1
    clr R24
    clr R25
print_best1:
    rcall print_time

    ldi R30, lo8(msg_p2_best)
    ldi R31, hi8(msg_p2_best)
    rcall send_string

    mov R24, r10
    mov R25, r11
    ldi r17, 2 
    rcall update_best_time
    ldi r16, 0xFF
    cp R24, r16
    cpc R25, r16
    brne print_best2
    clr R24
    clr R25
print_best2:
    rcall print_time

    ldi R30, lo8(msg_s_nl)
    ldi R31, hi8(msg_s_nl)
    rcall send_string
    ret

; LOGIKA VALIDASI DAN PENYIMPANAN BEST TIME (EEPROM)
update_best_time:
    push r17
    push r18
    push r20
    push r21

    rcall eeprom_read
    mov r20, r16
    inc r17
    rcall eeprom_read
    mov r21, r16
    dec r17 

    mov r16, r24
    or r16, r25
    breq return_eeprom_best

    ldi r16, 0xFF
    cp r20, r16
    cpc r21, r16
    breq save_current
    
    mov r16, r20
    or r16, r21
    breq save_current

    cp r24, r20
    cpc r25, r21
    brsh return_eeprom_best 

save_current:
    mov r18, r24
    rcall eeprom_write
    inc r17
    mov r18, r25
    rcall eeprom_write
    dec r17
    rjmp end_update_best

return_eeprom_best:
    mov r24, r20
    mov r25, r21
    ldi r16, 0xFF
    cp r24, r16
    cpc r25, r16
    brne end_update_best
    clr r24
    clr r25

end_update_best:
    pop r21
    pop r20
    pop r18
    pop r17
    ret

; OPERASI BACA DAN TULIS MEMORI EEPROM
eeprom_write:
    sbic EECR, EEPE
    rjmp eeprom_write
    ldi r19, 0
    out EEARH, r19
    out EEARL, r17 
    out EEDR, r18  
    cli
    sbi EECR, EEMPE
    sbi EECR, EEPE
    sei
    ret

eeprom_read:
    sbic EECR, EEPE
    rjmp eeprom_read
    ldi r19, 0
    out EEARH, r19
    out EEARL, r17
    sbi EECR, EERE
    in r16, EEDR
    ret

; ANIMASI AKHIR RONDE (KUNING)
selebrasi_kuning:
    rcall delay_1sec
    ldi r21, 0xFF
    rcall shift_8_bit
    ldi r21, 0xFF
    rcall shift_8_bit
    ldi r21, 0xFF
    rcall shift_8_bit
    ldi r21, 0xFF
    rcall shift_8_bit
    sbi PORTD, 4
    nop
    cbi PORTD, 4
    rcall delay_1sec
    rcall delay_1sec
    ret

; INTERUPSI HARDWARE TIMER 1 DETIK
TIMER1_COMPA_vect:
    push r16
    in r16, SREG
    push r16
    tst r7
    breq timer_done
    inc r8
    brne timer_done
    inc r9
timer_done:
    pop r16
    out SREG, r16
    pop r16
    reti

; INTERUPSI TOMBOL PLAYER 1
PCINT2_vect:
    push r16
    in r16, SREG            
    push r16
    push r24
    push r25
    rcall delay_debounce 
cek_tombol_1_isr:
    tst r12
    brne selesai_isr
    sbic PIND, 5
    rjmp cek_tombol_2_isr  
    mov r16, r23
    andi r16, 1
    brne selesai_isr        
    lsr r23
    ldi r22, 1
    rjmp selesai_isr
cek_tombol_2_isr:
    sbic PIND, 6
    rjmp selesai_isr       
    mov r16, r23
    andi r16, 3
    brne selesai_isr        
    lsr r23
    lsr r23
    ldi r22, 1
selesai_isr:
    ldi r16, (1 << PCIF2)
    out 0x1B, r16           
    pop r25
    pop r24
    pop r16
    out SREG, r16           
    pop r16
    reti                  

; INTERUPSI TOMBOL PLAYER 2
PCINT0_vect:
    push r16
    in r16, SREG            
    push r16
    push r24
    push r25
    rcall delay_debounce 
cek_tombol_3_isr:
    tst r13
    brne selesai_isr2
    sbic PINB, 0
    rjmp cek_tombol_4_isr  
    mov r16, r6
    andi r16, 1
    brne selesai_isr2        
    lsr r6
    ldi r22, 1
    rjmp selesai_isr2
cek_tombol_4_isr:
    sbic PINB, 1
    rjmp selesai_isr2       
    mov r16, r6
    andi r16, 3
    brne selesai_isr2        
    lsr r6
    lsr r6
    ldi r22, 1
selesai_isr2:
    ldi r16, (1 << PCIF0)
    out 0x1B, r16           
    pop r25
    pop r24
    pop r16
    out SREG, r16           
    pop r16
    reti  

; RENDER OUTPUT LED DAN SERIAL MONITOR
update_leds_only:
    mov r21, r3  
    mov r16, r13
    cpi r16, 1
    brne red_p2_ok
    mov r16, r28
    cpi r16, 2
    brne red_p2_ok
    clr r21
red_p2_ok:
    rcall shift_8_bit

    mov r21, r6  
    mov r16, r13
    cpi r16, 1
    brne grn_p2_ok
    mov r16, r28
    cpi r16, 2
    brne grn_p2_ok
    ldi r21, 0xFF
grn_p2_ok:
    rcall shift_8_bit

    mov r21, r2  
    mov r16, r12
    cpi r16, 1
    brne red_p1_ok
    mov r16, r28
    cpi r16, 1
    brne red_p1_ok
    clr r21
red_p1_ok:
    rcall shift_8_bit

    mov r21, r23 
    mov r16, r12
    cpi r16, 1
    brne grn_p1_ok
    mov r16, r28
    cpi r16, 1
    brne grn_p1_ok
    ldi r21, 0xFF
grn_p1_ok:
    rcall shift_8_bit

    sbi PORTD, 4 
    nop
    cbi PORTD, 4
    ret

update_system:
    rcall update_leds_only
    ldi R30, lo8(messager23)
    ldi R31, hi8(messager23)
    rcall send_string
    mov R24, r23
    clr R25
    rcall send_uint16
    ldi R30, lo8(msg_p2_pos)
    ldi R31, hi8(msg_p2_pos)
    rcall send_string
    mov R24, r6
    clr R25
    rcall send_uint16
    ldi r16, 10
    rcall send_char
    ldi r16, 13
    rcall send_char
    ret

; FUNGSI RESET GAME
reset_game:
    ldi r23, 0b10000000
    ldi r16, 0b10000000
    mov r6, r16         
    
    rcall get_random_obstacle
    mov r2, r16
    mov r3, r16        

    ldi R30, lo8(message)
    ldi R31, hi8(message)
    rcall send_string
    
    rcall update_scoreboard
    
    clr r8
    clr r9
    clr r10
    clr r11
    clr r12
    clr r13
    clr r14
    clr r15
    
    clr r7  
    clr r22 
    clr r28

    rcall update_system
    
    ret

; KOMUNIKASI SPI KE SHIFT REGISTER
shift_8_bit:
    push r18
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
    pop r18
    ret

; OPERASI LAYAR LCD 
lcd_init:
    rcall delay_15ms 
    ldi r16, 0x33
    rcall lcd_cmd
    ldi r16, 0x32
    rcall lcd_cmd
    ldi r16, 0x28
    rcall lcd_cmd
    ldi r16, 0x0C
    rcall lcd_cmd
    ldi r16, 0x01
    rcall lcd_cmd
    rcall delay_15ms
    ldi r16, 0x06
    rcall lcd_cmd
    ret

lcd_cmd:
    push r16
    cbi PORTC, 0 
    rjmp lcd_write
lcd_data:
    push r16
    sbi PORTC, 0 
lcd_write:
    push r17
    push r18
    mov r17, r16
    swap r17
    andi r17, 0x0F
    lsl r17
    lsl r17 
    in r18, PORTC
    andi r18, 0x03 
    or r18, r17
    out PORTC, r18
    sbi PORTC, 1 
    nop
    cbi PORTC, 1 
    rcall delay_2ms 
    mov r17, r16
    andi r17, 0x0F
    lsl r17
    lsl r17
    in r18, PORTC
    andi r18, 0x03
    or r18, r17
    out PORTC, r18
    sbi PORTC, 1 
    nop
    cbi PORTC, 1 
    rcall delay_2ms 
    pop r18
    pop r17
    pop r16
    ret

update_scoreboard:
    ldi r16, 0x01
    rcall lcd_cmd
    rcall delay_15ms
    ldi r16, 'S'
    rcall lcd_data
    ldi r16, 'C'
    rcall lcd_data
    ldi r16, 'O'
    rcall lcd_data
    ldi r16, 'R'
    rcall lcd_data
    ldi r16, 'E'
    rcall lcd_data
    ldi r16, 0xC0
    rcall lcd_cmd
    ldi r16, 'P'
    rcall lcd_data
    ldi r16, '1'
    rcall lcd_data
    ldi r16, ':'
    rcall lcd_data
    mov r16, r4
    subi r16, -48 
    rcall lcd_data
    ldi r16, ' '
    rcall lcd_data
    ldi r16, '|'
    rcall lcd_data
    ldi r16, ' '
    rcall lcd_data
    ldi r16, 'P'
    rcall lcd_data
    ldi r16, '2'
    rcall lcd_data
    ldi r16, ':'
    rcall lcd_data
    mov r16, r5
    subi r16, -48 
    rcall lcd_data
    ret

; KUMPULAN FUNGSI DELAY
delay_debounce:
    push R24
    push R25
    ldi R24, lo8(15000) 
    ldi R25, hi8(15000)
db_loop:
    sbiw R24, 1
    brne db_loop
    pop R25
    pop R24
    ret

delay_15ms:
    push R24
    push R25
    ldi R24, lo8(60000)
    ldi R25, hi8(60000)
d15_loop:
    sbiw R24, 1
    brne d15_loop
    pop R25
    pop R24
    ret

delay_2ms:
    push R24
    push R25
    ldi R24, lo8(8000)
    ldi R25, hi8(8000)
d2_loop:
    sbiw R24, 1
    brne d2_loop
    pop R25
    pop R24
    ret

delay_1sec:
    push r20
    ldi r20, 60
d1s_loop:
    rcall delay_15ms
    dec r20
    brne d1s_loop
    pop r20
    ret

; KUMPULAN FUNGSI PENGIRIMAN SERIAL MONITOR (UART)
print_time:
    push R26
    push R27
    clr R26
    clr R27
div_100_loop:
    cpi R24, 100
    ldi r16, 0
    cpc R25, r16
    brlo div_100_done
    subi R24, 100
    sbci R25, 0
    adiw R26, 1
    rjmp div_100_loop
div_100_done:
    push R24
    push R25
    mov R24, R26
    mov R25, R27
    rcall send_uint16
    ldi r16, '.'
    rcall send_char
    pop R25
    pop R24
    cpi R24, 10
    brsh print_rem
    ldi r16, '0'
    rcall send_char
print_rem:
    rcall send_uint16
    pop R27
    pop R26
    ret

send_string:
agn:
    lpm R18, Z+
    cpi R18, 0
    breq send_string_done
    mov r16, r18
    rcall send_char
    rjmp agn
send_string_done:
    ret

send_char:
    lds r17, UCSR0A
    sbrs r17, UDRE0
    rjmp send_char
    sts UDR0, r16
    ret

send_uint16:
    mov R26, R24
    mov R27, R25
    ldi R20, 0    
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
    inc R20
    cp R26, R1
    cpc R27, R1
    brne div_loop
print_digit:
    pop R18
    ldi R24, '0'
    add R18, R24
    mov r16, r18
    rcall send_char
    dec R20
    brne print_digit
    ret

get_random_obstacle:
    push r17
    push r30
    push r31

    ; Entropy dari timer
    lds r17, TCNT1L
    eor r0, r17
    tst r0
    brne lfsr_ok
    ldi r17, 0xAC
    mov r0, r17
lfsr_ok:
    lsr r0
    brcc no_feedback
    ldi r16, 0xB8
    eor r0, r16
no_feedback:

    ; Modulo 20
    mov r16, r0
    ldi r17, 20
mod_loop:
    cp r16, r17
    brlo mod_done
    sub r16, r17
    rjmp mod_loop
mod_done:

    ; Byte address = label + index, tapi lpm butuh byte addr
    ; GAS: lo8/hi8 sudah byte address, jadi langsung pakai
    ldi r30, lo8(obstacle_table)
    ldi r31, hi8(obstacle_table)
    clr r17
    add r30, r16
    adc r31, r17
    lpm r16, Z

    pop r31
    pop r30
    pop r17
    ret

; KUMPULAN DATA STRING TERMINAL
message:
    .byte 10, 13
    .ascii "WELKAM TO LED DRAG RACE"
    .byte 10, 13
    .ascii "Tekan tombol kanan untuk geser 1 langkah dan kiri untuk geser 2 langkah"
    .byte 10, 13
    .ascii "Hindari LED merah!"
    .byte 10, 13
    .ascii "P1: Button Ijo | P2: Button Biru"
    .byte 10, 13, 0

messager23:
    .ascii "P1 Pos: "
    .byte 0

msg_p2_pos:
    .ascii " | P2 Pos: "
    .byte 0

msg_gameover_p1:
    .byte 10, 13
    .ascii "DUARR P1 KENA JEBAKAN!"
    .byte 10, 13, 0

msg_gameover_p2:
    .byte 10, 13
    .ascii "DUARR P2 KENA JEBAKAN!"
    .byte 10, 13, 0

msg_p1_win:
    .byte 10, 13
    .ascii "P1 WIN!"
    .byte 10, 13, 0

msg_p2_win:
    .byte 10, 13
    .ascii "P2 WIN!"
    .byte 10, 13, 0

msg_p1_time:
    .ascii "P1 Time: "
    .byte 0

msg_p2_time:
    .ascii " s | P2 Time: "
    .byte 0

msg_s_nl:
    .ascii " s"
    .byte 10, 13, 0

msg_p1_best:
    .ascii "P1 Best Time: "
    .byte 0

msg_p2_best:
    .ascii " s | P2 Best Time: "
    .byte 0

obstacle_table:
    .byte 2, 4, 8, 10, 16, 18, 20
    .byte 32, 34, 36, 40, 42, 64
    .byte 66, 68, 72, 74, 80, 82
    .byte 84
obstacle_table_len = 20
