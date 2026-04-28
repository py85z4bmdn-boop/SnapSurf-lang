section .data
asm_pre: db "default rel",10,"global _start",10,"section .text",10,"_start:",10,"    call main",10,"    mov edi, eax",10,"    mov eax, 60",10,"    syscall",10,10,"main:",10,"    push rbp",10,"    mov rbp, rsp",10
asm_pre_len: equ $ - asm_pre
asm_stack_pre: db "    sub rsp, "
asm_stack_pre_len: equ $ - asm_stack_pre
asm_write_pre: db "    mov rax, 1",10,"    mov rdi, 1",10,"    lea rsi, [rel .Lstr0]",10,"    mov rdx, "
asm_write_pre_len: equ $ - asm_write_pre
asm_write_post: db 10,"    syscall",10
asm_write_post_len: equ $ - asm_write_post
asm_mov_rax_pre: db "    mov rax, "
asm_mov_rax_pre_len: equ $ - asm_mov_rax_pre
asm_store_local_pre: db "    mov [rbp - "
asm_store_local_pre_len: equ $ - asm_store_local_pre
asm_store_local_post: db "], rax",10
asm_store_local_post_len: equ $ - asm_store_local_post
asm_load_local_pre: db "    mov rax, [rbp - "
asm_load_local_pre_len: equ $ - asm_load_local_pre
asm_load_local_post: db "]",10
asm_load_local_post_len: equ $ - asm_load_local_post
asm_push_rax: db "    push rax",10
asm_push_rax_len: equ $ - asm_push_rax
asm_add_rax: db "    pop rcx",10,"    add rax, rcx",10
asm_add_rax_len: equ $ - asm_add_rax
asm_sub_rax: db "    mov rcx, rax",10,"    pop rax",10,"    sub rax, rcx",10
asm_sub_rax_len: equ $ - asm_sub_rax
asm_mul_rax: db "    pop rcx",10,"    imul rax, rcx",10
asm_mul_rax_len: equ $ - asm_mul_rax
asm_div_rax: db "    mov rcx, rax",10,"    pop rax",10,"    cqo",10,"    idiv rcx",10
asm_div_rax_len: equ $ - asm_div_rax
asm_mod_rax: db "    mov rcx, rax",10,"    pop rax",10,"    cqo",10,"    idiv rcx",10,"    mov rax, rdx",10
asm_mod_rax_len: equ $ - asm_mod_rax
asm_neg_rax: db "    neg rax",10
asm_neg_rax_len: equ $ - asm_neg_rax
asm_ret_epilogue: db "    mov rsp, rbp",10,"    pop rbp",10,"    ret",10
asm_ret_epilogue_len: equ $ - asm_ret_epilogue
asm_rodata_pre: db 10,"section .rodata",10,".Lstr0:",10,"    db "
asm_rodata_pre_len: equ $ - asm_rodata_pre
asm_final_newline: db 10
comma_space: db ", "
