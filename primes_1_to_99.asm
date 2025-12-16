; primes_1_to_99.asm
; MODE 1–friendly algorithm: uses only A,B,C,D = RAX,RBX,RCX,RDX for logic.
; RDI/RSI are used *only* at the syscall boundary to satisfy Linux ABI.

BITS 64
GLOBAL _start

SECTION .data
    msg_prime:     db " is prime."
    msg_prime_len: equ $ - msg_prime

    msg_notprime:  db " is not prime."
    msg_notprime_len: equ $ - msg_notprime

    spc:    db " "
    spc_len: equ $ - spc

    nl:     db 10
    nl_len: equ $ - nl

SECTION .bss
    numbuf: resb 2      ; enough for "99"

SECTION .text

_start:
    ; RBX = current n (1..99)
    mov     rbx, 1

.loop_n:
    ; ---- primality test for RBX ----
    ; Handle n < 2
    cmp     rbx, 2
    jb      .print_notprime

    ; RCX = divisor d = 2
    mov     rcx, 2

.check_div:
    ; if d*d > n => prime
    mov     rax, rcx
    imul    rax, rcx          ; rax = d*d
    cmp     rax, rbx
    jg      .print_prime

    ; divide n by d: if remainder == 0 => not prime
    mov     rax, rbx
    xor     rdx, rdx
    div     rcx               ; rax = n/d, rdx = n%d
    test    rdx, rdx
    jz      .print_notprime

    inc     rcx
    jmp     .check_div

.print_prime:
    ; print number
    mov     rax, rbx
    call    print_number

    ; print " is prime."
    mov     rax, 1            ; sys_write
    mov     rdi, 1            ; stdout
    mov     rsi, msg_prime
    mov     rdx, msg_prime_len
    syscall
    jmp     .after_sentence

.print_notprime:
    ; print number
    mov     rax, rbx
    call    print_number

    ; print " is not prime."
    mov     rax, 1            ; sys_write
    mov     rdi, 1            ; stdout
    mov     rsi, msg_notprime
    mov     rdx, msg_notprime_len
    syscall

.after_sentence:
    ; If n < 99, print space; else newline and exit
    cmp     rbx, 99
    je      .last_end
    ; print space
    mov     rax, 1
    mov     rdi, 1
    mov     rsi, spc
    mov     rdx, spc_len
    syscall
    ; next n
    inc     rbx
    jmp     .loop_n

.last_end:
    ; newline
    mov     rax, 1
    mov     rdi, 1
    mov     rsi, nl
    mov     rdx, nl_len
    syscall

    ; exit(0)
    mov     rax, 60
    xor     rdi, rdi
    syscall


; -----------------------------------------
; print_number
; IN : RAX = unsigned integer (1..99)
; TRASHES: RAX, RBX, RCX, RDX (A..D)
; OUT: writes the decimal ascii for the number
; -----------------------------------------
print_number:
    ; Divide by 10 -> tens in RAX, ones in RDX
    mov     rcx, 10
    xor     rdx, rdx
    div     rcx                ; RAX = tens (0..9), RDX = ones (0..9)

    cmp     rax, 0
    je      .single_digit

    ; two digits: write tens then ones into numbuf[0..1]
    ; tens
    mov     rcx, rax           ; RCX = tens
    add     cl, '0'
    mov     [numbuf], cl

    ; ones
    mov     rax, rdx           ; RAX = ones
    add     al, '0'
    mov     [numbuf+1], al

    ; write 2 bytes
    mov     rax, 1             ; sys_write
    mov     rdi, 1             ; stdout
    mov     rsi, numbuf
    mov     rdx, 2
    syscall
    ret

.single_digit:
    ; one digit: ones is RDX
    mov     rax, rdx
    add     al, '0'
    mov     [numbuf], al

    mov     rax, 1             ; sys_write
    mov     rdi, 1             ; stdout
    mov     rsi, numbuf
    mov     rdx, 1
    syscall
    ret
