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
    je .check_entry
    cmp rax, AST_FN_CALL_EXPR
    jne .loop
.check_entry:
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
    push r14
    mov r12, rdi
    
    ; Check if this is AST_CALL_STMT (io.write) or AST_FN_CALL_EXPR (io.open)
    mov rdi, r12
    call ast_kind
    cmp rax, AST_CALL_STMT
    je .call_stmt
    cmp rax, AST_FN_CALL_EXPR
    je .fn_call_expr
    jmp .fail
    
.call_stmt:
    ; io.write: string is at child position 2
    ; For CALL_STMT, we use the parent node ID for the label (backward compat)
    mov rdi, r12
    mov rsi, 2
    call ast_child_at
    test rax, rax
    jz .fail
    mov r14, rax
    ; Save parent CALL_STMT node ID for label generation
    mov r13, r12
    jmp .extract_string_call_stmt
    
.fn_call_expr:
    ; FN_CALL_EXPR: could be open(path, ...) or write(fd, buffer, len)
    ; Need to check which argument contains the string
    ; For open: string is arg 1 (first after function name)
    ; For write: string is arg 2 (second after function name)
    ; For FN_CALL_EXPR, we use the string literal node ID for the label
    
    ; Get first argument
    mov rdi, r12
    call ast_child
    mov rdi, rax
    call ast_next
    mov r14, rax
    test r14, r14
    jz .fail
    
    ; Check if first arg is a string literal (open case)
    mov rdi, r14
    call ast_kind
    cmp rax, AST_STR_LIT
    je .fn_call_first_arg_is_string
    
    ; Not a string, try second argument (write case)
    mov rdi, r14
    call ast_next
    mov r14, rax
    test r14, r14
    jz .skip  ; No second arg, skip
    
    ; Check if second arg is a string literal
    mov rdi, r14
    call ast_kind
    cmp rax, AST_STR_LIT
    jne .skip  ; Not a string, skip
    
.fn_call_first_arg_is_string:
    ; For expression context, use string literal node ID
    mov r13, r14
    jmp .extract_string_expr
    
.extract_string_call_stmt:
    ; CALL_STMT path: use parent node ID (r13 = r12)
    mov rdi, r14
    call ast_kind
    cmp rax, AST_STR_LIT
    jne .skip
    
    mov rdi, r14
    call ast_child
    mov rdi, rax
    call token_addr
    mov rbx, [rax + TOKEN_LEN]
    push rax
    mov rax, [rax + TOKEN_PAYLOAD]
    mov [tmp_payload], rax
    pop rax
    
    mov rdi, [out_fd]
    mov rsi, asm_rodata_label_pre
    mov rdx, asm_rodata_label_pre_len
    call write_all
    mov rdi, [out_fd]
    mov rax, r13  ; Use parent CALL_STMT node ID for backward compat
    call write_u64_fd
    jmp .write_string_data
    
.extract_string_expr:
    ; FN_CALL_EXPR path: use string literal node ID (r13 = r14)
    mov rdi, r14
    call ast_kind
    cmp rax, AST_STR_LIT
    jne .skip
    
    mov rdi, r14
    call ast_child
    mov rdi, rax
    call token_addr
    mov rbx, [rax + TOKEN_LEN]
    push rax
    mov rax, [rax + TOKEN_PAYLOAD]
    mov [tmp_payload], rax
    pop rax

    mov rdi, [out_fd]
    mov rsi, asm_rodata_label_pre
    mov rdx, asm_rodata_label_pre_len
    call write_all
    mov rdi, [out_fd]
    mov rax, r13  ; Use string literal node ID for expression context
    call write_u64_fd
    
.write_string_data:
    mov rdi, [out_fd]
    mov rsi, asm_rodata_label_post
    mov rdx, asm_rodata_label_post_len
    call write_all

    mov [parsed_str_len], rbx
    mov rdi, [out_fd]
    call write_db_string
    mov rdi, [out_fd]
    mov rsi, asm_final_newline
    mov rdx, 1
    call write_all
    xor rax, rax
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.skip:
    ; Not a string literal, just skip (return success)
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

; emit_asm_stmt: Emit decoded inline FASM text.
; rdi = AST_ASM_STMT node.
emit_asm_stmt:
    push r12
    push r13
    mov r12, rdi
    mov rdi, r12
    call ast_child
    test rax, rax
    jz .fail
    mov r13, rax
    mov rdi, r13
    call ast_child
    mov rdi, rax
    call token_addr
    mov rsi, [rax + TOKEN_PAYLOAD]
    mov rdx, [rax + TOKEN_LEN]
    mov rdi, [out_fd]
    call write_raw_string
    mov rdi, [out_fd]
    mov rsi, asm_final_newline
    mov rdx, 1
    call write_all
    xor rax, rax
    pop r13
    pop r12
    ret
.fail:
    mov rax, 1
    pop r13
    pop r12
    ret
