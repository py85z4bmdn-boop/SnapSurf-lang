; Status: PARTIAL.
; Small FASM instruction template emitters used by statement/expression codegen.

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
    push rbx
    push r12
    push r13
    mov r12, rdi
    mov rdi, r12
    mov rsi, 1
    call ast_child_at
    test rax, rax
    jz .fail
    mov rdi, rax
    call ast_child
    mov rdi, rax
    call token_addr
    mov rbx, [rax + TOKEN_PAYLOAD]
    mov rdi, r12
    mov rsi, 3
    call ast_child_at
    test rax, rax
    jz .fail
    mov rdi, rax
    call ast_child
    mov rdi, rax
    call token_addr
    mov r13, [rax + TOKEN_PAYLOAD]
    mov rdi, [out_fd]
    mov rsi, asm_write_pre
    mov rdx, asm_write_pre_len
    call write_all
    mov rdi, [out_fd]
    mov rax, rbx
    call write_u64_fd
    mov rdi, [out_fd]
    mov rsi, asm_write_mid
    mov rdx, asm_write_mid_len
    call write_all
    mov rdi, [out_fd]
    mov rax, r12
    call write_u64_fd
    mov rdi, [out_fd]
    mov rsi, asm_write_label_post
    mov rdx, asm_write_label_post_len
    call write_all
    mov rdi, [out_fd]
    mov rax, r13
    call write_u64_fd
    mov rdi, [out_fd]
    mov rsi, asm_write_post
    mov rdx, asm_write_post_len
    call write_all
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

emit_io_write_rodata:
    push rbx
    xor rbx, rbx
.loop:
    inc rbx
    cmp rbx, [ast_count]
    ja .done
    mov rdi, rbx
    call ast_kind
    cmp rax, AST_CALL_STMT
    jne .loop
    mov rdi, rbx
    call emit_io_write_rodata_entry
    test rax, rax
    jnz .fail
    jmp .loop
.done:
    xor rax, rax
    pop rbx
    ret
.fail:
    mov rax, 1
    pop rbx
    ret

emit_io_write_rodata_entry:
    push rbx
    push r12
    push r13
    mov r12, rdi
    mov rdi, r12
    mov rsi, 2
    call ast_child_at
    test rax, rax
    jz .fail
    mov rdi, rax
    call ast_child
    mov rdi, rax
    call token_addr
    mov r13, [rax + TOKEN_PAYLOAD]
    mov rbx, [rax + TOKEN_LEN]

    mov rdi, [out_fd]
    mov rsi, asm_rodata_label_pre
    mov rdx, asm_rodata_label_pre_len
    call write_all
    mov rdi, [out_fd]
    mov rax, r12
    call write_u64_fd
    mov rdi, [out_fd]
    mov rsi, asm_rodata_label_post
    mov rdx, asm_rodata_label_post_len
    call write_all

    mov [tmp_payload], r13
    mov [parsed_str_len], rbx
    mov rdi, [out_fd]
    call write_db_string
    mov rdi, [out_fd]
    mov rsi, asm_final_newline
    mov rdx, 1
    call write_all
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

; emit_print_stmt: Emit code for 'print expr' statement.
; Evaluates expression into rax, then calls a signed or unsigned decimal helper.
; rdi = print_stmt AST node.
emit_print_stmt:
    push rbx
    push r12
    push r13
    mov r12, rdi
    mov rdi, r12
    call ast_child
    mov r13, rax
    mov rdi, r13
    call semantic_expr_type
    test rax, rax
    jz .fail
    mov rbx, rax
    mov rdi, r13
    call emit_expr
    test rax, rax
    jnz .fail
    mov rdi, rbx
    call semantic_type_is_signed_integer
    test rax, rax
    jz .unsigned
    mov rdi, [out_fd]
    mov rsi, asm_call_print_int
    mov rdx, asm_call_print_int_len
    call write_all
    mov byte [needs_print_int_helper], 1
    jmp .ok
.unsigned:
    mov rdi, [out_fd]
    mov rsi, asm_call_print_uint
    mov rdx, asm_call_print_uint_len
    call write_all
    mov byte [needs_print_uint_helper], 1
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

emit_eprint_stmt:
    push rbx
    push r12
    push r13
    mov r12, rdi
    mov rdi, r12
    call ast_child
    mov r13, rax
    mov rdi, r13
    call semantic_expr_type
    test rax, rax
    jz .fail
    mov rbx, rax
    mov rdi, r13
    call emit_expr
    test rax, rax
    jnz .fail
    mov rdi, rbx
    call semantic_type_is_signed_integer
    test rax, rax
    jz .unsigned
    mov rdi, [out_fd]
    mov rsi, asm_call_eprint_int
    mov rdx, asm_call_eprint_int_len
    call write_all
    mov byte [needs_eprint_int_helper], 1
    jmp .ok
.unsigned:
    mov rdi, [out_fd]
    mov rsi, asm_call_eprint_uint
    mov rdx, asm_call_eprint_uint_len
    call write_all
    mov byte [needs_eprint_uint_helper], 1
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
