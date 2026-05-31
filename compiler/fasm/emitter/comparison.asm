; emitter/comparison.asm — Comparison and logical operator emission.

emit_comparison_expr:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r13, rsi
    mov rdi, r12
    call ast_child
    mov rbx, rax
    test rbx, rbx
    jz .fail
    mov rdi, rbx
    call semantic_expr_type
    test rax, rax
    jz .fail
    mov r14, rax
    mov rdi, rbx
    call ast_next
    mov r15, rax
    test r15, r15
    jz .fail
    mov rdi, r15
    call semantic_expr_type
    test rax, rax
    jz .fail
    push rax
    mov rdi, rbx
    call ast_kind
    pop rdx
    cmp rax, AST_INT_LIT
    je .use_right_type
    cmp rax, AST_UNARY_NEG
    jne .type_selected
.use_right_type:
    mov r14, rdx
.type_selected:
    mov rdi, r14
    call emit_type_is_unsigned_integer
    mov r14, rax
    mov rdi, rbx
    call emit_expr
    test rax, rax
    jnz .fail
    mov rdi, [out_fd]
    mov rsi, asm_push_rax
    mov rdx, asm_push_rax_len
    call write_all

    mov rdi, r15
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
    test r14, r14
    jnz .ugt
    mov rdi, [out_fd]
    mov rsi, asm_cmp_gt
    mov rdx, asm_cmp_gt_len
    call write_all
    jmp .ok
.ugt:
    mov rdi, [out_fd]
    mov rsi, asm_cmp_ugt
    mov rdx, asm_cmp_ugt_len
    call write_all
    jmp .ok
.lt:
    test r14, r14
    jnz .ult
    mov rdi, [out_fd]
    mov rsi, asm_cmp_lt
    mov rdx, asm_cmp_lt_len
    call write_all
    jmp .ok
.ult:
    mov rdi, [out_fd]
    mov rsi, asm_cmp_ult
    mov rdx, asm_cmp_ult_len
    call write_all
    jmp .ok
.ge:
    test r14, r14
    jnz .uge
    mov rdi, [out_fd]
    mov rsi, asm_cmp_ge
    mov rdx, asm_cmp_ge_len
    call write_all
    jmp .ok
.uge:
    mov rdi, [out_fd]
    mov rsi, asm_cmp_uge
    mov rdx, asm_cmp_uge_len
    call write_all
    jmp .ok
.le:
    test r14, r14
    jnz .ule
    mov rdi, [out_fd]
    mov rsi, asm_cmp_le
    mov rdx, asm_cmp_le_len
    call write_all
    jmp .ok
.ule:
    mov rdi, [out_fd]
    mov rsi, asm_cmp_ule
    mov rdx, asm_cmp_ule_len
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
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.fail:
    mov rax, 1
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

emit_type_is_unsigned_integer:
    cmp rdi, TYPE_U8
    je .yes
    cmp rdi, TYPE_U16
    je .yes
    cmp rdi, TYPE_U32
    je .yes
    cmp rdi, TYPE_U64
    je .yes
    cmp rdi, TYPE_USIZE
    je .yes
    xor rax, rax
    ret
.yes:
    mov rax, 1
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
    mov rdi, r12
    call emit_normalize_expr_result
    test rax, rax
    jnz .fail
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
