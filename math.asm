
; Different mathematical functions used in the AI.

%include "util.asm"

; Immediates for AVX operations
TRANCTUATE_NORMAL equ 0011b ; For vroundpd: trancuate, don't use control word settings

; General constants 
SIGN_BIT_SET equ 0x8000000000000000

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

    .main_loop: ;updating seeds in mem
        push rax
        call GetRandomInteger
        pop rax ;rax contains a new random integer
        mov [rbx], rax ;inserting a new random to mem
        add rbx, 4
        loop .main_loop

        sub rbx, 4*3 ;resetting rbx to original offset
        vcvtdq2pd ymm0, [rbx] ;converting integer array to double array
        vrcp14pd ymm0, ymm0 ;highly-temporary solution that uses AVX512 for a fast approximation of a recipocal.

        pop rbx
        pop rcx
        AVXPOP ymm0
        pop rax
        pop rbp
    ret 1*8

    ; A macro for calculating dot product between two ymm registers.
    ; *Note: result is in the low 64 bits of the destination.
    ;
    ; param %1: destination of calculation
    ; param %2, %3: operands
    ; param %4: corresponding xmm register of %1
    ; param %5: a (different) xmm register
    %macro DOTPROD 5
        vmulpd %1, %2, %3 ;dest = [x1*y1,...,x4*y4]
        vhaddpd %1, %1, %1 ;dest = [x1*y1+x2*y2, x1*y1+x2*y2, x3*y3+x4*y4, x3*y3+x4*y4]
        vextractf128 %5, %1, 1b ;temp = [x3*y3+x4*y4, same]
        vaddpd %4, %4, %5 ;dest = [x3*y3+x4*y4+x1*y1, same, garbage]
    %endmacro

    ; Calculates the fractional part of a vector.
    ;
    ; param %1: the input/output AVX register
    ; param %2: a helper AVX register
    %macro FRACTIONAL 2
        vroundpd %2, %1, TRANCTUATE_NORMAL
        vsubpd %1, %1, %2
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
