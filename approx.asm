
; Approximations of different mathematical functions: exponent, logarithm, etc.

%include "math.asm"

; General floating point format constants
MANTISSA_LEN equ 53
BIAS_F equ 0x408ff80000000000 
BIAS_F_DEC equ 0x408ff00000000000


; Taylor coefficents for 2^x - x
POW2_ZERO_TAYLOR equ 0x3ff0000000000000
POW2_FIRST_TAYLOR equ 0xbfd3a37a020b8c22
POW2_SECOND_TAYLOR equ 0x3fcebfbdff82c58e
POW2_THIRD_TAYLOR equ 0x3fac6b08d704a0be
POW2_FOURTH_TAYLOR equ 0x3f83b2ab6fba4e76

section .text

    ; Helper for POW2 macro: approximates 2^x - x using Taylor series evaluation.
    ; 
    ; param %1: input
    ; param %2: AVX helper
    ; param %3: xmm helper (disjoint from %2 and %3)
    ; param %4: other AVX helper
    %macro _TAYLOR_HELPER_POW2 4
        vpxor %2, %2, %2 ;zero helper: used to temporarily store result

        mov rax, POW2_FOURTH_TAYLOR
        BROADCASTREG %4, rax, %3
        vmulpd %2, %1, %4 ;result = a_4*x

        mov rax, POW2_THIRD_TAYLOR
        BROADCASTREG %4, rax, %3
        vaddpd %2, %2, %4 ;result = a_3 + a_4*x
        vmulpd %2, %2, %1 ;result = a_3*x + a_4*x^2

        mov rax, POW2_SECOND_TAYLOR
        BROADCASTREG %4, rax, %3
        vaddpd %2, %2, %4 ;result = a_2 + a_3*x + a_4*x^2
        vmulpd %2, %2, %1 ;result = a_2*x + a_3*x^2 + a_4*x^3

        mov rax, POW2_FIRST_TAYLOR
        BROADCASTREG %4, rax, %3
        vaddpd %2, %2, %4 ;result = a_1 + a_2*x + a_3*x^2 + a_4*x^3
        vmulpd %2, %2, %1 ;result = a_1*x + a_2*x^2 + a_3*x^3 + a_4*x^4

        mov rax, POW2_ZERO_TAYLOR
        BROADCASTREG %4, rax, %3
        vaddpd %1, %2, %4 ;%1 = result = a_0 + a_1*x + a_2*x^2 + a_3*x^3 + a_4*x^4
    %endmacro

    ; Calculates 2^x.
    ;
    ; param %1: input
    ; param %2: AVX helper
    ; param %3: xmm helper (disjoint from used AVX regs)
    ; param %4: AVX other helper
    ; param %5: AVX other helper
    %macro POW2 5
    ; Notice that when interperting 2^x as an integer, we get that
    ; 
    ; I_(2^x) = 2**L(x + B - 1 + 2^(x - floor(x)) + floor(x) - x)
    ;
    ; We can use Taylor approx. to find that in the range (-1, 1), a fourth order approx. is at max 0.1% wrong!
    ;
    ; f(x) = 1 + (ln(2) - 1)x + 1/2(ln(2)^2)x^2 + 1/6(ln(2)^3)x^3 + 1/24(ln(2)^4)x^4 + O(x^5)
    ;
    ; Hence, we use this approximation in our code.
        push rax
        mov rax, BIAS_F_DEC
        BROADCASTREG %2, rax, %3
        vmovupd %5, %1 ;copy of input
        vaddpd %1, %1, %2 ;x + B - 1

        FRACTIONAL %5, %2 ;%1 = x - floor(x)
        _TAYLOR_HELPER_POW2 %5, %2, %3, %4
        vaddpd %1, %1, %5 ;%1 = x + B - 1 + f(x - floor(x)) = 1 + B - 1 + f({x})
        vpslldq %1, %1, MANTISSA_LEN ; %1 = 2**L * (x + B - 1 + f({x}))
        pop rax
    %endmacro
