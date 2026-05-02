; lexer/scanner.asm — Core character-by-character scanner loop.
; Handles whitespace, newlines, dispatch to sub-scanners.

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
    cmp al, '['
    je .lbracket
    cmp al, ']'
    je .rbracket
    cmp al, '.'
    je .dot
    cmp al, '/'
    je .slash
    cmp al, ','
    je .comma
    cmp al, ';'
    je .semicolon
    cmp al, '='
    je .eq_or_ee
    cmp al, '>'
    je .gt_or_ge
    cmp al, '<'
    je .lt_or_le
    cmp al, '!'
    je .bang_or_ne
    cmp al, '&'
    je .amp
    ; Use branchless LUT for ident/digit classification (opt/chartab.asm)
    call opt_is_ident_start
    test rax, rax
    jnz .ident
    mov al, [src_buf + r12]
    call opt_is_digit
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

.fail:
    ret
