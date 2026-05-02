section .data
asm_pre: db "default rel",10,"global _start",10,"section .text",10,"_start:",10,"    call main",10,"    mov edi, eax",10,"    mov eax, 60",10,"    syscall",10,10
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
asm_store_param_rdi_post: db "], rdi",10
asm_store_param_rdi_post_len: equ $ - asm_store_param_rdi_post
asm_store_param_rsi_post: db "], rsi",10
asm_store_param_rsi_post_len: equ $ - asm_store_param_rsi_post
asm_store_param_rdx_post: db "], rdx",10
asm_store_param_rdx_post_len: equ $ - asm_store_param_rdx_post
asm_store_param_rcx_post: db "], rcx",10
asm_store_param_rcx_post_len: equ $ - asm_store_param_rcx_post
asm_store_param_r8_post: db "], r8",10
asm_store_param_r8_post_len: equ $ - asm_store_param_r8_post
asm_store_param_r9_post: db "], r9",10
asm_store_param_r9_post_len: equ $ - asm_store_param_r9_post
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
asm_ret_stmt: db "    ret",10
asm_ret_stmt_len: equ $ - asm_ret_stmt
test_label: db "testfn:",10
test_label_len: equ $ - test_label
user_fn_label: db "func:",10
user_fn_label_len: equ $ - user_fn_label
asm_fn_label_suffix: db ":",10,"    push rbp",10,"    mov rbp, rsp",10
asm_fn_label_suffix_len: equ $ - asm_fn_label_suffix
asm_fn_prologue: db "    push rbp",10,"    mov rbp, rsp",10
asm_fn_prologue_len: equ $ - asm_fn_prologue
asm_fn_epilogue: db "    mov rsp, rbp",10,"    pop rbp",10,"    ret",10
asm_fn_epilogue_len: equ $ - asm_fn_epilogue
asm_rodata_pre: db 10,"section .rodata",10,".Lstr0:",10,"    db "
asm_rodata_pre_len: equ $ - asm_rodata_pre
asm_final_newline: db 10
comma_space: db ", "
asm_call_prefix: db "    call "
asm_call_prefix_len: equ $ - asm_call_prefix
asm_pop_rdi: db "    pop rdi",10
asm_pop_rdi_len: equ $ - asm_pop_rdi
asm_pop_rsi: db "    pop rsi",10
asm_pop_rsi_len: equ $ - asm_pop_rsi
asm_pop_rdx: db "    pop rdx",10
asm_pop_rdx_len: equ $ - asm_pop_rdx
asm_pop_rcx: db "    pop rcx",10
asm_pop_rcx_len: equ $ - asm_pop_rcx
asm_pop_r8: db "    pop r8",10
asm_pop_r8_len: equ $ - asm_pop_r8
asm_pop_r9: db "    pop r9",10
asm_pop_r9_len: equ $ - asm_pop_r9
asm_fn_prefix: db "fn"
asm_fn_prefix_len: equ $ - asm_fn_prefix
asm_lea_rax_rbp: db "    lea rax, [rbp - "
asm_lea_rax_rbp_len: equ $ - asm_lea_rax_rbp
asm_lea_rax_rbp_end: db "]",10
asm_lea_rax_rbp_end_len: equ $ - asm_lea_rax_rbp_end
asm_mov_rax_at_rax: db "    mov rax, [rax]",10
asm_mov_rax_at_rax_len: equ $ - asm_mov_rax_at_rax
asm_mov_rcx_rax: db "    mov rcx, rax",10
asm_mov_rcx_rax_len: equ $ - asm_mov_rcx_rax
asm_mov_rax_at_rcx_rax_8: db "    mov rax, [rcx + rax*8]",10
asm_mov_rax_at_rcx_rax_8_len: equ $ - asm_mov_rax_at_rcx_rax_8

; print support templates
asm_call_print_int: db "    mov rdi, rax",10,"    call __snapsurf_print_int",10
asm_call_print_int_len: equ $ - asm_call_print_int

; __snapsurf_print_int: Convert integer in rdi to decimal string and print
; to stdout, followed by a newline. Clobbers rax,rcx,rdx,rsi,rdi.
asm_print_int_helper: db \
    "__snapsurf_print_int:",10, \
    "    push rbp",10, \
    "    mov rbp, rsp",10, \
    "    sub rsp, 32",10, \
    "    mov rax, rdi",10, \
    "    lea rsi, [rbp - 1]",10, \
    "    mov byte [rsi], 10",10, \
    "    mov rcx, 1",10, \
    "    test rax, rax",10, \
    "    jns .pi_pos",10, \
    "    neg rax",10, \
    ".pi_pos:",10, \
    "    mov r8, 10",10, \
    ".pi_loop:",10, \
    "    xor rdx, rdx",10, \
    "    div r8",10, \
    "    add dl, 48",10, \
    "    dec rsi",10, \
    "    mov [rsi], dl",10, \
    "    inc rcx",10, \
    "    test rax, rax",10, \
    "    jnz .pi_loop",10, \
    "    test rdi, rdi",10, \
    "    jns .pi_write",10, \
    "    dec rsi",10, \
    "    mov byte [rsi], 45",10, \
    "    inc rcx",10, \
    ".pi_write:",10, \
    "    mov rax, 1",10, \
    "    mov rdi, 1",10, \
    "    mov rdx, rcx",10, \
    "    syscall",10, \
    "    mov rsp, rbp",10, \
    "    pop rbp",10, \
    "    ret",10
asm_print_int_helper_len: equ $ - asm_print_int_helper
