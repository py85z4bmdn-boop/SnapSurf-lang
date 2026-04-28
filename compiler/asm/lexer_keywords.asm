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
