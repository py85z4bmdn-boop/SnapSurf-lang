; Status: PARTIAL.
; Fixed-capacity token buffer and cursor API.

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
