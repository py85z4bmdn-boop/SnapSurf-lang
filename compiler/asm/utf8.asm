; Implemented foundation subset: no BOM and strict UTF-8 validation.

validate_source_bytes:
    mov rsi, src_buf
    mov rcx, [src_len]
    cmp rcx, 3
    jb .utf8
    cmp byte [rsi], 0xEF
    jne .utf8
    cmp byte [rsi + 1], 0xBB
    jne .utf8
    cmp byte [rsi + 2], 0xBF
    jne .utf8
    mov rdi, src_path
    mov rsi, err_bom
    call print_diag
    mov rax, 1
    ret

.utf8:
    mov rsi, src_buf
    mov rcx, [src_len]
    call validate_utf8_buffer
    test rax, rax
    jnz .bad
    xor rax, rax
    ret
.bad:
    mov rdi, src_path
    mov rsi, err_utf8
    call print_diag
    mov rax, 1
    ret

validate_utf8_buffer:
    test rcx, rcx
    je .ok
.loop:
    mov al, [rsi]
    cmp al, 0x80
    jb .one
    cmp al, 0xC2
    jb .bad
    cmp al, 0xDF
    jbe .two
    cmp al, 0xE0
    je .three_e0
    cmp al, 0xEC
    jbe .three
    cmp al, 0xED
    je .three_ed
    cmp al, 0xEF
    jbe .three
    cmp al, 0xF0
    je .four_f0
    cmp al, 0xF3
    jbe .four
    cmp al, 0xF4
    je .four_f4
    jmp .bad

.one:
    inc rsi
    dec rcx
    jnz .loop
    jmp .ok

.two:
    cmp rcx, 2
    jb .bad
    mov al, [rsi + 1]
    call is_cont
    test rax, rax
    jz .bad
    add rsi, 2
    sub rcx, 2
    jnz .loop
    jmp .ok

.three_e0:
    cmp rcx, 3
    jb .bad
    mov al, [rsi + 1]
    cmp al, 0xA0
    jb .bad
    cmp al, 0xBF
    ja .bad
    mov al, [rsi + 2]
    call is_cont
    test rax, rax
    jz .bad
    add rsi, 3
    sub rcx, 3
    jnz .loop
    jmp .ok

.three_ed:
    cmp rcx, 3
    jb .bad
    mov al, [rsi + 1]
    cmp al, 0x80
    jb .bad
    cmp al, 0x9F
    ja .bad
    mov al, [rsi + 2]
    call is_cont
    test rax, rax
    jz .bad
    add rsi, 3
    sub rcx, 3
    jnz .loop
    jmp .ok

.three:
    cmp rcx, 3
    jb .bad
    mov al, [rsi + 1]
    call is_cont
    test rax, rax
    jz .bad
    mov al, [rsi + 2]
    call is_cont
    test rax, rax
    jz .bad
    add rsi, 3
    sub rcx, 3
    jnz .loop
    jmp .ok

.four_f0:
    cmp rcx, 4
    jb .bad
    mov al, [rsi + 1]
    cmp al, 0x90
    jb .bad
    cmp al, 0xBF
    ja .bad
    jmp .four_tail

.four_f4:
    cmp rcx, 4
    jb .bad
    mov al, [rsi + 1]
    cmp al, 0x80
    jb .bad
    cmp al, 0x8F
    ja .bad
    jmp .four_tail

.four:
    cmp rcx, 4
    jb .bad
    mov al, [rsi + 1]
    call is_cont
    test rax, rax
    jz .bad

.four_tail:
    mov al, [rsi + 2]
    call is_cont
    test rax, rax
    jz .bad
    mov al, [rsi + 3]
    call is_cont
    test rax, rax
    jz .bad
    add rsi, 4
    sub rcx, 4
    jnz .loop
    jmp .ok

.ok:
    xor rax, rax
    ret
.bad:
    mov rax, 1
    ret

is_cont:
    cmp al, 0x80
    jb .no
    cmp al, 0xBF
    ja .no
    mov rax, 1
    ret
.no:
    xor rax, rax
    ret

