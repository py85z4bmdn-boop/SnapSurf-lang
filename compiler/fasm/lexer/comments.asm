; lexer/comments.asm — Line and block comment scanning.

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

.unexpected_eof:
    mov [diag_line], r14
    mov [diag_col], r15
    mov rdi, src_path
    mov rsi, err_eof
    call print_diag
    mov rax, 1
    ret
