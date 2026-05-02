; Status: PARTIAL.
; NASM emitter for foundation v0 AST statements and arithmetic expressions.

emit_main_asm:
    call mkdir_build
    mov qword [label_counter], 0
    mov rax, SYS_OPEN
    mov rdi, asm_path
    mov rsi, O_WRONLY | O_CREAT | O_TRUNC
    mov rdx, 0644o
    syscall
    test rax, rax
    js .fail
    mov [out_fd], rax

    mov rdi, [out_fd]
    mov rsi, asm_pre
    mov rdx, asm_pre_len
    call write_all

    mov rdi, [ast_root]
    call ast_child
    test rax, rax
    jz .fail_close
    mov rbx, rax
.fn_loop:
    mov rdi, rbx
    call ast_kind
    cmp rax, AST_FN_DECL
    jne .next_fn
    mov rdi, rbx
    call emit_function
    test rax, rax
    jnz .fail_close

.next_fn:
    mov rdi, rbx
    call ast_next
    mov rbx, rax
    test rbx, rbx
    jnz .fn_loop

    ; Emit __snapsurf_print_int helper if print was used
    cmp byte [needs_print_int_helper], 0
    je .rodata_emit
    mov rdi, [out_fd]
    mov rsi, asm_print_int_helper
    mov rdx, asm_print_int_helper_len
    call write_all

.rodata_emit:
    cmp byte [has_io_write], 0
    je .close
    mov rdi, [out_fd]
    mov rsi, asm_rodata_pre
    mov rdx, asm_rodata_pre_len
    call write_all
    mov rdi, [out_fd]
    call write_db_string
    mov rdi, [out_fd]
    mov rsi, asm_final_newline
    mov rdx, 1
    call write_all

.close:
    mov rdi, [out_fd]
    mov rax, SYS_CLOSE
    syscall
    xor rax, rax
    ret
.fail_close:
    mov rdi, [out_fd]
    mov rax, SYS_CLOSE
    syscall
.fail:
    mov rdi, asm_path
    mov rsi, err_emit_failed
    call print_diag
    mov rax, 1
    ret

emit_function:
    push rbx
    push r12
    push r13
    push r14
    push r15

    mov r12, rdi
    mov rdi, r12
    call semantic_rebuild_function_for_emit
    test rax, rax
    jnz .ufn_error

    mov rdi, r12
    call ast_child
    test rax, rax
    jz .ufn_error
    mov r13, rax

    mov rdi, r13
    call ast_span_start
    mov r14, rax
    mov rdi, r13
    call ast_span_end
    mov r15, rax
    sub r15, r14
    mov rdi, [out_fd]
    mov rsi, r14
    mov rdx, r15
    call write_src_span
    mov rdi, [out_fd]
    mov rsi, asm_label_post
    mov rdx, asm_label_post_len
    call write_all

    mov rdi, [out_fd]
    mov rsi, asm_fn_prologue
    mov rdx, asm_fn_prologue_len
    call write_all

    cmp qword [local_count], 0
    je .spill_params
    mov rdi, [out_fd]
    mov rsi, asm_stack_pre
    mov rdx, asm_stack_pre_len
    call write_all
    mov rax, [local_count]
    imul rax, 8
    add rax, 15
    and rax, -16
    mov rdi, [out_fd]
    call write_u64_fd
    mov rdi, [out_fd]
    mov rsi, asm_final_newline
    mov rdx, 1
    call write_all

.spill_params:
    call emit_function_param_spills
    test rax, rax
    jz .ufn_error
    mov rdi, r12
    call semantic_fn_block
    test rax, rax
    jz .ufn_error
    mov [ast_block_node], rax
    mov rdi, rax
    call emit_block
    test rax, rax
    jnz .ufn_error

    xor rax, rax
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

.ufn_error:
    mov rax, 1
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

emit_user_function:
    call emit_function
    ret

emit_function_param_spills:
    push rbx
    push r12
    xor r12, r12
    mov rbx, [current_fn_param_count]
.loop:
    cmp r12, rbx
    jae .done
    mov rdi, [out_fd]
    mov rsi, asm_store_local_pre
    mov rdx, asm_store_local_pre_len
    call write_all
    mov rax, r12
    inc rax
    imul rax, 8
    mov rdi, [out_fd]
    call write_u64_fd
    mov rdi, [out_fd]
    cmp r12, 0
    je .rdi
    cmp r12, 1
    je .rsi
    cmp r12, 2
    je .rdx
    cmp r12, 3
    je .rcx
    cmp r12, 4
    je .r8
    cmp r12, 5
    je .r9
    jmp .fail
.rdi:
    mov rsi, asm_store_param_rdi_post
    mov rdx, asm_store_param_rdi_post_len
    jmp .write
.rsi:
    mov rsi, asm_store_param_rsi_post
    mov rdx, asm_store_param_rsi_post_len
    jmp .write
.rdx:
    mov rsi, asm_store_param_rdx_post
    mov rdx, asm_store_param_rdx_post_len
    jmp .write
.rcx:
    mov rsi, asm_store_param_rcx_post
    mov rdx, asm_store_param_rcx_post_len
    jmp .write
.r8:
    mov rsi, asm_store_param_r8_post
    mov rdx, asm_store_param_r8_post_len
    jmp .write
.r9:
    mov rsi, asm_store_param_r9_post
    mov rdx, asm_store_param_r9_post_len
.write:
    call write_all
    inc r12
    jmp .loop
.done:
    mov rax, 1
    pop r12
    pop rbx
    ret
.fail:
    xor rax, rax
    pop r12
    pop rbx
    ret

emit_block:
    push rbx
    call ast_child
    mov rbx, rax
.loop:
    test rbx, rbx
    jz .done
    mov rdi, rbx
    call emit_stmt
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

emit_stmt:
    push r12
    push r13
    mov r12, rdi
    call ast_kind
    mov r13, rax
    cmp r13, AST_CALL_STMT
    je .call
    cmp r13, AST_RET_STMT
    je .ret
    cmp r13, AST_LET_STMT
    je .store
    cmp r13, AST_MUT_STMT
    je .store
    cmp r13, AST_ASSIGN_STMT
    je .store
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
    cmp r13, AST_PRINT_STMT
    je .print_stmt
    xor rax, rax
    pop r13
    pop r12
    ret
.call:
    call emit_io_write
    pop r13
    pop r12
    ret
.ret:
    mov rdi, r12
    call ast_child
    mov rdi, rax
    call emit_expr
    test rax, rax
    jnz .fail
    mov rdi, [out_fd]
    mov rsi, asm_ret_epilogue
    mov rdx, asm_ret_epilogue_len
    call write_all
    xor rax, rax
    pop r13
    pop r12
    ret
.store:
    mov rdi, r12
    call emit_store_stmt
    pop r13
    pop r12
    ret
.if_stmt:
    mov rdi, r12
    call emit_if_stmt
    pop r13
    pop r12
    ret
.while_stmt:
    mov rdi, r12
    call emit_while_stmt
    pop r13
    pop r12
    ret
.loop_stmt:
    mov rdi, r12
    call emit_loop_stmt
    pop r13
    pop r12
    ret
.break_stmt:
    call emit_break_stmt
    pop r13
    pop r12
    ret
.continue_stmt:
    call emit_continue_stmt
    pop r13
    pop r12
    ret
.print_stmt:
    mov rdi, r12
    call emit_print_stmt
    pop r13
    pop r12
    ret
.fail:
    mov rax, 1
    pop r13
    pop r12
    ret

emit_store_stmt:
    push rbx
    mov r12, rdi
    call ast_child
    mov rbx, rax
    test rbx, rbx
    jz .fail
    mov rdi, rbx
    call ast_next
    test rax, rax
    jz .fail
    mov rdi, rax
    call emit_expr
    test rax, rax
    jnz .fail
    mov rdi, rbx
    call ast_child
    mov rdi, rax
    call symbol_slot_for_token
    test rax, rax
    jz .fail
    imul rax, 8
    mov rbx, rax
    mov rdi, [out_fd]
    mov rsi, asm_store_local_pre
    mov rdx, asm_store_local_pre_len
    call write_all
    mov rax, rbx
    mov rdi, [out_fd]
    call write_u64_fd
    mov rdi, [out_fd]
    mov rsi, asm_store_local_post
    mov rdx, asm_store_local_post_len
    call write_all
    xor rax, rax
    pop rbx
    ret
.fail:
    mov rax, 1
    pop rbx
    ret
