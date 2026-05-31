; emitter/comparison.asm — Comparison and logical operator emission.

emit_comparison_expr:
    push rbx
    push r12
    push r13
    mov r12, rdi
    mov r13, rsi
    mov rdi, r12
    call ast_child
    mov rdi, rax
    call emit_expr
    test rax, rax
    jnz .fail
    mov rdi, [out_fd]
    mov rsi, asm_push_rax
    mov rdx, asm_push_rax_len
    call write_all

    mov rdi, r12
    call ast_child
    mov rdi, rax
    call ast_next
    mov rdi, rax
    call emit_expr
    test rax, rax
    jnz .fail

    cmp r13, AST_BIN_GT
    je .gt
    cmp r13, AST_BIN_LT
    je .lt
    cmp r13, AST_BIN_GE
    je .ge
    cmp r13, AST_BIN_LE
    je .le
    cmp r13, AST_BIN_EE
    je .ee
    cmp r13, AST_BIN_NE
    je .ne
    jmp .fail

.gt:
    mov rdi, [out_fd]
    mov rsi, asm_cmp_gt
    mov rdx, asm_cmp_gt_len
    call write_all
    jmp .ok
.lt:
    mov rdi, [out_fd]
    mov rsi, asm_cmp_lt
    mov rdx, asm_cmp_lt_len
    call write_all
    jmp .ok
.ge:
    mov rdi, [out_fd]
    mov rsi, asm_cmp_ge
    mov rdx, asm_cmp_ge_len
    call write_all
    jmp .ok
.le:
    mov rdi, [out_fd]
    mov rsi, asm_cmp_le
    mov rdx, asm_cmp_le_len
    call write_all
    jmp .ok
.ee:
    mov rdi, [out_fd]
    mov rsi, asm_cmp_ee
    mov rdx, asm_cmp_ee_len
    call write_all
    jmp .ok
.ne:
    mov rdi, [out_fd]
    mov rsi, asm_cmp_ne
    mov rdx, asm_cmp_ne_len
    call write_all
    jmp .ok

.ok:
    xor rax, rax
    pop r13
    pop r12
    pop rbx
    ret
.fail:
    mov rax, 1
    pop r13
    pop r12
    pop rbx
    ret

emit_logical_expr:
    push rbx
    push r12
    push r13
    mov r12, rdi
    mov r13, rsi
    mov rdi, r12
    call ast_child
    mov rdi, rax
    call emit_expr
    test rax, rax
    jnz .fail
    mov rdi, [out_fd]
    mov rsi, asm_push_rax
    mov rdx, asm_push_rax_len
    call write_all

    mov rdi, r12
    call ast_child
    mov rdi, rax
    call ast_next
    mov rdi, rax
    call emit_expr
    test rax, rax
    jnz .fail

    cmp r13, AST_BIN_AND
    je .and_op
    cmp r13, AST_BIN_OR
    je .or_op
    jmp .fail

.and_op:
    mov rdi, [out_fd]
    mov rsi, asm_and_rax
    mov rdx, asm_and_rax_len
    call write_all
    jmp .ok
.or_op:
    mov rdi, [out_fd]
    mov rsi, asm_or_rax
    mov rdx, asm_or_rax_len
    call write_all
    jmp .ok

.ok:
    xor rax, rax
    pop r13
    pop r12
    pop rbx
    ret
.fail:
    mov rax, 1
    pop r13
    pop r12
    pop rbx
    ret
