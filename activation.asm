
; Contains all of the used activation functions

%include "math.asm"

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
    ; param 1: x, input/output
    ; param 2: helper xmm
    ; param 3: helper AVX
    ; param 4: other helper AVX
    %macro SIGMOID 4
        NEGATE %1, %2, %3
        EXP %1, %3, %2, %4 ;%1 = e^-x
        push rax
        mov rax, ONE_F
        BROADCASTREG %3, rax, %2 ;%3 = 1
        vaddpd %1, %1, %3 ;%1 = e^(-x)+1
        vrcp14pd %1, %1 ;%1 = sigmoid(x)
        pop rax
    %endmacro

    ; Calculates the sigmoid function on an array of doubles in memory.
    ;
    ; Note: the length of the array must be divisible by 4
    ;
    ; see SIGMOID macro
    ; param 1 start address: the start address of the array
    ; param 2 end address: the end address of the array
    Sigmoid:
        push rbp
        mov rbp, rsp
        AVXPUSH5
        push rbx
        push rsi

        mov rbx, [rbp+8*3] ;start address
        mov rsi, [rbp+8*2] ;end address

    .main_loop:
        vmovupd ymm0, [rbx]
        SIGMOID ymm0, xmm1, ymm2, ymm3
        vmovupd [rbx], ymm0

        add rbx, YMM_BYTE_LENGTH
        cmp rbx, rsi
        jne .main_loop

        pop rsi
        pop rbx
        AVXPOP5 
        pop rbp
    ret 2*8

    ; Calculates the ReLu function on an array of doubles in memory.
    ;
    ; Note: the length of the array must be divisible by 4
    ;
    ; see RELU macro
    ; param 1 start address: the start address of the array
    ; param 2 end address: the end address of the array
    ReLu:
        push rbp
        mov rbp, rsp
        AVXPUSH ymm0
        AVXPUSH ymm1
        push rbx
        push rsi

        mov rbx, [rbp+8*3] ;start address
        mov rsi, [rbp+8*2] ;end address

    .main_loop:
        vmovupd ymm0, [rbx]
        RELU ymm0, ymm1
        vmovupd [rbx], ymm0

        add rbx, 4*64
        cmp rbx, rsi
        jne .main_loop

        pop rsi
        pop rbx
        AVXPOP ymm1
        AVXPOP ymm0
        pop rbp
    ret 2*8
