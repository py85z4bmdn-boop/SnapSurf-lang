; Status: PARTIAL.
; Small NASM instruction template emitters used by statement/expression codegen.

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
