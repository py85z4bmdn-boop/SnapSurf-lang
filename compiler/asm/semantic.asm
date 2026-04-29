; Status: COMPLETE for foundation v0 subset.
; Semantic checker with proper scoping for nested blocks.
; All functions properly save/restore callee-saved registers (rbx, r12-r15).

semantic_check_subset:
    cmp qword [ast_error_flag], 0
    jne .ast_error
    cmp qword [ast_main_fn], 0
    je .no_main
    cmp qword [ast_block_node], 0
    je .bad_ret
    call semantic_reset_symbols
    call type_init
    call scope_push
    test rax, rax
    jnz .fail
    mov rdi, [ast_block_node]
    call semantic_block
    test rax, rax
    jnz .fail
    cmp byte [return_seen], 0
    je .bad_ret
    xor rax, rax
    ret
.ast_error:
    mov rdi, src_path
    mov rsi, err_ast_overflow
    call print_diag
    mov rax, 1
    ret
.no_main:
    mov rdi, src_path
    mov rsi, err_no_main
    call print_diag
    mov rax, 1
    ret
.bad_ret:
    mov rdi, src_path
    mov rsi, err_ret
    call print_diag
    mov rax, 1
    ret
.fail:
    ret

semantic_reset_symbols:
    mov qword [sym_count], 0
    mov qword [local_count], 0
    mov qword [slot_cursor], 0
    mov qword [scope_depth], 0
    mov byte [return_seen], 0
    ret

; Rebuild the symbol table flat (no scoping) for the emitter.
; Walks the main block AST and re-adds all let/mut declarations.
semantic_rebuild_for_emit:
    call semantic_reset_symbols
    mov rdi, [ast_block_node]
    call rebuild_block_flat
    ret

rebuild_block_flat:
    push rbx
    call ast_child
    mov rbx, rax
.loop:
    test rbx, rbx
    jz .done
    mov rdi, rbx
    call rebuild_stmt_flat
    mov rdi, rbx
    call ast_next
    mov rbx, rax
    jmp .loop
.done:
    pop rbx
    ret

rebuild_stmt_flat:
    push r12
    push r13
    mov r12, rdi
    call ast_kind
    mov r13, rax
    cmp r13, AST_LET_STMT
    je .decl
    cmp r13, AST_MUT_STMT
    je .decl_mut
    cmp r13, AST_IF_STMT
    je .if_stmt
    cmp r13, AST_WHILE_STMT
    je .while_stmt
    cmp r13, AST_LOOP_STMT
    je .loop_stmt
    pop r13
    pop r12
    ret
.decl:
    mov rdi, r12
    call ast_child
    mov rdi, rax
    call ast_child
    mov rdi, rax
    xor rsi, rsi
    mov rdx, TYPE_I32
    call symbol_add
    pop r13
    pop r12
    ret
.decl_mut:
    mov rdi, r12
    call ast_child
    mov rdi, rax
    call ast_child
    mov rdi, rax
    mov rsi, 1
    mov rdx, TYPE_I32
    call symbol_add
    pop r13
    pop r12
    ret
.if_stmt:
    ; Get then-block (second child = ast_next(condition))
    mov rdi, r12
    call ast_child
    mov rdi, rax
    call ast_next
    mov rdi, rax          ; rdi = then_block
    push rdi              ; save then_block for else lookup
    call rebuild_block_flat
    ; Walk else-block if present (third child = ast_next(then_block))
    pop rdi               ; rdi = then_block
    call ast_next
    test rax, rax
    jz .if_done
    mov rdi, rax
    call rebuild_block_flat
.if_done:
    pop r13
    pop r12
    ret
.while_stmt:
    ; Walk body (second child = ast_next(condition))
    mov rdi, r12
    call ast_child
    mov rdi, rax
    call ast_next
    mov rdi, rax
    call rebuild_block_flat
    pop r13
    pop r12
    ret
.loop_stmt:
    ; Walk body (first child)
    mov rdi, r12
    call ast_child
    mov rdi, rax
    call rebuild_block_flat
    pop r13
    pop r12
    ret

; semantic_block: walk the child list of a block AST node and check each stmt.
; rdi = block node index.
semantic_block:
    push rbx
    mov rdi, rdi
    call ast_child
    mov rbx, rax
.loop:
    test rbx, rbx
    jz .done
    mov rdi, rbx
    call semantic_stmt
    test rax, rax
    jnz .fail
    mov rdi, rbx
    call ast_next
    mov rbx, rax
    jmp .loop
.done:
    xor rax, rax
    pop rbx
    ret
.fail:
    pop rbx
    ret

; semantic_stmt: check a single statement node.
; rdi = statement node index.
semantic_stmt:
    push r12
    push r13
    mov r12, rdi
    call ast_kind
    mov r13, rax
    cmp r13, AST_RET_STMT
    je .ret
    cmp r13, AST_CALL_STMT
    je .call
    cmp r13, AST_LET_STMT
    je .let
    cmp r13, AST_MUT_STMT
    je .mut
    cmp r13, AST_ASSIGN_STMT
    je .assign
    cmp r13, AST_IF_STMT
    je .if_stmt
    cmp r13, AST_WHILE_STMT
    je .while_stmt
    cmp r13, AST_LOOP_STMT
    je .loop_stmt
    cmp r13, AST_BREAK_STMT
    je .break_stmt
    cmp r13, AST_CONTINUE_STMT
    je .continue_stmt
    mov rdi, src_path
    mov rsi, err_unsup_ast
    call print_diag
    mov rax, 1
    pop r13
    pop r12
    ret
.ret:
    mov rdi, r12
    call semantic_ret_stmt
    pop r13
    pop r12
    ret
.call:
    mov rdi, r12
    call semantic_load_call
    pop r13
    pop r12
    ret
.let:
    mov rdi, r12
    xor rsi, rsi
    call semantic_decl_stmt
    pop r13
    pop r12
    ret
.mut:
    mov rdi, r12
    mov rsi, 1
    call semantic_decl_stmt
    pop r13
    pop r12
    ret
.assign:
    mov rdi, r12
    call semantic_assign_stmt
    pop r13
    pop r12
    ret
.if_stmt:
    mov rdi, r12
    call semantic_if_stmt
    pop r13
    pop r12
    ret
.while_stmt:
    mov rdi, r12
    call semantic_while_stmt
    pop r13
    pop r12
    ret
.loop_stmt:
    mov rdi, r12
    call semantic_loop_stmt
    pop r13
    pop r12
    ret
.break_stmt:
    xor rax, rax
    pop r13
    pop r12
    ret
.continue_stmt:
    xor rax, rax
    pop r13
    pop r12
    ret

semantic_decl_stmt:
    push rbx
    push r12
    push r13
    mov r12, rdi
    mov r13, rsi
    mov rdi, r12
    call ast_child
    mov rbx, rax
    test rbx, rbx
    jz .bad
    mov rdi, rbx
    call ast_next
    test rax, rax
    jz .bad
    mov rdi, rax
    call semantic_expr_type
    test rax, rax
    jz .fail
    cmp rax, TYPE_I32
    jne .type_bad
    mov rdi, rbx
    call semantic_ident_token
    mov rdi, rax
    mov rsi, r13
    mov rdx, TYPE_I32
    call symbol_add
    test rax, rax
    jnz .fail
    xor rax, rax
    pop r13
    pop r12
    pop rbx
    ret
.type_bad:
    mov rdi, rbx
    call semantic_ident_token
    mov rdi, rax
    call set_diag_from_token
    mov rdi, src_path
    mov rsi, err_type
    call print_diag
    mov rax, 1
    pop r13
    pop r12
    pop rbx
    ret
.bad:
    mov rdi, src_path
    mov rsi, err_unsup_ast
    call print_diag
.fail:
    mov rax, 1
    pop r13
    pop r12
    pop rbx
    ret

semantic_assign_stmt:
    push rbx
    push r12
    mov r12, rdi
    mov rdi, r12
    call ast_child
    mov rbx, rax
    test rbx, rbx
    jz .bad
    mov rdi, rbx
    call semantic_ident_token
    mov [tmp_token], rax
    mov rdi, rax
    call symbol_find
    test rax, rax
    jz .undefined
    dec rax
    mov rdx, rax
    imul rdx, 8
    cmp qword [sym_mut + rdx], 0
    je .immutable
    mov rdi, rbx
    call ast_next
    test rax, rax
    jz .bad
    mov rdi, rax
    call semantic_expr_type
    test rax, rax
    jz .fail
    cmp rax, TYPE_I32
    jne .type_bad
    xor rax, rax
    pop r12
    pop rbx
    ret
.undefined:
    mov rdi, [tmp_token]
    call set_diag_from_token
    mov rdi, src_path
    mov rsi, err_undefined
    call print_diag
    mov rax, 1
    pop r12
    pop rbx
    ret
.immutable:
    mov rdi, [tmp_token]
    call set_diag_from_token
    mov rdi, src_path
    mov rsi, err_immutable
    call print_diag
    mov rax, 1
    pop r12
    pop rbx
    ret
.type_bad:
    mov rdi, [tmp_token]
    call set_diag_from_token
    mov rdi, src_path
    mov rsi, err_type
    call print_diag
    mov rax, 1
    pop r12
    pop rbx
    ret
.bad:
    mov rdi, src_path
    mov rsi, err_unsup_ast
    call print_diag
.fail:
    mov rax, 1
    pop r12
    pop rbx
    ret

semantic_ret_stmt:
    push r12
    mov r12, rdi
    mov rdi, r12
    call ast_child
    mov rdi, rax
    test rdi, rdi
    jz .bad
    call semantic_expr_type
    test rax, rax
    jz .fail
    cmp rax, TYPE_I32
    jne .bad
    mov byte [return_seen], 1
    xor rax, rax
    pop r12
    ret
.bad:
    mov rdi, src_path
    mov rsi, err_ret
    call print_diag
    mov rax, 1
    pop r12
    ret
.fail:
    mov rax, 1
    pop r12
    ret

; semantic_if_stmt: AST structure is
;   if_stmt -> child chain: [condition, then_block, (optional else_block)]
semantic_if_stmt:
    push rbx
    push r12
    push r13
    mov r12, rdi
    ; Get condition (first child of if_stmt)
    mov rdi, r12
    call ast_child
    mov rbx, rax
    test rbx, rbx
    jz .bad
    mov rdi, rbx
    call semantic_expr_type
    cmp rax, TYPE_BOOL
    jne .bad_cond
    ; Get then-block (second child = ast_next(condition))
    mov rdi, rbx
    call ast_next
    mov r13, rax
    test r13, r13
    jz .bad
    call scope_push
    test rax, rax
    jnz .fail
    mov rdi, r13
    call semantic_block
    test rax, rax
    jnz .fail_pop
    call scope_pop
    ; Check for else-block (third child = ast_next(then_block))
    mov rdi, r13
    call ast_next
    test rax, rax
    jz .done
    mov r13, rax
    call scope_push
    test rax, rax
    jnz .fail
    mov rdi, r13
    call semantic_block
    test rax, rax
    jnz .fail_pop
    call scope_pop
.done:
    xor rax, rax
    pop r13
    pop r12
    pop rbx
    ret
.bad_cond:
    mov rdi, rbx
    call set_diag_from_expr_node
    mov rdi, src_path
    mov rsi, err_bad_cond
    call print_diag
    mov rax, 1
    pop r13
    pop r12
    pop rbx
    ret
.bad:
    mov rdi, src_path
    mov rsi, err_unsup_ast
    call print_diag
    mov rax, 1
    pop r13
    pop r12
    pop rbx
    ret
.fail_pop:
    call scope_pop
.fail:
    mov rax, 1
    pop r13
    pop r12
    pop rbx
    ret

; semantic_while_stmt: AST structure is
;   while_stmt -> child chain: [condition, body_block]
semantic_while_stmt:
    push rbx
    push r12
    push r13
    mov r12, rdi
    mov rdi, r12
    call ast_child
    mov rbx, rax
    test rbx, rbx
    jz .bad
    mov rdi, rbx
    call semantic_expr_type
    cmp rax, TYPE_BOOL
    jne .bad_cond
    ; Get body (second child = ast_next(condition))
    mov rdi, rbx
    call ast_next
    mov r13, rax
    test r13, r13
    jz .bad
    call scope_push
    test rax, rax
    jnz .fail
    mov rdi, r13
    call semantic_block
    test rax, rax
    jnz .fail_scope
    call scope_pop
    xor rax, rax
    pop r13
    pop r12
    pop rbx
    ret
.bad_cond:
    mov rdi, rbx
    call set_diag_from_expr_node
    mov rdi, src_path
    mov rsi, err_bad_cond
    call print_diag
    mov rax, 1
    pop r13
    pop r12
    pop rbx
    ret
.bad:
    mov rdi, src_path
    mov rsi, err_unsup_ast
    call print_diag
    mov rax, 1
    pop r13
    pop r12
    pop rbx
    ret
.fail_scope:
    call scope_pop
    mov rax, 1
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

; semantic_loop_stmt: AST structure is
;   loop_stmt -> child chain: [body_block]
semantic_loop_stmt:
    push r12
    push r13
    mov r12, rdi
    mov rdi, r12
    call ast_child
    mov r13, rax
    test r13, r13
    jz .bad
    call scope_push
    test rax, rax
    jnz .fail
    mov rdi, r13
    call semantic_block
    test rax, rax
    jnz .fail_scope
    call scope_pop
    xor rax, rax
    pop r13
    pop r12
    ret
.bad:
    mov rdi, src_path
    mov rsi, err_unsup_ast
    call print_diag
    mov rax, 1
    pop r13
    pop r12
    ret
.fail_scope:
    call scope_pop
    mov rax, 1
    pop r13
    pop r12
    ret
.fail:
    mov rax, 1
    pop r13
    pop r12
    ret
