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
    call ast_addr
    mov r12, [rax + AST_CHILD_OR_DATA]
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
    call ast_addr
    mov r13, [rax + AST_KIND]
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
    call ast_addr
    mov rdi, [rax + AST_CHILD_OR_DATA]
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
    call ast_addr
    mov rbx, [rax + AST_CHILD_OR_DATA]
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
    call ast_addr
    mov rdi, [rax + AST_CHILD_OR_DATA]
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

emit_expr:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    call ast_addr
    mov r13, [rax + AST_KIND]
    cmp r13, AST_INT_LIT
    je .int
    cmp r13, AST_BOOL_LIT
    je .bool
    cmp r13, AST_VAR_REF
    je .var
    cmp r13, AST_UNARY_NEG
    je .neg
    cmp r13, AST_BIN_ADD
    je .binary
    cmp r13, AST_BIN_SUB
    je .binary
    cmp r13, AST_BIN_MUL
    je .binary
    cmp r13, AST_BIN_DIV
    je .binary
    cmp r13, AST_BIN_MOD
    je .binary
    jmp .fail
.int:
    mov rdi, r12
    call ast_addr
    mov rdi, [rax + AST_CHILD_OR_DATA]
    call token_addr
    mov rbx, [rax + TOKEN_PAYLOAD]
    call emit_mov_rax_imm
    jmp .ok
.bool:
    mov rdi, r12
    call ast_addr
    mov rbx, [rax + AST_CHILD_OR_DATA]
    call emit_mov_rax_imm
    jmp .ok
.var:
    mov rdi, r12
    call ast_addr
    mov rdi, [rax + AST_CHILD_OR_DATA]
    call symbol_slot_for_token
    test rax, rax
    jz .fail
    imul rax, 8
    mov rbx, rax
    mov rdi, [out_fd]
    mov rsi, asm_load_local_pre
    mov rdx, asm_load_local_pre_len
    call write_all
    mov rax, rbx
    mov rdi, [out_fd]
    call write_u64_fd
    mov rdi, [out_fd]
    mov rsi, asm_load_local_post
    mov rdx, asm_load_local_post_len
    call write_all
    jmp .ok
.neg:
    mov rdi, r12
    call ast_addr
    mov rdi, [rax + AST_CHILD_OR_DATA]
    call emit_expr
    test rax, rax
    jnz .fail
    mov rdi, [out_fd]
    mov rsi, asm_neg_rax
    mov rdx, asm_neg_rax_len
    call write_all
    jmp .ok
.binary:
    mov rdi, r12
    call emit_binary_expr
    test rax, rax
    jnz .fail
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

emit_binary_expr:
    push rbx
    push r12
    push r13
    push r14
    mov r12, rdi
    call ast_addr
    mov r13, [rax + AST_KIND]
    mov r14, [rax + AST_CHILD_OR_DATA]
    test r14, r14
    jz .fail
    mov rdi, r14
    call ast_next
    test rax, rax
    jz .fail
    mov rbx, rax
    mov rdi, r14
    call emit_expr
    test rax, rax
    jnz .fail
    mov rdi, [out_fd]
    mov rsi, asm_push_rax
    mov rdx, asm_push_rax_len
    call write_all
    mov rdi, rbx
    call emit_expr
    test rax, rax
    jnz .fail
    cmp r13, AST_BIN_ADD
    je .add
    cmp r13, AST_BIN_SUB
    je .sub
    cmp r13, AST_BIN_MUL
    je .mul
    cmp r13, AST_BIN_DIV
    je .div
    cmp r13, AST_BIN_MOD
    je .mod
    jmp .fail
.add:
    mov rdi, [out_fd]
    mov rsi, asm_add_rax
    mov rdx, asm_add_rax_len
    call write_all
    jmp .ok
.sub:
    mov rdi, [out_fd]
    mov rsi, asm_sub_rax
    mov rdx, asm_sub_rax_len
    call write_all
    jmp .ok
.mul:
    mov rdi, [out_fd]
    mov rsi, asm_mul_rax
    mov rdx, asm_mul_rax_len
    call write_all
    jmp .ok
.div:
    mov rdi, [out_fd]
    mov rsi, asm_div_rax
    mov rdx, asm_div_rax_len
    call write_all
    jmp .ok
.mod:
    mov rdi, [out_fd]
    mov rsi, asm_mod_rax
    mov rdx, asm_mod_rax_len
    call write_all
.ok:
    xor rax, rax
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.fail:
    mov rax, 1
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

emit_mov_rax_imm:
    mov rdi, [out_fd]
    mov rsi, asm_mov_rax_pre
    mov rdx, asm_mov_rax_pre_len
    call write_all
    mov rax, rbx
    mov rdi, [out_fd]
    call write_u64_fd
    mov rdi, [out_fd]
    mov rsi, asm_final_newline
    mov rdx, 1
    call write_all
    ret

emit_io_write:
    mov rdi, [out_fd]
    mov rsi, asm_write_pre
    mov rdx, asm_write_pre_len
    call write_all
    mov rdi, [out_fd]
    mov rax, [parsed_io_len]
    call write_u64_fd
    mov rdi, [out_fd]
    mov rsi, asm_write_post
    mov rdx, asm_write_post_len
    call write_all
    xor rax, rax
    ret

write_u64_fd:
    push rbx
    push rcx
    push rdx
    push r8
    mov r8, rdi
    mov rbx, 10
    lea rsi, [num_buf + 31]
    mov byte [rsi], 0
    cmp rax, 0
    jne .digits
    dec rsi
    mov byte [rsi], '0'
    jmp .write
.digits:
    xor rdx, rdx
    div rbx
    add dl, '0'
    dec rsi
    mov [rsi], dl
    test rax, rax
    jne .digits
.write:
    mov rdi, r8
    push rsi
    call strlen
    mov rdx, rax
    pop rsi
    mov rax, SYS_WRITE
    syscall
    pop r8
    pop rdx
    pop rcx
    pop rbx
    ret

write_db_string:
    push rbx
    push r12
    push r13
    push r14
    mov r12, rdi
    mov r13, [parsed_str_len]
    mov r14, [tmp_payload]
    xor rbx, rbx
    cmp r13, 0
    jne .loop
    mov rdi, r12
    xor rax, rax
    call write_u64_fd
    jmp .done
.loop:
    cmp rbx, 0
    je .num
    mov rdi, r12
    mov rsi, comma_space
    mov rdx, 2
    call write_all
.num:
    movzx rax, byte [str_buf + r14 + rbx]
    mov rdi, r12
    call write_u64_fd
    inc rbx
    cmp rbx, r13
    jb .loop
.done:
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
