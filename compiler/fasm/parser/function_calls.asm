; parser/function_calls.asm — Function call expression parsing.

parse_fn_call_expr:
    push rbx
    push r12
    push r13
    push r14

    mov r12, rdi
    mov rdi, r12
    call ast_span_start
    mov r13, rax
    mov rdi, r12
    call ast_span_end
    mov r14, rax

    mov rdi, AST_FN_CALL_EXPR
    mov rsi, r13
    mov rdx, r14
    xor rcx, rcx
    xor r8, r8
    call ast_new
    test rax, rax
    jz .fail
    mov rbx, rax
    mov rdi, rbx
    mov rsi, r12
    call ast_append_child

    call current_token_kind
    cmp rax, TOK_LPAREN
    je .with_parens
    jmp .bare_args

.with_parens:
    call advance_token
    call current_token_kind
    cmp rax, TOK_RPAREN
    je .paren_done
.paren_loop:
    xor rdi, rdi
    call parse_expr_min
    test rax, rax
    jz .fail
    mov rdi, rbx
    mov rsi, rax
    call ast_append_child
    call current_token_kind
    cmp rax, TOK_COMMA
    je .paren_comma
    cmp rax, TOK_RPAREN
    je .paren_done
    jmp .fail
.paren_comma:
    call advance_token
    jmp .paren_loop
.paren_done:
    call advance_token
    jmp .ok

.bare_args:
    call current_token_kind
    mov rdi, rax
    call token_starts_expr
    test rax, rax
    jz .ok
    xor rdi, rdi
    call parse_expr_min
    test rax, rax
    jz .fail
    mov rdi, rbx
    mov rsi, rax
    call ast_append_child
    jmp .bare_args

.ok:
    mov rax, rbx
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.fail:
    xor rax, rax
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

token_starts_expr:
    cmp rdi, TOK_INT
    je .yes
    cmp rdi, TOK_IDENT
    je .yes
    cmp rdi, TOK_TRUE
    je .yes
    cmp rdi, TOK_FALSE
    je .yes
    cmp rdi, TOK_NOT
    je .yes
    cmp rdi, TOK_LPAREN
    je .yes
    cmp rdi, TOK_STRING
    je .yes
    xor rax, rax
    ret
.yes:
    mov rax, 1
    ret
