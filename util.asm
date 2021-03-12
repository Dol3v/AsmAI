
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
    ; param: a 64-bit helper register to use
    %macro AVXPUSH 2
        vmovq %2, %1
        push %2
        vpermpd %1, %1, MOVE_SECOND_TO_FIRST
        vmovq %2, %1
        push %2
        vpermpd %1, %1, MOVE_SECOND_TO_FIRST
        vmovq %2, %1
        push %2
        vpermpd %1, %1, MOVE_SECOND_TO_FIRST
        vmovq %2, %1
        push %2
        vpermpd %1, %1, MOVE_SECOND_TO_FIRST
    %endmacro 

    ; Pops an AVX register from the stack.
    ;
    ; param: the AVX register
    ; param: a helper 64-bit register to use
    %macro AVXPOP 2
        pop %2
        vmovq %1, %2
        vpermpd %1, %1, MOVE_FIRST_TO_LAST
        pop %2
        vmovq %1, %2
        vpermpd %1, %1, MOVE_FIRST_TO_THIRD
        pop %2
        vmovq %1, %2
        vpermpd %1, %1, MOVE_FIRST_TO_SECOND
        pop %2
        vmovq %1, %2
    %endmacro
