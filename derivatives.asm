
; Derivatives of different activation functions

%include "approx.asm"

section .text

    ; Calculates the derivative of the sigmoid function,
    ; Sigmoid'(x) = e^x/(1+e^x)^2
    ;
    ; param 1: x, input/output
    ; param 2: helper xmm
    ; param 3: helper AVX
    ; param 4: other helper AVX
    ; param 5: other helper AVX
    %macro SIGMOID_DER 5
        EXP %1, %2, %3, %4, %5 ;%1 = e^x
        push rax
        mov rax, ONE_F 
        BROADCASTREG %3, rax, %2 ;%3 = 1 
        pop rax
        vaddpd %3, %3, %1 ;%3 = 1 + e^x

        vmulpd %3, %3, %3 ;%3 = (1 + e^x)^2
        vdivpd %1, %1, %3 ;%1 = e^x/(1 + e^x)^2
    %endmacro
    