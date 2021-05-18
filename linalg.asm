
; Linear algebra methods to be used in Forward Prop

%include "math.asm"

section .text

; Implements matrix multiplication, rather inefficently, (with O(n^3) time complexity)
; but it's SIMD accelerated and will only apply for small matrices anyways, so who cares?
;
; Assumes the matrix is ordered via rows, i.e, (row | row | row |...|row), and that both contain doubles.
;
; param 1: matrix offset (nxm, m divisible by 4)
; param 2: vector offset (mx1, m divisible by 4)
; param 3: output offset
; param 4: vector length (n, bytes)
; param 5: matrix width (m, bytes)
MatrixVectorMultiply:
    PUSHREGS
    AVXPUSH ymm0
    AVXPUSH ymm1
    AVXPUSH ymm2
    AVXPUSH ymm3
    push r8

    mov rax, ONE_F
    BROADCASTREG ymm3, rax, xmm3 ;vector of ones

    mov rsi, [rbp+8*2] ;width
    mov rdi, [rbp+8*3] ;height
    mov rax, [rbp+8*6] ;matrix offset
    mov rbx, [rbp+8*5] ;vector offset
    mov rcx, [rbp+8*4] ;output offset

    xor r8, r8 ;loop counter over vector
    .loop_over_n:
        xor rdx, rdx ;loop counter
        vpxor ymm2, ymm2, ymm2 ;accumulator for sum
        .loop_over_m:
            vmovupd ymm0, [rax + rdx] ;row segment of matrix
            vmovupd ymm1, [rbx + rdx] ;col segment of vector
            vmulpd ymm0, ymm1, ymm0 ;multiply
            DOTPROD ymm0, ymm0, ymm3, xmm0, xmm1 ;sum em up
            vaddsd xmm2, xmm2, xmm0 ;accumulate

            add rdx, YMM_BYTE_LENGTH
            cmp rdx, rsi
            jne .loop_over_m

        vmovsd [rcx + r8], xmm2
        add r8, DOUBLE_BYTE_LENGTH
        cmp r8, rdi
        jne .loop_over_n

    pop r8
    AVXPOP ymm3
    AVXPOP ymm2
    AVXPOP ymm1
    AVXPOP ymm0
    POPREGS
ret 8*5
