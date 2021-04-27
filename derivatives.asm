
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
        SIGMOID %1, %2, %3, %4, %5
        push rax
        mov rax, ONE_F
        BROADCASTREG %3, rax, %2 ;%3 = 1
        pop rax
        vsubpd %3, %3, %1 ;%3 = 1 - sigmoid(x)
        vmulpd %1, %1, %3 ;%1 = sigmoid(x)(1-sigmoid(x)) = sigmoid'(x)
    %endmacro
    