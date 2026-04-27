; Implemented foundation subset: deterministic NASM emission for hello-world.

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

    cmp qword [ast_call_stmt], 0
    je .ret

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

.ret:
    mov rdi, [out_fd]
    mov rsi, asm_ret_pre
    mov rdx, asm_ret_pre_len
    call write_all

    mov rdi, [out_fd]
    mov rax, [parsed_ret_value]
    call write_u64_fd

    mov rdi, [out_fd]
    mov rsi, asm_ret_post
    mov rdx, asm_ret_post_len
    call write_all

    mov rdi, [out_fd]
    call write_db_string

    mov rdi, [out_fd]
    mov rsi, asm_final_newline
    mov rdx, 1
    call write_all

    mov rdi, [out_fd]
    mov rax, SYS_CLOSE
    syscall
    xor rax, rax
    ret
.fail:
    mov rdi, asm_path
    mov rsi, err_emit_failed
    call print_diag
    mov rax, 1
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
