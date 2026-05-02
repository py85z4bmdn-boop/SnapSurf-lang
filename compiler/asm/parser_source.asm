; parser_source.asm — Modular source parser entry point.
; Sub-modules handle specific statement types:
;   parser/declarations.asm — let, mut, assignment
;   parser/control_flow.asm — if/else, while, loop, break, continue
;   parser/statements.asm   — ret, call
; This file contains: parse_source_subset, parse_main_fn, parse_block,
; parse_block_inner, and the top-level dispatch tables.

parse_source_subset:
    mov qword [token_index], 0
    call ast_reset
    mov rdi, AST_SOURCE_FILE
    xor rsi, rsi
    mov rdx, [src_len]
    xor rcx, rcx
    xor r8, r8
    call ast_new
    test rax, rax
    jz .fail
    mov [ast_root], rax

    xor r15, r15                        ; Track function count
    call skip_newline_tokens
.use_loop:
    call current_token_kind
    cmp rax, TOK_USE
    jne .fn_parse_loop
    call parse_use_decl
    test rax, rax
    jnz .fail
    call skip_newline_tokens
    jmp .use_loop

.fn_parse_loop:
    call skip_newline_tokens
    call current_token_kind
    cmp rax, TOK_FN
    jne .fn_parse_done
    
    ; Parse a function (can be any name, not just main)
    mov qword [parser_found_main], 0    ; Reset main flag for this iteration
    call parse_fn_or_main
    test rax, rax
    jnz .fail
    inc r15                             ; Increment function count
    jmp .fn_parse_loop

.fn_parse_done:
    ; Check we found at least one function
    test r15, r15
    jz .no_functions
    
    ; Check for EOF or unexpected token
    call current_token_kind
    cmp rax, TOK_EOF
    je .success
    cmp rax, TOK_END
    je .success
    
    ; Unexpected token after functions
    call print_unsupported_current
    mov rax, 1
    ret

.success:
    xor rax, rax
    ret

.no_functions:
    call set_diag_from_current
    mov rdi, src_path
    mov rsi, err_no_functions
    call print_diag
    mov rax, 1
    ret
.fail:
    mov rax, 1
    ret

parse_use_decl:
    call current_token_addr
    mov r12, [rax + TOKEN_START]
    call advance_token

    call expect_ident_text_core
    test rax, rax
    jz .bad
    call advance_token
    call current_token_kind
    cmp rax, TOK_SLASH
    jne .bad
    call advance_token
    call expect_ident_text_io
    test rax, rax
    jz .bad
    call current_token_addr
    mov r13, [rax + TOKEN_START]
    add r13, [rax + TOKEN_LEN]
    call advance_token

    mov rdi, AST_USE_DECL
    mov rsi, r12
    mov rdx, r13
    xor rcx, rcx
    xor r8, r8
    call ast_new
    mov r14, rax
    mov rdi, [ast_root]
    mov rsi, r14
    call ast_append_child

    mov rdi, AST_PATH
    mov rsi, r12
    mov rdx, r13
    xor rcx, rcx
    xor r8, r8
    call ast_new
    mov rdi, r14
    mov rsi, rax
    call ast_append_child
    xor rax, rax
    ret
.bad:
    call set_diag_from_current
    mov rdi, src_path
    mov rsi, err_bad_use
    call print_diag
    mov rax, 1
    ret

parse_fn_or_main:
    ; Parse a single function (FN token already verified by caller)
    ; Input: current token should be at 'fn' keyword
    ; Returns: 0 on success, non-zero on failure
    call skip_newline_tokens
    call current_token_kind
    cmp rax, TOK_FN
    jne .bad_expected_fn
    call current_token_addr
    mov r12, [rax + TOKEN_START]
    call advance_token

    call current_token_kind
    cmp rax, TOK_IDENT
    jne .bad_fn_name

    call current_token_addr
    mov r15, [rax + TOKEN_START]
    mov r14, [rax + TOKEN_LEN]
    add r14, r15

    mov rdi, AST_FN_DECL
    mov rsi, r12
    mov rdx, r14
    xor rcx, rcx
    xor r8, r8
    call ast_new
    test rax, rax
    jz .fail
    mov r13, rax

    mov rdi, [ast_root]
    mov rsi, r13
    call ast_append_child

    mov rdi, AST_PATH
    mov rsi, r15
    mov rdx, r14
    xor rcx, rcx
    xor r8, r8
    call ast_new
    test rax, rax
    jz .fail
    mov rdi, r13
    mov rsi, rax
    call ast_append_child

    ; Check if this is the 'main' function
    mov rax, r14
    sub rax, r15
    cmp rax, 4
    je .check_main_name
    jmp .not_main
.check_main_name:
    mov al, byte [src_buf + r15]
    cmp al, 'm'
    jne .not_main
    mov al, byte [src_buf + r15 + 1]
    cmp al, 'a'
    jne .not_main
    mov al, byte [src_buf + r15 + 2]
    cmp al, 'i'
    jne .not_main
    mov al, byte [src_buf + r15 + 3]
    cmp al, 'n'
    jne .not_main
    mov qword [parser_found_main], 1
    mov [ast_main_node_idx], r13

.not_main:
    call advance_token
    call current_token_kind
    cmp rax, TOK_LPAREN
    je .params_paren
    jmp .parse_params


.params_paren:
    call advance_token
    call current_token_kind
    cmp rax, TOK_RPAREN
    je .params_paren_done
.params_paren_loop:
    mov rdi, r13
    call parse_fn_param_node
    test rax, rax
    jnz .fail
    call current_token_kind
    cmp rax, TOK_COMMA
    je .params_paren_comma
    cmp rax, TOK_RPAREN
    je .params_paren_done
    jmp .bad_fn_sig
.params_paren_comma:
    call advance_token
    jmp .params_paren_loop
.params_paren_done:
    call advance_token
    jmp .params_done

.parse_params:
    call current_token_kind
    cmp rax, TOK_ARROW
    je .params_done
    cmp rax, TOK_IDENT
    jne .bad_fn_sig
    mov rdi, r13
    call parse_fn_param_node
    test rax, rax
    jnz .fail
    jmp .parse_params
.params_done:
    call current_token_kind
    cmp rax, TOK_ARROW
    jne .bad_fn_sig
    call advance_token

    call parse_any_type
    test rax, rax
    jz .bad_return_type
    call advance_token

    mov rdi, AST_BLOCK
    mov rsi, r12
    mov rdx, r12
    xor rcx, rcx
    xor r8, r8
    call ast_new
    test rax, rax
    jz .fail
    mov [ast_block_node], rax
    mov rdi, r13
    mov rsi, rax
    call ast_append_child

    call parse_block
    ret

.bad_expected_fn:
    call set_diag_from_current
    mov rdi, src_path
    mov rsi, err_bad_fn
    call print_diag
    mov rax, 1
    ret
.unexpected_end:
    call set_diag_from_current
    mov rdi, src_path
    mov rsi, err_unexpected_end
    call print_diag
    mov rax, 1
    ret
.bad_fn_name:
    call set_diag_from_current
    mov rdi, src_path
    mov rsi, err_bad_fn_name
    call print_diag
    mov rax, 1
    ret
.bad_fn_sig:
    call set_diag_from_current
    mov rdi, src_path
    mov rsi, err_bad_fn_sig
    call print_diag
    mov rax, 1
    ret
.bad_param_type:
    call set_diag_from_current
    mov rdi, src_path
    mov rsi, err_bad_param_type
    call print_diag
    mov rax, 1
    ret
.bad_return_type:
    call set_diag_from_current
    mov rdi, src_path
    mov rsi, err_bad_return_type
    call print_diag
    mov rax, 1
    ret
.fail:
    mov rax, 1
    ret

parse_fn_param_node:
    push rbx
    push r12
    push r13
    mov rbx, rdi
    call parse_ident_node
    test rax, rax
    jz .bad_name
    mov r12, rax
    call parse_any_type
    test rax, rax
    jz .bad_type
    mov [tmp_type_id], rax
    call advance_token
    mov rdi, r12
    call ast_span_start
    mov r13, rax
    mov rdi, r12
    call ast_span_end
    mov rdx, rax
    mov rdi, AST_FN_PARAM
    mov rsi, r13
    mov rcx, r12
    xor r8, r8
    call ast_new
    test rax, rax
    jz .fail
    mov rdi, rbx
    mov rsi, rax
    call ast_append_child
    xor rax, rax
    pop r13
    pop r12
    pop rbx
    ret
.bad_name:
    call set_diag_from_current
    mov rdi, src_path
    mov rsi, err_bad_param_name
    call print_diag
    mov rax, 1
    pop r13
    pop r12
    pop rbx
    ret
.bad_type:
    call set_diag_from_current
    mov rdi, src_path
    mov rsi, err_bad_param_type
    call print_diag
.fail:
    mov rax, 1
    pop r13
    pop r12
    pop rbx
    ret

parse_block:
.loop:
    call skip_newline_tokens
    call current_token_kind
    cmp rax, TOK_END
    je .end
    cmp rax, TOK_EOF
    je .missing_end
    cmp rax, TOK_RET
    je .ret
    cmp rax, TOK_LET
    je .decl
    cmp rax, TOK_MUT
    je .decl
    cmp rax, TOK_IF
    je .if_stmt
    cmp rax, TOK_WHILE
    je .while_stmt
    cmp rax, TOK_LOOP
    je .loop_stmt
    cmp rax, TOK_BREAK
    je .break_stmt
    cmp rax, TOK_CONTINUE
    je .continue_stmt
    cmp rax, TOK_IDENT
    je .ident_stmt
    cmp rax, TOK_PRINT
    je .print_stmt
    jmp .unsupported
.ret:
    call parse_ret_stmt
    test rax, rax
    jnz .fail
    jmp .loop
.decl:
    call parse_decl_stmt
    test rax, rax
    jnz .fail
    jmp .loop
.if_stmt:
    call parse_if_stmt
    test rax, rax
    jnz .fail
    jmp .loop
.while_stmt:
    call parse_while_stmt
    test rax, rax
    jnz .fail
    jmp .loop
.loop_stmt:
    call parse_loop_stmt
    test rax, rax
    jnz .fail
    jmp .loop
.break_stmt:
    call parse_break_stmt
    test rax, rax
    jnz .fail
    jmp .loop
.continue_stmt:
    call parse_continue_stmt
    test rax, rax
    jnz .fail
    jmp .loop
.ident_stmt:
    call current_is_io_write
    test rax, rax
    jnz .call
    call parse_assign_stmt
    test rax, rax
    jnz .fail
    jmp .loop
.call:
    call parse_call_stmt
    test rax, rax
    jnz .fail
    jmp .loop
.print_stmt:
    call parse_print_stmt
    test rax, rax
    jnz .fail
    jmp .loop
.end:
    call advance_token
    xor rax, rax
    ret
.missing_end:
    call set_diag_from_current
    mov rdi, src_path
    mov rsi, err_missing_end
    call print_diag
    mov rax, 1
    ret
.unsupported:
    call print_unsupported_current
    mov rax, 1
    ret
.fail:
    ret

parse_block_inner:
.loop:
    call skip_newline_tokens
    call current_token_kind
    cmp rax, TOK_END
    je .end
    cmp rax, TOK_ELSE
    je .end
    cmp rax, TOK_ELIF
    je .end
    cmp rax, TOK_EOF
    je .missing_end
    cmp rax, TOK_RET
    je .ret
    cmp rax, TOK_LET
    je .decl
    cmp rax, TOK_MUT
    je .decl
    cmp rax, TOK_IF
    je .if_stmt
    cmp rax, TOK_WHILE
    je .while_stmt
    cmp rax, TOK_LOOP
    je .loop_stmt
    cmp rax, TOK_BREAK
    je .break_stmt
    cmp rax, TOK_CONTINUE
    je .continue_stmt
    cmp rax, TOK_IDENT
    je .ident_stmt
    cmp rax, TOK_PRINT
    je .print_stmt
    jmp .unsupported
.ret:
    call parse_ret_stmt
    test rax, rax
    jnz .fail
    jmp .loop
.decl:
    call parse_decl_stmt
    test rax, rax
    jnz .fail
    jmp .loop
.if_stmt:
    call parse_if_stmt
    test rax, rax
    jnz .fail
    jmp .loop
.while_stmt:
    call parse_while_stmt
    test rax, rax
    jnz .fail
    jmp .loop
.loop_stmt:
    call parse_loop_stmt
    test rax, rax
    jnz .fail
    jmp .loop
.break_stmt:
    call parse_break_stmt
    test rax, rax
    jnz .fail
    jmp .loop
.continue_stmt:
    call parse_continue_stmt
    test rax, rax
    jnz .fail
    jmp .loop
.ident_stmt:
    call current_is_io_write
    test rax, rax
    jnz .call
    call parse_assign_stmt
    test rax, rax
    jnz .fail
    jmp .loop
.call:
    call parse_call_stmt
    test rax, rax
    jnz .fail
    jmp .loop
.print_stmt:
    call parse_print_stmt
    test rax, rax
    jnz .fail
    jmp .loop
.end:
    xor rax, rax
    ret
.missing_end:
    call set_diag_from_current
    mov rdi, src_path
    mov rsi, err_missing_end
    call print_diag
    mov rax, 1
    ret
.unsupported:
    call print_unsupported_current
    mov rax, 1
    ret
.fail:
    ret

; Include sub-module implementations
%include "compiler/asm/parser/declarations.asm"
%include "compiler/asm/parser/control_flow.asm"
%include "compiler/asm/parser/statements.asm"
