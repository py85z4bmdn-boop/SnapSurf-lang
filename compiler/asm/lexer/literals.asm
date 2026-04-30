; lexer/literals.asm — Identifier, integer, and string literal scanning.

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
    cmp rdi, TOK_TRUE
    jne .not_true
    mov r9, 1
.not_true:
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
