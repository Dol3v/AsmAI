
; Contains functions for forward propagtion.

%include "math.asm"
%include "linalg.asm"

%ifndef FORWARD_PROP
%define FORWARD_PROP
; used constants
DOUBLE_BYTE_LENGTH equ 8

section .text

    ; Fills a hidden layer with random numbers.
    ; 
    ; Note: the layer's length must be divisible by 4.
    ;
    ; param 1 start addrs: the starting address of the layer
    ; param 2 end addrs: the end address of the layer
    ; param 3 seeds: address to seeds used
    InitilizeHiddenLayer:
        push rbp
        mov rbp, rsp
        push rbx
        push rsi
        push rdi
        AVXPUSH ymm0

        mov rbx, [rbp+8*4] ;start address
        mov rsi, [rbp+8*3] ;end address
        mov rdi, [rbp+8*2] ;seeds

    .main_loop:
        AVXPUSH ymm0
        push rdi
        call GetRandomDouble
        AVXPOP ymm0 ;ymm0 contains random doubles

        vmovupd [rbx], ymm0 ;writing random numbers to memory
        add rbx, YMM_BYTE_LENGTH
        cmp rbx, rsi
        jne .main_loop

        AVXPOP ymm0
        pop rdi
        pop rsi
        pop rbx
        pop rbp
    ret 3*8

    ; Forward propagates a layer.
    ;
    ; Note: number of inputs must be divisible by 4
    ;
    ; param 1 start addrs: the starting address of the layer
    ; param 2 input size: the size of the input vector (in bytes)
    ; param 3 output size: the size of the output vector 
    ; param 4 output start addrs: the start of the output vector
    ; ForwardPropagate:
    ;     PUSHREGS
    ;     AVXPUSH5
    ;     push r8

    ;     mov rbx, [rbp+8*2] ;output start
    ;     mov rax, [rbp+8*3] ;output size 
    ;     mov rcx, [rbp+8*4] ;input size (bytes)
    ;     mov rdi, [rbp+8*5] ;input address
    ;     mov r8, rbx ;copy of thr output addrs

    ;     push rax
    ;     mul rcx
    ;     xor rdx, rdx
    ;     mov rsi, rax ;rsi = input*output size
    ;     pop rax 

    ;     mov rdx, rdi
    ;     add rdx, rcx ;rdx is the weights address
    ;     mov rcx, rdx ;input size isn't used anymore, so rcx saves initial weights address

    ;     add rsi, rdx ;rsi is the biases address

    ; .main_loop:
    ;     push rdi
    ;     .dot_product: ;calculate the dot product of the input vector and weights vector
    ;         vmovupd ymm1, [rdi] ;input subvector
    ;         vmovupd ymm2, [rdx] ;weight subvector
    ;         DOTPROD ymm3, ymm1, ymm2, xmm3, xmm4
    ;         vaddsd xmm0, xmm0, xmm3 ;accumulate dot product in ymm0

    ;         add rdi, YMM_BYTE_LENGTH
    ;         add rdx, YMM_BYTE_LENGTH
    ;         cmp rdi, rcx ;have we covered all input vectors?
    ;         jne .dot_product

    ;     pop rdi ;restore input offset
    ;     vaddsd xmm0, xmm0, [rsi] ;add bias
    ;     vmovsd [rbx], xmm0 ;outputting

    ;     add rsi, DOUBLE_BYTE_LENGTH
    ;     add rbx, DOUBLE_BYTE_LENGTH
    ;     cmp rsi, r8 ;have we covered all biases?
    ;     jne .main_loop

    ;     pop r8
    ;     AVXPOP5
    ;     POPREGS
    ; ret 4*8

    ; Forward propagates a layer.
    ;
    ; The weight matrix should be ordered via the output, i.e, the w_{jk} should correspond to the weight
    ; connecting a_k from layer l, and a_j from layer l+1. Seems counter-intuitive, but after wasting 10 hours on backprop
    ; and 5 hours on forwardprop with the reverse being true,  I can safetly say - it's not. More formally, 
    ; it allows forward prop to be represented by matrix multiplication, and gives way to calculation on multiple data entries.
    ;
    ; param 1: input offset
    ; param 2: weight martix offset
    ; param 3: bias offset
    ; param 4: zs offset
    ; param 5: input size (bytes)
    ; param 6: output size (bytes)
    ForwardPropagateLayer:
        PUSHREGS

        mov rax, [rbp+8*2] ;output size
        mov rbx, [rbp+8*3] ;input size
        mov rcx, [rbp+8*4] ;zs offset
        mov rdx, [rbp+8*5] ;bias offset
        mov rdi, [rbp+8*6] ;weights
        mov rsi, [rbp+8*7] ;input offset

        push rdi
        push rsi
        push rcx
        push rax
        push rbx
        call MatrixVectorMultiply ;weight multiplication

        xor rbx, rbx ;loop counter
        .add_biases:
            vmovupd ymm0, [rcx + rbx] ;w*x
            vaddpd ymm0, ymm0, [rdx + rbx] ;add biases
            vmovupd [rcx + rbx], ymm0 ;update zs

            add rbx, YMM_BYTE_LENGTH
            cmp rbx, rax
            jne .add_biases

        POPREGS
    ret 8*6

%endif