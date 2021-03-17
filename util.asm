
; Useful macros for the rest of the code

STDOUT_HNDL equ 1 ;file handle of sdout

; permutation control words
MOVE_SECOND_TO_FIRST equ 11100101b 
MOVE_FIRST_TO_LAST equ 00100100b
MOVE_FIRST_TO_THIRD equ 11000100b
MOVE_FIRST_TO_SECOND equ 11100000b


section .data
msg db "REACHED HERE"

section .text

    ; Prints a new-line-terminated string to the screen.
    ;
    ; param: the message's offset
    %macro PRINT 1
        push rax
        push rsi
        push rdi
        push rdx

        mov rsi, %1
        mov rax, 1
        mov rdx, 13
        mov rdi, STDOUT_HNDL
        syscall

        pop rdx
        pop rax
        pop rsi
        pop rdi
    %endmacro

    ; Exits the program with error code 0.
    %macro EXIT 0
        mov       rax, 60
        xor       rdi, rdi                
        syscall
    %endmacro

    ; Pushes an AVX register into the stack.
    ;
    ; param: the AVX register
    %macro AVXPUSH 1
        vmovupd [rsp], %1
        sub rsp, 0x100
    %endmacro 

    ; Pops an AVX register from the stack.
    ;
    ; param: the AVX register
    %macro AVXPOP 1
        vmovupd %1, [rsp]
        add rsp, 0x100
    %endmacro

    ; Broadcasts a 64 bit register to a ymm register.
    ;
    ; param: avx register
    ; param: 64-bit register
    ; param: some xmm register
    %macro BROADCASTREG 3
        vmovq %3, %1
        vbroadcastsd %2, %3
    %endmacro