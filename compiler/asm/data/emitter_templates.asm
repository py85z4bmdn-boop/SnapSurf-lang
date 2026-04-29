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
asm_not_rax: db "    test rax, rax",10,"    setz al",10,"    movzx rax, al",10
asm_not_rax_len: equ $ - asm_not_rax
asm_cmp_gt: db "    pop rcx",10,"    cmp rcx, rax",10,"    setg al",10,"    movzx rax, al",10
asm_cmp_gt_len: equ $ - asm_cmp_gt
asm_cmp_lt: db "    pop rcx",10,"    cmp rcx, rax",10,"    setl al",10,"    movzx rax, al",10
asm_cmp_lt_len: equ $ - asm_cmp_lt
asm_cmp_ge: db "    pop rcx",10,"    cmp rcx, rax",10,"    setge al",10,"    movzx rax, al",10
asm_cmp_ge_len: equ $ - asm_cmp_ge
asm_cmp_le: db "    pop rcx",10,"    cmp rcx, rax",10,"    setle al",10,"    movzx rax, al",10
asm_cmp_le_len: equ $ - asm_cmp_le
asm_cmp_ee: db "    pop rcx",10,"    cmp rcx, rax",10,"    sete al",10,"    movzx rax, al",10
asm_cmp_ee_len: equ $ - asm_cmp_ee
asm_cmp_ne: db "    pop rcx",10,"    cmp rcx, rax",10,"    setne al",10,"    movzx rax, al",10
asm_cmp_ne_len: equ $ - asm_cmp_ne
asm_and_rax: db "    pop rcx",10,"    and rax, rcx",10
asm_and_rax_len: equ $ - asm_and_rax
asm_or_rax: db "    pop rcx",10,"    or rax, rcx",10
asm_or_rax_len: equ $ - asm_or_rax
asm_jz_pre: db "    test rax, rax",10,"    jz .L"
asm_jz_pre_len: equ $ - asm_jz_pre
asm_jz_post: db 10
asm_jz_post_len: equ $ - asm_jz_post
asm_jmp_pre: db "    jmp .L"
asm_jmp_pre_len: equ $ - asm_jmp_pre
asm_label_pre: db ".L"
asm_label_pre_len: equ $ - asm_label_pre
asm_label_post: db ":",10
asm_label_post_len: equ $ - asm_label_post
asm_ret_epilogue: db "    mov rsp, rbp",10,"    pop rbp",10,"    ret",10
asm_ret_epilogue_len: equ $ - asm_ret_epilogue
asm_rodata_pre: db 10,"section .rodata",10,".Lstr0:",10,"    db "
asm_rodata_pre_len: equ $ - asm_rodata_pre
asm_final_newline: db 10
comma_space: db ", "
