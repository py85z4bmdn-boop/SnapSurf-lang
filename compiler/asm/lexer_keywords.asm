; Status: PARTIAL.
; Keyword and ASCII identifier classification for the current source subset.

keyword_kind:
    cmp rsi, 2
    je .len2
    cmp rsi, 3
    je .len3
    cmp rsi, 4
    je .len4
    cmp rsi, 5
    je .len5
    cmp rsi, 6
    je .len6
    cmp rsi, 8
    je .len8
    jmp .ident
.len2:
    cmp byte [rdi], 'f'
    je .check_fn
    cmp byte [rdi], 'i'
    je .check_if
    cmp byte [rdi], 'o'
    je .check_or
    jmp .ident
.check_fn:
    cmp byte [rdi + 1], 'n'
    jne .ident
    mov rax, TOK_FN
    ret
.check_if:
    cmp byte [rdi + 1], 'f'
    jne .ident
    mov rax, TOK_IF
    ret
.check_or:
    cmp byte [rdi + 1], 'r'
    jne .ident
    mov rax, TOK_OR
    ret
.len3:
    cmp byte [rdi], 'u'
    je .check_use
    cmp byte [rdi], 'a'
    je .check_and
    cmp byte [rdi], 'n'
    je .check_not
    cmp byte [rdi], 'r'
    je .check_ret
    cmp byte [rdi], 'e'
    je .check_end
    cmp byte [rdi], 'l'
    je .check_let
    cmp byte [rdi], 'm'
    je .check_mut
    jmp .ident
.check_use:
    cmp byte [rdi + 1], 's'
    jne .ident
    cmp byte [rdi + 2], 'e'
    jne .ident
    mov rax, TOK_USE
    ret
.check_and:
    cmp byte [rdi + 1], 'n'
    jne .ident
    cmp byte [rdi + 2], 'd'
    jne .ident
    mov rax, TOK_AND
    ret
.check_not:
    cmp byte [rdi + 1], 'o'
    jne .ident
    cmp byte [rdi + 2], 't'
    jne .ident
    mov rax, TOK_NOT
    ret
.check_ret:
    cmp byte [rdi + 1], 'e'
    jne .ident
    cmp byte [rdi + 2], 't'
    jne .ident
    mov rax, TOK_RET
    ret
.check_end:
    cmp byte [rdi + 1], 'n'
    jne .ident
    cmp byte [rdi + 2], 'd'
    jne .ident
    mov rax, TOK_END
    ret
.check_let:
    cmp byte [rdi + 1], 'e'
    jne .ident
    cmp byte [rdi + 2], 't'
    jne .ident
    mov rax, TOK_LET
    ret
.check_mut:
    cmp byte [rdi + 1], 'u'
    jne .ident
    cmp byte [rdi + 2], 't'
    jne .ident
    mov rax, TOK_MUT
    ret
.len4:
    cmp byte [rdi], 'c'
    je .check_call
    cmp byte [rdi], 't'
    je .check_true
    cmp byte [rdi], 'e'
    je .check_else_or_elif
    cmp byte [rdi], 'l'
    je .check_loop
    jmp .ident
.check_call:
    cmp byte [rdi + 1], 'a'
    jne .ident
    cmp byte [rdi + 2], 'l'
    jne .ident
    cmp byte [rdi + 3], 'l'
    jne .ident
    mov rax, TOK_CALL
    ret
.check_true:
    cmp byte [rdi + 1], 'r'
    jne .ident
    cmp byte [rdi + 2], 'u'
    jne .ident
    cmp byte [rdi + 3], 'e'
    jne .ident
    mov rax, TOK_TRUE
    ret
.check_else_or_elif:
    cmp byte [rdi + 1], 'l'
    jne .ident
    cmp byte [rdi + 2], 's'
    jne .check_elif
    cmp byte [rdi + 3], 'e'
    jne .ident
    mov rax, TOK_ELSE
    ret
.check_elif:
    cmp byte [rdi + 2], 'i'
    jne .ident
    cmp byte [rdi + 3], 'f'
    jne .ident
    mov rax, TOK_ELIF
    ret
.check_loop:
    cmp byte [rdi + 1], 'o'
    jne .ident
    cmp byte [rdi + 2], 'o'
    jne .ident
    cmp byte [rdi + 3], 'p'
    jne .ident
    mov rax, TOK_LOOP
    ret
.len5:
    cmp byte [rdi], 'f'
    je .check_false
    cmp byte [rdi], 'w'
    je .check_while
    cmp byte [rdi], 'b'
    je .check_break
    cmp byte [rdi], 'c'
    je .check_const
    cmp byte [rdi], 'p'
    je .check_print
    jmp .ident
.check_false:
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
.check_while:
    cmp byte [rdi + 1], 'h'
    jne .ident
    cmp byte [rdi + 2], 'i'
    jne .ident
    cmp byte [rdi + 3], 'l'
    jne .ident
    cmp byte [rdi + 4], 'e'
    jne .ident
    mov rax, TOK_WHILE
    ret
.check_break:
    cmp byte [rdi + 1], 'r'
    jne .ident
    cmp byte [rdi + 2], 'e'
    jne .ident
    cmp byte [rdi + 3], 'a'
    jne .ident
    cmp byte [rdi + 4], 'k'
    jne .ident
    mov rax, TOK_BREAK
    ret
.check_const:
    cmp byte [rdi + 1], 'o'
    jne .ident
    cmp byte [rdi + 2], 'n'
    jne .ident
    cmp byte [rdi + 3], 's'
    jne .ident
    cmp byte [rdi + 4], 't'
    jne .ident
    mov rax, TOK_CONST
    ret
.check_print:
    cmp byte [rdi + 1], 'r'
    jne .ident
    cmp byte [rdi + 2], 'i'
    jne .ident
    cmp byte [rdi + 3], 'n'
    jne .ident
    cmp byte [rdi + 4], 't'
    jne .ident
    mov rax, TOK_PRINT
    ret
.len6:
    cmp byte [rdi], 'u'
    je .check_unsafe
    jmp .ident
.check_unsafe:
    cmp byte [rdi + 1], 'n'
    jne .ident
    cmp byte [rdi + 2], 's'
    jne .ident
    cmp byte [rdi + 3], 'a'
    jne .ident
    cmp byte [rdi + 4], 'f'
    jne .ident
    cmp byte [rdi + 5], 'e'
    jne .ident
    mov rax, TOK_UNSAFE
    ret
.len8:
    cmp byte [rdi], 'c'
    jne .ident
    cmp byte [rdi + 1], 'o'
    jne .ident
    cmp byte [rdi + 2], 'n'
    jne .ident
    cmp byte [rdi + 3], 't'
    jne .ident
    cmp byte [rdi + 4], 'i'
    jne .ident
    cmp byte [rdi + 5], 'n'
    jne .ident
    cmp byte [rdi + 6], 'u'
    jne .ident
    cmp byte [rdi + 7], 'e'
    jne .ident
    mov rax, TOK_CONTINUE
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
