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
    call type_init
    mov qword [struct_registry_count], 0
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
    jne .struct_parse_loop
    call parse_use_decl
    test rax, rax
    jnz .fail
    call skip_newline_tokens
    jmp .use_loop

.struct_parse_loop:
    call skip_newline_tokens
    call current_token_kind
    cmp rax, TOK_STRUCT
    jne .fn_parse_loop
    call parse_struct_decl
    test rax, rax
    jnz .fail
    call skip_newline_tokens
    jmp .struct_parse_loop

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

parse_struct_decl:
    ; Parse: struct Name
    ;         field1 type1;
    ;         field2 type2;
    ;         ...
    ;         end
    ; Input: current token at TOK_STRUCT
    ; Output: 0 on success, 1 on failure
    push rbx
    push r12
    push r13
    push r14
    push r15
    
    ; Get struct token position
    call current_token_addr
    mov r12, [rax + TOKEN_START]
    call advance_token
    
    ; Parse struct name (identifier)
    call current_token_kind
    cmp rax, TOK_IDENT
    jne .bad
    
    call current_token_addr
    mov r13, [rax + TOKEN_START]
    mov r14, [rax + TOKEN_LEN]
    call advance_token
    
    call skip_newline_tokens
    
    ; Create struct AST node
    mov rdi, AST_STRUCT_DECL
    mov rsi, r12
    mov rdx, r12
    xor rcx, rcx
    xor r8, r8
    call ast_new
    test rax, rax
    jz .bad
    mov r15, rax
    
    ; Parse fields: field type; field type; ...
    xor rbx, rbx                ; Field counter
.field_loop:
    call current_token_kind
    cmp rax, TOK_END
    je .fields_done
    
    ; Parse field name
    cmp rax, TOK_IDENT
    jne .bad
    
    call current_token_addr
    mov r8, [rax + TOKEN_START]
    mov r9, [rax + TOKEN_LEN]
    call advance_token
    
    ; Parse field type
    call parse_any_type
    test rax, rax
    jz .bad
    mov r10, rax                ; Save type ID
    call advance_token
    
    ; Expect semicolon
    call current_token_kind
    cmp rax, TOK_SEMICOLON
    jne .bad
    call advance_token
    
    ; Create AST_STRUCT_FIELD node
    mov rdi, AST_STRUCT_FIELD
    mov rsi, r8                 ; field name start
    mov rdx, r8
    add rdx, r9                 ; field name end
    xor rcx, rcx
    xor r8, r8
    call ast_new
    test rax, rax
    jz .bad
    
    ; Set field type tag
    mov rdi, rax
    mov rsi, r10
    call ast_set_type_tag
    
    ; Append to struct
    mov rdi, r15
    mov rsi, rax
    call ast_append_child
    
    inc rbx
    call skip_newline_tokens
    jmp .field_loop
    
.fields_done:
    ; Consume end
    call advance_token
    
    ; Register struct in registry
    mov rax, [struct_registry_count]
    cmp rax, 256
    jae .registry_overflow
    
    mov rcx, rax
    mov [struct_name_start + rcx * 8], r13
    mov [struct_name_len + rcx * 8], r14
    mov [struct_field_count + rcx * 8], rbx
    
    ; Create struct type and store type ID
    mov rdi, r13
    mov rsi, r14
    mov rdx, rbx
    mov rcx, r15
    call type_intern_struct
    mov r10, rax                        ; Save struct type ID
    test r10, r10
    jz .bad
    
    ; Store the returned struct type ID in the registry
    mov rax, [struct_registry_count]
    mov rcx, rax
    mov [struct_type_id + rcx * 8], r10
    mov [struct_ast_node + rcx * 8], r15
    inc qword [struct_registry_count]
    
    xor rax, rax
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
    
.registry_overflow:
    call set_diag_from_current
    mov rdi, src_path
    mov rsi, err_struct_registry_overflow
    call print_diag
    mov rax, 1
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
    
.bad:
    call set_diag_from_current
    mov rdi, src_path
    mov rsi, err_bad_struct
    call print_diag
    mov rax, 1
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
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
    mov r14, rax
    mov rdi, rax
    mov rsi, [tmp_type_id]
    call ast_set_type_tag
    mov rdi, rbx
    mov rsi, r14
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
    cmp rax, TOK_UNSAFE
    je .unsafe_block_parse
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
.unsafe_block_parse:
    call parse_unsafe_block
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
    cmp rax, TOK_UNSAFE
    je .unsafe_block
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
.unsafe_block:
    call parse_unsafe_block
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

parse_unsafe_block:
    call current_token_addr
    mov r12, [rax + TOKEN_START]
    call advance_token

    call current_token_kind
    cmp rax, TOK_ARROW
    jne .bad
    call advance_token

    mov rdi, AST_BLOCK
    mov rsi, r12
    mov rdx, r12
    xor rcx, rcx
    xor r8, r8
    call ast_new
    test rax, rax
    jz .bad
    mov r14, rax

    mov rbx, [ast_block_node]
    mov [ast_block_node], r14

    push r12
    push r14
    push rbx
    call parse_block_inner
    pop rbx
    pop r14
    pop r12
    test rax, rax
    jnz .restore_and_fail

    call current_token_kind
    cmp rax, TOK_END
    jne .bad_block_end

    mov rdi, AST_UNSAFE_BLOCK
    mov rsi, r12
    mov rdx, r12
    mov rcx, r14
    xor r8, r8
    call ast_new
    test rax, rax
    jz .bad_block_end

    mov rdi, [ast_block_node]
    mov rsi, rax
    call ast_append_child
    call advance_token

    mov [ast_block_node], rbx
    xor rax, rax
    ret
.restore_and_fail:
    mov [ast_block_node], rbx
    jmp .bad
.bad_block_end:
    mov [ast_block_node], rbx
.bad:
    mov rax, 1
    ret

; Include sub-module implementations
%include "compiler/asm/parser/declarations.asm"
%include "compiler/asm/parser/control_flow.asm"
%include "compiler/asm/parser/statements.asm"
