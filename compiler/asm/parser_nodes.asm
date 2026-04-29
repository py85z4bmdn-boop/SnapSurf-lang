; Status: PARTIAL.
; AST leaf-node constructors used by statement and expression parsing.

parse_ident_node:
    call current_token_kind
    cmp rax, TOK_IDENT
    jne .bad
    mov rdi, [token_index]
    call token_addr
    mov r12, [rax + TOKEN_START]
    mov r13, r12
    add r13, [rax + TOKEN_LEN]
    mov rcx, [token_index]
    mov rdi, AST_IDENT
    mov rsi, r12
    mov rdx, r13
    xor r8, r8
    call ast_new
    mov r12, rax
    call advance_token
    mov rax, r12
    ret
.bad:
    xor rax, rax
    ret

parse_var_ref_node:
    mov rdi, [token_index]
    call token_addr
    mov r12, [rax + TOKEN_START]
    mov r13, r12
    add r13, [rax + TOKEN_LEN]
    mov rcx, [token_index]
    mov rdi, AST_VAR_REF
    mov rsi, r12
    mov rdx, r13
    xor r8, r8
    call ast_new
    ret

parse_int_node_at:
    push rdi
    call token_addr
    pop rcx
    mov r12, [rax + TOKEN_START]
    mov r13, r12
    add r13, [rax + TOKEN_LEN]
    mov rdi, AST_INT_LIT
    mov rsi, r12
    mov rdx, r13
    xor r8, r8
    call ast_new
    ret

parse_str_node_at:
    push rdi
    call token_addr
    pop rcx
    mov r12, [rax + TOKEN_START]
    mov r13, r12
    add r13, [rax + TOKEN_LEN]
    mov rdi, AST_STR_LIT
    mov rsi, r12
    mov rdx, r13
    xor r8, r8
    call ast_new
    ret

parse_bool_node:
    call current_token_addr
    mov r13, [rax + TOKEN_START]
    mov r14, r13
    add r14, [rax + TOKEN_LEN]
    mov rcx, [token_index]
    mov rdi, AST_BOOL_LIT
    mov rsi, r13
    mov rdx, r14
    xor r8, r8
    call ast_new
    ret
