
; Computes the derivatives of the cost function with respect to different weights and biases.

%include "neural_net.asm"
%include "derivatives.asm"
%include "loss.asm"

section .data

; Stores derivatives of cost function
der_nn_weights_1 times INPUT_SIZE*4*YMM_BYTE_LENGTH*FIRST_HIDDEN_LAYER_SIZE*4 dq 0 ;weights
der_nn_biases_1 times FIRST_HIDDEN_LAYER_SIZE*4*YMM_BYTE_LENGTH dq 0 ;biases
der_nn_zs_1 times FIRST_HIDDEN_LAYER_SIZE*4*YMM_BYTE_LENGTH dq 0 ;outputs, without activation

der_nn_inputs_2 times FIRST_HIDDEN_LAYER_SIZE*4*YMM_BYTE_LENGTH dq 0 ;first hidden layer inputs
der_nn_weights_2 times FIRST_HIDDEN_LAYER_SIZE*4*YMM_BYTE_LENGTH*SECOND_HIDDEN_LAYER_SIZE*4 dq 0 ;weights
der_nn_biases_2 times SECOND_HIDDEN_LAYER_SIZE*4*YMM_BYTE_LENGTH dq 0 ;biases
der_nn_zs_2 times SECOND_HIDDEN_LAYER_SIZE*4*YMM_BYTE_LENGTH dq 0 ;outputs, without activation

der_nn_inputs_3 times SECOND_HIDDEN_LAYER_SIZE*4*YMM_BYTE_LENGTH dq 0 ;output layer inputs
der_nn_weights_3 times SECOND_HIDDEN_LAYER_SIZE*4*YMM_BYTE_LENGTH*2 dq 0 ;weights
der_nn_zs_3 times OUTPUT_SIZE*YMM_BYTE_LENGTH dq 0 ;outputs, without activation
der_padding times 2*YMM_BYTE_LENGTH dq 0 ;padding

; Stores averages of derivatives of cost function
avg_nn_weights_1 times INPUT_SIZE*4*YMM_BYTE_LENGTH*FIRST_HIDDEN_LAYER_SIZE*4 dq 0 ;weights
avg_nn_biases_1 times FIRST_HIDDEN_LAYER_SIZE*4*YMM_BYTE_LENGTH dq 0 ;biases
avg_nn_zs_1 times FIRST_HIDDEN_LAYER_SIZE*4*YMM_BYTE_LENGTH dq 0 ;outputs, without activation

avg_nn_inputs_2 times FIRST_HIDDEN_LAYER_SIZE*4*YMM_BYTE_LENGTH dq 0 ;first hidden layer inputs
avg_nn_weights_2 times FIRST_HIDDEN_LAYER_SIZE*4*YMM_BYTE_LENGTH*SECOND_HIDDEN_LAYER_SIZE*4 dq 0 ;weights
avg_nn_biases_2 times SECOND_HIDDEN_LAYER_SIZE*4*YMM_BYTE_LENGTH dq 0 ;biases
avg_nn_zs_2 times SECOND_HIDDEN_LAYER_SIZE*4*YMM_BYTE_LENGTH dq 0 ;outputs, without activation

avg_nn_inputs_3 times SECOND_HIDDEN_LAYER_SIZE*4*YMM_BYTE_LENGTH dq 0 ;output layer inputs
avg_nn_weights_3 times SECOND_HIDDEN_LAYER_SIZE*4*YMM_BYTE_LENGTH*2 dq 0 ;weights
avg_nn_biases_3 times OUTPUT_SIZE*YMM_BYTE_LENGTH dq 0 ;outputs, without activation
avg_nn_output times OUTPUT_SIZE*YMM_BYTE_LENGTH dq 0 ;neural net output

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

        MSE_DER ymm0, ymm1, ymm2, xmm2 ;calculate loss derivative
        vmovupd [rsi], ymm0 ;output to memory
        SIGMOID_DER ymm0, xmm1, ymm2, ymm3, ymm4

        vmulpd ymm0, ymm0, [rsi] ;derivative with respect to zs
        vmovupd [rsi], ymm0 ;saving in memory

        mov rbx, rsi ;copy of rsi
        sub rsi, SECOND_HIDDEN_LAYER_SIZE*4*YMM_BYTE_LENGTH*2 ;weights address
        mov rdi, rsi ;copy of weights address 
        sub rsi, SECOND_HIDDEN_LAYER_SIZE*4*YMM_BYTE_LENGTH ;activation length

        vmovq rcx, xmm0 ;first output node's derivative
        vpextrq rdx, xmm0, 1b ;extract upper half
        BROADCASTREG ymm1, rcx, xmm1
        BROADCASTREG ymm2, rdx, xmm2 ;broadcasting
        
        vmovupd ymm0, [rsi] ;activations
        vmulpd ymm1, ymm0, ymm1 
        vmulpd ymm2, ymm0, ymm2 ;derivatives wrt weights

        vmovupd [rdi], ymm1 
        add rdi, 2*SECOND_HIDDEN_LAYER_SIZE*4*YMM_BYTE_LENGTH ;upper half
        vmovupd [rdi], ymm2 ;outputting to memory

        AVXPOP5
        POPREGS
    ret 3*8
