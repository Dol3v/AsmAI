
; Different mathematical functions used in the AI.

section .text

    ; Returns a random integer that can occupy up to 30 bits using a linear congruential generator.
    ; TODO: change to vectorized version for better performance.
    ; 
    ; An LCG takes a seed X_n, and generates the pseudo-random number
    ; LCG(X_n) = X_{n+1} = aX_n + c (mod m).
    ;
    ; Used parameters are taken from glibc: 
    ;   a = 1103515245
    ;   m = 2147483648
    ;   c = 12345
    ;
    ; TODO: expand range
    ; param seed: an integer containing X_n.
    GetRandomInteger:
        push rbp
        mov rbp, rsp
        push rax
        push rcx
        push rdx

        mov rax, [rbp+8*2] ;seed
        mov rcx, 2147483648 ;m
    
        mov rax, 1103515245 ;a
        mul rdx ;rdx:rax = aX_n
        add rax, 12345 ;rdx:rax = aX_n + c
        div rcx ;rdx = X_{n+1}

        mov [rbp+8*2], rdx ;outputting to stack

        pop rax
        pop rcx
        pop rdx
        pop rbp
    ret 1*8
