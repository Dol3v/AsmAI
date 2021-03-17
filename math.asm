
; Different mathematical functions used in the AI.

%include "util.asm"

RECIP_LOG2E equ 0x3fe62e42feffbb3c ; approx. 0.69314, or 1/log_2(e)
ONE_OVER_MANTISSA_LENGTH equ 0x3cb0000000000000 ;approx. 1/2^52, where 52 is the size of the mantissa in the double format
LOG_SHIFT_FACTOR equ 0x408FF8582319E07C ;shifting constant for logarithm approximation

section .text

    ; Returns a random integer that can occupy up to 30 bits using a linear congruential generator.
    ; TODO: change to vectorized version for better performance.
    ; 
    ; An LCG takes a seed X_n, and generates the pseudo-random number
    ; LCG(X_n) = X_{n+1} = aX_n + c (mod m).
    ;
    ; Used parameters are taken from glibc: 
    ;   a = 1103515245
    ;   m = 2147483648
    ;   c = 12345
    ;
    ; TODO: expand range
    ; param seed: an integer containing X_n.
    GetRandomInteger:
        push rbp
        mov rbp, rsp
        push rax
        push rcx
        push rdx

        mov rax, [rbp+8*2] ;seed
        mov rcx, 2147483648 ;m
    
        mov rax, 1103515245 ;a
        mul rdx ;rdx:rax = aX_n
        add rax, 12345 ;rdx:rax = aX_n + c
        div rcx ;rdx = X_{n+1}

        mov [rbp+8*2], rdx ;outputting to stack

        pop rax
        pop rcx
        pop rdx
        pop rbp
    ret 1*8

    ; Computes an array of four pseudo-random doubles between 0 and 1 using a LCG,
    ; and updates the seeds in memory.
    ;
    ; param seeds: an offset pointing at four dwords to be used as seeds.
    GetRandomDouble:
        push rbp
        mov rbp, rsp
        AVXPUSH ymm0
        push rcx
        push rbx

        mov rbx, [rbp+8*2] ;seed offsets
        mov rcx, 4 ;loop counter

    GetRandomDouble_main_loop: ;updating seeds in mem
        push rax
        call GetRandomInteger
        pop rax ;rax contains a new random integer
        mov [rbx], rax ;inserting a new random to mem
        add rbx, 4
        loop GetRandomDouble_main_loop

        sub rbx, 4*3 ;resetting rbx to original offset
        vcvtdq2pd ymm0, [rbx] ;converting integer array to double array
        vrcp14pd ymm0, ymm0 ;highly-temporary solution that uses AVX512 for a fast approximation of a recipocal.

        pop rbx
        pop rcx
        AVXPOP ymm0
        pop rax
        pop rbp
    ret 1*8

    ; Definitely the most awesome log macro that exists. 
    ;
    ; Calculates log_2(x) using floating point bit magic. More specifically,
    ;
    ; log2(x) = Ix/L - (bias - log_approx_factor)
    ;
    ; param: input, AVX register
    ; param: a helper xmm register
    ; param: a helper AVX register
    ; returns input: returns log_2(input)
    %macro LOG2 3
        push rax
        mov rax, ONE_OVER_MANTISSA_LENGTH ;scaling factor
        vmovq %2, rax
        vbroadcastsd %3, %2
        vpmuludq %1, %1, %3

        mov rax, LOG_SHIFT_FACTOR ;scaling factor
        vmovq %2, rax
        vbroadcastsd %3, %2
        vpaddq %1, %1, %3 
        pop rax
    %endmacro
