
; Useful macros for the rest of the code

STDOUT_HNDL equ 1

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