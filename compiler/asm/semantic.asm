; Status: PARTIAL.
; Semantic checker reads AST arena nodes produced by parser_source.asm.

semantic_check_subset:
    cmp qword [ast_error_flag], 0
    jne .ast_error
    cmp qword [ast_main_fn], 0
    je .no_main
    cmp qword [ast_ret_stmt], 0
    je .bad_ret

    call semantic_load_ret
    test rax, rax
    jnz .fail

    cmp qword [ast_call_stmt], 0
    je .ok
    call semantic_load_call
    test rax, rax
    jnz .fail

.ok:
    xor rax, rax
    ret
.ast_error:
    mov rdi, src_path
    mov rsi, err_ast_overflow
    call print_diag
    mov rax, 1
    ret
.no_main:
    mov rdi, src_path
    mov rsi, err_no_main
    call print_diag
    mov rax, 1
    ret
.bad_ret:
    mov rdi, src_path
    mov rsi, err_ret
    call print_diag
    mov rax, 1
    ret
.fail:
    ret

semantic_load_ret:
    mov rdi, [ast_ret_stmt]
    call ast_addr
    mov rdi, [rax + AST_CHILD_OR_DATA]
    test rdi, rdi
    jz .bad
    call ast_addr
    cmp qword [rax + AST_KIND], AST_INT_LIT
    jne .bad
    mov rdi, [rax + AST_CHILD_OR_DATA]
    call token_addr
    cmp qword [rax + TOKEN_TYPE], TOK_INT
    jne .bad
    mov rbx, [rax + TOKEN_PAYLOAD]
    mov [parsed_ret_value], rbx
    xor rax, rax
    ret
.bad:
    mov rdi, src_path
    mov rsi, err_ret
    call print_diag
    mov rax, 1
    ret

semantic_load_call:
    mov rdi, [ast_call_stmt]
    call ast_addr
    mov rdi, [rax + AST_CHILD_OR_DATA]
    test rdi, rdi
    jz .bad
    call ast_next
    test rax, rax
    jz .bad
    mov rdi, rax
    call ast_next
    test rax, rax
    jz .bad
    mov [tmp_ast_b], rax
    mov rdi, rax
    call ast_next
    test rax, rax
    jz .bad
    mov [tmp_ast_c], rax

    mov rdi, [tmp_ast_b]
    call ast_addr
    cmp qword [rax + AST_KIND], AST_STR_LIT
    jne .bad
    mov rdi, [rax + AST_CHILD_OR_DATA]
    call token_addr
    cmp qword [rax + TOKEN_TYPE], TOK_STRING
    jne .bad
    mov rbx, [rax + TOKEN_LEN]
    mov [parsed_str_len], rbx
    mov rbx, [rax + TOKEN_PAYLOAD]
    mov [tmp_payload], rbx

    mov rdi, [tmp_ast_c]
    call ast_addr
    cmp qword [rax + AST_KIND], AST_INT_LIT
    jne .bad
    mov rdi, [rax + AST_CHILD_OR_DATA]
    call token_addr
    cmp qword [rax + TOKEN_TYPE], TOK_INT
    jne .bad
    mov rbx, [rax + TOKEN_PAYLOAD]
    mov [parsed_io_len], rbx
    cmp rbx, [parsed_str_len]
    jne .len_mismatch
    xor rax, rax
    ret
.bad:
    mov rdi, src_path
    mov rsi, err_unsup_expr
    call print_diag
    mov rax, 1
    ret
.len_mismatch:
    mov rdi, src_path
    mov rsi, err_len_mismatch
    call print_diag
    mov rax, 1
    ret

ast_next:
    call ast_addr
    mov rax, [rax + AST_NEXT_OR_EXTRA]
    ret

