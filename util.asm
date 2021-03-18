
; Useful macros for the rest of the code

STDOUT_HNDL equ 1
CARRAGE_RETURN equ 13

section .text

    ; Prints a new-line-terminated string to the screen.
    ; *String mustn't be empty - it shouldn't be equal to 13.
    ;
    ; param: the message's offset
    %macro PRINT 1
        push rax
        push rsi
        push rdi
        push rdx
        
        mov rsi, %1
    
    %%print_char:
        mov rax, 1
        mov rdx, 1 ;print out a char each time
        mov rdi, STDOUT_HNDL
        syscall

        inc rsi
        cmp byte [rsi], CARRAGE_RETURN
        jne %%print_char

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