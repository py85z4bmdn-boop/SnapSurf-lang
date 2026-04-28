; Status: PARTIAL.
; Parser consumes the token buffer and builds AST arena nodes for the
; foundation v0 subset: main, use, io.write, let/mut locals, assignment,
; return expressions, and arithmetic Pratt expressions.

parse_source_subset:
    mov qword [token_index], 0
    call ast_reset
    mov rdi, AST_SOURCE_FILE
    xor rsi, rsi
    mov rdx, [src_len]
    xor rcx, rcx
    xor r8, r8
    call ast_new
    test rax, rax
    jz .fail
    mov [ast_root], rax

    call skip_newline_tokens
.use_loop:
    call current_token_kind
    cmp rax, TOK_USE
    jne .fn
    call parse_use_decl
    test rax, rax
    jnz .fail
    call skip_newline_tokens
    jmp .use_loop

.fn:
    call parse_main_fn
    test rax, rax
    jnz .fail
    call skip_newline_tokens
    call current_token_kind
    cmp rax, TOK_EOF
    jne .trailing
    xor rax, rax
    ret
.trailing:
    call print_unsupported_current
.fail:
    mov rax, 1
    ret

parse_use_decl:
    call current_token_addr
    mov r12, [rax + TOKEN_START]
    call advance_token

    call expect_ident_text_core
    test rax, rax
    jz .bad
    call advance_token
    call current_token_kind
    cmp rax, TOK_SLASH
    jne .bad
    call advance_token
    call expect_ident_text_io
    test rax, rax
    jz .bad
    call current_token_addr
    mov r13, [rax + TOKEN_START]
    add r13, [rax + TOKEN_LEN]
    call advance_token

    mov rdi, AST_USE_DECL
    mov rsi, r12
    mov rdx, r13
    xor rcx, rcx
    xor r8, r8
    call ast_new
    mov r14, rax
    mov rdi, [ast_root]
    mov rsi, r14
    call ast_append_child

    mov rdi, AST_PATH
    mov rsi, r12
    mov rdx, r13
    xor rcx, rcx
    xor r8, r8
    call ast_new
    mov rdi, r14
    mov rsi, rax
    call ast_append_child
    xor rax, rax
    ret
.bad:
    call set_diag_from_current
    mov rdi, src_path
    mov rsi, err_bad_use
    call print_diag
    mov rax, 1
    ret

parse_main_fn:
    call skip_newline_tokens
    call current_token_kind
    cmp rax, TOK_EOF
    je .no_main
    cmp rax, TOK_END
    je .unexpected_end
    cmp rax, TOK_FN
    jne .no_main
    call current_token_addr
    mov r12, [rax + TOKEN_START]
    call advance_token

    call expect_ident_text_main
    test rax, rax
    jz .bad_main
    call advance_token
    call current_token_kind
    cmp rax, TOK_ARROW
    jne .bad_fn
    call advance_token
    call expect_ident_text_i32
    test rax, rax
    jz .bad_main
    call current_token_addr
    mov r13, [rax + TOKEN_START]
    add r13, [rax + TOKEN_LEN]
    call advance_token

    mov rdi, AST_FN_DECL
    mov rsi, r12
    mov rdx, r13
    xor rcx, rcx
    xor r8, r8
    call ast_new
    mov [ast_main_fn], rax
    mov rdi, [ast_root]
    mov rsi, rax
    call ast_append_child

    mov rdi, AST_BLOCK
    mov rsi, r13
    mov rdx, r13
    xor rcx, rcx
    xor r8, r8
    call ast_new
    mov [ast_block_node], rax
    mov rdi, [ast_main_fn]
    mov rsi, rax
    call ast_append_child

    call parse_block
    ret

.no_main:
    call set_diag_from_current
    mov rdi, src_path
    mov rsi, err_no_main
    call print_diag
    mov rax, 1
    ret
.unexpected_end:
    call set_diag_from_current
    mov rdi, src_path
    mov rsi, err_unexpected_end
    call print_diag
    mov rax, 1
    ret
.bad_main:
    call set_diag_from_current
    mov rdi, src_path
    mov rsi, err_bad_main
    call print_diag
    mov rax, 1
    ret
.bad_fn:
    call set_diag_from_current
    mov rdi, src_path
    mov rsi, err_bad_fn
    call print_diag
    mov rax, 1
    ret

parse_block:
.loop:
    call skip_newline_tokens
    call current_token_kind
    cmp rax, TOK_END
    je .end
    cmp rax, TOK_EOF
    je .missing_end
    cmp rax, TOK_RET
    je .ret
    cmp rax, TOK_LET
    je .decl
    cmp rax, TOK_MUT
    je .decl
    cmp rax, TOK_IDENT
    je .ident_stmt
    jmp .unsupported
.ret:
    call parse_ret_stmt
    test rax, rax
    jnz .fail
    jmp .loop
.decl:
    call parse_decl_stmt
    test rax, rax
    jnz .fail
    jmp .loop
.ident_stmt:
    call current_is_io_write
    test rax, rax
    jnz .call
    call parse_assign_stmt
    test rax, rax
    jnz .fail
    jmp .loop
.call:
    call parse_call_stmt
    test rax, rax
    jnz .fail
    jmp .loop
.end:
    call advance_token
    xor rax, rax
    ret
.missing_end:
    call set_diag_from_current
    mov rdi, src_path
    mov rsi, err_missing_end
    call print_diag
    mov rax, 1
    ret
.unsupported:
    call print_unsupported_current
    mov rax, 1
    ret
.fail:
    ret

parse_decl_stmt:
    call current_token_addr
    mov r12, [rax + TOKEN_START]
    call current_token_kind
    cmp rax, TOK_MUT
    je .mut_head
    mov r15, AST_LET_STMT
    call advance_token
    jmp .name
.mut_head:
    mov r15, AST_MUT_STMT
    call advance_token
.name:
    call parse_ident_node
    test rax, rax
    jz .bad
    mov [tmp_ast_a], rax

    call expect_ident_text_i32
    test rax, rax
    jz .bad
    call advance_token
    call current_token_kind
    cmp rax, TOK_EQ
    jne .bad
    call advance_token

    xor rdi, rdi
    call parse_expr_min
    test rax, rax
    jz .fail
    mov [tmp_ast_b], rax

    mov rdi, r15
    mov rsi, r12
    mov rdx, r12
    xor rcx, rcx
    xor r8, r8
    call ast_new
    mov r14, rax
    mov rdi, r14
    mov rsi, [tmp_ast_a]
    call ast_append_child
    mov rdi, r14
    mov rsi, [tmp_ast_b]
    call ast_append_child
    mov rdi, [ast_block_node]
    mov rsi, r14
    call ast_append_child
    xor rax, rax
    ret
.bad:
    call print_unsupported_current
.fail:
    mov rax, 1
    ret

parse_assign_stmt:
    call current_token_addr
    mov r12, [rax + TOKEN_START]
    call parse_ident_node
    test rax, rax
    jz .bad
    mov [tmp_ast_a], rax
    call current_token_kind
    cmp rax, TOK_EQ
    jne .bad
    call advance_token

    xor rdi, rdi
    call parse_expr_min
    test rax, rax
    jz .fail
    mov [tmp_ast_b], rax

    mov rdi, AST_ASSIGN_STMT
    mov rsi, r12
    mov rdx, r12
    xor rcx, rcx
    xor r8, r8
    call ast_new
    mov r14, rax
    mov rdi, r14
    mov rsi, [tmp_ast_a]
    call ast_append_child
    mov rdi, r14
    mov rsi, [tmp_ast_b]
    call ast_append_child
    mov rdi, [ast_block_node]
    mov rsi, r14
    call ast_append_child
    xor rax, rax
    ret
.bad:
    call print_unsupported_current
.fail:
    mov rax, 1
    ret

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
