; Status: PARTIAL.
; Parser consumes the token buffer and builds AST arena nodes for the
; hello-world foundation subset.

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
    call current_token_kind
    cmp rax, TOK_USE
    jne .fn
    call parse_use_decl
    test rax, rax
    jnz .fail
    call skip_newline_tokens

.fn:
    call parse_main_fn
    test rax, rax
    jnz .fail
    xor rax, rax
    ret
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
    cmp rax, TOK_IDENT
    je .call
    jmp .unsupported
.ret:
    call parse_ret_stmt
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
    call set_diag_from_current
    mov rdi, src_path
    mov rsi, err_unsup_expr
    call print_diag
    mov rax, 1
    ret
.fail:
    ret

parse_ret_stmt:
    call current_token_addr
    mov r12, [rax + TOKEN_START]
    call advance_token
    call current_token_kind
    cmp rax, TOK_INT
    jne .bad
    mov rdi, [token_index]
    call token_addr
    mov r13, [rax + TOKEN_START]
    add r13, [rax + TOKEN_LEN]
    mov rcx, [token_index]
    mov rdi, AST_INT_LIT
    mov rsi, [rax + TOKEN_START]
    mov rdx, r13
    xor r8, r8
    call ast_new
    mov r14, rax
    call advance_token

    mov rdi, AST_RET_STMT
    mov rsi, r12
    mov rdx, r13
    mov rcx, r14
    xor r8, r8
    call ast_new
    mov [ast_ret_stmt], rax
    mov rdi, [ast_block_node]
    mov rsi, rax
    call ast_append_child
    xor rax, rax
    ret
.bad:
    call set_diag_from_current
    mov rdi, src_path
    mov rsi, err_ret
    call print_diag
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
    call token_addr
    mov r13, [rax + TOKEN_START]
    add r13, [rax + TOKEN_LEN]
    mov rcx, [token_index]
    mov rdi, AST_INT_LIT
    mov rsi, [rax + TOKEN_START]
    mov rdx, r13
    xor r8, r8
    call ast_new
    mov [tmp_ast_a], rax
    call advance_token

    call current_token_kind
    cmp rax, TOK_STRING
    jne .unsupported
    mov rdi, [token_index]
    call token_addr
    mov r13, [rax + TOKEN_START]
    add r13, [rax + TOKEN_LEN]
    mov rcx, [token_index]
    mov rdi, AST_STR_LIT
    mov rsi, [rax + TOKEN_START]
    mov rdx, r13
    xor r8, r8
    call ast_new
    mov [tmp_ast_b], rax
    call advance_token

    call current_token_kind
    cmp rax, TOK_INT
    jne .unsupported
    mov rdi, [token_index]
    call token_addr
    mov r13, [rax + TOKEN_START]
    add r13, [rax + TOKEN_LEN]
    mov rcx, [token_index]
    mov rdi, AST_INT_LIT
    mov rsi, [rax + TOKEN_START]
    mov rdx, r13
    xor r8, r8
    call ast_new
    mov [tmp_ast_c], rax
    call advance_token

    mov rdi, AST_CALL_STMT
    mov rsi, r12
    mov rdx, r13
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
    call set_diag_from_current
    mov rdi, src_path
    mov rsi, err_unsup_expr
    call print_diag
    mov rax, 1
    ret

expect_ident_text_core:
    mov rsi, text_core
    mov rdx, 4
    jmp current_ident_text_eq
expect_ident_text_io:
    mov rsi, text_io
    mov rdx, 2
    jmp current_ident_text_eq
expect_ident_text_main:
    mov rsi, text_main
    mov rdx, 4
    jmp current_ident_text_eq
expect_ident_text_i32:
    mov rsi, text_i32
    mov rdx, 3
    jmp current_ident_text_eq
expect_ident_text_write:
    mov rsi, text_write
    mov rdx, 5
    jmp current_ident_text_eq

current_ident_text_eq:
    call current_token_kind
    cmp rax, TOK_IDENT
    jne .no
    mov rdi, [token_index]
    call token_text_eq
    ret
.no:
    xor rax, rax
    ret

token_text_eq:
    push rbx
    push r12
    mov r12, rsi
    mov rbx, rdx
    call token_addr
    cmp [rax + TOKEN_LEN], rbx
    jne .no
    mov rdi, src_buf
    add rdi, [rax + TOKEN_START]
    xor rcx, rcx
.loop:
    cmp rcx, rbx
    je .yes
    mov dl, [rdi + rcx]
    cmp dl, [r12 + rcx]
    jne .no
    inc rcx
    jmp .loop
.yes:
    mov rax, 1
    pop r12
    pop rbx
    ret
.no:
    xor rax, rax
    pop r12
    pop rbx
    ret

set_diag_from_current:
    call current_token_addr
    mov rbx, [rax + TOKEN_LINE]
    mov [diag_line], rbx
    mov rbx, [rax + TOKEN_COL]
    mov [diag_col], rbx
    ret

