; Status: PARTIAL.
; Human-readable token dump names used by the fixture-backed debug command.

dump_tokens:
    xor r12, r12
.loop:
    cmp r12, [token_count]
    jae .done
    mov rdi, r12
    call token_addr
    mov rdi, [rax + TOKEN_TYPE]
    call token_name_ptr
    mov rdi, rax
    call print_stdout_z
    inc r12
    jmp .loop
.done:
    ret

token_name_ptr:
    cmp rdi, TOK_EOF
    je .eof
    cmp rdi, TOK_IDENT
    je .ident
    cmp rdi, TOK_INT
    je .int
    cmp rdi, TOK_STRING
    je .str
    cmp rdi, TOK_ERROR
    je .err
    cmp rdi, TOK_USE
    je .use
    cmp rdi, TOK_FN
    je .fn
    cmp rdi, TOK_RET
    je .ret
    cmp rdi, TOK_END
    je .end
    cmp rdi, TOK_TRUE
    je .true
    cmp rdi, TOK_FALSE
    je .false
    cmp rdi, TOK_LET
    je .let
    cmp rdi, TOK_MUT
    je .mut
    cmp rdi, TOK_IF
    je .if
    cmp rdi, TOK_ELSE
    je .else
    cmp rdi, TOK_WHILE
    je .while
    cmp rdi, TOK_LOOP
    je .loop
    cmp rdi, TOK_BREAK
    je .break
    cmp rdi, TOK_AND
    je .and
    cmp rdi, TOK_OR
    je .or
    cmp rdi, TOK_NOT
    je .not
    cmp rdi, TOK_ARROW
    je .arrow
    cmp rdi, TOK_DOT
    je .dot
    cmp rdi, TOK_SLASH
    je .slash
    cmp rdi, TOK_COMMA
    je .comma
    cmp rdi, TOK_EQ
    je .eq
    cmp rdi, TOK_PLUS
    je .plus
    cmp rdi, TOK_MINUS
    je .minus
    cmp rdi, TOK_STAR
    je .star
    cmp rdi, TOK_PERCENT
    je .percent
    cmp rdi, TOK_LPAREN
    je .lparen
    cmp rdi, TOK_RPAREN
    je .rparen
    cmp rdi, TOK_GT
    je .gt
    cmp rdi, TOK_LT
    je .lt
    cmp rdi, TOK_GE
    je .ge
    cmp rdi, TOK_LE
    je .le
    cmp rdi, TOK_EE
    je .ee
    cmp rdi, TOK_NE
    je .ne
    cmp rdi, TOK_NEWLINE
    je .newline
    mov rax, tok_name_unknown
    ret
.eof:
    mov rax, tok_name_eof
    ret
.ident:
    mov rax, tok_name_ident
    ret
.int:
    mov rax, tok_name_int
    ret
.str:
    mov rax, tok_name_str
    ret
.err:
    mov rax, tok_name_error
    ret
.use:
    mov rax, tok_name_use
    ret
.fn:
    mov rax, tok_name_fn
    ret
.ret:
    mov rax, tok_name_ret
    ret
.end:
    mov rax, tok_name_end
    ret
.true:
    mov rax, tok_name_true
    ret
.false:
    mov rax, tok_name_false
    ret
.let:
    mov rax, tok_name_let
    ret
.mut:
    mov rax, tok_name_mut
    ret
.if:
    mov rax, tok_name_if
    ret
.else:
    mov rax, tok_name_else
    ret
.while:
    mov rax, tok_name_while
    ret
.loop:
    mov rax, tok_name_loop
    ret
.break:
    mov rax, tok_name_break
    ret
.and:
    mov rax, tok_name_and
    ret
.or:
    mov rax, tok_name_or
    ret
.not:
    mov rax, tok_name_not
    ret
.arrow:
    mov rax, tok_name_arrow
    ret
.dot:
    mov rax, tok_name_dot
    ret
.slash:
    mov rax, tok_name_slash
    ret
.comma:
    mov rax, tok_name_comma
    ret
.eq:
    mov rax, tok_name_eq
    ret
.plus:
    mov rax, tok_name_plus
    ret
.minus:
    mov rax, tok_name_minus
    ret
.star:
    mov rax, tok_name_star
    ret
.percent:
    mov rax, tok_name_percent
    ret
.lparen:
    mov rax, tok_name_lparen
    ret
.rparen:
    mov rax, tok_name_rparen
    ret
.gt:
    mov rax, tok_name_gt
    ret
.lt:
    mov rax, tok_name_lt
    ret
.ge:
    mov rax, tok_name_ge
    ret
.le:
    mov rax, tok_name_le
    ret
.ee:
    mov rax, tok_name_ee
    ret
.ne:
    mov rax, tok_name_ne
    ret
.newline:
    mov rax, tok_name_newline
    ret
