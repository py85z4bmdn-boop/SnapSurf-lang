; Status: PARTIAL.
; Semantic checker for the foundation v0 AST. This is a fixed-capacity
; single-function symbol table, not a full resolver or type system.

semantic_check_subset:
    cmp qword [ast_error_flag], 0
    jne .ast_error
    cmp qword [ast_main_fn], 0
    je .no_main
    cmp qword [ast_block_node], 0
    je .bad_ret
    call semantic_reset_symbols
    call type_init
    call scope_push
    test rax, rax
    jnz .fail
    mov rdi, [ast_block_node]
    call semantic_block
    test rax, rax
    jnz .fail
    cmp byte [return_seen], 0
    je .bad_ret
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

semantic_reset_symbols:
    mov qword [sym_count], 0
    mov qword [local_count], 0
    mov qword [slot_cursor], 0
    mov qword [scope_depth], 0
    mov byte [return_seen], 0
    ret

type_init:
    mov qword [type_count], TYPE_PRIMITIVE_COUNT
    mov rcx, 1
.loop:
    cmp rcx, TYPE_PRIMITIVE_COUNT
    jae .done
    mov rax, rcx
    imul rax, TYPE_DESC_SIZE
    mov byte [type_table + rax + TYPE_DESC_KIND], TYPE_KIND_PRIM
    mov byte [type_table + rax + TYPE_DESC_MUT], TYPE_MUT_CONST
    mov dword [type_table + rax + TYPE_DESC_INNER], ecx
    mov qword [type_table + rax + TYPE_DESC_SIZE_PARAM], 0
    inc rcx
    jmp .loop
.done:
    ret

type_check_binary:
    cmp rdx, AST_BIN_ADD
    je .arith
    cmp rdx, AST_BIN_SUB
    je .arith
    cmp rdx, AST_BIN_MUL
    je .arith
    cmp rdx, AST_BIN_DIV
    je .arith
    cmp rdx, AST_BIN_MOD
    je .arith
    xor rax, rax
    ret
.arith:
    cmp rdi, TYPE_I32
    jne .bad
    cmp rsi, TYPE_I32
    jne .bad
    mov rax, TYPE_I32
    ret
.bad:
    xor rax, rax
    ret

type_intern_ptr:
    push rbx
    push r12
    push r13
    mov r12, rdi
    mov r13, rsi
    mov rbx, [type_count]
    cmp rbx, TYPE_TBL_CAP
    jae .overflow
    mov rax, rbx
    imul rax, TYPE_DESC_SIZE
    mov byte [type_table + rax + TYPE_DESC_KIND], TYPE_KIND_PTR
    mov byte [type_table + rax + TYPE_DESC_MUT], r13b
    mov dword [type_table + rax + TYPE_DESC_INNER], r12d
    mov qword [type_table + rax + TYPE_DESC_SIZE_PARAM], 0
    mov rax, rbx
    inc qword [type_count]
    pop r13
    pop r12
    pop rbx
    ret
.overflow:
    xor rax, rax
    pop r13
    pop r12
    pop rbx
    ret

scope_push:
    mov rax, [scope_depth]
    cmp rax, SCOPE_CAP
    jae .overflow
    mov rdx, rax
    imul rdx, 8
    mov rcx, [sym_count]
    mov [scope_sym_base + rdx], rcx
    mov rcx, [slot_cursor]
    mov [scope_slot_base + rdx], rcx
    inc qword [scope_depth]
    xor rax, rax
    ret
.overflow:
    mov rdi, src_path
    mov rsi, err_scope_overflow
    call print_diag
    mov rax, 1
    ret

scope_pop:
    mov rax, [scope_depth]
    test rax, rax
    jz .done
    dec rax
    mov [scope_depth], rax
    imul rax, 8
    mov rcx, [scope_sym_base + rax]
    mov [sym_count], rcx
    mov rcx, [scope_slot_base + rax]
    mov [slot_cursor], rcx
.done:
    xor rax, rax
    ret

semantic_block:
    call ast_addr
    mov r12, [rax + AST_CHILD_OR_DATA]
.loop:
    test r12, r12
    jz .done
    mov rdi, r12
    call semantic_stmt
    test rax, rax
    jnz .fail
    mov rdi, r12
    call ast_next
    mov r12, rax
    jmp .loop
.done:
    xor rax, rax
    ret
.fail:
    ret

semantic_stmt:
    mov r12, rdi
    call ast_addr
    mov r13, [rax + AST_KIND]
    cmp r13, AST_RET_STMT
    je .ret
    cmp r13, AST_CALL_STMT
    je .call
    cmp r13, AST_LET_STMT
    je .let
    cmp r13, AST_MUT_STMT
    je .mut
    cmp r13, AST_ASSIGN_STMT
    je .assign
    mov rdi, src_path
    mov rsi, err_unsup_ast
    call print_diag
    mov rax, 1
    ret
.ret:
    mov rdi, r12
    call semantic_ret_stmt
    ret
.call:
    mov rdi, r12
    call semantic_load_call
    ret
.let:
    mov rdi, r12
    xor rsi, rsi
    call semantic_decl_stmt
    ret
.mut:
    mov rdi, r12
    mov rsi, 1
    call semantic_decl_stmt
    ret
.assign:
    mov rdi, r12
    call semantic_assign_stmt
    ret

semantic_decl_stmt:
    push rbx
    push r12
    push r13
    mov r12, rdi
    mov r13, rsi
    call ast_addr
    mov rbx, [rax + AST_CHILD_OR_DATA]
    test rbx, rbx
    jz .bad
    mov rdi, rbx
    call ast_next
    test rax, rax
    jz .bad
    mov rdi, rax
    call semantic_expr_type
    test rax, rax
    jz .fail
    cmp rax, TYPE_I32
    jne .type_bad
    mov rdi, rbx
    call semantic_ident_token
    mov rdi, rax
    mov rsi, r13
    mov rdx, TYPE_I32
    call symbol_add
    test rax, rax
    jnz .fail
    xor rax, rax
    pop r13
    pop r12
    pop rbx
    ret
.type_bad:
    mov rdi, rbx
    call semantic_ident_token
    mov rdi, rax
    call set_diag_from_token
    mov rdi, src_path
    mov rsi, err_type
    call print_diag
    mov rax, 1
    pop r13
    pop r12
    pop rbx
    ret
.bad:
    mov rdi, src_path
    mov rsi, err_unsup_ast
    call print_diag
.fail:
    mov rax, 1
    pop r13
    pop r12
    pop rbx
    ret

semantic_assign_stmt:
    push rbx
    push r12
    mov r12, rdi
    call ast_addr
    mov rbx, [rax + AST_CHILD_OR_DATA]
    test rbx, rbx
    jz .bad
    mov rdi, rbx
    call semantic_ident_token
    mov [tmp_token], rax
    mov rdi, rax
    call symbol_find
    test rax, rax
    jz .undefined
    dec rax
    mov rdx, rax
    imul rdx, 8
    cmp qword [sym_mut + rdx], 0
    je .immutable
    mov rdi, rbx
    call ast_next
    test rax, rax
    jz .bad
    mov rdi, rax
    call semantic_expr_type
    test rax, rax
    jz .fail
    cmp rax, TYPE_I32
    jne .type_bad
    xor rax, rax
    pop r12
    pop rbx
    ret
.undefined:
    mov rdi, [tmp_token]
    call set_diag_from_token
    mov rdi, src_path
    mov rsi, err_undefined
    call print_diag
    mov rax, 1
    pop r12
    pop rbx
    ret
.immutable:
    mov rdi, [tmp_token]
    call set_diag_from_token
    mov rdi, src_path
    mov rsi, err_immutable
    call print_diag
    mov rax, 1
    pop r12
    pop rbx
    ret
.type_bad:
    mov rdi, [tmp_token]
    call set_diag_from_token
    mov rdi, src_path
    mov rsi, err_type
    call print_diag
    mov rax, 1
    pop r12
    pop rbx
    ret
.bad:
    mov rdi, src_path
    mov rsi, err_unsup_ast
    call print_diag
.fail:
    mov rax, 1
    pop r12
    pop rbx
    ret

semantic_ret_stmt:
    call ast_addr
    mov rdi, [rax + AST_CHILD_OR_DATA]
    test rdi, rdi
    jz .bad
    call semantic_expr_type
    test rax, rax
    jz .fail
    cmp rax, TYPE_I32
    jne .bad
    mov byte [return_seen], 1
    xor rax, rax
    ret
.bad:
    mov rdi, src_path
    mov rsi, err_ret
    call print_diag
    mov rax, 1
    ret
.fail:
    mov rax, 1
    ret

semantic_expr_type:
    push rbx
    push r12
    push r13
    push r14
    mov r12, rdi
    mov r14, rdi
    call ast_addr
    mov r13, [rax + AST_KIND]
    cmp r13, AST_INT_LIT
    je .i32
    cmp r13, AST_BOOL_LIT
    je .bool
    cmp r13, AST_VAR_REF
    je .var
    cmp r13, AST_UNARY_NEG
    je .unary_i32
    cmp r13, AST_BIN_ADD
    je .binary_i32
    cmp r13, AST_BIN_SUB
    je .binary_i32
    cmp r13, AST_BIN_MUL
    je .binary_i32
    cmp r13, AST_BIN_DIV
    je .binary_i32
    cmp r13, AST_BIN_MOD
    je .binary_i32
    jmp .bad
.i32:
    mov rax, TYPE_I32
    jmp .done
.bool:
    mov rax, TYPE_BOOL
    jmp .done
.var:
    mov rdi, r12
    call ast_addr
    mov rdi, [rax + AST_CHILD_OR_DATA]
    mov [tmp_token], rdi
    call symbol_find
    test rax, rax
    jz .undefined
    dec rax
    imul rax, 8
    mov rax, [sym_type + rax]
    jmp .done
.unary_i32:
    mov rdi, r12
    call ast_addr
    mov rdi, [rax + AST_CHILD_OR_DATA]
    test rdi, rdi
    jz .bad
    call semantic_expr_type
    cmp rax, TYPE_I32
    jne .bad_type_current
    mov rax, TYPE_I32
    jmp .done
.binary_i32:
    mov rdi, r12
    call ast_addr
    mov rbx, [rax + AST_CHILD_OR_DATA]
    mov r13, [rax + AST_KIND]
    test rbx, rbx
    jz .bad
    mov rdi, rbx
    call semantic_expr_type
    test rax, rax
    jz .done
    mov r12, rax
    mov rdi, rbx
    call ast_next
    test rax, rax
    jz .bad
    mov rdi, rax
    call semantic_expr_type
    test rax, rax
    jz .done
    mov rdi, r12
    mov rsi, rax
    mov rdx, r13
    call type_check_binary
    test rax, rax
    jz .bad_type_current
    jmp .done
.undefined:
    mov rdi, [tmp_token]
    call set_diag_from_token
    mov rdi, src_path
    mov rsi, err_undefined
    call print_diag
    xor rax, rax
    jmp .done
.bad_type_current:
    mov rdi, r14
    call set_diag_from_expr_node
    mov rdi, src_path
    mov rsi, err_type
    call print_diag
    xor rax, rax
    jmp .done
.bad:
    mov rdi, src_path
    mov rsi, err_unsup_ast
    call print_diag
    xor rax, rax
.done:
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

semantic_load_call:
    mov r12, rdi
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
    mov rsi, err_unsup_ast
    call print_diag
    mov rax, 1
    ret
.len_mismatch:
    mov rdi, src_path
    mov rsi, err_len_mismatch
    call print_diag
    mov rax, 1
    ret

semantic_ident_token:
    call ast_addr
    mov rax, [rax + AST_CHILD_OR_DATA]
    ret

symbol_add:
    push rbx
    push r12
    push r13
    push r14
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    call symbol_find_current_scope
    test rax, rax
    jnz .duplicate
    mov rbx, [sym_count]
    cmp rbx, SYM_CAP
    jae .overflow
    mov rdi, r12
    call token_addr
    mov rdx, rbx
    imul rdx, 8
    mov rcx, [rax + TOKEN_START]
    mov [sym_start + rdx], rcx
    mov rcx, [rax + TOKEN_LEN]
    mov [sym_len + rdx], rcx
    mov [sym_mut + rdx], r13
    mov [sym_type + rdx], r14
    mov rcx, [slot_cursor]
    inc rcx
    mov [sym_slot + rdx], rcx
    mov [slot_cursor], rcx
    cmp rcx, [local_count]
    jbe .count_ok
    mov [local_count], rcx
.count_ok:
    inc qword [sym_count]
    xor rax, rax
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.duplicate:
    mov rdi, r12
    call set_diag_from_token
    mov rdi, src_path
    mov rsi, err_duplicate
    call print_diag
    mov rax, 1
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.overflow:
    mov rdi, r12
    call set_diag_from_token
    mov rdi, src_path
    mov rsi, err_symbol_overflow
    call print_diag
    mov rax, 1
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

symbol_find_current_scope:
    push rbx
    push r12
    push r13
    push r14
    mov r12, rdi
    mov r13, [sym_count]
    test r13, r13
    jz .not_found
    mov r14, [scope_depth]
    test r14, r14
    jz .base_zero
    dec r14
    imul r14, 8
    mov r14, [scope_sym_base + r14]
    jmp .scan
.base_zero:
    xor r14, r14
.scan:
    mov rbx, r13
    dec rbx
.loop:
    cmp rbx, r14
    jb .not_found
    mov rax, rbx
    imul rax, 8
    mov rsi, src_buf
    add rsi, [sym_start + rax]
    mov rdx, [sym_len + rax]
    mov rdi, r12
    call token_text_eq
    test rax, rax
    jnz .found
    test rbx, rbx
    jz .not_found
    dec rbx
    jmp .loop
.found:
    mov rax, rbx
    inc rax
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.not_found:
    xor rax, rax
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

symbol_find:
    push rbx
    push r12
    push r13
    mov r12, rdi
    mov r13, [sym_count]
    test r13, r13
    jz .not_found
    mov rbx, r13
    dec rbx
.loop:
    mov rax, rbx
    imul rax, 8
    mov rsi, src_buf
    add rsi, [sym_start + rax]
    mov rdx, [sym_len + rax]
    mov rdi, r12
    call token_text_eq
    test rax, rax
    jnz .found
    test rbx, rbx
    jz .not_found
    inc rbx
    sub rbx, 2
    jmp .loop
.found:
    mov rax, rbx
    inc rax
    pop r13
    pop r12
    pop rbx
    ret
.not_found:
    xor rax, rax
    pop r13
    pop r12
    pop rbx
    ret

symbol_slot_for_token:
    call symbol_find
    test rax, rax
    jz .missing
    dec rax
    imul rax, 8
    mov rax, [sym_slot + rax]
    ret
.missing:
    xor rax, rax
    ret

ast_next:
    call ast_addr
    mov rax, [rax + AST_NEXT_OR_EXTRA]
    ret

set_diag_from_token:
    call token_addr
    mov rbx, [rax + TOKEN_LINE]
    mov [diag_line], rbx
    mov rbx, [rax + TOKEN_COL]
    mov [diag_col], rbx
    ret

set_diag_from_expr_node:
    push rbx
    push r12
    mov r12, rdi
    call ast_addr
    mov rbx, [rax + AST_KIND]
    cmp rbx, AST_INT_LIT
    je .token_child
    cmp rbx, AST_STR_LIT
    je .token_child
    cmp rbx, AST_IDENT
    je .token_child
    cmp rbx, AST_VAR_REF
    je .token_child
    cmp rbx, AST_BOOL_LIT
    je .span_start
    mov rdi, [rax + AST_CHILD_OR_DATA]
    test rdi, rdi
    jz .done
    call set_diag_from_expr_node
    jmp .done
.token_child:
    mov rdi, [rax + AST_CHILD_OR_DATA]
    call set_diag_from_token
    jmp .done
.span_start:
    mov rdi, [rax + AST_SPAN_START]
    call set_diag_from_start
.done:
    pop r12
    pop rbx
    ret

set_diag_from_start:
    push rbx
    push r12
    mov r12, rdi
    xor rbx, rbx
.loop:
    cmp rbx, [token_count]
    jae .done
    mov rdi, rbx
    call token_addr
    cmp [rax + TOKEN_START], r12
    je .found
    inc rbx
    jmp .loop
.found:
    mov rcx, [rax + TOKEN_LINE]
    mov [diag_line], rcx
    mov rcx, [rax + TOKEN_COL]
    mov [diag_col], rcx
.done:
    pop r12
    pop rbx
    ret
