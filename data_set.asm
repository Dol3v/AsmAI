
; Contains procedures for handeling the data set

OPEN_FILE_SYSCALL equ 2
OPEN_READ_ONLY_FLAG equ 0x00

CLOSE_FILE_SYSCALL equ 3

section .data

dataFileDescriptor dq 0

section .text

; Opens a file with read only perms and default mode.
;
; param: register containing offset to path, 
; output: file descriptor in rax
%macro OPEN_READ_ONLY_FILE 1
    push rdi
    push rsi
    push rdx

    mov rax, OPEN_FILE_SYSCALL
    mov rdi, %1
    mov rsi, OPEN_READ_ONLY_FLAG
    xor rdx, rdx
    syscall
    mov %1, rax

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
