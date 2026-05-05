#define __SFR_OFFSET 0x00
#include "avr/io.h"
#include "avr/interrupt.h"

.global main
.global PCINT2_vect 
.global PCINT0_vect

main:
    clr r1
    clr r4 ; r4 = Score P1
    clr r5 ; r5 = Score P2

    ; 1. Inisialisasi Serial Monitor
    clr R24
    sts UBRR0H, R24
    ldi R24, 103
    sts UBRR0L, R24
    ldi R24, (1<<RXEN0 | 1<<TXEN0)
    sts UCSR0B, R24
    ldi R24, (1<<UCSZ01 | 1<<UCSZ00)
    sts UCSR0C, R24

    ; 2. Setup Pin Shift Register
    sbi DDRD, 2 ; PD2 = DS
    sbi DDRD, 3 ; PD3 = SHCP
    sbi DDRD, 4 ; PD4 = STCP

    ; 3. Setup Tombol P1 (PD5, PD6)
    cbi DDRD, 5 
    sbi PORTD, 5 
    cbi DDRD, 6 
    sbi PORTD, 6 

    ; 4. Setup Tombol P2 (PB0/Pin8, PB1/Pin9)
    cbi DDRB, 0 
    sbi PORTB, 0
    cbi DDRB, 1 
    sbi PORTB, 1

    ; 5. Setup Interrupt Tombol
    lds r16, PCICR
    ori r16, (1 << PCIE2) | (1 << PCIE0)
    sts PCICR, r16

    lds r16, PCMSK2
    ori r16, (1 << PCINT21) | (1 << PCINT22)
    sts PCMSK2, r16

    lds r16, PCMSK0
    ori r16, (1 << PCINT0) | (1 << PCINT1)
    sts PCMSK0, r16

    ; 6. Setup LCD Cepat
    ldi r16, 0x3F 
    out DDRC, r16
    rcall lcd_init
    
    sei ; Aktifkan sistem Interrupt
    
    ; 7. Panggil fungsi reset untuk memulai ronde pertama
    rcall reset_game 

main_loop:
    tst r22
    breq main_loop ; Tunggu sampai ada yang mencet tombol / flag = 1

    clr r22 ; Hapus flag        

    ; =========================================================
    ; RENDER DULU! Biar lampu hijau kliatan nyampe garis finish
    ; atau nabrak merah sebelum animasinya dimainkan!
    ; =========================================================
    rcall update_system

    ; Cek Tabrakan P1
    mov r16, r23
    and r16, r2
    brne p1_kalah       

    ; Cek Tabrakan P2
    mov r16, r6
    and r16, r3
    brne p2_kalah

    ; Cek Menang P1 (Nyampe bit paling kiri)
    cpi r23, 1
    breq p1_menang
    cpi r23, 0
    breq p1_menang

    ; Cek Menang P2 (Nyampe bit paling kiri)
    ldi r16, 1      
    cp r6, r16      
    breq p2_menang
    ldi r16, 0      
    cp r6, r16      
    breq p2_menang

    rjmp main_loop

p1_kalah:
    inc r5 
    rcall tampilkan_game_over
    rcall reset_game
    rjmp main_loop

p2_kalah:
    inc r4 
    rcall tampilkan_game_over
    rcall reset_game
    rjmp main_loop

p1_menang:
    inc r4 
    rcall tampilkan_menang
    rcall reset_game
    rjmp main_loop

p2_menang:
    inc r5 
    rcall tampilkan_menang
    rcall reset_game
    rjmp main_loop

; ============ ISR PEMAIN 1 (SANGAT RESPONSIF) ============
PCINT2_vect:
    push r16
    in r16, SREG            
    push r16
    push r24
    push r25

    rcall delay_debounce 

cek_tombol_1_isr:
    sbic PIND, 5
    rjmp cek_tombol_2_isr  
    mov r16, r23
    andi r16, 0b00000001
    brne selesai_isr        
    lsr r23
    ldi r22, 1
    rjmp selesai_isr

cek_tombol_2_isr:
    sbic PIND, 6
    rjmp selesai_isr       
    mov r16, r23
    andi r16, 0b00000011
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

; ============ ISR PEMAIN 2 (SANGAT RESPONSIF) ============
PCINT0_vect:
    push r16
    in r16, SREG            
    push r16
    push r24
    push r25

    rcall delay_debounce 

cek_tombol_3_isr:
    sbic PINB, 0
    rjmp cek_tombol_4_isr  
    mov r16, r6
    andi r16, 0b00000001
    brne selesai_isr2        
    lsr r6
    ldi r22, 1
    rjmp selesai_isr2

cek_tombol_4_isr:
    sbic PINB, 1
    rjmp selesai_isr2       
    mov r16, r6
    andi r16, 0b00000011
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

; ================== RUTIN GAME ==================
update_leds_only:
    mov r21, r3  
    rcall shift_8_bit
    mov r21, r6  
    rcall shift_8_bit
    mov r21, r2  
    rcall shift_8_bit
    mov r21, r23 
    rcall shift_8_bit
    sbi PORTD, 4 
    nop
    cbi PORTD, 4
    ret

update_system:
    rcall update_leds_only

    ; Tulis ke Serial Monitor!
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

tampilkan_game_over:
    rcall delay_1sec ; Biarkan pemain liat jelas kalau dia nabrak merah!

    ldi R30, lo8(msg_gameover)
    ldi R31, hi8(msg_gameover)
    rcall send_string

    ; Animasi Nge-flash Merah Semua!
    ldi r21, 0xFF ; Merah P2
    rcall shift_8_bit
    ldi r21, 0x00 ; Hijau P2
    rcall shift_8_bit
    ldi r21, 0xFF ; Merah P1
    rcall shift_8_bit
    ldi r21, 0x00 ; Hijau P1
    rcall shift_8_bit
    sbi PORTD, 4
    nop
    cbi PORTD, 4

    rcall delay_1sec
    rcall delay_1sec
    ret

tampilkan_menang:
    rcall delay_1sec ; Tahan frame saat ijo paling ujung kiri nyala biar diliat!

    ldi R30, lo8(msg_menang)
    ldi R31, hi8(msg_menang)
    rcall send_string

    ; Animasi Nge-flash Kuning Terang (Merah + Hijau nyala full)
    ldi r21, 0xFF ; Merah P2
    rcall shift_8_bit
    ldi r21, 0xFF ; Hijau P2
    rcall shift_8_bit
    ldi r21, 0xFF ; Merah P1
    rcall shift_8_bit
    ldi r21, 0xFF ; Hijau P1
    rcall shift_8_bit
    sbi PORTD, 4
    nop
    cbi PORTD, 4

    rcall delay_1sec
    rcall delay_1sec
    ret

reset_game:
    ; Atur Ulang Semuanya ke Posisi Start
    ldi r23, 0b10000000 ; Posisi P1 (128 / Ujung Kanan)
    ldi r16, 0b10000000
    mov r6, r16         ; Posisi P2 (128 / Ujung Kanan)
    
    ldi r16, 0b01010100 ; 3 Jebakan Identik
    mov r2, r16         ; Jebakan P1
    mov r3, r16         ; Jebakan P2

    ; Tulis Welcome Teks + Aturan Main P1 Ijo, P2 Biru ke Monitor
    ldi R30, lo8(message)
    ldi R31, hi8(message)
    rcall send_string
    
    ; Update LCD
    rcall update_scoreboard
    
    ; Picu flag r22 supaya main_loop langsung memunculkan posisi awal LED dan Terminal!
    ldi r22, 1 
    ret

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

; ================== RUTIN LCD NGEBUT ==================
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

; ================== RUTIN DELAY PRESISI ==================
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

; ================== RUTIN UART ==================
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

; ================== DATA STRING FINAL ==================
message:
    .byte 10, 13
    .ascii "WELKAM TO LED DRAG RACE"
    .byte 10, 13
    .ascii "Tekan PD5 untuk geser 1 langkah dan PD6 untuk geser 2 langkah"
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

msg_gameover:
    .byte 10, 13
    .ascii "DUARR KENA JEBAKAN!"
    .byte 10, 13, 0

msg_menang:
    .byte 10, 13
    .ascii "MANTAP SAMPAI FINISH!"
    .byte 10, 13, 0