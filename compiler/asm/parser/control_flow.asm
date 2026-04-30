; parser/control_flow.asm — Control flow statement parsers.
; Handles: if/else, while, loop, break, continue.

parse_if_stmt:
    push rbx
    push r12
    push r13
    push r14
    push r15
    call current_token_addr
    mov r12, [rax + TOKEN_START]
    call advance_token

    xor rdi, rdi
    call parse_expr_min
    test rax, rax
    jz .bad
    mov r14, rax

    call current_token_kind
    cmp rax, TOK_ARROW
    jne .bad
    call advance_token

    mov rdi, AST_BLOCK
    mov rsi, r12
    mov rdx, r12
    xor rcx, rcx
    xor r8, r8
    call ast_new
    mov r15, rax

    mov rbx, [ast_block_node]
    mov [ast_block_node], r15

    push r12
    push r14
    push r15
    call parse_block_inner
    pop r15
    pop r14
    pop r12
    test rax, rax
    jnz .restore_and_fail

    call current_token_kind
    cmp rax, TOK_ELSE
    je .has_else
    cmp rax, TOK_END
    jne .restore_and_fail

    mov rdi, AST_IF_STMT
    mov rsi, r12
    mov rdx, r12
    xor rcx, rcx
    xor r8, r8
    call ast_new
    mov r13, rax

    mov rdi, r13
    mov rsi, r14
    call ast_append_child
    mov rdi, r13
    mov rsi, r15
    call ast_append_child

    mov rdi, rbx
    mov rsi, r13
    call ast_append_child

    call advance_token
    mov [ast_block_node], rbx
    xor rax, rax
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

.has_else:
    mov [tmp_ast_a], r15
    call advance_token

    call current_token_kind
    cmp rax, TOK_ARROW
    jne .restore_and_fail
    call advance_token

    mov rdi, AST_BLOCK
    mov rsi, r12
    mov rdx, r12
    xor rcx, rcx
    xor r8, r8
    call ast_new
    mov r15, rax

    mov [ast_block_node], r15

    push r12
    push r14
    push r15
    call parse_block_inner
    pop r15
    pop r14
    pop r12
    test rax, rax
    jnz .restore_and_fail

    mov rdi, AST_IF_STMT
    mov rsi, r12
    mov rdx, r12
    xor rcx, rcx
    xor r8, r8
    call ast_new
    mov r13, rax

    mov rdi, r13
    mov rsi, r14
    call ast_append_child
    mov rdi, r13
    mov rsi, [tmp_ast_a]
    call ast_append_child
    mov rdi, r13
    mov rsi, r15
    call ast_append_child

    mov rdi, rbx
    mov rsi, r13
    call ast_append_child

    call advance_token
    mov [ast_block_node], rbx
    xor rax, rax
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

.restore_and_fail:
    mov [ast_block_node], rbx
.bad:
    call print_unsupported_current
    mov rax, 1
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

parse_while_stmt:
    push rbx
    push r12
    push r13
    push r14
    push r15
    call current_token_addr
    mov r12, [rax + TOKEN_START]
    call advance_token

    xor rdi, rdi
    call parse_expr_min
    test rax, rax
    jz .bad
    mov r14, rax

    call current_token_kind
    cmp rax, TOK_ARROW
    jne .bad
    call advance_token

    mov rdi, AST_BLOCK
    mov rsi, r12
    mov rdx, r12
    xor rcx, rcx
    xor r8, r8
    call ast_new
    mov r15, rax

    mov rbx, [ast_block_node]
    mov [ast_block_node], r15

    push r12
    push r14
    push r15
    call parse_block_inner
    pop r15
    pop r14
    pop r12
    test rax, rax
    jnz .restore_and_fail

    mov rdi, AST_WHILE_STMT
    mov rsi, r12
    mov rdx, r12
    xor rcx, rcx
    xor r8, r8
    call ast_new
    mov r13, rax

    mov rdi, r13
    mov rsi, r14
    call ast_append_child
    mov rdi, r13
    mov rsi, r15
    call ast_append_child

    mov rdi, rbx
    mov rsi, r13
    call ast_append_child

    mov [ast_block_node], rbx
    call advance_token
    xor rax, rax
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

.restore_and_fail:
    mov [ast_block_node], rbx
.bad:
    call print_unsupported_current
    mov rax, 1
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

parse_loop_stmt:
    push rbx
    push r12
    push r13
    push r14
    push r15
    call current_token_addr
    mov r12, [rax + TOKEN_START]
    call advance_token

    call current_token_kind
    cmp rax, TOK_ARROW
    jne .bad
    call advance_token

    mov rdi, AST_BLOCK
    mov rsi, r12
    mov rdx, r12
    xor rcx, rcx
    xor r8, r8
    call ast_new
    mov r15, rax

    mov rbx, [ast_block_node]
    mov [ast_block_node], r15

    push r12
    push r15
    call parse_block_inner
    pop r15
    pop r12
    test rax, rax
    jnz .restore_and_fail

    mov rdi, AST_LOOP_STMT
    mov rsi, r12
    mov rdx, r12
    xor rcx, rcx
    xor r8, r8
    call ast_new
    mov r13, rax

    mov rdi, r13
    mov rsi, r15
    call ast_append_child

    mov rdi, rbx
    mov rsi, r13
    call ast_append_child

    mov [ast_block_node], rbx
    call advance_token
    xor rax, rax
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

.restore_and_fail:
    mov [ast_block_node], rbx
.bad:
    call print_unsupported_current
    mov rax, 1
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

parse_break_stmt:
    call current_token_addr
    mov r12, [rax + TOKEN_START]
    call advance_token

    mov rdi, AST_BREAK_STMT
    mov rsi, r12
    mov rdx, r12
    xor rcx, rcx
    xor r8, r8
    call ast_new
    mov r14, rax

    mov rdi, [ast_block_node]
    mov rsi, r14
    call ast_append_child
    xor rax, rax
    ret

parse_continue_stmt:
    call current_token_addr
    mov r12, [rax + TOKEN_START]
    call advance_token

    mov rdi, AST_CONTINUE_STMT
    mov rsi, r12
    mov rdx, r12
    xor rcx, rcx
    xor r8, r8
    call ast_new
    mov r14, rax

    mov rdi, [ast_block_node]
    mov rsi, r14
    call ast_append_child
    xor rax, rax
    ret
