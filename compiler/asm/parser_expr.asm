; Status: PARTIAL.
; Pratt expression parser for current integer/bool/local expression subset.

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
