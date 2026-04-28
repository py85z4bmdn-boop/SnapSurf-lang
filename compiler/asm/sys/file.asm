; Status: PARTIAL.
; File-system syscalls used by package loading and NASM emission.

open_read:
    mov rax, SYS_OPEN
    mov rsi, O_RDONLY
    xor rdx, rdx
    syscall
    ret

file_exists:
    call open_read
    test rax, rax
    js .no
    mov rdi, rax
    mov rax, SYS_CLOSE
    syscall
    mov rax, 1
    ret
.no:
    xor rax, rax
    ret

read_file:
    push r12
    push r13
    mov r12, rsi
    mov r13, rdx
    call open_read
    test rax, rax
    js .fail
    mov r8, rax
    mov rax, SYS_READ
    mov rdi, r8
    mov rsi, r12
    mov rdx, r13
    syscall
    push rax
    mov rdi, r8
    mov rax, SYS_CLOSE
    syscall
    pop rax
    test rax, rax
    js .fail
    pop r13
    pop r12
    ret
.fail:
    mov rax, -1
    pop r13
    pop r12
    ret

mkdir_build:
    mov rax, SYS_MKDIR
    mov rdi, build_dir
    mov rsi, 0755o
    syscall
    ret
