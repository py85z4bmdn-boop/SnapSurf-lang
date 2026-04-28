; Status: PARTIAL.
; NASM emitter for foundation v0 AST statements and arithmetic expressions.

emit_main_asm:
    call mkdir_build
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

    cmp qword [local_count], 0
    je .body
    mov rdi, [out_fd]
    mov rsi, asm_stack_pre
    mov rdx, asm_stack_pre_len
    call write_all
    mov rax, [local_count]
    imul rax, 8
    mov rdi, [out_fd]
    call write_u64_fd
    mov rdi, [out_fd]
    mov rsi, asm_final_newline
    mov rdx, 1
    call write_all

.body:
    mov rdi, [ast_block_node]
    call emit_block
    test rax, rax
    jnz .fail_close

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

emit_block:
    call ast_child
    mov r12, rax
.loop:
    test r12, r12
    jz .done
    mov rdi, r12
    call emit_stmt
    test rax, rax
    jnz .fail
    mov rdi, r12
    call ast_next
    mov r12, rax
    jmp .loop
.done:
    xor rax, rax
    ret
.fail:
    ret

emit_stmt:
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
    xor rax, rax
    ret
.call:
    call emit_io_write
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
    ret
.store:
    mov rdi, r12
    call emit_store_stmt
    ret
.fail:
    mov rax, 1
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
