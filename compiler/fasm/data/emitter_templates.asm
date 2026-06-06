segment readable writeable
asm_raw_pre: db "format binary",10
asm_raw_pre_len = $ - asm_raw_pre
asm_pre: db "format ELF64 executable 3",10,"entry _start",10,"segment readable executable",10,"_start:",10,"    call fn_main",10,"    mov edi, eax",10,"    mov eax, 60",10,"    syscall",10,10
asm_pre_len = $ - asm_pre
asm_stack_pre: db "    sub rsp, "
asm_stack_pre_len = $ - asm_stack_pre
asm_write_pre: db "    mov rax, 1",10,"    mov rdi, "
asm_write_pre_len = $ - asm_write_pre
asm_write_mid: db 10,"    lea rsi, [str_"
asm_write_mid_len = $ - asm_write_mid
asm_write_label_post: db "]",10,"    mov rdx, "
asm_write_label_post_len = $ - asm_write_label_post
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
asm_mov_rax_rdi: db "    mov rax, rdi",10
asm_mov_rax_rdi_len = $ - asm_mov_rax_rdi
asm_mov_rax_rsi: db "    mov rax, rsi",10
asm_mov_rax_rsi_len = $ - asm_mov_rax_rsi
asm_mov_rax_rdx: db "    mov rax, rdx",10
asm_mov_rax_rdx_len = $ - asm_mov_rax_rdx
asm_mov_rax_rcx: db "    mov rax, rcx",10
asm_mov_rax_rcx_len = $ - asm_mov_rax_rcx
asm_mov_rax_r8: db "    mov rax, r8",10
asm_mov_rax_r8_len = $ - asm_mov_rax_r8
asm_mov_rax_r9: db "    mov rax, r9",10
asm_mov_rax_r9_len = $ - asm_mov_rax_r9
asm_load_local_pre: db "    mov rax, [rbp - "
asm_load_local_pre_len = $ - asm_load_local_pre
asm_load_local_post: db "]",10
asm_load_local_post_len = $ - asm_load_local_post
asm_norm_i8: db "    movsx rax, al",10
asm_norm_i8_len = $ - asm_norm_i8
asm_norm_u8: db "    movzx rax, al",10
asm_norm_u8_len = $ - asm_norm_u8
asm_norm_i16: db "    movsx rax, ax",10
asm_norm_i16_len = $ - asm_norm_i16
asm_norm_u16: db "    movzx rax, ax",10
asm_norm_u16_len = $ - asm_norm_u16
asm_norm_i32: db "    movsxd rax, eax",10
asm_norm_i32_len = $ - asm_norm_i32
asm_norm_u32: db "    mov eax, eax",10
asm_norm_u32_len = $ - asm_norm_u32
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
asm_udiv_rax: db "    mov rcx, rax",10,"    pop rax",10,"    xor rdx, rdx",10,"    div rcx",10
asm_udiv_rax_len = $ - asm_udiv_rax
asm_umod_rax: db "    mov rcx, rax",10,"    pop rax",10,"    xor rdx, rdx",10,"    div rcx",10,"    mov rax, rdx",10
asm_umod_rax_len = $ - asm_umod_rax
asm_div_zero_check_pre: db "    test rax, rax",10,"    jnz .L"
asm_div_zero_check_pre_len = $ - asm_div_zero_check_pre
asm_div_zero_trap: db "    mov edi, 102",10,"    mov eax, 60",10,"    syscall",10
asm_div_zero_trap_len = $ - asm_div_zero_trap
asm_sdiv_overflow_check_pre: db "    cmp rax, -1",10,"    jne .L"
asm_sdiv_overflow_check_pre_len = $ - asm_sdiv_overflow_check_pre
asm_sdiv_overflow_check_mid: db 10,"    mov rdx, 0x8000000000000000",10,"    cmp qword [rsp], rdx",10,"    jne .L"
asm_sdiv_overflow_check_mid_len = $ - asm_sdiv_overflow_check_mid
asm_sdiv_overflow_check_i8_mid: db 10,"    cmp qword [rsp], -128",10,"    jne .L"
asm_sdiv_overflow_check_i8_mid_len = $ - asm_sdiv_overflow_check_i8_mid
asm_sdiv_overflow_check_i16_mid: db 10,"    cmp qword [rsp], -32768",10,"    jne .L"
asm_sdiv_overflow_check_i16_mid_len = $ - asm_sdiv_overflow_check_i16_mid
asm_sdiv_overflow_check_i32_mid: db 10,"    cmp qword [rsp], -2147483648",10,"    jne .L"
asm_sdiv_overflow_check_i32_mid_len = $ - asm_sdiv_overflow_check_i32_mid
asm_sdiv_overflow_trap: db "    mov edi, 103",10,"    mov eax, 60",10,"    syscall",10
asm_sdiv_overflow_trap_len = $ - asm_sdiv_overflow_trap
asm_wrapping_div_overflow_value: db "    pop rax",10
asm_wrapping_div_overflow_value_len = $ - asm_wrapping_div_overflow_value
asm_wrapping_mod_overflow_value: db "    pop rcx",10,"    xor rax, rax",10
asm_wrapping_mod_overflow_value_len = $ - asm_wrapping_mod_overflow_value
asm_saturating_div_overflow_i8_value: db "    pop rcx",10,"    mov rax, 127",10
asm_saturating_div_overflow_i8_value_len = $ - asm_saturating_div_overflow_i8_value
asm_saturating_div_overflow_i16_value: db "    pop rcx",10,"    mov rax, 32767",10
asm_saturating_div_overflow_i16_value_len = $ - asm_saturating_div_overflow_i16_value
asm_saturating_div_overflow_i32_value: db "    pop rcx",10,"    mov rax, 2147483647",10
asm_saturating_div_overflow_i32_value_len = $ - asm_saturating_div_overflow_i32_value
asm_saturating_div_overflow_word_value: db "    pop rcx",10,"    mov rax, 0x7fffffffffffffff",10
asm_saturating_div_overflow_word_value_len = $ - asm_saturating_div_overflow_word_value
asm_saturating_mod_overflow_value: db "    pop rcx",10,"    xor rax, rax",10
asm_saturating_mod_overflow_value_len = $ - asm_saturating_mod_overflow_value
asm_sadd_overflow_check_pre: db "    pop rcx",10,"    add rax, rcx",10,"    jno .L"
asm_sadd_overflow_check_pre_len = $ - asm_sadd_overflow_check_pre
asm_sadd_overflow_trap: db "    mov edi, 104",10,"    mov eax, 60",10,"    syscall",10
asm_sadd_overflow_trap_len = $ - asm_sadd_overflow_trap
asm_ssub_overflow_check_pre: db "    mov rcx, rax",10,"    pop rax",10,"    sub rax, rcx",10,"    jno .L"
asm_ssub_overflow_check_pre_len = $ - asm_ssub_overflow_check_pre
asm_ssub_overflow_trap: db "    mov edi, 105",10,"    mov eax, 60",10,"    syscall",10
asm_ssub_overflow_trap_len = $ - asm_ssub_overflow_trap
asm_smul_overflow_check_pre: db "    pop rcx",10,"    imul rax, rcx",10,"    jno .L"
asm_smul_overflow_check_pre_len = $ - asm_smul_overflow_check_pre
asm_smul_overflow_trap: db "    mov edi, 106",10,"    mov eax, 60",10,"    syscall",10
asm_smul_overflow_trap_len = $ - asm_smul_overflow_trap
asm_uadd_overflow_check_pre: db "    pop rcx",10,"    add rax, rcx",10,"    jnc .L"
asm_uadd_overflow_check_pre_len = $ - asm_uadd_overflow_check_pre
asm_uadd_overflow_trap: db "    mov edi, 110",10,"    mov eax, 60",10,"    syscall",10
asm_uadd_overflow_trap_len = $ - asm_uadd_overflow_trap
asm_usub_overflow_check_pre: db "    mov rcx, rax",10,"    pop rax",10,"    sub rax, rcx",10,"    jnc .L"
asm_usub_overflow_check_pre_len = $ - asm_usub_overflow_check_pre
asm_usub_overflow_trap: db "    mov edi, 111",10,"    mov eax, 60",10,"    syscall",10
asm_usub_overflow_trap_len = $ - asm_usub_overflow_trap
asm_umul_overflow_check_pre: db "    pop rcx",10,"    mul rcx",10,"    jno .L"
asm_umul_overflow_check_pre_len = $ - asm_umul_overflow_check_pre
asm_umul_overflow_trap: db "    mov edi, 112",10,"    mov eax, 60",10,"    syscall",10
asm_umul_overflow_trap_len = $ - asm_umul_overflow_trap
asm_usaturating_add_rax: db "    pop rcx",10,"    add rax, rcx",10,"    sbb rcx, rcx",10,"    or rax, rcx",10
asm_usaturating_add_rax_len = $ - asm_usaturating_add_rax
asm_usaturating_sub_rax: db "    mov rcx, rax",10,"    pop rax",10,"    sub rax, rcx",10,"    sbb rcx, rcx",10,"    not rcx",10,"    and rax, rcx",10
asm_usaturating_sub_rax_len = $ - asm_usaturating_sub_rax
asm_usaturating_mul_rax: db "    pop rcx",10,"    mul rcx",10,"    mov rcx, 0",10,"    seto cl",10,"    neg rcx",10,"    or rax, rcx",10
asm_usaturating_mul_rax_len = $ - asm_usaturating_mul_rax
asm_ssaturating_add_rax: db "    pop rcx",10,"    add rax, rcx",10,"    mov rcx, 0",10,"    seto cl",10,"    neg rcx",10,"    mov rdx, rax",10,"    sar rdx, 63",10,"    mov r8, 0x8000000000000000",10,"    add rdx, r8",10,"    and rdx, rcx",10,"    not rcx",10,"    and rax, rcx",10,"    or rax, rdx",10
asm_ssaturating_add_rax_len = $ - asm_ssaturating_add_rax
asm_ssaturating_sub_rax: db "    mov rcx, rax",10,"    pop rax",10,"    sub rax, rcx",10,"    mov rcx, 0",10,"    seto cl",10,"    neg rcx",10,"    mov rdx, rax",10,"    sar rdx, 63",10,"    mov r8, 0x8000000000000000",10,"    add rdx, r8",10,"    and rdx, rcx",10,"    not rcx",10,"    and rax, rcx",10,"    or rax, rdx",10
asm_ssaturating_sub_rax_len = $ - asm_ssaturating_sub_rax
asm_ssaturating_mul_rax: db "    pop rcx",10,"    mov rdx, rax",10,"    xor rdx, rcx",10,"    sar rdx, 63",10,"    imul rax, rcx",10,"    mov rcx, 0",10,"    seto cl",10,"    neg rcx",10,"    mov r8, 0x7fffffffffffffff",10,"    xor rdx, r8",10,"    and rdx, rcx",10,"    not rcx",10,"    and rax, rcx",10,"    or rax, rdx",10
asm_ssaturating_mul_rax_len = $ - asm_ssaturating_mul_rax
asm_usaturating_add_u8_rax: db "    pop rcx",10,"    add rax, rcx",10,"    mov rdx, 255",10,"    cmp rax, rdx",10,"    cmova rax, rdx",10
asm_usaturating_add_u8_rax_len = $ - asm_usaturating_add_u8_rax
asm_usaturating_add_u16_rax: db "    pop rcx",10,"    add rax, rcx",10,"    mov rdx, 65535",10,"    cmp rax, rdx",10,"    cmova rax, rdx",10
asm_usaturating_add_u16_rax_len = $ - asm_usaturating_add_u16_rax
asm_usaturating_add_u32_rax: db "    pop rcx",10,"    add rax, rcx",10,"    mov rdx, 4294967295",10,"    cmp rax, rdx",10,"    cmova rax, rdx",10
asm_usaturating_add_u32_rax_len = $ - asm_usaturating_add_u32_rax
asm_usaturating_mul_u8_rax: db "    pop rcx",10,"    mul rcx",10,"    mov rdx, 255",10,"    cmp rax, rdx",10,"    cmova rax, rdx",10
asm_usaturating_mul_u8_rax_len = $ - asm_usaturating_mul_u8_rax
asm_usaturating_mul_u16_rax: db "    pop rcx",10,"    mul rcx",10,"    mov rdx, 65535",10,"    cmp rax, rdx",10,"    cmova rax, rdx",10
asm_usaturating_mul_u16_rax_len = $ - asm_usaturating_mul_u16_rax
asm_usaturating_mul_u32_rax: db "    pop rcx",10,"    mul rcx",10,"    mov rdx, 4294967295",10,"    cmp rax, rdx",10,"    cmova rax, rdx",10
asm_usaturating_mul_u32_rax_len = $ - asm_usaturating_mul_u32_rax
asm_ssaturating_add_i8_rax: db "    pop rcx",10,"    add rax, rcx",10,"    mov rdx, 127",10,"    cmp rax, rdx",10,"    cmovg rax, rdx",10,"    mov rdx, -128",10,"    cmp rax, rdx",10,"    cmovl rax, rdx",10
asm_ssaturating_add_i8_rax_len = $ - asm_ssaturating_add_i8_rax
asm_ssaturating_add_i16_rax: db "    pop rcx",10,"    add rax, rcx",10,"    mov rdx, 32767",10,"    cmp rax, rdx",10,"    cmovg rax, rdx",10,"    mov rdx, -32768",10,"    cmp rax, rdx",10,"    cmovl rax, rdx",10
asm_ssaturating_add_i16_rax_len = $ - asm_ssaturating_add_i16_rax
asm_ssaturating_add_i32_rax: db "    pop rcx",10,"    add rax, rcx",10,"    mov rdx, 2147483647",10,"    cmp rax, rdx",10,"    cmovg rax, rdx",10,"    mov rdx, -2147483648",10,"    cmp rax, rdx",10,"    cmovl rax, rdx",10
asm_ssaturating_add_i32_rax_len = $ - asm_ssaturating_add_i32_rax
asm_ssaturating_sub_i8_rax: db "    mov rcx, rax",10,"    pop rax",10,"    sub rax, rcx",10,"    mov rdx, 127",10,"    cmp rax, rdx",10,"    cmovg rax, rdx",10,"    mov rdx, -128",10,"    cmp rax, rdx",10,"    cmovl rax, rdx",10
asm_ssaturating_sub_i8_rax_len = $ - asm_ssaturating_sub_i8_rax
asm_ssaturating_sub_i16_rax: db "    mov rcx, rax",10,"    pop rax",10,"    sub rax, rcx",10,"    mov rdx, 32767",10,"    cmp rax, rdx",10,"    cmovg rax, rdx",10,"    mov rdx, -32768",10,"    cmp rax, rdx",10,"    cmovl rax, rdx",10
asm_ssaturating_sub_i16_rax_len = $ - asm_ssaturating_sub_i16_rax
asm_ssaturating_sub_i32_rax: db "    mov rcx, rax",10,"    pop rax",10,"    sub rax, rcx",10,"    mov rdx, 2147483647",10,"    cmp rax, rdx",10,"    cmovg rax, rdx",10,"    mov rdx, -2147483648",10,"    cmp rax, rdx",10,"    cmovl rax, rdx",10
asm_ssaturating_sub_i32_rax_len = $ - asm_ssaturating_sub_i32_rax
asm_ssaturating_mul_i8_rax: db "    pop rcx",10,"    imul rax, rcx",10,"    mov rdx, 127",10,"    cmp rax, rdx",10,"    cmovg rax, rdx",10,"    mov rdx, -128",10,"    cmp rax, rdx",10,"    cmovl rax, rdx",10
asm_ssaturating_mul_i8_rax_len = $ - asm_ssaturating_mul_i8_rax
asm_ssaturating_mul_i16_rax: db "    pop rcx",10,"    imul rax, rcx",10,"    mov rdx, 32767",10,"    cmp rax, rdx",10,"    cmovg rax, rdx",10,"    mov rdx, -32768",10,"    cmp rax, rdx",10,"    cmovl rax, rdx",10
asm_ssaturating_mul_i16_rax_len = $ - asm_ssaturating_mul_i16_rax
asm_ssaturating_mul_i32_rax: db "    pop rcx",10,"    imul rax, rcx",10,"    mov rdx, 2147483647",10,"    cmp rax, rdx",10,"    cmovg rax, rdx",10,"    mov rdx, -2147483648",10,"    cmp rax, rdx",10,"    cmovl rax, rdx",10
asm_ssaturating_mul_i32_rax_len = $ - asm_ssaturating_mul_i32_rax
asm_neg_rax: db "    neg rax",10
asm_neg_rax_len = $ - asm_neg_rax
asm_sabs_overflow_i8_check_pre: db "    mov rdx, -128",10,"    cmp rax, rdx",10,"    jne .L"
asm_sabs_overflow_i8_check_pre_len = $ - asm_sabs_overflow_i8_check_pre
asm_sabs_overflow_i16_check_pre: db "    mov rdx, -32768",10,"    cmp rax, rdx",10,"    jne .L"
asm_sabs_overflow_i16_check_pre_len = $ - asm_sabs_overflow_i16_check_pre
asm_sabs_overflow_i32_check_pre: db "    mov rdx, -2147483648",10,"    cmp rax, rdx",10,"    jne .L"
asm_sabs_overflow_i32_check_pre_len = $ - asm_sabs_overflow_i32_check_pre
asm_sabs_overflow_i64_check_pre: db "    mov rdx, 0x8000000000000000",10,"    cmp rax, rdx",10,"    jne .L"
asm_sabs_overflow_i64_check_pre_len = $ - asm_sabs_overflow_i64_check_pre
asm_sabs_overflow_trap: db "    mov edi, 109",10,"    mov eax, 60",10,"    syscall",10
asm_sabs_overflow_trap_len = $ - asm_sabs_overflow_trap
asm_abs_rax: db "    cqo",10,"    xor rax, rdx",10,"    sub rax, rdx",10
asm_abs_rax_len = $ - asm_abs_rax
asm_min_rax: db "    pop rcx",10,"    cmp rcx, rax",10,"    cmovl rax, rcx",10
asm_min_rax_len = $ - asm_min_rax
asm_max_rax: db "    pop rcx",10,"    cmp rcx, rax",10,"    cmovg rax, rcx",10
asm_max_rax_len = $ - asm_max_rax
asm_clamp_rax: db "    pop rcx",10,"    pop rdx",10,"    cmp rdx, rcx",10,"    cmovl rdx, rcx",10,"    cmp rdx, rax",10,"    cmovg rdx, rax",10,"    mov rax, rdx",10
asm_clamp_rax_len = $ - asm_clamp_rax
asm_umin_rax: db "    pop rcx",10,"    cmp rcx, rax",10,"    cmovb rax, rcx",10
asm_umin_rax_len = $ - asm_umin_rax
asm_umax_rax: db "    pop rcx",10,"    cmp rcx, rax",10,"    cmova rax, rcx",10
asm_umax_rax_len = $ - asm_umax_rax
asm_uclamp_rax: db "    pop rcx",10,"    pop rdx",10,"    cmp rdx, rcx",10,"    cmovb rdx, rcx",10,"    cmp rdx, rax",10,"    cmova rdx, rax",10,"    mov rax, rdx",10
asm_uclamp_rax_len = $ - asm_uclamp_rax
asm_popcount_rax: db "    mov rcx, rax",10,"    shr rcx, 1",10,"    mov rdx, 0x5555555555555555",10,"    and rcx, rdx",10,"    sub rax, rcx",10,"    mov rcx, rax",10,"    mov rdx, 0x3333333333333333",10,"    and rax, rdx",10,"    shr rcx, 2",10,"    and rcx, rdx",10,"    add rax, rcx",10,"    mov rcx, rax",10,"    shr rcx, 4",10,"    add rax, rcx",10,"    mov rdx, 0x0f0f0f0f0f0f0f0f",10,"    and rax, rdx",10,"    mov rcx, rax",10,"    shr rcx, 8",10,"    add rax, rcx",10,"    mov rcx, rax",10,"    shr rcx, 16",10,"    add rax, rcx",10,"    mov rcx, rax",10,"    shr rcx, 32",10,"    add rax, rcx",10,"    and rax, 0x7f",10
asm_popcount_rax_len = $ - asm_popcount_rax
asm_bitcount_mask8: db "    movzx rax, al",10
asm_bitcount_mask8_len = $ - asm_bitcount_mask8
asm_bitcount_mask16: db "    movzx rax, ax",10
asm_bitcount_mask16_len = $ - asm_bitcount_mask16
asm_bitcount_mask32: db "    mov eax, eax",10
asm_bitcount_mask32_len = $ - asm_bitcount_mask32
asm_leading_zeros_8_rax: db "    xor rdx, rdx",10,"    test rax, rax",10,"    setz dl",10,"    or rax, 1",10,"    bsr rcx, rax",10,"    mov rax, 7",10,"    sub rax, rcx",10,"    add rax, rdx",10
asm_leading_zeros_8_rax_len = $ - asm_leading_zeros_8_rax
asm_leading_zeros_16_rax: db "    xor rdx, rdx",10,"    test rax, rax",10,"    setz dl",10,"    or rax, 1",10,"    bsr rcx, rax",10,"    mov rax, 15",10,"    sub rax, rcx",10,"    add rax, rdx",10
asm_leading_zeros_16_rax_len = $ - asm_leading_zeros_16_rax
asm_leading_zeros_32_rax: db "    xor rdx, rdx",10,"    test rax, rax",10,"    setz dl",10,"    or rax, 1",10,"    bsr rcx, rax",10,"    mov rax, 31",10,"    sub rax, rcx",10,"    add rax, rdx",10
asm_leading_zeros_32_rax_len = $ - asm_leading_zeros_32_rax
asm_leading_zeros_rax: db "    xor rdx, rdx",10,"    test rax, rax",10,"    setz dl",10,"    or rax, 1",10,"    bsr rcx, rax",10,"    mov rax, 63",10,"    sub rax, rcx",10,"    add rax, rdx",10
asm_leading_zeros_rax_len = $ - asm_leading_zeros_rax
asm_trailing_zeros_8_rax: db "    xor rdx, rdx",10,"    test rax, rax",10,"    setz dl",10,"    movzx rdx, dl",10,"    or rax, 0x80",10,"    bsf rax, rax",10,"    add rax, rdx",10
asm_trailing_zeros_8_rax_len = $ - asm_trailing_zeros_8_rax
asm_trailing_zeros_16_rax: db "    xor rdx, rdx",10,"    test rax, rax",10,"    setz dl",10,"    movzx rdx, dl",10,"    or rax, 0x8000",10,"    bsf rax, rax",10,"    add rax, rdx",10
asm_trailing_zeros_16_rax_len = $ - asm_trailing_zeros_16_rax
asm_trailing_zeros_32_rax: db "    xor rdx, rdx",10,"    test rax, rax",10,"    setz dl",10,"    movzx rdx, dl",10,"    or eax, 0x80000000",10,"    bsf rax, rax",10,"    add rax, rdx",10
asm_trailing_zeros_32_rax_len = $ - asm_trailing_zeros_32_rax
asm_trailing_zeros_rax: db "    xor rdx, rdx",10,"    test rax, rax",10,"    setz dl",10,"    movzx rdx, dl",10,"    mov rcx, 0x8000000000000000",10,"    or rax, rcx",10,"    bsf rax, rax",10,"    add rax, rdx",10
asm_trailing_zeros_rax_len = $ - asm_trailing_zeros_rax
asm_call_gcd_u64: db "    mov rsi, rax",10,"    pop rdi",10,"    call __snapsurf_gcd_u64",10
asm_call_gcd_u64_len = $ - asm_call_gcd_u64
asm_call_lcm_u64: db "    mov rsi, rax",10,"    pop rdi",10,"    call __snapsurf_lcm_u64",10
asm_call_lcm_u64_len = $ - asm_call_lcm_u64
asm_call_sqrt_u64: db "    mov rdi, rax",10,"    call __snapsurf_isqrt_u64",10
asm_call_sqrt_u64_len = $ - asm_call_sqrt_u64
asm_call_cbrt_u64: db "    mov rdi, rax",10,"    call __snapsurf_icbrt_u64",10
asm_call_cbrt_u64_len = $ - asm_call_cbrt_u64
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
asm_cmp_ugt: db "    pop rcx",10,"    cmp rcx, rax",10,"    seta al",10,"    movzx rax, al",10
asm_cmp_ugt_len = $ - asm_cmp_ugt
asm_cmp_ult: db "    pop rcx",10,"    cmp rcx, rax",10,"    setb al",10,"    movzx rax, al",10
asm_cmp_ult_len = $ - asm_cmp_ult
asm_cmp_uge: db "    pop rcx",10,"    cmp rcx, rax",10,"    setae al",10,"    movzx rax, al",10
asm_cmp_uge_len = $ - asm_cmp_uge
asm_cmp_ule: db "    pop rcx",10,"    cmp rcx, rax",10,"    setbe al",10,"    movzx rax, al",10
asm_cmp_ule_len = $ - asm_cmp_ule
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
asm_rol_al: db "    mov rcx, rax",10,"    pop rax",10,"    rol al, cl",10
asm_rol_al_len = $ - asm_rol_al
asm_rol_ax: db "    mov rcx, rax",10,"    pop rax",10,"    rol ax, cl",10
asm_rol_ax_len = $ - asm_rol_ax
asm_rol_eax: db "    mov rcx, rax",10,"    pop rax",10,"    rol eax, cl",10
asm_rol_eax_len = $ - asm_rol_eax
asm_rol_rax: db "    mov rcx, rax",10,"    pop rax",10,"    rol rax, cl",10
asm_rol_rax_len = $ - asm_rol_rax
asm_ror_al: db "    mov rcx, rax",10,"    pop rax",10,"    ror al, cl",10
asm_ror_al_len = $ - asm_ror_al
asm_ror_ax: db "    mov rcx, rax",10,"    pop rax",10,"    ror ax, cl",10
asm_ror_ax_len = $ - asm_ror_ax
asm_ror_eax: db "    mov rcx, rax",10,"    pop rax",10,"    ror eax, cl",10
asm_ror_eax_len = $ - asm_ror_eax
asm_ror_rax: db "    mov rcx, rax",10,"    pop rax",10,"    ror rax, cl",10
asm_ror_rax_len = $ - asm_ror_rax
asm_pow_init_pre: db "    pop rcx",10,"    mov r8, rax",10,"    mov rax, 1",10,"    test r8, r8",10,"    jle .L"
asm_pow_init_pre_len = $ - asm_pow_init_pre
asm_pow_loop_body_pre: db "    imul rax, rcx",10,"    dec r8",10,"    jnz .L"
asm_pow_loop_body_pre_len = $ - asm_pow_loop_body_pre
asm_pow_loop_body_checked_pre: db "    imul rax, rcx",10,"    jo .L"
asm_pow_loop_body_checked_pre_len = $ - asm_pow_loop_body_checked_pre
asm_pow_loop_body_checked_mid: db "    dec r8",10,"    jnz .L"
asm_pow_loop_body_checked_mid_len = $ - asm_pow_loop_body_checked_mid
asm_spow_overflow_trap: db "    mov edi, 107",10,"    mov eax, 60",10,"    syscall",10
asm_spow_overflow_trap_len = $ - asm_spow_overflow_trap
asm_upow_init_pre: db "    pop rcx",10,"    mov r8, rax",10,"    mov rax, 1",10,"    test r8, r8",10,"    jz .L"
asm_upow_init_pre_len = $ - asm_upow_init_pre
asm_upow_loop_body_checked_pre: db "    mul rcx",10,"    jo .L"
asm_upow_loop_body_checked_pre_len = $ - asm_upow_loop_body_checked_pre
asm_upow_overflow_trap: db "    mov edi, 113",10,"    mov eax, 60",10,"    syscall",10
asm_upow_overflow_trap_len = $ - asm_upow_overflow_trap
asm_saturating_pow_signed_init_pre: db "    pop r9",10,"    mov r10, rax",10,"    mov rax, 1",10,"    test r10, r10",10,"    jle .L"
asm_saturating_pow_signed_init_pre_len = $ - asm_saturating_pow_signed_init_pre
asm_saturating_pow_unsigned_init_pre: db "    pop r9",10,"    mov r10, rax",10,"    mov rax, 1",10,"    test r10, r10",10,"    jz .L"
asm_saturating_pow_unsigned_init_pre_len = $ - asm_saturating_pow_unsigned_init_pre
asm_saturating_pow_push_base: db "    push r9",10
asm_saturating_pow_push_base_len = $ - asm_saturating_pow_push_base
asm_saturating_pow_loop_mid: db "    dec r10",10,"    jnz .L"
asm_saturating_pow_loop_mid_len = $ - asm_saturating_pow_loop_mid
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
asm_rodata_pre: db 10,"segment readable",10
asm_rodata_pre_len = $ - asm_rodata_pre
asm_rodata_label_pre: db "str_"
asm_rodata_label_pre_len = $ - asm_rodata_label_pre
asm_rodata_label_post: db ":",10,"    db "
asm_rodata_label_post_len = $ - asm_rodata_label_post
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
asm_mov_rsi_rax: db "    mov rsi, rax",10
asm_mov_rsi_rax_len = $ - asm_mov_rsi_rax
asm_mov_rdx_rax: db "    mov rdx, rax",10
asm_mov_rdx_rax_len = $ - asm_mov_rdx_rax
asm_mov_rdi_rax: db "    mov rdi, rax",10
asm_mov_rdi_rax_len = $ - asm_mov_rdi_rax
asm_lea_rdi_str: db "    lea rdi, [str_"
asm_lea_rdi_str_len = $ - asm_lea_rdi_str
asm_lea_rsi_str: db "    lea rsi, [str_"
asm_lea_rsi_str_len = $ - asm_lea_rsi_str
asm_lea_rax_str: db "    lea rax, [str_"
asm_lea_rax_str_len = $ - asm_lea_rax_str
asm_lea_end: db "]",10
asm_lea_end_len = $ - asm_lea_end
asm_mov_rax_0: db "    mov rax, 0",10
asm_mov_rax_0_len = $ - asm_mov_rax_0
asm_mov_rax_1: db "    mov rax, 1",10
asm_mov_rax_1_len = $ - asm_mov_rax_1
asm_mov_rax_2: db "    mov rax, 2",10
asm_mov_rax_2_len = $ - asm_mov_rax_2
asm_mov_rax_3: db "    mov rax, 3",10
asm_mov_rax_3_len = $ - asm_mov_rax_3
asm_syscall: db "    syscall",10
asm_syscall_len = $ - asm_syscall
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
asm_array_bounds_neg_pre: db "    cmp rax, 0",10,"    jl .L"
asm_array_bounds_neg_pre_len = $ - asm_array_bounds_neg_pre
asm_array_bounds_upper_pre: db "    cmp rax, "
asm_array_bounds_upper_pre_len = $ - asm_array_bounds_upper_pre
asm_array_bounds_upper_post: db 10,"    jb .L"
asm_array_bounds_upper_post_len = $ - asm_array_bounds_upper_post
asm_array_bounds_trap: db "    mov edi, 101",10,"    mov eax, 60",10,"    syscall",10
asm_array_bounds_trap_len = $ - asm_array_bounds_trap
asm_mov_rax_at_rcx_rax_8: db "    mov rax, [rcx + rax*8]",10
asm_mov_rax_at_rcx_rax_8_len = $ - asm_mov_rax_at_rcx_rax_8
asm_movzx_rax_byte_at_rcx_rax: db "    movzx rax, byte [rcx + rax]",10
asm_movzx_rax_byte_at_rcx_rax_len = $ - asm_movzx_rax_byte_at_rcx_rax
asm_movsx_rax_byte_at_rcx_rax: db "    movsx rax, byte [rcx + rax]",10
asm_movsx_rax_byte_at_rcx_rax_len = $ - asm_movsx_rax_byte_at_rcx_rax
asm_movzx_rax_word_at_rcx_rax_2: db "    movzx rax, word [rcx + rax*2]",10
asm_movzx_rax_word_at_rcx_rax_2_len = $ - asm_movzx_rax_word_at_rcx_rax_2
asm_movsx_rax_word_at_rcx_rax_2: db "    movsx rax, word [rcx + rax*2]",10
asm_movsx_rax_word_at_rcx_rax_2_len = $ - asm_movsx_rax_word_at_rcx_rax_2
asm_mov_eax_at_rcx_rax_4: db "    mov eax, [rcx + rax*4]",10
asm_mov_eax_at_rcx_rax_4_len = $ - asm_mov_eax_at_rcx_rax_4
asm_movsxd_rax_at_rcx_rax_4: db "    movsxd rax, dword [rcx + rax*4]",10
asm_movsxd_rax_at_rcx_rax_4_len = $ - asm_movsxd_rax_at_rcx_rax_4
asm_lea_rax_rcx_rax: db "    lea rax, [rcx + rax]",10
asm_lea_rax_rcx_rax_len = $ - asm_lea_rax_rcx_rax
asm_lea_rax_rcx_rax_8: db "    lea rax, [rcx + rax*8]",10
asm_lea_rax_rcx_rax_8_len = $ - asm_lea_rax_rcx_rax_8


; print support templates
asm_call_print_int: db "    mov rdi, rax",10,"    call __snapsurf_print_int",10
asm_call_print_int_len = $ - asm_call_print_int
asm_call_print_uint: db "    mov rdi, rax",10,"    call __snapsurf_print_uint",10
asm_call_print_uint_len = $ - asm_call_print_uint
asm_call_eprint_int: db "    mov rdi, rax",10,"    call __snapsurf_eprint_int",10
asm_call_eprint_int_len = $ - asm_call_eprint_int
asm_call_eprint_uint: db "    mov rdi, rax",10,"    call __snapsurf_eprint_uint",10
asm_call_eprint_uint_len = $ - asm_call_eprint_uint

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

asm_print_uint_helper: db \
    "__snapsurf_print_uint:",10, \
    "    push rbp",10, \
    "    mov rbp, rsp",10, \
    "    sub rsp, 32",10, \
    "    mov rax, rdi",10, \
    "    lea rsi, [rbp - 1]",10, \
    "    mov byte [rsi], 10",10, \
    "    mov rcx, 1",10, \
    "    mov r8, 10",10, \
    ".pu_loop:",10, \
    "    xor rdx, rdx",10, \
    "    div r8",10, \
    "    add dl, 48",10, \
    "    dec rsi",10, \
    "    mov [rsi], dl",10, \
    "    inc rcx",10, \
    "    test rax, rax",10, \
    "    jnz .pu_loop",10, \
    "    mov rax, 1",10, \
    "    mov rdi, 1",10, \
    "    mov rdx, rcx",10, \
    "    syscall",10, \
    "    mov rsp, rbp",10, \
    "    pop rbp",10, \
    "    ret",10
asm_print_uint_helper_len = $ - asm_print_uint_helper

asm_eprint_int_helper: db \
    "__snapsurf_eprint_int:",10, \
    "    push rbp",10, \
    "    mov rbp, rsp",10, \
    "    sub rsp, 32",10, \
    "    mov rax, rdi",10, \
    "    lea rsi, [rbp - 1]",10, \
    "    mov byte [rsi], 10",10, \
    "    mov rcx, 1",10, \
    "    test rax, rax",10, \
    "    jns .epi_pos",10, \
    "    neg rax",10, \
    ".epi_pos:",10, \
    "    mov r8, 10",10, \
    ".epi_loop:",10, \
    "    xor rdx, rdx",10, \
    "    div r8",10, \
    "    add dl, 48",10, \
    "    dec rsi",10, \
    "    mov [rsi], dl",10, \
    "    inc rcx",10, \
    "    test rax, rax",10, \
    "    jnz .epi_loop",10, \
    "    test rdi, rdi",10, \
    "    jns .epi_write",10, \
    "    dec rsi",10, \
    "    mov byte [rsi], 45",10, \
    "    inc rcx",10, \
    ".epi_write:",10, \
    "    mov rax, 1",10, \
    "    mov rdi, 2",10, \
    "    mov rdx, rcx",10, \
    "    syscall",10, \
    "    mov rsp, rbp",10, \
    "    pop rbp",10, \
    "    ret",10
asm_eprint_int_helper_len = $ - asm_eprint_int_helper

asm_eprint_uint_helper: db \
    "__snapsurf_eprint_uint:",10, \
    "    push rbp",10, \
    "    mov rbp, rsp",10, \
    "    sub rsp, 32",10, \
    "    mov rax, rdi",10, \
    "    lea rsi, [rbp - 1]",10, \
    "    mov byte [rsi], 10",10, \
    "    mov rcx, 1",10, \
    "    mov r8, 10",10, \
    ".epu_loop:",10, \
    "    xor rdx, rdx",10, \
    "    div r8",10, \
    "    add dl, 48",10, \
    "    dec rsi",10, \
    "    mov [rsi], dl",10, \
    "    inc rcx",10, \
    "    test rax, rax",10, \
    "    jnz .epu_loop",10, \
    "    mov rax, 1",10, \
    "    mov rdi, 2",10, \
    "    mov rdx, rcx",10, \
    "    syscall",10, \
    "    mov rsp, rbp",10, \
    "    pop rbp",10, \
    "    ret",10
asm_eprint_uint_helper_len = $ - asm_eprint_uint_helper

asm_gcd_u64_helper: db \
    "__snapsurf_gcd_u64:",10, \
    "    mov rcx, rdi",10, \
    "    mov r8, rsi",10, \
    ".gcd_loop:",10, \
    "    test r8, r8",10, \
    "    jz .gcd_done",10, \
    "    mov rax, rcx",10, \
    "    xor rdx, rdx",10, \
    "    div r8",10, \
    "    mov rcx, r8",10, \
    "    mov r8, rdx",10, \
    "    jmp .gcd_loop",10, \
    ".gcd_done:",10, \
    "    mov rax, rcx",10, \
    "    ret",10
asm_gcd_u64_helper_len = $ - asm_gcd_u64_helper

asm_lcm_u64_helper: db \
    "__snapsurf_lcm_u64:",10, \
    "    test rdi, rdi",10, \
    "    jz .lcm_zero",10, \
    "    test rsi, rsi",10, \
    "    jz .lcm_zero",10, \
    "    mov r9, rdi",10, \
    "    mov r10, rsi",10, \
    "    mov rcx, rdi",10, \
    "    mov r8, rsi",10, \
    ".lcm_gcd_loop:",10, \
    "    test r8, r8",10, \
    "    jz .lcm_gcd_done",10, \
    "    mov rax, rcx",10, \
    "    xor rdx, rdx",10, \
    "    div r8",10, \
    "    mov rcx, r8",10, \
    "    mov r8, rdx",10, \
    "    jmp .lcm_gcd_loop",10, \
    ".lcm_gcd_done:",10, \
    "    mov rax, r9",10, \
    "    xor rdx, rdx",10, \
    "    div rcx",10, \
    "    mul r10",10, \
    "    jno .lcm_ret",10, \
    "    mov edi, 108",10, \
    "    mov eax, 60",10, \
    "    syscall",10, \
    ".lcm_ret:",10, \
    "    ret",10, \
    ".lcm_zero:",10, \
    "    xor rax, rax",10, \
    "    ret",10
asm_lcm_u64_helper_len = $ - asm_lcm_u64_helper

asm_sqrt_u64_helper: db \
    "__snapsurf_isqrt_u64:",10, \
    "    mov r8, rdi",10, \
    "    xor rcx, rcx",10, \
    "    mov rdx, 0x4000000000000000",10, \
    ".isqrt_bit_down:",10, \
    "    cmp rdx, r8",10, \
    "    jbe .isqrt_loop",10, \
    "    shr rdx, 2",10, \
    "    jmp .isqrt_bit_down",10, \
    ".isqrt_loop:",10, \
    "    test rdx, rdx",10, \
    "    jz .isqrt_done",10, \
    "    mov r9, rcx",10, \
    "    add r9, rdx",10, \
    "    cmp r8, r9",10, \
    "    jb .isqrt_skip",10, \
    "    sub r8, r9",10, \
    "    shr rcx, 1",10, \
    "    add rcx, rdx",10, \
    "    jmp .isqrt_next",10, \
    ".isqrt_skip:",10, \
    "    shr rcx, 1",10, \
    ".isqrt_next:",10, \
    "    shr rdx, 2",10, \
    "    jmp .isqrt_loop",10, \
    ".isqrt_done:",10, \
    "    mov rax, rcx",10, \
    "    ret",10
asm_sqrt_u64_helper_len = $ - asm_sqrt_u64_helper

asm_cbrt_u64_helper: db \
    "__snapsurf_icbrt_u64:",10, \
    "    xor r8, r8",10, \
    "    mov r9, 2642245",10, \
    ".icbrt_loop:",10, \
    "    cmp r8, r9",10, \
    "    jae .icbrt_done",10, \
    "    mov r10, r8",10, \
    "    add r10, r9",10, \
    "    inc r10",10, \
    "    shr r10, 1",10, \
    "    mov rax, rdi",10, \
    "    xor rdx, rdx",10, \
    "    div r10",10, \
    "    xor rdx, rdx",10, \
    "    div r10",10, \
    "    cmp rax, r10",10, \
    "    jb .icbrt_too_high",10, \
    "    mov r8, r10",10, \
    "    jmp .icbrt_loop",10, \
    ".icbrt_too_high:",10, \
    "    mov r9, r10",10, \
    "    dec r9",10, \
    "    jmp .icbrt_loop",10, \
    ".icbrt_done:",10, \
    "    mov rax, r8",10, \
    "    ret",10
asm_cbrt_u64_helper_len = $ - asm_cbrt_u64_helper
