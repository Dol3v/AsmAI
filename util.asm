
; Useful macros for the rest of the code

%ifndef UTILS
    %define UTILS 
    STDOUT_HNDL equ 1 ;handle for standard output
    END_CHAR equ "$" ;end char for printing

    YMM_BYTE_LENGTH equ 32
    DOUBLE_BYTE_LENGTH equ 8
    ZERO_ASCII_VAL equ 48

    ONE_F equ 0x3ff0000000000000
    TEN_F equ 0x4024000000000000

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

    ; Converts an ascii character to an integer.
    ;
    ; param: character, stored in register
    ; returns: integer from char, stored in %1.
    %macro CHAR_TO_INT 1
        sub %1, ZERO_ASCII_VAL
    %endmacro

    ; Converts a string of a double to a double.
    ;
    ; Example: "3.6216" -> 0x400cf9096bb98c7e
    ;
    ; param 1: decimal start offset
    ; param 2: decimal end offset
    ; param 3: output register
    %macro STRING2DOUBLE 3
        AVXPUSH ymm0
        AVXPUSH ymm1
        AVXPUSH ymm2
        push rbx
        push rax
        push rsi

        vpxor ymm0, ymm0, ymm0 ;accumulator for powers of ten
        mov rax, ONE_F
        vmovq xmm2, rax

        vpxor ymm1, ymm1, ymm1 ;stores number
        vpxor ymm2, ymm2, ymm2 
        mov rax, TEN_F
        vmovq xmm2, rax ;ymm2 contains ten
        
        mov rbx, %2
        mov rsi, %1
        dec rsi ;one byte before start offset

    %%loop_over_chars:
        xor rax, rax
        mov al, [rbx]
        cmp al, "-"
        je %%negate_result

        cmp al, "."
        je %%finish_loop
        
        CHAR_TO_INT al ;get integer
        cvtsi2sd xmm1, rax ;convert to float
        vmulsd ymm1, ymm0, ymm1 ;multiply by power of ten
        vaddsd ymm1, ymm2, ymm1 ;accumulate

        vmulpd ymm0, ymm0, ymm2 ;mult by 10

    %%finish_loop:
        dec rbx
        cmp rbx, rsi
        jne %%loop_over_chars
        jmp %%finish_macro

    %%negate_result:
        NEGATE ymm1, xmm1, ymm2

    %%finish_macro:
        vdivsd ymm1, ymm1, ymm0 ;divide by powers of ten
        vmovq %1, xmm1 ;outputting 

        pop rsi
        pop rax
        pop rbx
        AVXPOP ymm2
        AVXPOP ymm1
        AVXPOP ymm0
    %endmacro

    ; Negates a number, i.e, multiplies it by -1.
    ;
    ; param %1: input/output
    ; param %2: helper xmm register, not disjoint from %3
    ; param %3: helper AVX register
    %macro NEGATE 3
        push rax
        mov rax, SIGN_BIT_SET
        BROADCASTREG %3, rax, %2
        vxorpd %1, %1, %3
        pop rax
    %endmacro
%endif
