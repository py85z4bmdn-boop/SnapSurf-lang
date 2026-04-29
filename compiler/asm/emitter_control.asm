; Control flow emission: if/else, while, loop, break, continue.
; Loop context stack: break_label_stack/continue_label_stack track exit/start
; labels for nested loops. loop_depth is the current stack depth.

loop_context_push:
    ; rdi = break label, rsi = continue label
    push rbx
    mov rbx, [loop_depth]
    cmp rbx, SCOPE_CAP
    jae .overflow
    imul rbx, 8
    mov [break_label_stack + rbx], rdi
    mov [continue_label_stack + rbx], rsi
    inc qword [loop_depth]
    pop rbx
    ret
.overflow:
    pop rbx
    ret

loop_context_pop:
    cmp qword [loop_depth], 0
    je .done
    dec qword [loop_depth]
.done:
    ret

emit_break_stmt:
    cmp qword [loop_depth], 0
    je .fail
    mov rax, [loop_depth]
    dec rax
    imul rax, 8
    mov rax, [break_label_stack + rax]
    push rax
    mov rdi, [out_fd]
    mov rsi, asm_jmp_pre
    mov rdx, asm_jmp_pre_len
    call write_all
    pop rax
    mov rdi, [out_fd]
    call write_u64_fd
    mov rdi, [out_fd]
    mov rsi, asm_jz_post
    mov rdx, asm_jz_post_len
    call write_all
    xor rax, rax
    ret
.fail:
    mov rax, 1
    ret

emit_continue_stmt:
    cmp qword [loop_depth], 0
    je .fail
    mov rax, [loop_depth]
    dec rax
    imul rax, 8
    mov rax, [continue_label_stack + rax]
    push rax
    mov rdi, [out_fd]
    mov rsi, asm_jmp_pre
    mov rdx, asm_jmp_pre_len
    call write_all
    pop rax
    mov rdi, [out_fd]
    call write_u64_fd
    mov rdi, [out_fd]
    mov rsi, asm_jz_post
    mov rdx, asm_jz_post_len
    call write_all
    xor rax, rax
    ret
.fail:
    mov rax, 1
    ret

; emit_if_stmt: AST structure is
;   if_stmt -> child chain: [condition, then_block, (optional else_block)]
; So: ast_child(if_stmt)=condition, ast_next(condition)=then_block,
;     ast_next(then_block)=else_block or NULL.
emit_if_stmt:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r13, [label_counter]
    inc qword [label_counter]
    mov r14, [label_counter]
    inc qword [label_counter]

    ; Get condition (first child of if_stmt)
    mov rdi, r12
    call ast_child
    mov r15, rax            ; r15 = condition node
    mov rdi, r15
    call emit_expr
    test rax, rax
    jnz .fail

    ; Emit: test rax,rax / jz .Lelse
    mov rdi, [out_fd]
    mov rsi, asm_jz_pre
    mov rdx, asm_jz_pre_len
    call write_all
    mov rax, r13
    mov rdi, [out_fd]
    call write_u64_fd
    mov rdi, [out_fd]
    mov rsi, asm_jz_post
    mov rdx, asm_jz_post_len
    call write_all

    ; Get then-block (second child = ast_next(condition))
    mov rdi, r15
    call ast_next
    mov r15, rax            ; r15 = then_block
    mov rdi, r15
    call emit_block
    test rax, rax
    jnz .fail

    ; Check for else-block (third child = ast_next(then_block))
    mov rdi, r15
    call ast_next
    test rax, rax
    jz .no_else
    mov r15, rax            ; r15 = else_block

    ; Emit: jmp .Lend (skip else)
    mov rdi, [out_fd]
    mov rsi, asm_jmp_pre
    mov rdx, asm_jmp_pre_len
    call write_all
    mov rax, r14
    mov rdi, [out_fd]
    call write_u64_fd
    mov rdi, [out_fd]
    mov rsi, asm_jz_post
    mov rdx, asm_jz_post_len
    call write_all

    ; Emit: .Lelse:
    mov rdi, [out_fd]
    mov rsi, asm_label_pre
    mov rdx, asm_label_pre_len
    call write_all
    mov rax, r13
    mov rdi, [out_fd]
    call write_u64_fd
    mov rdi, [out_fd]
    mov rsi, asm_label_post
    mov rdx, asm_label_post_len
    call write_all

    ; Emit else body
    mov rdi, r15
    call emit_block
    test rax, rax
    jnz .fail

    ; Emit: .Lend:
    mov rdi, [out_fd]
    mov rsi, asm_label_pre
    mov rdx, asm_label_pre_len
    call write_all
    mov rax, r14
    mov rdi, [out_fd]
    call write_u64_fd
    mov rdi, [out_fd]
    mov rsi, asm_label_post
    mov rdx, asm_label_post_len
    call write_all

    xor rax, rax
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

.no_else:
    ; Emit: .Lelse: (no else body, just the label)
    mov rdi, [out_fd]
    mov rsi, asm_label_pre
    mov rdx, asm_label_pre_len
    call write_all
    mov rax, r13
    mov rdi, [out_fd]
    call write_u64_fd
    mov rdi, [out_fd]
    mov rsi, asm_label_post
    mov rdx, asm_label_post_len
    call write_all

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

; emit_while_stmt: AST structure is
;   while_stmt -> child chain: [condition, body_block]
; So: ast_child(while_stmt)=condition, ast_next(condition)=body_block.
emit_while_stmt:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r13, [label_counter]
    inc qword [label_counter]
    mov r14, [label_counter]
    inc qword [label_counter]

    ; Push loop context: break -> r14 (exit), continue -> r13 (top)
    mov rdi, r14
    mov rsi, r13
    call loop_context_push

    ; Emit loop-top label: .Ltop:
    mov rdi, [out_fd]
    mov rsi, asm_label_pre
    mov rdx, asm_label_pre_len
    call write_all
    mov rax, r13
    mov rdi, [out_fd]
    call write_u64_fd
    mov rdi, [out_fd]
    mov rsi, asm_label_post
    mov rdx, asm_label_post_len
    call write_all

    ; Get condition (first child of while_stmt)
    mov rdi, r12
    call ast_child
    mov r15, rax            ; r15 = condition node
    mov rdi, r15
    call emit_expr
    test rax, rax
    jnz .fail

    ; Emit: test rax,rax / jz .Lexit
    mov rdi, [out_fd]
    mov rsi, asm_jz_pre
    mov rdx, asm_jz_pre_len
    call write_all
    mov rax, r14
    mov rdi, [out_fd]
    call write_u64_fd
    mov rdi, [out_fd]
    mov rsi, asm_jz_post
    mov rdx, asm_jz_post_len
    call write_all

    ; Get body (second child = ast_next(condition))
    mov rdi, r15
    call ast_next
    mov rdi, rax
    call emit_block
    test rax, rax
    jnz .fail

    ; Emit: jmp .Ltop
    mov rdi, [out_fd]
    mov rsi, asm_jmp_pre
    mov rdx, asm_jmp_pre_len
    call write_all
    mov rax, r13
    mov rdi, [out_fd]
    call write_u64_fd
    mov rdi, [out_fd]
    mov rsi, asm_jz_post
    mov rdx, asm_jz_post_len
    call write_all

    ; Emit exit label: .Lexit:
    mov rdi, [out_fd]
    mov rsi, asm_label_pre
    mov rdx, asm_label_pre_len
    call write_all
    mov rax, r14
    mov rdi, [out_fd]
    call write_u64_fd
    mov rdi, [out_fd]
    mov rsi, asm_label_post
    mov rdx, asm_label_post_len
    call write_all

    call loop_context_pop
    xor rax, rax
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

.fail:
    call loop_context_pop
    mov rax, 1
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; emit_loop_stmt: AST structure is
;   loop_stmt -> child chain: [body_block]
; So: ast_child(loop_stmt)=body_block.
emit_loop_stmt:
    push rbx
    push r12
    push r13
    push r14
    mov r12, rdi
    mov r13, [label_counter]
    inc qword [label_counter]
    mov r14, [label_counter]
    inc qword [label_counter]

    ; Push loop context: break -> r14 (exit), continue -> r13 (top)
    mov rdi, r14
    mov rsi, r13
    call loop_context_push

    ; Emit loop-top label: .Ltop:
    mov rdi, [out_fd]
    mov rsi, asm_label_pre
    mov rdx, asm_label_pre_len
    call write_all
    mov rax, r13
    mov rdi, [out_fd]
    call write_u64_fd
    mov rdi, [out_fd]
    mov rsi, asm_label_post
    mov rdx, asm_label_post_len
    call write_all

    ; Get body (first child of loop_stmt)
    mov rdi, r12
    call ast_child
    mov rdi, rax
    call emit_block
    test rax, rax
    jnz .fail

    ; Emit: jmp .Ltop
    mov rdi, [out_fd]
    mov rsi, asm_jmp_pre
    mov rdx, asm_jmp_pre_len
    call write_all
    mov rax, r13
    mov rdi, [out_fd]
    call write_u64_fd
    mov rdi, [out_fd]
    mov rsi, asm_jz_post
    mov rdx, asm_jz_post_len
    call write_all

    ; Emit exit label: .Lexit:
    mov rdi, [out_fd]
    mov rsi, asm_label_pre
    mov rdx, asm_label_pre_len
    call write_all
    mov rax, r14
    mov rdi, [out_fd]
    call write_u64_fd
    mov rdi, [out_fd]
    mov rsi, asm_label_post
    mov rdx, asm_label_post_len
    call write_all

    call loop_context_pop
    xor rax, rax
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

.fail:
    call loop_context_pop
    mov rax, 1
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

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
