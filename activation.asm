
; Contains all of the used activation functions

%include "approx.asm"

section .text

    ; Calculates the ReLu activation function:
    ; 
    ; ReLu(x) = max(x, 0)
    ;
    ; param %1: input/output
    ; param %2: helper AVX register
    %macro RELU 2
        vpxor %2, %2 ;zero helper
        vblendvpd %1, %1, %2, %1 ;if the sign bit is 1, the number is negative hence we move 0.0 to it
    %endmacro

    ; Calculates the sigmoid activation function:
    ;
    ; Sigmoid(x) = 1/(e^(-x) + 1)
    ;
    ; 
    %macro SIGMOID 5
        NEGATE %1, %2, %3
        EXP %1, %2, %3, %4, %5 ;%1 = e^-x
        push rax
        mov rax, ONE_F
        BROADCASTREG %3, rax, %2 ;%3 = 1
        vaddpd %1, %1, %3 ;%1 = e^(-x)+1
        vrcp14pd %1, %1 ;%1 = sigmoid(x)
        pop rax
    %endmacro
