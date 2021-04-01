
; Functions that affect the whole neural network.

%include "forward_prop.asm"
%include "activation.asm"


INPUT_SIZE equ 1
FIRST_HIDDEN_LAYER_SIZE equ 2
SECOND_HIDDEN_LAYER_SIZE equ 1
OUTPUT_SIZE equ 2

section .data
    nueral_net times INPUT_SIZE*4*YMM_BYTE_LENGTH dq 0 ;input layer
    nn_weights_1 times INPUT_SIZE*4*YMM_BYTE_LENGTH*FIRST_HIDDEN_LAYER_SIZE*4 dq 0 ;weights
    nn_biases_1 times FIRST_HIDDEN_LAYER_SIZE*4*YMM_BYTE_LENGTH dq 0 ;biases
    nn_zs_1 times FIRST_HIDDEN_LAYER_SIZE*4*YMM_BYTE_LENGTH dq 0 ;outputs, without activation

    nn_inputs_2 times FIRST_HIDDEN_LAYER_SIZE*4*YMM_BYTE_LENGTH dq 0 ;first hidden layer inputs
    nn_weights_2 times FIRST_HIDDEN_LAYER_SIZE*4*YMM_BYTE_LENGTH*SECOND_HIDDEN_LAYER_SIZE*4 dq 0 ;weights
    nn_biases_2 times SECOND_HIDDEN_LAYER_SIZE*4*YMM_BYTE_LENGTH dq 0 ;biases
    nn_zs_2 times SECOND_HIDDEN_LAYER_SIZE*4*YMM_BYTE_LENGTH dq 0 ;outputs, without activation

    nn_inputs_3 times SECOND_HIDDEN_LAYER_SIZE*4*YMM_BYTE_LENGTH dq 0 ;output layer inputs
    nn_weights_3 times SECOND_HIDDEN_LAYER_SIZE*4*YMM_BYTE_LENGTH*2 dq 0 ;weights
    nn_biases_3 times OUTPUT_SIZE*YMM_BYTE_LENGTH dq 0 ;biases
    nn_zs_3 times OUTPUT_SIZE*YMM_BYTE_LENGTH dq 0 ;outputs, without activation
    nn_output times OUTPUT_SIZE*YMM_BYTE_LENGTH dq 0 ;neural net output

section .text

    ; Forward-propagates a neural net.
    ;
    ; *Assumes used activation function is Sigmoid.
    ;
    ; param 1: input_size offset
    ; param 2: neural_net offset
    ; see: BINARY_NEURAL_NET macro
    ForwardPropagateNetwork:
        PUSHREGS

        mov rbx, [rbp+8*3] ;input_sizes offset
        mov rax, [rbx] ;input size
        mov rcx, [rbx+8] ;layer 1 output size

        mov rdi, [rbp+8*2] ;inputs offset
        mov rsi, rdi ;TODO

        POPREGS
    ret 2*8
