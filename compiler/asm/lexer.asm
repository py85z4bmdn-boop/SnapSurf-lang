; Status: PARTIAL.
; Implemented foundation token buffer lexer for the hello-world subset.

lex_source_subset:
    mov qword [token_count], 0
    mov qword [token_index], 0
    mov qword [string_pool_len], 0
    xor r12, r12
    mov r13, [src_len]
    mov r14, 1
    mov r15, 1

.loop:
    cmp r12, r13
    jae .eof
    mov al, [src_buf + r12]

    cmp al, ' '
    je .space
    cmp al, 9
    je .space
    cmp al, 10
    je .newline_lf
    cmp al, 13
    je .newline_cr
    cmp al, '"'
    je .string
    cmp al, '+'
    je .plus
    cmp al, '-'
    je .maybe_arrow
    cmp al, '*'
    je .star
    cmp al, '%'
    je .percent
    cmp al, '('
    je .lparen
    cmp al, ')'
    je .rparen
    cmp al, '.'
    je .dot
    cmp al, '/'
    je .slash
    cmp al, ','
    je .comma
    cmp al, '='
    je .eq
    call is_ident_start_al
    test rax, rax
    jnz .ident
    mov al, [src_buf + r12]
    call is_digit_al
    test rax, rax
    jnz .int
    jmp .invalid

.space:
    inc r12
    inc r15
    jmp .loop

.newline_lf:
    mov rdi, TOK_NEWLINE
    mov rsi, r12
    mov rdx, 1
    mov rcx, r14
    mov r8, r15
    xor r9, r9
    call token_add
    test rax, rax
    jnz .fail
    inc r12
    inc r14
    mov r15, 1
    jmp .loop

.newline_cr:
    mov rbx, 1
    mov rax, r12
    inc rax
    cmp rax, r13
    jae .emit_cr
    cmp byte [src_buf + rax], 10
    jne .emit_cr
    mov rbx, 2
.emit_cr:
    mov rdi, TOK_NEWLINE
    mov rsi, r12
    mov rdx, rbx
    mov rcx, r14
    mov r8, r15
    xor r9, r9
    call token_add
    test rax, rax
    jnz .fail
    add r12, rbx
    inc r14
    mov r15, 1
    jmp .loop

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
.eq:
    mov rdi, TOK_EQ
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

.line_comment:
    add r12, 2
    add r15, 2
.line_comment_loop:
    cmp r12, r13
    jae .eof
    mov al, [src_buf + r12]
    cmp al, 10
    je .loop
    cmp al, 13
    je .loop
    inc r12
    inc r15
    jmp .line_comment_loop

.block_comment:
    add r12, 2
    add r15, 2
.block_comment_loop:
    cmp r12, r13
    jae .unexpected_eof
    mov al, [src_buf + r12]
    cmp al, 10
    je .block_comment_lf
    cmp al, 13
    je .block_comment_cr
    cmp al, '*'
    jne .block_comment_step
    mov rax, r12
    inc rax
    cmp rax, r13
    jae .unexpected_eof
    cmp byte [src_buf + rax], '/'
    je .block_comment_done
.block_comment_step:
    inc r12
    inc r15
    jmp .block_comment_loop
.block_comment_lf:
    inc r12
    inc r14
    mov r15, 1
    jmp .block_comment_loop
.block_comment_cr:
    inc r12
    inc r14
    mov r15, 1
    cmp r12, r13
    jae .block_comment_loop
    cmp byte [src_buf + r12], 10
    jne .block_comment_loop
    inc r12
    jmp .block_comment_loop
.block_comment_done:
    add r12, 2
    add r15, 2
    jmp .loop

.ident:
    mov rbx, r12
    mov r10, r14
    mov r11, r15
.ident_loop:
    cmp r12, r13
    jae .ident_done
    mov al, [src_buf + r12]
    call is_ident_rest_al
    test rax, rax
    jz .ident_done
    inc r12
    inc r15
    jmp .ident_loop
.ident_done:
    mov rdi, src_buf
    add rdi, rbx
    mov rsi, r12
    sub rsi, rbx
    call keyword_kind
    mov rdi, rax
    mov rsi, rbx
    mov rdx, r12
    sub rdx, rbx
    mov rcx, r10
    mov r8, r11
    xor r9, r9
    call token_add
    test rax, rax
    jnz .fail
    jmp .loop

.int:
    mov rbx, r12
    mov r10, r14
    mov r11, r15
    xor r9, r9
.int_loop:
    cmp r12, r13
    jae .int_done
    mov al, [src_buf + r12]
    call is_digit_al
    test rax, rax
    jz .int_done
    imul r9, r9, 10
    movzx rax, byte [src_buf + r12]
    sub rax, '0'
    add r9, rax
    inc r12
    inc r15
    jmp .int_loop
.int_done:
    mov rdi, TOK_INT
    mov rsi, rbx
    mov rdx, r12
    sub rdx, rbx
    mov rcx, r10
    mov r8, r11
    call token_add
    test rax, rax
    jnz .fail
    jmp .loop

.string:
    mov rbx, r12
    mov r10, r14
    mov r11, r15
    mov rax, [string_pool_len]
    mov [tmp_payload], rax
    xor r8, r8
    inc r12
    inc r15
.string_loop:
    cmp r12, r13
    jae .unterminated
    mov al, [src_buf + r12]
    cmp al, '"'
    je .string_done
    cmp al, 10
    je .unterminated
    cmp al, 13
    je .unterminated
    cmp al, 92
    je .escape
    call string_store_al
    inc r8
    inc r12
    inc r15
    jmp .string_loop
.escape:
    inc r12
    inc r15
    cmp r12, r13
    jae .unterminated
    mov al, [src_buf + r12]
    cmp al, 'n'
    je .esc_n
    cmp al, 't'
    je .esc_t
    cmp al, 'r'
    je .esc_r
    cmp al, 92
    je .esc_raw
    cmp al, '"'
    je .esc_raw
    cmp al, '0'
    je .esc_zero
    cmp al, 'x'
    je .bad_escape
    jmp .bad_escape
.esc_n:
    mov al, 10
    jmp .esc_store
.esc_t:
    mov al, 9
    jmp .esc_store
.esc_r:
    mov al, 13
    jmp .esc_store
.esc_zero:
    xor al, al
    jmp .esc_store
.esc_raw:
    mov al, [src_buf + r12]
.esc_store:
    call string_store_al
    inc r8
    inc r12
    inc r15
    jmp .string_loop
.string_done:
    inc r12
    inc r15
    mov rax, [string_pool_len]
    add rax, r8
    mov [string_pool_len], rax
    mov rdi, TOK_STRING
    mov rsi, rbx
    mov rdx, r8
    mov rcx, r10
    mov r8, r11
    mov r9, [tmp_payload]
    call token_add
    test rax, rax
    jnz .fail
    jmp .loop

.eof:
    mov rdi, TOK_EOF
    mov rsi, r12
    xor rdx, rdx
    mov rcx, r14
    mov r8, r15
    xor r9, r9
    call token_add
    test rax, rax
    jnz .fail
    xor rax, rax
    ret

.invalid:
    mov rdi, TOK_ERROR
    mov rsi, r12
    mov rdx, 1
    mov rcx, r14
    mov r8, r15
    xor r9, r9
    call token_add
    mov [diag_line], r14
    mov [diag_col], r15
    mov rdi, src_path
    mov rsi, err_bad_char
    call print_diag
    mov rax, 1
    ret

.unterminated:
    mov [diag_line], r14
    mov [diag_col], r15
    mov rdi, src_path
    mov rsi, err_unterm_string
    call print_diag
    mov rax, 1
    ret

.bad_escape:
    mov [diag_line], r14
    mov [diag_col], r15
    mov rdi, src_path
    mov rsi, err_bad_escape
    call print_diag
    mov rax, 1
    ret
.unexpected_eof:
    mov [diag_line], r14
    mov [diag_col], r15
    mov rdi, src_path
    mov rsi, err_eof
    call print_diag
    mov rax, 1
    ret
.fail:
    ret

string_store_al:
    push rbx
    mov rbx, [tmp_payload]
    add rbx, r8
    cmp rbx, MAX_STRING
    jae .skip
    mov [str_buf + rbx], al
.skip:
    pop rbx
    ret

token_add:
    mov r10, [token_count]
    cmp r10, TOKEN_CAP
    jae .overflow
    mov r11, r10
    imul r11, TOKEN_SIZE
    mov [token_buf + r11 + TOKEN_TYPE], rdi
    mov [token_buf + r11 + TOKEN_START], rsi
    mov [token_buf + r11 + TOKEN_LEN], rdx
    mov [token_buf + r11 + TOKEN_LINE], rcx
    mov [token_buf + r11 + TOKEN_COL], r8
    mov [token_buf + r11 + TOKEN_PAYLOAD], r9
    inc qword [token_count]
    xor rax, rax
    ret
.overflow:
    mov rdi, src_path
    mov rsi, err_token_overflow
    call print_diag
    mov rax, 1
    ret

token_addr:
    mov rax, rdi
    imul rax, TOKEN_SIZE
    add rax, token_buf
    ret

current_token_addr:
    mov rdi, [token_index]
    call token_addr
    ret

current_token_kind:
    call current_token_addr
    mov rax, [rax + TOKEN_TYPE]
    ret

advance_token:
    mov rax, [token_index]
    cmp rax, [token_count]
    jae .done
    inc qword [token_index]
.done:
    ret

skip_newline_tokens:
.loop:
    call current_token_kind
    cmp rax, TOK_NEWLINE
    jne .done
    call advance_token
    jmp .loop
.done:
    ret

keyword_kind:
    cmp rsi, 2
    je .len2
    cmp rsi, 3
    je .len3
    cmp rsi, 4
    je .len4
    cmp rsi, 5
    je .len5
    jmp .ident
.len2:
    cmp byte [rdi], 'f'
    jne .ident
    cmp byte [rdi + 1], 'n'
    jne .ident
    mov rax, TOK_FN
    ret
.len3:
    cmp byte [rdi], 'u'
    jne .check_ret
    cmp byte [rdi + 1], 's'
    jne .ident
    cmp byte [rdi + 2], 'e'
    jne .ident
    mov rax, TOK_USE
    ret
.check_ret:
    cmp byte [rdi], 'r'
    jne .check_end
    cmp byte [rdi + 1], 'e'
    jne .ident
    cmp byte [rdi + 2], 't'
    jne .ident
    mov rax, TOK_RET
    ret
.check_end:
    cmp byte [rdi], 'e'
    jne .check_let
    cmp byte [rdi + 1], 'n'
    jne .ident
    cmp byte [rdi + 2], 'd'
    jne .ident
    mov rax, TOK_END
    ret
.check_let:
    cmp byte [rdi], 'l'
    jne .check_mut
    cmp byte [rdi + 1], 'e'
    jne .ident
    cmp byte [rdi + 2], 't'
    jne .ident
    mov rax, TOK_LET
    ret
.check_mut:
    cmp byte [rdi], 'm'
    jne .ident
    cmp byte [rdi + 1], 'u'
    jne .ident
    cmp byte [rdi + 2], 't'
    jne .ident
    mov rax, TOK_MUT
    ret
.len4:
    cmp byte [rdi], 't'
    jne .ident
    cmp byte [rdi + 1], 'r'
    jne .ident
    cmp byte [rdi + 2], 'u'
    jne .ident
    cmp byte [rdi + 3], 'e'
    jne .ident
    mov rax, TOK_TRUE
    ret
.len5:
    cmp byte [rdi], 'f'
    jne .ident
    cmp byte [rdi + 1], 'a'
    jne .ident
    cmp byte [rdi + 2], 'l'
    jne .ident
    cmp byte [rdi + 3], 's'
    jne .ident
    cmp byte [rdi + 4], 'e'
    jne .ident
    mov rax, TOK_FALSE
    ret
.ident:
    mov rax, TOK_IDENT
    ret

is_ident_start_al:
    cmp al, '_'
    je .yes
    cmp al, 'A'
    jb .no
    cmp al, 'Z'
    jbe .yes
    cmp al, 'a'
    jb .no
    cmp al, 'z'
    jbe .yes
.no:
    xor rax, rax
    ret
.yes:
    mov rax, 1
    ret

is_ident_rest_al:
    call is_ident_start_al
    test rax, rax
    jnz .yes
    mov al, [src_buf + r12]
    call is_digit_al
    ret
.yes:
    mov rax, 1
    ret

is_digit_al:
    cmp al, '0'
    jb .no
    cmp al, '9'
    ja .no
    mov rax, 1
    ret
.no:
    xor rax, rax
    ret

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
.newline:
    mov rax, tok_name_newline
    ret
