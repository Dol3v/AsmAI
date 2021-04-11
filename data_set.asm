
; Contains procedures for handeling the data set

OPENAT_FILE_SYSCALL equ 0x101
OPEN_READ_ONLY_FLAG equ 0x00

CLOSE_FILE_SYSCALL equ 3

READ_FILE_SYSCALL equ 0

section .data

dataFileDescriptor dq 0

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
; param: byte count - register
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


