; emitter/break_continue.asm — Break and continue statement emission.

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
