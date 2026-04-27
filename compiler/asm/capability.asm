; Implemented foundation subset: io.write requires requires syscall.

capability_check_subset:
    cmp qword [ast_call_stmt], 0
    je .ok
    cmp byte [has_syscall], 1
    je .ok
    mov rdi, src_path
    mov rsi, err_syscall_cap
    call print_diag
    mov rax, 1
    ret
.ok:
    xor rax, rax
    ret
