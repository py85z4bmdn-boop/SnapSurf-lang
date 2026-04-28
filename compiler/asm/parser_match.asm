; Status: PARTIAL.
; Token lookahead, identifier matching, and parser diagnostic positions.

current_is_io_write:
    call expect_ident_text_io
    test rax, rax
    jz .no
    call next_token_kind
    cmp rax, TOK_DOT
    jne .no
    mov rax, 1
    ret
.no:
    xor rax, rax
    ret

next_token_kind:
    mov rdi, [token_index]
    inc rdi
    cmp rdi, [token_count]
    jae .eof
    call token_addr
    mov rax, [rax + TOKEN_TYPE]
    ret
.eof:
    mov rax, TOK_EOF
    ret

expect_ident_text_core:
    mov rsi, text_core
    mov rdx, 4
    jmp current_ident_text_eq
expect_ident_text_io:
    mov rsi, text_io
    mov rdx, 2
    jmp current_ident_text_eq
expect_ident_text_main:
    mov rsi, text_main
    mov rdx, 4
    jmp current_ident_text_eq
expect_ident_text_i32:
    mov rsi, text_i32
    mov rdx, 3
    jmp current_ident_text_eq
expect_ident_text_write:
    mov rsi, text_write
    mov rdx, 5
    jmp current_ident_text_eq

current_ident_text_eq:
    call current_token_kind
    cmp rax, TOK_IDENT
    jne .no
    mov rdi, [token_index]
    call token_text_eq
    ret
.no:
    xor rax, rax
    ret

token_text_eq:
    push rbx
    push r12
    mov r12, rsi
    mov rbx, rdx
    call token_addr
    cmp [rax + TOKEN_LEN], rbx
    jne .no
    mov rdi, src_buf
    add rdi, [rax + TOKEN_START]
    xor rcx, rcx
.loop:
    cmp rcx, rbx
    je .yes
    mov dl, [rdi + rcx]
    cmp dl, [r12 + rcx]
    jne .no
    inc rcx
    jmp .loop
.yes:
    mov rax, 1
    pop r12
    pop rbx
    ret
.no:
    xor rax, rax
    pop r12
    pop rbx
    ret

set_diag_from_current:
    call current_token_addr
    mov rbx, [rax + TOKEN_LINE]
    mov [diag_line], rbx
    mov rbx, [rax + TOKEN_COL]
    mov [diag_col], rbx
    ret
