
; Contains compatibility checks for AVX.

%include "util.asm"

section .data
    AVX2Enabled db "Your computer has AVX2 enabled, proceeding to run the program...", 13, 10, "$"
    AVX2NotEnabled db "Your computer doesn't have AVX2 enabled, exiting the program...", 13, 10,"$"

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

    ; Prints to the screen if host computer is AVX2 compatible.
    ;
    ; param: addr of AVX2 compatibility message
    ; param: addr of AVX2 incompatibility message
    PrintAVX2Compatible:
        push rbp
        mov rbp, rsp
        push rbx
        push rax

        push rax
        call IsAVX2Compatible
        pop rax
        shr rax, 1
        jc AVX2_compatible

        mov rbx, [rbp + 8*2] ;incompatibility message offset
        PRINT rbx
        jmp PrintAVX2Compatible_finish

    AVX2_compatible:
        mov rbx, [rbp + 8*3] ;compatibility message offset
        PRINT rbx
    PrintAVX2Compatible_finish:
        pop rax
        pop rbx
        pop rbp
    ret 8*2

    ; Prints AVX2 compatibility with pre-defined messages.
    ;
    ; exits: if host computer isn't AVX2 compatible
    %macro USER_AVX2_COMPATIBLE 0
        push AVX2Enabled
        push AVX2NotEnabled
        call PrintAVX2Compatible
    %endmacro
