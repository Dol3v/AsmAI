
; Approximations of different mathematical functions: exponent, logarithm, etc.

%include "math.asm"
%include "util.asm"

; Constants for continued fraction of e^x
ONE_F equ 0x3ff0000000000000
TWO_F equ 0x4000000000000000
SIX_F equ 0x4018000000000000
TEN_F equ 0x4024000000000000

section .text

; Calculates e^x.
;
; param %1: input
; param %2: helper xmm register (disjoint from %3)
; param %3: helper AVX register
; param %4: other helper AVX register
; param %5: other helper AVX register
%macro EXP 5
; Instead of using floating-point evil bit hacking and Taylor series, we use continued fractions to 
; approximate e^x:
;
; e^x = 1 + (2x) / (2 - x + x**2/(6 + x**2/10))
    push rax
    vmulpd %5, %1, %1 ;%5 contains frequently used constants
    mov rax, TEN_F
    BROADCASTREG %4, rax, %2 ;%4 helper register
    vdivpd %3, %5, %4 ;TODO: check for correctness, x^2/10 in result

    mov rax, SIX_F
    BROADCASTREG %4, rax, %2 ;%4 = 6
    vaddpd %3, %3, %4 ;result = 6 + x^2/10
    vdivpd %3, %5, %3 ;result = x^2/(6 + x^2/10)

    mov rax, TWO_F
    BROADCASTREG %4, rax, %2 ;%4 = 2
    vaddpd %3, %3, %4 ;result = 2 + x^2/(6 + x^2/10)
    vsubpd %3, %3, %1 ;result - 2 - x + x^2/(6 + x^2/10)
    vmulpd %1, %4, %1 ;%1 = 2x

    vdivpd %1, %1, %3 ;%1 = result = 2x/(2 - x + x^2/(6 + x^2/10))
    mov rax, ONE_F
    BROADCASTREG %4, rax, %2 ;%4 = 1
    vaddpd %1, %1, %4 ;result = 1 + (2x/(2 - x + x^2/(6 + x^2/10)))
    pop rax
%endmacro
