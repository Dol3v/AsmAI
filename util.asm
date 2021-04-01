
; Useful macros for the rest of the code

section .text

    STDOUT_HNDL equ 1 ;handle for standard output
    END_CHAR equ "$" ;end char for printing

    YMM_BYTE_LENGTH equ 32

    ; Prints a string to the screen.
    ;
    ; Note: the string should terminate at END_CHAR.
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
        cmp byte [rsi], END_CHAR
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
        sub rsp, YMM_BYTE_LENGTH
        vmovupd [rsp], %1
    %endmacro 

    ; Pops an AVX register from the stack.
    ;
    ; param: the AVX register
    %macro AVXPOP 1
        vmovupd %1, [rsp]
        add rsp, YMM_BYTE_LENGTH
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
    %macro AVXPOP5 0
        AVXPOP ymm4
        AVXPOP ymm3
        AVXPOP ymm2
        AVXPOP ymm1
        AVXPOP ymm0
    %endmacro

    ; Pushes several frequently used registers.
    %macro PUSHREGS 0
        push rbp
        mov rbp, rsp
        push rax
        push rbx
        push rcx
        push rdx
        push rdi
        push rsi
    %endmacro

    ; Pops several frequently used registers.
    %macro POPREGS 0
        pop rsi
        pop rdi
        pop rdx
        pop rcx
        pop rbx
        pop rax
        pop rbp
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
