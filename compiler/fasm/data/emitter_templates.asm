segment readable writeable
asm_pre: db "format ELF64 executable 3",10,"entry _start",10,"segment readable executable",10,"_start:",10,"    call fn_main",10,"    mov edi, eax",10,"    mov eax, 60",10,"    syscall",10,10
asm_pre_len = $ - asm_pre
asm_stack_pre: db "    sub rsp, "
asm_stack_pre_len = $ - asm_stack_pre
asm_write_pre: db "    mov rax, 1",10,"    mov rdi, 1",10,"    lea rsi, [.Lstr0]",10,"    mov rdx, "
asm_write_pre_len = $ - asm_write_pre
asm_write_post: db 10,"    syscall",10
asm_write_post_len = $ - asm_write_post
asm_mov_rax_pre: db "    mov rax, "
asm_mov_rax_pre_len = $ - asm_mov_rax_pre
asm_store_local_pre: db "    mov [rbp - "
asm_store_local_pre_len = $ - asm_store_local_pre
asm_store_local_post: db "], rax",10
asm_store_local_post_len = $ - asm_store_local_post
asm_store_param_rdi_post: db "], rdi",10
asm_store_param_rdi_post_len = $ - asm_store_param_rdi_post
asm_store_param_rsi_post: db "], rsi",10
asm_store_param_rsi_post_len = $ - asm_store_param_rsi_post
asm_store_param_rdx_post: db "], rdx",10
asm_store_param_rdx_post_len = $ - asm_store_param_rdx_post
asm_store_param_rcx_post: db "], rcx",10
asm_store_param_rcx_post_len = $ - asm_store_param_rcx_post
asm_store_param_r8_post: db "], r8",10
asm_store_param_r8_post_len = $ - asm_store_param_r8_post
asm_store_param_r9_post: db "], r9",10
asm_store_param_r9_post_len = $ - asm_store_param_r9_post
asm_load_local_pre: db "    mov rax, [rbp - "
asm_load_local_pre_len = $ - asm_load_local_pre
asm_load_local_post: db "]",10
asm_load_local_post_len = $ - asm_load_local_post
asm_push_rax: db "    push rax",10
asm_push_rax_len = $ - asm_push_rax
asm_add_rax: db "    pop rcx",10,"    add rax, rcx",10
asm_add_rax_len = $ - asm_add_rax
asm_sub_rax: db "    mov rcx, rax",10,"    pop rax",10,"    sub rax, rcx",10
asm_sub_rax_len = $ - asm_sub_rax
asm_mul_rax: db "    pop rcx",10,"    imul rax, rcx",10
asm_mul_rax_len = $ - asm_mul_rax
asm_div_rax: db "    mov rcx, rax",10,"    pop rax",10,"    cqo",10,"    idiv rcx",10
asm_div_rax_len = $ - asm_div_rax
asm_mod_rax: db "    mov rcx, rax",10,"    pop rax",10,"    cqo",10,"    idiv rcx",10,"    mov rax, rdx",10
asm_mod_rax_len = $ - asm_mod_rax
asm_neg_rax: db "    neg rax",10
asm_neg_rax_len = $ - asm_neg_rax
asm_not_rax: db "    test rax, rax",10,"    setz al",10,"    movzx rax, al",10
asm_not_rax_len = $ - asm_not_rax
asm_bit_not_rax: db "    not rax",10
asm_bit_not_rax_len = $ - asm_bit_not_rax
asm_cmp_gt: db "    pop rcx",10,"    cmp rcx, rax",10,"    setg al",10,"    movzx rax, al",10
asm_cmp_gt_len = $ - asm_cmp_gt
asm_cmp_lt: db "    pop rcx",10,"    cmp rcx, rax",10,"    setl al",10,"    movzx rax, al",10
asm_cmp_lt_len = $ - asm_cmp_lt
asm_cmp_ge: db "    pop rcx",10,"    cmp rcx, rax",10,"    setge al",10,"    movzx rax, al",10
asm_cmp_ge_len = $ - asm_cmp_ge
asm_cmp_le: db "    pop rcx",10,"    cmp rcx, rax",10,"    setle al",10,"    movzx rax, al",10
asm_cmp_le_len = $ - asm_cmp_le
asm_cmp_ee: db "    pop rcx",10,"    cmp rcx, rax",10,"    sete al",10,"    movzx rax, al",10
asm_cmp_ee_len = $ - asm_cmp_ee
asm_cmp_ne: db "    pop rcx",10,"    cmp rcx, rax",10,"    setne al",10,"    movzx rax, al",10
asm_cmp_ne_len = $ - asm_cmp_ne
asm_and_rax: db "    pop rcx",10,"    and rax, rcx",10
asm_and_rax_len = $ - asm_and_rax
asm_or_rax: db "    pop rcx",10,"    or rax, rcx",10
asm_or_rax_len = $ - asm_or_rax
asm_xor_rax: db "    pop rcx",10,"    xor rax, rcx",10
asm_xor_rax_len = $ - asm_xor_rax
asm_shl_rax: db "    mov rcx, rax",10,"    pop rax",10,"    shl rax, cl",10
asm_shl_rax_len = $ - asm_shl_rax
asm_shr_rax: db "    mov rcx, rax",10,"    pop rax",10,"    shr rax, cl",10
asm_shr_rax_len = $ - asm_shr_rax
asm_rol_rax: db "    mov rcx, rax",10,"    pop rax",10,"    rol rax, cl",10
asm_rol_rax_len = $ - asm_rol_rax
asm_ror_rax: db "    mov rcx, rax",10,"    pop rax",10,"    ror rax, cl",10
asm_ror_rax_len = $ - asm_ror_rax
asm_pow_init_pre: db "    pop rcx",10,"    mov r8, rax",10,"    mov rax, 1",10,"    test r8, r8",10,"    jle .L"
asm_pow_init_pre_len = $ - asm_pow_init_pre
asm_pow_loop_body_pre: db "    imul rax, rcx",10,"    dec r8",10,"    jnz .L"
asm_pow_loop_body_pre_len = $ - asm_pow_loop_body_pre
asm_jz_pre: db "    test rax, rax",10,"    jz .L"
asm_jz_pre_len = $ - asm_jz_pre
asm_jz_post: db 10
asm_jz_post_len = $ - asm_jz_post
asm_jmp_pre: db "    jmp .L"
asm_jmp_pre_len = $ - asm_jmp_pre
asm_label_pre: db ".L"
asm_label_pre_len = $ - asm_label_pre
asm_label_post: db ":",10
asm_label_post_len = $ - asm_label_post
asm_ret_epilogue: db "    mov rsp, rbp",10,"    pop rbp",10,"    ret",10
asm_ret_epilogue_len = $ - asm_ret_epilogue
asm_ret_stmt: db "    ret",10
asm_ret_stmt_len = $ - asm_ret_stmt
test_label: db "testfn:",10
test_label_len = $ - test_label
user_fn_label: db "func:",10
user_fn_label_len = $ - user_fn_label
asm_fn_label_suffix: db ":",10,"    push rbp",10,"    mov rbp, rsp",10
asm_fn_label_suffix_len = $ - asm_fn_label_suffix
asm_fn_prologue: db "    push rbp",10,"    mov rbp, rsp",10
asm_fn_prologue_len = $ - asm_fn_prologue
asm_fn_epilogue: db "    mov rsp, rbp",10,"    pop rbp",10,"    ret",10
asm_fn_epilogue_len = $ - asm_fn_epilogue
asm_rodata_pre: db 10,"segment readable",10,".Lstr0:",10,"    db "
asm_rodata_pre_len = $ - asm_rodata_pre
asm_final_newline: db 10
comma_space: db ", "
asm_call_prefix: db "    call "
asm_call_prefix_len = $ - asm_call_prefix
asm_pop_rdi: db "    pop rdi",10
asm_pop_rdi_len = $ - asm_pop_rdi
asm_pop_rsi: db "    pop rsi",10
asm_pop_rsi_len = $ - asm_pop_rsi
asm_pop_rdx: db "    pop rdx",10
asm_pop_rdx_len = $ - asm_pop_rdx
asm_pop_rcx: db "    pop rcx",10
asm_pop_rcx_len = $ - asm_pop_rcx
asm_pop_r8: db "    pop r8",10
asm_pop_r8_len = $ - asm_pop_r8
asm_pop_r9: db "    pop r9",10
asm_pop_r9_len = $ - asm_pop_r9
asm_fn_prefix: db "fn_"
asm_fn_prefix_len = $ - asm_fn_prefix
asm_lea_rax_rbp: db "    lea rax, [rbp - "
asm_lea_rax_rbp_len = $ - asm_lea_rax_rbp
asm_lea_rax_rbp_end: db "]",10
asm_lea_rax_rbp_end_len = $ - asm_lea_rax_rbp_end
asm_mov_rax_at_rax: db "    mov rax, [rax]",10
asm_mov_rax_at_rax_len = $ - asm_mov_rax_at_rax
asm_mov_rcx_rax: db "    mov rcx, rax",10
asm_mov_rcx_rax_len = $ - asm_mov_rcx_rax
asm_mov_rax_at_rcx_rax_8: db "    mov rax, [rcx + rax*8]",10
asm_mov_rax_at_rcx_rax_8_len = $ - asm_mov_rax_at_rcx_rax_8

; print support templates
asm_call_print_int: db "    mov rdi, rax",10,"    call __snapsurf_print_int",10
asm_call_print_int_len = $ - asm_call_print_int

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
asm_print_int_helper_len = $ - asm_print_int_helper
