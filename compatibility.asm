
; Contains compatibility checks for AVX.

section .text

    ; Returns whether the host computer is AVX compatible.
    ;
    ; param: one redundant push
    ; returns: 1 if AVX compatible, 0 otherwise
    IsAVX2Compatible:
        push rbp
        mov rbp, rsp
        push rax
        push rcx
        push rbx

        mov eax, 7
        xor ecx, ecx
        cpuid ;checking for extended feature bits - AVX2
        shr ebx, 5
        and ebx, 1 ;ebx = 1 iff computer is AVX2 enabled
        mov [rbp+8*2], ebx ;outputting to stack

        pop rbx
        pop rcx
        pop rax
        pop rbp
    ret 