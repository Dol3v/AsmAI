
; Different loss functions

%include "math.asm"

TWO_F equ 0x4000000000000000

section .text

    ; Calculates the mean squared loss:
    ; MSE(y_pred, y_true) = \sum_i (y_true - y_pred)^2
    ;
    ; param %1: the predicted output
    ; param %2: the target output
    ; param %3: function's output
    ; param %4: xmm register of %3
    ; param %5: different xmm register
    ; returns: MSE in first 64 bits of %3
    %macro MSE 5
        vsubpd %1,  %1, %2
        DOTPROD %3, %1, %1, %4, %5
    %endmacro

    ; Calculates the derivative of MSE.
    ;
    ; param %1: predicted output
    ; param %2: target output
    ; param %3: helper AVX register
    ; param %4: helper xmm register (not disjoint from helper)
    ; returns: MSE derivative in %1
    %macro MSE_DER 3
        push rax
        mov rax, TWO_F
        BROADCASTREG %3, rax, %2
        pop rax
        vsubpd %1, %1, %2 ;%1 = (output - target)
        vmulpd %1, %1, %3 ;%1 = 2*(output - target)
    %endmacro

    ; Calculates MSE for a binary-classification nueral net.
    ;
    ; param 1: redundant register push
    ; param 2: network's output offset
    ; param 3: target output offset
    ; returns: total MSE on stack
    BinaryMeanSquaredLoss:
        push rbp
        mov rbp, rsp
        push rbx
        push rsi
        AVXPUSH ymm0
        AVXPUSH ymm1
        AVXPUSH ymm2

        mov rbx, [rbp+8*3] ;output offset
        mov rsi, [rbp+8*2] ;target output offset

        vpxor ymm0, ymm0, ymm0
        vpxor ymm1, ymm1, ymm1 
        vmovupd xmm0, [rbx] ;ymm0 contains output
        vmovupd xmm1, [rsi] ;ymm1 contains target

        MSE ymm0, ymm1, ymm0, xmm0, xmm2 ;calculate MSE
        vmovq rbx, ymm0 
        mov [rbp+8*4], rbx ;outputting to stack

        AVXPOP ymm2
        AVXPOP ymm1
        AVXPOP ymm0
        pop rsi 
        pop rbx
        pop rbp
    ret 2*8
