
; Contains procedures for handeling the data set

%include "util.asm"

OPENAT_FILE_SYSCALL equ 0x101
OPEN_READ_ONLY_FLAG equ 0x00

CLOSE_FILE_SYSCALL equ 3

READ_FILE_SYSCALL equ 0

LSEEK_FILE_SYSCALL equ 0x08
SEEK_CUR equ 1 ;sets offset to offset plus bytes in lseek

NUMBER_OF_INPUTS equ 1372

section .data

dataFileDescriptor dq 0
currentLine dq 0

section .text

    ; Opens a file with read only perms and default mode.
    ;
    ; param: register containing relative offset to path
    ; output: file descriptor in rax
    %macro OPEN_READ_ONLY_FILE 1
        push rdi
        push rsi
        push rdx
        push r10

        mov rax, OPENAT_FILE_SYSCALL
        mov rdi, %1
        mov rsi, %1
        mov rdx, OPEN_READ_ONLY_FILE
        xor r10, r10
        syscall
        mov %1, rax

        pop r10
        pop rdx
        pop rsi
        pop rdi
    %endmacro

    ; Closes a file given its file descriptor.
    ;
    ; param: register containing the file descriptor
    %macro CLOSE_FILE 1
        push rax
        push rdi

        mov rax, CLOSE_FILE_SYSCALL
        mov rdi, %1
        syscall

        pop rdi
        pop rax
    %endmacro

    ; Reads from a file.
    ;
    ; param: file descriptor
    ; param: buffer offset
    ; param: byte count, register
    %macro READ_FILE 3
        push rax
        push rdi
        push rdx
        push rsi

        mov rax, READ_FILE_SYSCALL
        mov rdi, %1
        mov rsi, %2
        mov rdx, %3
        syscall

        cmp rax, -1
        je %%error_occured

    %%error_occured:
        %error "There was an error reading the file."

        pop rsi
        pop rdx
        pop rdi
        pop rax
    %endmacro

    ; Repositions the file's offset.
    ;
    ; param 1: file descriptor
    ; param 2: bytes to add
    %macro REPOSITION_OFFSET 2
        push rax
        push rsi
        push rdi
        push rdx

        mov rax, LSEEK_FILE_SYSCALL
        mov rdi, %1
        mov rsi, %2
        mov rdx, SEEK_CUR
        syscall

        sub %1, rax
        %if %1 == 1
            %error "Reposition Failed"
        %endif

        pop rdx
        pop rdi
        pop rsi
        pop rax
    %endmacro

    ; Reads a line.
    ;
    ; param: file descriptor
    ; param: buffer offset
    ; param: currentInput offset's
    ; param: temporary buffer offset, 16 bytes long
    ReadEntry:
        PUSHREGS

        mov rdx, [rbp + 8*2] ;buffer offset
        mov rax, [rbp + 8*3] ;currentInput
        mov rbx, [rbp + 8*4] ;buffer offset
        mov rcx, [rbp + 8*5] ;fd
        xor rdi, rdi
        mov rdi, [rax] ;input offset
        xor rsi, rsi ;loop counter

    .loop_over_number:
        inc rdi

        .find_offsets: ;find offsets of word
            cmp [rdi + rsi], ","
            je .end_offset_found
            cmp [rdi + rsi], "/n"
            je .end_offset_found
            
            inc rsi
            jmp .find_offsets

        .end_offset_found:
            REPOSITION_OFFSET rcx, 1
            dec rsi ;number of bytes till the end
            READ_FILE rcx, rdx, rsi ;read file and store in buffer
        

        POPREGS
    ret 8*4
