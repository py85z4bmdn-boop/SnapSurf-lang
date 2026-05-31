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

; emit_print_stmt: Emit code for 'print expr' statement.
; Evaluates expression into rax, then calls __snapsurf_print_int.
; rdi = print_stmt AST node.
emit_print_stmt:
    push rbx
    push r12
    mov r12, rdi
    mov rdi, r12
    call ast_child
    mov rdi, rax
    call emit_expr
    test rax, rax
    jnz .fail
    ; Emit: call __snapsurf_print_int
    mov rdi, [out_fd]
    mov rsi, asm_call_print_int
    mov rdx, asm_call_print_int_len
    call write_all
    mov byte [needs_print_int_helper], 1
    xor rax, rax
    pop r12
    pop rbx
    ret
.fail:
    mov rax, 1
    pop r12
    pop rbx
    ret
