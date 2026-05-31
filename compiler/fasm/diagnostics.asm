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

print_unsupported_current:
    call set_diag_from_current
    call current_token_kind
    mov [tmp_diag_kind], rax
    mov rdi, src_path
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
    mov rdi, err_unsup_expr
    call print_stderr_z
    mov rdi, [tmp_diag_kind]
    call token_name_ptr
    mov rdi, rax
    call print_stderr_z
    ret
