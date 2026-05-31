; Status: PARTIAL.
; Direct Linux write wrappers for compiler diagnostics and generated output.

print_stdout_z:
    mov rsi, rdi
    call strlen
    mov rdx, rax
    mov rdi, 1
    mov rax, SYS_WRITE
    syscall
    ret

print_stderr_z:
    mov rsi, rdi
    call strlen
    mov rdx, rax
    mov rdi, 2
    mov rax, SYS_WRITE
    syscall
    ret

write_all:
    mov rax, SYS_WRITE
    syscall
    ret
