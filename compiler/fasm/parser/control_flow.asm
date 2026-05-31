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
    cmp rax, TOK_ELIF
    je .has_elif_entry
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

; --- elif support ---
; elif is desugared into nested if/else:
;   if A -> ... elif B -> ... else -> ... end
; becomes:
;   if A -> ... else -> if B -> ... else -> ... end end
; We use parse_elif_tail to recursively build the inner if/else chain.
.has_elif_entry:
    call advance_token      ; skip past 'elif' token
.has_elif:
    ; r14 = condition of original if
    ; r15 = then-block of original if
    ; rbx = saved parent block node

    ; Save original if's then-block
    mov [tmp_ast_a], r15

    ; Build the elif tail as an inner if_stmt
    call parse_elif_tail
    test rax, rax
    jz .elif_fail
    mov r15, rax            ; r15 = inner if_stmt from elif tail

    ; Wrap inner if_stmt in an else-block
    mov rdi, AST_BLOCK
    mov rsi, r12
    mov rdx, r12
    xor rcx, rcx
    xor r8, r8
    call ast_new
    mov r13, rax            ; r13 = else-block containing inner if

    mov rdi, r13
    mov rsi, r15
    call ast_append_child

    ; Build the outer if_stmt: cond=r14, then=[tmp_ast_a], else=r13
    mov rdi, AST_IF_STMT
    mov rsi, r12
    mov rdx, r12
    xor rcx, rcx
    xor r8, r8
    call ast_new
    mov r15, rax

    mov rdi, r15
    mov rsi, r14
    call ast_append_child
    mov rdi, r15
    mov rsi, [tmp_ast_a]
    call ast_append_child
    mov rdi, r15
    mov rsi, r13
    call ast_append_child

    ; Append to parent block
    mov rdi, rbx
    mov rsi, r15
    call ast_append_child

    call advance_token      ; consume 'end'
    mov [ast_block_node], rbx
    xor rax, rax
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

.elif_fail:
    mov [ast_block_node], rbx
    jmp .bad

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

; parse_elif_tail: Parse an elif's condition + block, then handle
; the continuation (end, else, or another elif).
; Called AFTER the 'elif' token has been consumed.
; Returns: rax = if_stmt AST node on success, 0 on failure.
parse_elif_tail:
    push rbx
    push r12
    push r13
    push r14
    push r15

    ; Parse condition
    xor rdi, rdi
    call parse_expr_min
    test rax, rax
    jz .tail_fail
    mov r14, rax            ; r14 = condition expr

    ; Expect ->
    call current_token_kind
    cmp rax, TOK_ARROW
    jne .tail_fail
    call advance_token

    ; Create elif then-block
    mov rdi, AST_BLOCK
    mov rsi, 0
    mov rdx, 0
    xor rcx, rcx
    xor r8, r8
    call ast_new
    mov r15, rax            ; r15 = then-block

    mov rbx, [ast_block_node]
    mov [ast_block_node], r15

    push r14
    push r15
    call parse_block_inner
    pop r15
    pop r14
    test rax, rax
    jnz .tail_restore_fail

    ; Check what follows: end, else, elif
    call current_token_kind
    cmp rax, TOK_ELIF
    je .tail_elif
    cmp rax, TOK_ELSE
    je .tail_else

    ; Must be 'end' — no else block, create if_stmt(cond, then_block)
    mov rdi, AST_IF_STMT
    mov rsi, 0
    mov rdx, 0
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

    mov [ast_block_node], rbx
    mov rax, r13
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

.tail_elif:
    ; Another elif follows — recurse
    call advance_token      ; consume 'elif'
    call parse_elif_tail
    test rax, rax
    jz .tail_restore_fail
    mov r12, rax            ; r12 = inner if_stmt

    ; Wrap inner if_stmt in an else-block
    mov rdi, AST_BLOCK
    mov rsi, 0
    mov rdx, 0
    xor rcx, rcx
    xor r8, r8
    call ast_new
    mov r13, rax

    mov rdi, r13
    mov rsi, r12
    call ast_append_child

    ; Create if_stmt(cond, then_block, else_block)
    mov rdi, AST_IF_STMT
    mov rsi, 0
    mov rdx, 0
    xor rcx, rcx
    xor r8, r8
    call ast_new
    mov r12, rax

    mov rdi, r12
    mov rsi, r14
    call ast_append_child
    mov rdi, r12
    mov rsi, r15
    call ast_append_child
    mov rdi, r12
    mov rsi, r13
    call ast_append_child

    mov [ast_block_node], rbx
    mov rax, r12
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

.tail_else:
    ; else -> ... end
    call advance_token      ; consume 'else'
    call current_token_kind
    cmp rax, TOK_ARROW
    jne .tail_restore_fail
    call advance_token

    ; Create else-block
    mov rdi, AST_BLOCK
    mov rsi, 0
    mov rdx, 0
    xor rcx, rcx
    xor r8, r8
    call ast_new
    mov r13, rax
    mov [ast_block_node], r13

    push r13
    push r14
    push r15
    call parse_block_inner
    pop r15
    pop r14
    pop r13
    test rax, rax
    jnz .tail_restore_fail2

    ; Create if_stmt(cond, then_block, else_block)
    mov rdi, AST_IF_STMT
    mov rsi, 0
    mov rdx, 0
    xor rcx, rcx
    xor r8, r8
    call ast_new
    mov r12, rax

    mov rdi, r12
    mov rsi, r14
    call ast_append_child
    mov rdi, r12
    mov rsi, r15
    call ast_append_child
    mov rdi, r12
    mov rsi, r13
    call ast_append_child

    mov [ast_block_node], rbx
    mov rax, r12
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

.tail_restore_fail2:
    mov [ast_block_node], rbx
    jmp .tail_fail
.tail_restore_fail:
    mov [ast_block_node], rbx
.tail_fail:
    call print_unsupported_current
    xor rax, rax
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
