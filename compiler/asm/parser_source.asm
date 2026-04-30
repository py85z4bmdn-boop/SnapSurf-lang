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

    call skip_newline_tokens
.use_loop:
    call current_token_kind
    cmp rax, TOK_USE
    jne .fn
    call parse_use_decl
    test rax, rax
    jnz .fail
    call skip_newline_tokens
    jmp .use_loop

.fn:
    call parse_main_fn
    test rax, rax
    jnz .fail
    call skip_newline_tokens
    call current_token_kind
    cmp rax, TOK_EOF
    jne .trailing
    xor rax, rax
    ret
.trailing:
    call print_unsupported_current
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

parse_main_fn:
    call skip_newline_tokens
    call current_token_kind
    cmp rax, TOK_EOF
    je .no_main
    cmp rax, TOK_END
    je .unexpected_end
    cmp rax, TOK_FN
    jne .no_main
    call current_token_addr
    mov r12, [rax + TOKEN_START]
    call advance_token

    call expect_ident_text_main
    test rax, rax
    jz .bad_main
    call advance_token
    call current_token_kind
    cmp rax, TOK_ARROW
    jne .bad_fn
    call advance_token
    call expect_ident_text_i32
    test rax, rax
    jz .bad_main
    call current_token_addr
    mov r13, [rax + TOKEN_START]
    add r13, [rax + TOKEN_LEN]
    call advance_token

    mov rdi, AST_FN_DECL
    mov rsi, r12
    mov rdx, r13
    xor rcx, rcx
    xor r8, r8
    call ast_new
    mov [ast_main_fn], rax
    mov rdi, [ast_root]
    mov rsi, rax
    call ast_append_child

    mov rdi, AST_BLOCK
    mov rsi, r13
    mov rdx, r13
    xor rcx, rcx
    xor r8, r8
    call ast_new
    mov [ast_block_node], rax
    mov rdi, [ast_main_fn]
    mov rsi, rax
    call ast_append_child

    call parse_block
    ret

.no_main:
    call set_diag_from_current
    mov rdi, src_path
    mov rsi, err_no_main
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
.bad_main:
    call set_diag_from_current
    mov rdi, src_path
    mov rsi, err_bad_main
    call print_diag
    mov rax, 1
    ret
.bad_fn:
    call set_diag_from_current
    mov rdi, src_path
    mov rsi, err_bad_fn
    call print_diag
    mov rax, 1
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
