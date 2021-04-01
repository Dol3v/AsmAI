
; Contains functions for forward propagtion.

%include "math.asm"

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
    ; Note: all lengths must be divisible by 4
    ; 
    ; param 1 start addrs: the starting address of the layer
    ; param 2 input size: the size of the input vector
    ; param 3 output size: the size of the output vector
    ; param 4 output start addrs: the start of the output vector
    ForwardPropagate:
        PUSHREGS
        AVXPUSH5

        mov rbx, [rbp+8*2] ;output start
        mov rax, [rbp+8*3] ;output size
        mov rcx, [rbp+8*4] ;input size
        mov rdi, [rbp+8*5] ;input address

        push rax
        mul rcx
        xor rdx, rdx
        mov rsi, rax ;rsi = input*output size
        pop rax 

        mov rdx, rdi
        add rdx, rcx ;rdx is the weights address
        mov rcx, rdx ;input size isn't used anymore, so rcx saves initial weights address

        add rsi, rdx ;rsi is the biases address

    .main_loop:
        push rdi
        .dot_product: ;calculate the dot product of the input vector and weights vector
            vmovupd ymm1, [rdi] ;input subvector
            vmovupd ymm2, [rdx] ;weight subvector
            DOTPROD ymm3, ymm1, ymm2, xmm3, xmm4
            vaddps ymm0, ymm0, ymm3 ;accumulate dot product in ymm0

            add rdi, YMM_BYTE_LENGTH
            add rdx, YMM_BYTE_LENGTH
            cmp rdi, rcx ;have we covered all input vectors?
            jne .dot_product

        pop rdi ;restore input offset
        vaddps ymm0, ymm0, [rsi] ;add bias
        vmovups [rbx], ymm0 ;outputting

        add rsi, DOUBLE_BYTE_LENGTH
        add rbx, DOUBLE_BYTE_LENGTH
        cmp rsi, [rbp+8*3] ;have we covered all biases?
        jne .main_loop

        AVXPOP5
        POPREGS
    ret
