
; Contains functions for forward propagtion.

%include "math.asm"

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
