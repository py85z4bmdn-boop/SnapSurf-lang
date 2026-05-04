; lexer/operators.asm — Operator and punctuation token scanning.
; Single-char operators and multi-char operators (arrows, comparisons).

.maybe_arrow:
    mov rax, r12
    inc rax
    cmp rax, r13
    jae .minus
    cmp byte [src_buf + rax], '>'
    jne .minus
    mov rdi, TOK_ARROW
    mov rsi, r12
    mov rdx, 2
    mov rcx, r14
    mov r8, r15
    xor r9, r9
    call token_add
    test rax, rax
    jnz .fail
    add r12, 2
    add r15, 2
    jmp .loop

.plus:
    mov rdi, TOK_PLUS
    jmp .single
.minus:
    mov rdi, TOK_MINUS
    jmp .single
.star:
    mov rdi, TOK_STAR
    jmp .single
.percent:
    mov rdi, TOK_PERCENT
    jmp .single
.lparen:
    mov rdi, TOK_LPAREN
    jmp .single
.rparen:
    mov rdi, TOK_RPAREN
    jmp .single
.lbracket:
    mov rdi, TOK_LBRACKET
    jmp .single
.rbracket:
    mov rdi, TOK_RBRACKET
    jmp .single
.dot:
    mov rdi, TOK_DOT
    jmp .single
.slash:
    mov rax, r12
    inc rax
    cmp rax, r13
    jae .slash_single
    cmp byte [src_buf + rax], '/'
    je .line_comment
    cmp byte [src_buf + rax], '*'
    je .block_comment
.slash_single:
    mov rdi, TOK_SLASH
    jmp .single
.comma:
    mov rdi, TOK_COMMA
    jmp .single
.semicolon:
    mov rdi, TOK_SEMICOLON
    jmp .single
.eq_or_ee:
    mov rax, r12
    inc rax
    cmp rax, r13
    jae .eq_single
    cmp byte [src_buf + rax], '='
    jne .eq_single
    mov rdi, TOK_EE
    mov rsi, r12
    mov rdx, 2
    mov rcx, r14
    mov r8, r15
    xor r9, r9
    call token_add
    test rax, rax
    jnz .fail
    add r12, 2
    add r15, 2
    jmp .loop
.eq_single:
    mov rdi, TOK_EQ
    jmp .single
.gt_or_ge:
    mov rax, r12
    inc rax
    cmp rax, r13
    jae .gt_single
    cmp byte [src_buf + rax], '='
    jne .gt_single
    mov rdi, TOK_GE
    mov rsi, r12
    mov rdx, 2
    mov rcx, r14
    mov r8, r15
    xor r9, r9
    call token_add
    test rax, rax
    jnz .fail
    add r12, 2
    add r15, 2
    jmp .loop
.gt_single:
    mov rdi, TOK_GT
    jmp .single
.lt_or_le:
    mov rax, r12
    inc rax
    cmp rax, r13
    jae .lt_single
    cmp byte [src_buf + rax], '='
    jne .lt_single
    mov rdi, TOK_LE
    mov rsi, r12
    mov rdx, 2
    mov rcx, r14
    mov r8, r15
    xor r9, r9
    call token_add
    test rax, rax
    jnz .fail
    add r12, 2
    add r15, 2
    jmp .loop
.lt_single:
    mov rdi, TOK_LT
    jmp .single
.bang_or_ne:
    mov rax, r12
    inc rax
    cmp rax, r13
    jae .invalid
    cmp byte [src_buf + rax], '='
    jne .invalid
    mov rdi, TOK_NE
    mov rsi, r12
    mov rdx, 2
    mov rcx, r14
    mov r8, r15
    xor r9, r9
    call token_add
    test rax, rax
    jnz .fail
    add r12, 2
    add r15, 2
    jmp .loop
.single:
    mov rsi, r12
    mov rdx, 1
    mov rcx, r14
    mov r8, r15
    xor r9, r9
    call token_add
    test rax, rax
    jnz .fail
    inc r12
    inc r15
    jmp .loop

; Address-of operator
.amp:
    mov rdi, TOK_AMP
    jmp .single

; Left brace
.lbrace:
    mov rdi, TOK_LBRACE
    jmp .single

; Right brace
.rbrace:
    mov rdi, TOK_RBRACE
    jmp .single
