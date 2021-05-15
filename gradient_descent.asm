
; Computes the derivatives of the cost function with respect to different weights and biases.

%include "neural_net.asm"
%include "derivatives.asm"
%include "loss.asm"

DOUBLE_BYTE_LENGTH equ 8

section .text

    ; Calculates the initial derivatives of the weights and biases in the last 
    ; layer w.r.t the cost function.
    ;
    ; param 1: output' offset for last layer
    ; param 2: derivative z's offset for last layer
    ; param 3: expected output offset
    InitialLoadingOfDerivatives:
        PUSHREGS 
        AVXPUSH5
        mov rax, [rbp+8*2] ;expected output
        mov rsi, [rbp+8*3] ;derivative zs
        mov rbx, [rbp+8*4] ;outputs

        vpxor ymm0, ymm0, ymm0
        vmovupd xmm0, [rbx] ;ymm0 contains outputs
        vpxor ymm1, ymm1, ymm1
        vmovupd xmm1, [rax] ;ymm1 contains expected

        ; MSE_DER ymm0, ymm1, ymm2, xmm2 ;calculate loss derivative
        vmovupd [rsi], ymm0 ;output to memory
        SIGMOID_DER ymm0, xmm1, ymm2, ymm3, ymm4

        vmulpd ymm0, ymm0, [rsi] ;derivative with respect to zs
        vmovupd [rsi], ymm0 ;saving in memory

        mov rbx, rsi ;copy of rsi
        sub rsi, SECOND_HIDDEN_LAYER_SIZE*YMM_BYTE_LENGTH*OUTPUT_SIZE ;weights address
        mov rdi, rsi ;copy of weights address 
        sub rsi, SECOND_HIDDEN_LAYER_SIZE*YMM_BYTE_LENGTH ;activation length

        vmovq rcx, xmm0 ;first output node's derivative
        vpextrq rdx, xmm0, 1b ;extract upper half
        BROADCASTREG ymm1, rcx, xmm1
        BROADCASTREG ymm2, rdx, xmm2 ;broadcasting
        
        vmovupd ymm0, [rsi] ;activations
        vmulpd ymm1, ymm0, ymm1 
        vmulpd ymm2, ymm0, ymm2 ;derivatives wrt weights

        vmovupd [rdi], ymm1 
        add rdi, OUTPUT_SIZE*SECOND_HIDDEN_LAYER_SIZE*YMM_BYTE_LENGTH ;upper half
        vmovupd [rdi], ymm2 ;outputting to memory

        AVXPOP5
        POPREGS
    ret 3*8

    ; Calculates the derivatives of the biases, given that the derivatives of the previous 
    ; layers have been calculated.
    ;
    ; param bias_der_offset: the offset of the bias derivatives
    ; param der_zs_offset: the zs derivative offset of the previous layer
    ; param output_size: the output size of the layer (bytes)
    ; param input_size: the input size of the layer (bytes)
    CalcDerBiases:
        PUSHREGS
        AVXPUSH ymm0
        AVXPUSH ymm1
        AVXPUSH ymm2
        AVXPUSH ymm3

        mov rax, ONE_F
        BROADCASTREG ymm1, rax, xmm1
        vpxor ymm2, ymm2, ymm2 ;accumulator for zs der
        vpxor ymm3, ymm3, ymm3 ;helper for dot product

        mov rax, [rbp+8*2] ;input size
        mov rbx, [rbp+8*3] ;output size
        mov rcx, [rbp+8*4] ;zs derivative offset
        mov rdx, [rbp+8*5] ;bias derivatives offset
        xor rsi, rsi ;loop counter


        .calc_sum_zs_der:
            vmovupd ymm0, [rcx + rsi] ;get zs der
            DOTPROD ymm0, ymm0, ymm1, xmm0, xmm3
            vaddsd xmm2, xmm2, xmm0 ;accumulate
            add rsi, YMM_BYTE_LENGTH
            cmp rsi, rbx
            jne .calc_sum_zs_der

        xor rsi, rsi ;loop counter
        .move_to_biases_der:
            vmovsd [rdx + rsi], xmm2
            add rsi, DOUBLE_BYTE_LENGTH
            cmp rsi, rax
            jne .move_to_biases_der

        AVXPOP ymm3
        AVXPOP ymm2
        AVXPOP ymm1
        AVXPOP ymm0
        POPREGS
    ret 4*8 

    ; Calculates the derivative of the cost function wrt the activation function.
    ;
    ; param activation_der_offset
    ; param zs_der_offset
    ; param weights: the offset of the weights of the layer
    ; param input_size (bytes)
    ; param output_size (bytes)
    CalcDerActivation:
        PUSHREGS
        AVXPUSH5

        mov rax, ONE_F
        BROADCASTREG ymm1, rax, xmm1 ;ones
        vpxor ymm2, ymm2, ymm2 ;accumulator
        vpxor ymm3, ymm3, ymm3 ;helper for dot prod

        mov rax, [rbp+8*2] ;output size
        mov rbx, [rbp+8*3] ;input size
        mov rcx, [rbp+8*4] ;weights offset
        mov rdx, [rbp+8*5] ;zs der
        mov rsi, [rbp+8*6] ;activation der
        xor rdi, rdi ;loop counter

        .calc_sum_zs_der:
            vmovupd ymm0, [rcx + rdi] ;get zs der
            DOTPROD ymm0, ymm0, ymm1, xmm0, xmm3
            vaddsd xmm2, xmm2, xmm0 ;accumulate
            add rdi, YMM_BYTE_LENGTH
            cmp rdi, rax
            jne .calc_sum_zs_der

        vmovq rdi, xmm2
        BROADCASTREG ymm2, rdi, xmm2 ;broadcast zs der to all entries of ymm2
        xor rdi, rdi ;loop counter 2

        .calc_activation_der:
            ; vmovupd ymm0, []
        POPREGS
        AVXPOP5
    ret 5*8
    
    ; Calculates the derivative of the zs assuming the derivatives wrt
    ; the activation function have been calculated.
    ;
    ; param zs_der
    ; param activation_der
    ; param zs: the zs of the layer (offset)
    ; param input_size (bytes)
    CalcZsDer:
        PUSHREGS
        AVXPUSH5
        AVXPUSH ymm5

        mov rax, [rbp+8*2] ;input size
        mov rbx, [rbp+8*3] ;zs
        mov rcx, [rbp+8*4] ;activation der
        mov rdx, [rbp+8*5] ;zs der
        xor rsi, rsi ;loop counter

        .calc_zs_der:
            vmovupd [rcx+rsi], ymm0 ;activation ders
            vmovupd [rbx+rsi], ymm1 ;zs
            SIGMOID_DER ymm1, xmm2, ymm3, ymm4, ymm5 ;derivative of sigmoid wrt zs
            vmulpd ymm0, ymm1, ymm0 ;zs der
            vmovupd [rdx+rsi], ymm0 ;outputting

            add rsi, YMM_BYTE_LENGTH
            cmp rsi, rax 
            jne .calc_zs_der

        AVXPOP ymm5
        AVXPOP5
        POPREGS
    ret 4*8

    ; Calculates the derivative of the cost function wrt the weights.
    ;
    ; param weight_der
    ; param zs_der
    ; param activations for prev layer
    ; param output size (bytes)
    ; param prev layer input size (bytes)
    CalcWeightDer:
        PUSHREGS
        push r8
        push r9
        AVXPUSH ymm0
        AVXPUSH ymm1

        mov rax, [rbp+8*2] ;prev layer input size (bytes)
        mov rbx, [rbp+8*3] ;output size (bytes)
        mov rcx, [rbp+8*4] ;prev activation offset
        mov rdx, [rbp+8*5] ;zs der offset
        mov rdi, [rbp+8*6] ;weight der offset

        xor r9, r9 ;loop counter over all weights
        xor rsi, rsi ;loop counter over input
    .loop_over_input_layer:
        xor r8, r8 ;loop over prev
        .loop_over_prev_layer:
            vmovupd ymm0, [rdx+rsi] ;zs der
            vmovupd ymm1, [rcx+r8] ;prev activation
            vmulpd ymm0, ymm1, ymm0 ;weight der
            vmovupd [rdi+r9], ymm0 ;outputting

            add r9, YMM_BYTE_LENGTH
            add r8, YMM_BYTE_LENGTH
            cmp r8, rax
            jne .loop_over_prev_layer
        add rsi, YMM_BYTE_LENGTH
        cmp rsi, rbx
        jne .loop_over_input_layer

        AVXPOP ymm1
        AVXPOP ymm0
        pop r8
        POPREGS
    ret 4*8

    ; Backpropagates a layer, which is not the last one.
    ;
    ; param input offset 
    ; param der input offset
    ; param input size (not bytes)
    ; param output size (not bytes)
    ; param prev layer input size (not bytes)
    BackpropLayer:
        PUSHREGS
        
        mov rax, [rbp+8*2] ;prev input size
        mov rbx, [rbp+8*3] ;output size
        mov rcx, [rbp+8*4] ;input size
        mov rdx, [rbp+8*5] ;output offset
        mov rdi, [rbp+8*6] ;input offset


        POPREGS
    ret 4*8
