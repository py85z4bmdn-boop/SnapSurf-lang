; parser/statements.asm — Return and call statement parsers.
; Handles: ret, io.write call.

parse_ret_stmt:
    call current_token_addr
    mov r12, [rax + TOKEN_START]
    call advance_token
    xor rdi, rdi
    call parse_expr_min
    test rax, rax
    jz .fail
    mov r14, rax

    mov rdi, AST_RET_STMT
    mov rsi, r12
    mov rdx, r12
    mov rcx, r14
    xor r8, r8
    call ast_new
    mov [ast_ret_stmt], rax
    mov rdi, [ast_block_node]
    mov rsi, rax
    call ast_append_child
    xor rax, rax
    ret
.fail:
    mov rax, 1
    ret

parse_call_stmt:
    call current_token_addr
    mov r12, [rax + TOKEN_START]
    call expect_ident_text_io
    test rax, rax
    jz .unsupported
    call advance_token
    call current_token_kind
    cmp rax, TOK_DOT
    jne .unsupported
    call advance_token
    call expect_ident_text_write
    test rax, rax
    jz .unsupported
    call advance_token

    mov rdi, AST_PATH
    mov rsi, r12
    mov rdx, r12
    xor rcx, rcx
    xor r8, r8
    call ast_new
    mov r15, rax

    call current_token_kind
    cmp rax, TOK_INT
    jne .unsupported
    mov rdi, [token_index]
    call parse_int_node_at
    mov [tmp_ast_a], rax
    call advance_token

    call current_token_kind
    cmp rax, TOK_STRING
    jne .unsupported
    mov rdi, [token_index]
    call parse_str_node_at
    mov [tmp_ast_b], rax
    call advance_token

    call current_token_kind
    cmp rax, TOK_INT
    jne .unsupported
    mov rdi, [token_index]
    call parse_int_node_at
    mov [tmp_ast_c], rax
    call advance_token

    mov rdi, AST_CALL_STMT
    mov rsi, r12
    mov rdx, r12
    xor rcx, rcx
    xor r8, r8
    call ast_new
    mov [ast_call_stmt], rax
    mov r14, rax
    mov byte [has_io_write], 1

    mov rdi, r14
    mov rsi, r15
    call ast_append_child
    mov rdi, r14
    mov rsi, [tmp_ast_a]
    call ast_append_child
    mov rdi, r14
    mov rsi, [tmp_ast_b]
    call ast_append_child
    mov rdi, r14
    mov rsi, [tmp_ast_c]
    call ast_append_child

    mov rdi, [ast_block_node]
    mov rsi, r14
    call ast_append_child
    xor rax, rax
    ret
.unsupported:
    call print_unsupported_current
    mov rax, 1
    ret
