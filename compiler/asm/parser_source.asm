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

parse_expr_min:
    push rbx
    push r12
    push r13
    push r14
    push r15
    push rdi
    call parse_prefix_expr
    test rax, rax
    jz .fail
    mov r13, rax
.loop:
    call current_token_kind
    mov rdi, rax
    call infix_binding_power
    test rax, rax
    jz .done
    cmp rax, [rsp]
    jb .done
    mov r14, rdx
    mov rbx, rax
    call advance_token
    mov rdi, rbx
    inc rdi
    call parse_expr_min
    test rax, rax
    jz .fail
    mov r15, rax
    mov rdi, r14
    xor rsi, rsi
    xor rdx, rdx
    xor rcx, rcx
    xor r8, r8
    call ast_new
    test rax, rax
    jz .fail
    mov rbx, rax
    mov rdi, rbx
    mov rsi, r13
    call ast_append_child
    mov rdi, rbx
    mov rsi, r15
    call ast_append_child
    mov r13, rbx
    jmp .loop
.done:
    mov rax, r13
    add rsp, 8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.fail:
    xor rax, rax
    add rsp, 8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

parse_prefix_expr:
    call current_token_kind
    cmp rax, TOK_INT
    je .int
    cmp rax, TOK_TRUE
    je .true
    cmp rax, TOK_FALSE
    je .false
    cmp rax, TOK_IDENT
    je .var
    cmp rax, TOK_MINUS
    je .neg
    cmp rax, TOK_LPAREN
    je .group
    jmp .bad
.int:
    mov rdi, [token_index]
    call parse_int_node_at
    mov r12, rax
    call advance_token
    mov rax, r12
    ret
.true:
    mov rdi, 1
    call parse_bool_node
    mov r12, rax
    call advance_token
    mov rax, r12
    ret
.false:
    xor rdi, rdi
    call parse_bool_node
    mov r12, rax
    call advance_token
    mov rax, r12
    ret
.var:
    call parse_var_ref_node
    mov r12, rax
    call advance_token
    mov rax, r12
    ret
.neg:
    call advance_token
    mov rdi, 30
    call parse_expr_min
    test rax, rax
    jz .fail
    mov r12, rax
    mov rdi, AST_UNARY_NEG
    xor rsi, rsi
    xor rdx, rdx
    mov rcx, r12
    xor r8, r8
    call ast_new
    ret
.group:
    call advance_token
    xor rdi, rdi
    call parse_expr_min
    test rax, rax
    jz .fail
    mov r12, rax
    call current_token_kind
    cmp rax, TOK_RPAREN
    jne .bad
    call advance_token
    mov rax, r12
    ret
.bad:
    call print_unsupported_current
.fail:
    xor rax, rax
    ret

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
    mov r12, rdi
    call current_token_addr
    mov r13, [rax + TOKEN_START]
    mov r14, r13
    add r14, [rax + TOKEN_LEN]
    mov rdi, AST_BOOL_LIT
    mov rsi, r13
    mov rdx, r14
    mov rcx, r12
    xor r8, r8
    call ast_new
    ret

infix_binding_power:
    cmp rdi, TOK_PLUS
    je .add
    cmp rdi, TOK_MINUS
    je .sub
    cmp rdi, TOK_STAR
    je .mul
    cmp rdi, TOK_SLASH
    je .div
    cmp rdi, TOK_PERCENT
    je .mod
    xor rax, rax
    xor rdx, rdx
    ret
.add:
    mov rax, 10
    mov rdx, AST_BIN_ADD
    ret
.sub:
    mov rax, 10
    mov rdx, AST_BIN_SUB
    ret
.mul:
    mov rax, 20
    mov rdx, AST_BIN_MUL
    ret
.div:
    mov rax, 20
    mov rdx, AST_BIN_DIV
    ret
.mod:
    mov rax, 20
    mov rdx, AST_BIN_MOD
    ret

current_is_io_write:
    call expect_ident_text_io
    test rax, rax
    jz .no
    call next_token_kind
    cmp rax, TOK_DOT
    jne .no
    mov rax, 1
    ret
.no:
    xor rax, rax
    ret

next_token_kind:
    mov rdi, [token_index]
    inc rdi
    cmp rdi, [token_count]
    jae .eof
    call token_addr
    mov rax, [rax + TOKEN_TYPE]
    ret
.eof:
    mov rax, TOK_EOF
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
