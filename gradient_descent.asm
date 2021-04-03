
; Computes the derivatives of the cost function with respect to different weights and biases.

%include "neural_net.asm"
%include "derivatives.asm"
%include "loss.asm"

DOUBLE_BYTE_LENGTH equ 8

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

    ; Back-propagates a layer.
    ;
    ; TODO: optimize loops: combine weight loop and bias loop to one loop
    ;
    ; param 1: actual layer offset
    ; param 2: derivative layer offset
    ; param 3: input size
    ; param 4: output size
    ; param 5: previous layer's input size
    BackwardsPropagateLayer:
        PUSHREGS
        AVXPUSH5
        AVXPUSH ymm5
        push r8

        mov rax, [rbp+8*3] ;output size
        mov rbx, [rbp+8*4] ;input size
        mov rcx, [rbp+8*5] ;derivatives
        mov rdx, [rbp+8*6] ;layer offset

        mov rdi, ONE_F
        BROADCASTREG ymm2, rdi, xmm2 ;1s register
        vpxor ymm4, ymm4, ymm4 ;accumulator for biases

        xor rdi, rdi ;loop counter
        mov rsi, rcx

        push rax
        push rbx
        push rdx
        inc rax
        inc rbx
        mul rbx

        mov rbx, YMM_BYTE_LENGTH
        mul rbx
        add rsi, rax ;calculate zs derivative offset
        pop rdx
        pop rbx
        pop rax
        .calc_dot_products: ;calculate sum of zs
            vmovupd ymm0, [rsi + YMM_BYTE_LENGTH*rdi] ;move zs derivative
            DOTPROD ymm0, ymm2, ymm1, xmm0, xmm3 ;sum all zs up
            vaddps ymm4, ymm4, ymm0 ;accumulate biases
            add rdi, 4
            cmp rdi, rax ;have we covered all zs?
            jne .calc_dot_products
            
        vmovq r8, xmm4 
        BROADCASTREG ymm4, r8, xmm4 ;broadcast bias derivative
        xor rdi, rdi
        push rax
        push rdx
        push rbx
        mov rbx, YMM_BYTE_LENGTH
        mul rbx
        sub rsi, rax ;update rsi to point at biases
        pop rbx
        pop rdx
        pop rax

        .save_biases_ders: ;save biases' derivatives to memory
            vmovupd [rsi + YMM_BYTE_LENGTH*rdi], ymm4
            add rdi, 4
            cmp rdi, rax
            jne .save_biases_ders
        
        ; update rsi to point at weights
        push rax
        push rbx
        push rdx
        mul rbx
        sub rsi, rax
        pop rdx
        pop rbx
        pop rax
        xor r8, r8 ;counts over outputs
        .save_activation_der:
            vpxor ymm2, ymm2
            xor rdi, rdi ;loop counter for dot prod
            .loop_over_rows: ;loops over all weights matching a specific output nodes
                vmovupd ymm0, [rsi + YMM_BYTE_LENGTH*rdi + YMM_BYTE_LENGTH*rax*r8] ;extract weights
                DOTPROD ymm0, ymm4, ymm1, xmm0, xmm3 ;dotting with bias derivative
                vaddps ymm2, ymm2, ymm0 ;accumulate in ymm2
                add rdi, 4
                cmp rdi, rax
                jne .loop_over_rows

            vmovups [rcx+r8], ymm2 ;outputting to mem
            add r8, DOUBLE_BYTE_LENGTH
            cmp r8, rbx
            jne .save_activation_der
        
        ; update rdx to point at neural zs
        push rax
        push rbx
        push rdx
        inc rax
        inc rbx
        mul rbx

        mov rbx, YMM_BYTE_LENGTH
        mul rbx
        add rdx, rax ;calculate zs offset
        pop rdx
        pop rbx
        pop rax

        mov r8, rsi ;update r8 to point at zs derivative
        push rax
        push rbx
        push rdx

        mul rbx
        add r8, rax
        pop rdx
        pop rbx
        pop rax

        ; update rsi to point at activation derivative
        sub rsi, rbx

        .save_zs_der:
            vmovupd ymm5, [rsi + YMM_BYTE_LENGTH*rdi] ;get activation derivatives
            vmovupd ymm0, [rdx +YMM_BYTE_LENGTH*rdi] ;get zs
            SIGMOID_DER ymm0, xmm1, ymm2, ymm3, ymm4 ;calculate derivatives
            vmulpd ymm0, ymm0, ymm5 ;get zs derivative
            vmovupd [r8 + YMM_BYTE_LENGTH*rdi], ymm0 ;save in memory

            add rdi, 4
            cmp rdi, rax 
            jne .save_zs_der
        
        ; update rdx to point at activations
        sub rdx, rbx
        ; update rsi to point at weight der
        push rax
        push rbx
        push rdx

        mul rbx
        add rsi, rax
        pop rax
        pop rbx
        pop rdx
        
        xor rcx, rcx ;loop counter for rows
        mov rax, [rbp+8*2] ;previous layer's input size
        .calc_weight_der:
            xor rdi, rdi ;loop counter for within a row
            .loop_in_row:
                vmovupd ymm0, [r8 + rdi*YMM_BYTE_LENGTH] ;load z derivatives
                vmovupd ymm1, [rdx + rcx*YMM_BYTE_LENGTH] ;load activations
                vmulpd ymm0, ymm0, ymm1 ;weight derivative
                vmovupd [rsi + rcx*rax*YMM_BYTE_LENGTH + rdi*YMM_BYTE_LENGTH], ymm0 ;load der to memory
                
                add rdi, 4
                cmp rdi, rax
                jne .loop_in_row
            add rcx, 4
            cmp rcx, rbx
            jne .calc_weight_der

        pop r8
        AVXPOP ymm5
        AVXPOP5
        POPREGS
    ret 5*8
