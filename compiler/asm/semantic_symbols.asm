; Status: PARTIAL.
; Fixed-capacity local symbol table for the foundation checker/emitter.

semantic_ident_token:
    call ast_child
    ret

symbol_add:
    push rbx
    push r12
    push r13
    push r14
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    call symbol_find_current_scope
    test rax, rax
    jnz .duplicate
    mov rbx, [sym_count]
    cmp rbx, SYM_CAP
    jae .overflow
    mov rdi, r12
    call token_addr
    mov rdx, rbx
    imul rdx, 8
    mov rcx, [rax + TOKEN_START]
    mov [sym_start + rdx], rcx
    mov rcx, [rax + TOKEN_LEN]
    mov [sym_len + rdx], rcx
    mov [sym_mut + rdx], r13
    mov [sym_type + rdx], r14
    mov rcx, [slot_cursor]
    inc rcx
    mov [sym_slot + rdx], rcx
    mov [slot_cursor], rcx
    cmp rcx, [local_count]
    jbe .count_ok
    mov [local_count], rcx
.count_ok:
    inc qword [sym_count]
    xor rax, rax
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.duplicate:
    mov rdi, r12
    call set_diag_from_token
    mov rdi, src_path
    mov rsi, err_duplicate
    call print_diag
    mov rax, 1
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.overflow:
    mov rdi, r12
    call set_diag_from_token
    mov rdi, src_path
    mov rsi, err_symbol_overflow
    call print_diag
    mov rax, 1
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

symbol_find_current_scope:
    push rbx
    push r12
    push r13
    push r14
    mov r12, rdi
    mov r13, [sym_count]
    test r13, r13
    jz .not_found
    mov r14, [scope_depth]
    test r14, r14
    jz .base_zero
    dec r14
    imul r14, 8
    mov r14, [scope_sym_base + r14]
    jmp .scan
.base_zero:
    xor r14, r14
.scan:
    mov rbx, r13
    dec rbx
.loop:
    cmp rbx, r14
    jb .not_found
    mov rax, rbx
    imul rax, 8
    mov rsi, src_buf
    add rsi, [sym_start + rax]
    mov rdx, [sym_len + rax]
    mov rdi, r12
    call token_text_eq
    test rax, rax
    jnz .found
    test rbx, rbx
    jz .not_found
    dec rbx
    jmp .loop
.found:
    mov rax, rbx
    inc rax
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.not_found:
    xor rax, rax
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

symbol_find:
    push rbx
    push r12
    push r13
    mov r12, rdi
    mov r13, [sym_count]
    test r13, r13
    jz .not_found
    mov rbx, r13
    dec rbx
.loop:
    mov rax, rbx
    imul rax, 8
    mov rsi, src_buf
    add rsi, [sym_start + rax]
    mov rdx, [sym_len + rax]
    mov rdi, r12
    call token_text_eq
    test rax, rax
    jnz .found
    test rbx, rbx
    jz .not_found
    inc rbx
    sub rbx, 2
    jmp .loop
.found:
    mov rax, rbx
    inc rax
    pop r13
    pop r12
    pop rbx
    ret
.not_found:
    xor rax, rax
    pop r13
    pop r12
    pop rbx
    ret

symbol_slot_for_token:
    call symbol_find
    test rax, rax
    jz .missing
    dec rax
    imul rax, 8
    mov rax, [sym_slot + rax]
    ret
.missing:
    xor rax, rax
    ret
