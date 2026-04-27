; Implemented foundation subset: deterministic code/message diagnostics.

print_diag:
    push rdi
    push rsi
    call print_stderr_z
    mov rdi, colon_z
    call print_stderr_z
    mov rdi, 2
    mov rax, [diag_line]
    call write_u64_fd
    mov rdi, colon_z
    call print_stderr_z
    mov rdi, 2
    mov rax, [diag_col]
    call write_u64_fd
    mov rdi, space_z
    call print_stderr_z
    pop rdi
    call print_stderr_z
    mov rdi, newline_z
    call print_stderr_z
    pop rdi
    ret
