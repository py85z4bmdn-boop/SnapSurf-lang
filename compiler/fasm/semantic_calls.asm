; Status: COMPLETE for foundation v0 subset.
; Semantic lowering/validation for supported foundation calls.

semantic_load_call:
    push rbx
    push r12
    mov r12, rdi
    xor rsi, rsi
    call ast_child_at
    mov rdi, rax
    test rdi, rdi
    jz .bad
    mov rdi, r12
    mov rsi, 1
    call ast_child_at
    test rax, rax
    jz .bad
    mov rdi, r12
    mov rsi, 2
    call ast_child_at
    test rax, rax
    jz .bad
    mov [tmp_ast_b], rax
    mov rdi, r12
    mov rsi, 3
    call ast_child_at
    test rax, rax
    jz .bad
    mov [tmp_ast_c], rax

    mov rdi, [tmp_ast_b]
    call ast_kind
    cmp rax, AST_STR_LIT
    jne .bad
    mov rdi, [tmp_ast_b]
    call ast_child
    mov rdi, rax
    call token_addr
    cmp qword [rax + TOKEN_TYPE], TOK_STRING
    jne .bad
    mov rbx, [rax + TOKEN_LEN]
    mov [parsed_str_len], rbx
    mov rbx, [rax + TOKEN_PAYLOAD]
    mov [tmp_payload], rbx

    mov rdi, [tmp_ast_c]
    call ast_kind
    cmp rax, AST_INT_LIT
    jne .bad
    mov rdi, [tmp_ast_c]
    call ast_child
    mov rdi, rax
    call token_addr
    cmp qword [rax + TOKEN_TYPE], TOK_INT
    jne .bad
    mov rbx, [rax + TOKEN_PAYLOAD]
    mov [parsed_io_len], rbx
    cmp rbx, [parsed_str_len]
    jne .len_mismatch
    xor rax, rax
    pop r12
    pop rbx
    ret
.bad:
    mov rdi, src_path
    mov rsi, err_unsup_ast
    call print_diag
    mov rax, 1
    pop r12
    pop rbx
    ret
.len_mismatch:
    mov rdi, src_path
    mov rsi, err_len_mismatch
    call print_diag
    mov rax, 1
    pop r12
    pop rbx
    ret
