
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
        vmovupd [rsp], %1
        add rsp, 0x100
    %endmacro

    ; Pushes the registers ymm0 - ymm5 onto the stack.
    %macro AVXPUSH5 0
        AVXPUSH ymm0
        AVXPUSH ymm1
        AVXPUSH ymm2
        AVXPUSH ymm3
        AVXPUSH ymm4
    %endmacro

    ; Pops the registers ymm0 - ymm5 from the stack.
    %macro AVXPUSH5 0
        AVXPOP ymm4
        AVXPOP ymm3
        AVXPOP ymm2
        AVXPOP ymm1
        AVXPOP ymm0
    %endmacro

    ; Broadcasts a 64 bit register to a ymm register.
    ;
    ; param: avx register
    ; param: 64-bit register
    ; param: some xmm register
    %macro BROADCASTREG 3
        vmovq %3, %2
        vbroadcastsd %1, %3
    %endmacro
