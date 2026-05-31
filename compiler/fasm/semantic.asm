; Status: PARTIAL.
; Semantic checker for the current AST subset, including function registry,
; per-function symbols, and checked user-function calls.

semantic_check_subset:
    cmp qword [ast_error_flag], 0
    jne .ast_error
    cmp qword [ast_root], 0
    je .no_ast

    call semantic_init_fn_registry

    mov rdi, [ast_root]
    call ast_child
    mov rbx, rax
.register_loop:
    test rbx, rbx
    jz .register_done
    mov rdi, rbx
    call ast_kind
    cmp rax, AST_FN_DECL
    je .register_fn
    mov rdi, rbx
    call ast_next
    mov rbx, rax
    jmp .register_loop

.register_fn:
    mov rdi, rbx
    call semantic_register_function
    test rax, rax
    jnz .fail
    mov rdi, rbx
    call ast_next
    mov rbx, rax
    jmp .register_loop

.register_done:
    cmp qword [ast_main_fn], 0
    je .no_main
    mov rdi, [ast_main_fn]
    call semantic_function_param_count
    test rax, rax
    jnz .bad_main
    mov rdi, [ast_main_fn]
    call ast_get_type_tag
    cmp rax, TYPE_I32
    jne .bad_main

    mov rdi, [ast_root]
    call ast_child
    mov rbx, rax
.check_loop:
    test rbx, rbx
    jz .check_done
    mov rdi, rbx
    call ast_kind
    cmp rax, AST_FN_DECL
    je .check_fn
    mov rdi, rbx
    call ast_next
    mov rbx, rax
    jmp .check_loop

.check_fn:
    mov rdi, rbx
    call semantic_check_function
    test rax, rax
    jnz .fail
    mov rdi, rbx
    call ast_next
    mov rbx, rax
    jmp .check_loop

.check_done:
    xor rax, rax
    ret

.ast_error:
    mov rdi, src_path
    mov rsi, err_ast_overflow
    call print_diag
    mov rax, 1
    ret
.no_ast:
    mov rdi, src_path
    mov rsi, err_no_main
    call print_diag
    mov rax, 1
    ret
.no_main:
    mov rdi, src_path
    mov rsi, err_no_main
    call print_diag
    mov rax, 1
    ret
.bad_main:
    mov rdi, [ast_main_fn]
    call set_diag_from_expr_node
    mov rdi, src_path
    mov rsi, err_bad_main
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

; semantic_init_fn_registry: Initialize the function registry
; Returns: rax = 0 always
semantic_init_fn_registry:
    mov qword [fn_registry_count], 0
    mov qword [fn_emit_counter], 0
    mov qword [current_fn_param_count], 0
    mov qword [current_fn_return_type], TYPE_I32
    xor rax, rax
    ret

; semantic_find_function: lookup by source span.
; Input: rdi = name start offset, rsi = name length.
; Returns: rax = registry index + 1, or 0 if not found.
semantic_find_function:
    push rbx
    push r12
    push r13
    push r14
    mov r12, rdi
    mov r13, rsi
    xor rbx, rbx
.search_loop:
    cmp rbx, [fn_registry_count]
    jge .not_found
    mov rax, rbx
    imul rax, 8
    cmp [fn_name_len + rax], r13
    jne .next_entry
    mov r14, [fn_name_start + rax]
    xor rcx, rcx
.compare_loop:
    cmp rcx, r13
    jge .found
    mov al, [src_buf + r12 + rcx]
    mov dl, [src_buf + r14 + rcx]
    cmp al, dl
    jne .next_entry
    inc rcx
    jmp .compare_loop

.next_entry:
    inc rbx
    jmp .search_loop

.found:
    mov rax, rbx
    inc rax
    jmp .out
.not_found:
    xor rax, rax
.out:
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

semantic_register_function:
    push rbx
    push r12
    push r13
    push r14
    mov r12, rdi
    mov rdi, r12
    call ast_child
    test rax, rax
    jz .no_name
    mov rbx, rax
    mov rdi, rbx
    call ast_span_start
    mov r13, rax
    mov rdi, rbx
    call ast_span_end
    mov r14, rax
    sub r14, r13
    mov rdi, r13
    mov rsi, r14
    call semantic_find_function
    test rax, rax
    jnz .duplicate
    mov rbx, [fn_registry_count]
    cmp rbx, FN_REG_CAP
    jge .registry_overflow
    mov rax, rbx
    imul rax, 8
    mov [fn_name_start + rax], r13
    mov [fn_name_len + rax], r14
    mov [fn_ast_node + rax], r12
    mov rdi, r12
    call semantic_function_param_count
    cmp rax, 6
    ja .bad_signature
    mov rdx, rbx
    imul rdx, 8
    mov [fn_param_count + rdx], rax
    mov rdi, r12
    call ast_get_type_tag
    test rax, rax
    jnz .return_type_ok
    mov rax, TYPE_I32
.return_type_ok:
    mov rdx, rbx
    imul rdx, 8
    mov [fn_return_type + rdx], rax
    mov rdi, r13
    mov rsi, r14
    call source_span_is_main
    test rax, rax
    jz .not_main
    mov [ast_main_fn], r12
.not_main:
    inc qword [fn_registry_count]
    xor rax, rax
    jmp .out

.no_name:
    mov rax, 1
    jmp .out
.duplicate:
    mov rdi, r12
    call set_diag_from_expr_node
    mov rdi, src_path
    mov rsi, err_duplicate
    call print_diag
    mov rax, 1
    jmp .out
.bad_signature:
    mov rdi, r12
    call set_diag_from_expr_node
    mov rdi, src_path
    mov rsi, err_bad_fn_sig
    call print_diag
    mov rax, 1
    jmp .out
.registry_overflow:
    mov rdi, src_path
    mov rsi, err_fn_registry_overflow
    call print_diag
    mov rax, 1
.out:
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

source_span_is_main:
    cmp rsi, 4
    jne .no
    cmp byte [src_buf + rdi], 'm'
    jne .no
    cmp byte [src_buf + rdi + 1], 'a'
    jne .no
    cmp byte [src_buf + rdi + 2], 'i'
    jne .no
    cmp byte [src_buf + rdi + 3], 'n'
    jne .no
    mov rax, 1
    ret
.no:
    xor rax, rax
    ret

semantic_fn_block:
    push rbx
    call ast_child
    mov rbx, rax
.loop:
    test rbx, rbx
    jz .missing
    mov rdi, rbx
    call ast_kind
    cmp rax, AST_BLOCK
    je .found
    mov rdi, rbx
    call ast_next
    mov rbx, rax
    jmp .loop
.found:
    mov rax, rbx
    pop rbx
    ret
.missing:
    xor rax, rax
    pop rbx
    ret

semantic_function_param_count:
    push rbx
    push r12
    xor r12, r12
    call ast_child
    mov rbx, rax
.loop:
    test rbx, rbx
    jz .done
    mov rdi, rbx
    call ast_kind
    cmp rax, AST_BLOCK
    je .done
    cmp rax, AST_FN_PARAM
    jne .next
    inc r12
.next:
    mov rdi, rbx
    call ast_next
    mov rbx, rax
    jmp .loop
.done:
    mov rax, r12
    pop r12
    pop rbx
    ret

semantic_bind_params:
    push rbx
    push r12
    call ast_child
    mov rbx, rax
.loop:
    test rbx, rbx
    jz .done
    mov rdi, rbx
    call ast_kind
    cmp rax, AST_BLOCK
    je .done
    cmp rax, AST_FN_PARAM
    jne .next
    mov rdi, rbx
    call ast_get_type_tag
    test rax, rax
    jnz .param_type_ok
    mov rax, TYPE_I32
.param_type_ok:
    mov [tmp_type_id], rax
    mov rdi, rbx
    call ast_child
    mov rdi, rax
    call semantic_ident_token
    mov rdi, rax
    xor rsi, rsi
    mov rdx, [tmp_type_id]
    call symbol_add
    test rax, rax
    jnz .fail
.next:
    mov rdi, rbx
    call ast_next
    mov rbx, rax
    jmp .loop
.done:
    xor rax, rax
    pop r12
    pop rbx
    ret
.fail:
    mov rax, 1
    pop r12
    pop rbx
    ret

semantic_check_function:
    push rbx
    push r12
    mov r12, rdi
    mov rdi, r12
    call ast_get_type_tag
    test rax, rax
    jnz .return_type_ok
    mov rax, TYPE_I32
.return_type_ok:
    mov [current_fn_return_type], rax

    mov rdi, r12
    call semantic_fn_block
    test rax, rax
    jz .bad
    mov rbx, rax
    call semantic_reset_symbols
    call scope_push
    test rax, rax
    jnz .fail
    mov rdi, r12
    call semantic_bind_params
    test rax, rax
    jnz .fail_pop
    mov rdi, rbx
    mov [ast_block_node], rbx
    call semantic_block
    test rax, rax
    jnz .fail_pop
    mov rdi, rbx
    call semantic_block_returns
    test rax, rax
    jz .fail_pop_bad_ret
    call scope_pop
    xor rax, rax
    pop r12
    pop rbx
    ret
.bad:
    mov rdi, src_path
    mov rsi, err_unsup_ast
    call print_diag
    mov rax, 1
    pop r12
    pop rbx
    ret
.bad_ret:
    mov rdi, src_path
    mov rsi, err_ret
    call print_diag
    mov rax, 1
    pop r12
    pop rbx
    ret
.fail_pop:
    call scope_pop
.fail:
    mov rax, 1
    pop r12
    pop rbx
    ret
.fail_pop_bad_ret:
    call scope_pop
    mov rdi, r12
    call ast_span_start
    mov rdi, rax
    call set_diag_from_start
    jmp .bad_ret

semantic_fn_call_type:
    push rbx
    push r12
    push r13
    push r14
    mov r12, rdi
    mov rdi, r12
    call ast_child
    test rax, rax
    jz .bad
    mov rbx, rax
    mov rdi, rbx
    call ast_span_start
    mov r13, rax
    mov rdi, rbx
    call ast_span_end
    mov r14, rax
    sub r14, r13
    mov rdi, r13
    mov rsi, r14
    call semantic_find_function
    test rax, rax
    jz .not_found
    dec rax
    imul rax, 8
    mov r14, [fn_param_count + rax]
    mov r13, [fn_return_type + rax]
    test r13, r13
    jnz .return_type_known
    mov r13, TYPE_I32
.return_type_known:
    mov rdi, r12
    call semantic_call_arg_count
    cmp rax, r14
    jne .arity_bad
    ; Walk the fn decl AST to get param nodes for type comparison
    mov rdi, rbx
    call ast_next
    mov rbx, rax

    ; Locate the first FN_PARAM child of the function AST node
    dec r14                     ; r14 was registry index+1 from earlier
    imul r14, 8
    mov r14, [fn_ast_node + r14] ; r14 = function AST node
    push r14
    mov rdi, r14
    call ast_child
    mov r14, rax                ; r14 = first child of fn decl
    ; Skip non-param children (PATH node comes first)
.skip_to_params:
    test r14, r14
    jz .params_exhausted
    mov rdi, r14
    call ast_kind
    cmp rax, AST_FN_PARAM
    je .arg_loop
    cmp rax, AST_BLOCK
    je .params_exhausted
    mov rdi, r14
    call ast_next
    mov r14, rax
    jmp .skip_to_params

.arg_loop:
    test rbx, rbx
    jz .params_exhausted
    test r14, r14
    jz .params_exhausted
    mov rdi, rbx
    call semantic_expr_type
    test rax, rax
    jz .type_bad
    ; Compare against declared parameter type
    push rax
    mov rdi, r14
    call ast_get_type_tag
    mov rcx, rax
    pop rax
    test rcx, rcx
    jz .arg_type_ok           ; param has no type tag — skip check
    cmp rax, rcx
    jne .arg_type_mismatch
.arg_type_ok:
    mov rdi, rbx
    call ast_next
    mov rbx, rax
    mov rdi, r14
    call ast_next
    mov r14, rax
    ; Skip to next FN_PARAM (might hit BLOCK)
.next_param:
    test r14, r14
    jz .arg_loop
    mov rdi, r14
    call ast_kind
    cmp rax, AST_FN_PARAM
    je .arg_loop
    cmp rax, AST_BLOCK
    je .arg_loop
    mov rdi, r14
    call ast_next
    mov r14, rax
    jmp .next_param
.params_exhausted:
    pop r14
.ok:
    mov rax, r13
    jmp .out
.not_found:
    mov rdi, r12
    call set_diag_from_expr_node
    mov rdi, src_path
    mov rsi, err_fn_not_found
    call print_diag
    xor rax, rax
    jmp .out
.arity_bad:
    mov rdi, r12
    call set_diag_from_expr_node
    mov rdi, src_path
    mov rsi, err_fn_param_mismatch
    call print_diag
    xor rax, rax
    jmp .out
.arg_type_mismatch:
    pop r14
    mov rdi, rbx
    call set_diag_from_expr_node
    mov rdi, src_path
    mov rsi, err_fn_arg_type
    call print_diag
    xor rax, rax
    jmp .out
.type_bad:
    pop r14
    mov rdi, rbx
    call set_diag_from_expr_node
    mov rdi, src_path
    mov rsi, err_type
    call print_diag
    xor rax, rax
    jmp .out
.bad:
    mov rdi, src_path
    mov rsi, err_unsup_ast
    call print_diag
    xor rax, rax
.out:
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

semantic_call_arg_count:
    push rbx
    push r12
    xor r12, r12
    call ast_child
    mov rbx, rax
    test rbx, rbx
    jz .done
    mov rdi, rbx
    call ast_next
    mov rbx, rax
.loop:
    test rbx, rbx
    jz .done
    inc r12
    mov rdi, rbx
    call ast_next
    mov rbx, rax
    jmp .loop
.done:
    mov rax, r12
    pop r12
    pop rbx
    ret

semantic_reset_symbols:
    mov qword [sym_count], 0
    mov qword [local_count], 0
    mov qword [slot_cursor], 0
    mov qword [scope_depth], 0
    mov qword [semantic_loop_depth], 0
    mov qword [semantic_unsafe_depth], 0
    mov byte [return_seen], 0
    ret

; Rebuild the symbol table flat (no scoping) for the emitter.
; Walks a function block AST and re-adds parameters plus let/mut declarations.
semantic_rebuild_for_emit:
    mov rdi, [ast_main_fn]
    call semantic_rebuild_function_for_emit
    ret

semantic_rebuild_function_for_emit:
    push rbx
    push r12
    mov r12, rdi
    call semantic_reset_symbols
    mov rdi, r12
    call ast_get_type_tag
    test rax, rax
    jnz .return_type_ok
    mov rax, TYPE_I32
.return_type_ok:
    mov [current_fn_return_type], rax
    mov rdi, r12
    call semantic_bind_params
    test rax, rax
    jnz .fail
    mov rdi, r12
    call semantic_function_param_count
    mov [current_fn_param_count], rax
    mov rdi, r12
    call semantic_fn_block
    test rax, rax
    jz .fail
    mov rbx, rax
    mov [ast_block_node], rbx
    mov rdi, rbx
    call rebuild_block_flat
    xor rax, rax
    pop r12
    pop rbx
    ret
.fail:
    mov rax, 1
    pop r12
    pop rbx
    ret

rebuild_block_flat:
    push rbx
    call ast_child
    mov rbx, rax
.loop:
    test rbx, rbx
    jz .done
    mov rdi, rbx
    call rebuild_stmt_flat
    mov rdi, rbx
    call ast_next
    mov rbx, rax
    jmp .loop
.done:
    pop rbx
    ret

rebuild_stmt_flat:
    push r12
    push r13
    mov r12, rdi
    call ast_kind
    mov r13, rax
    cmp r13, AST_LET_STMT
    je .decl
    cmp r13, AST_MUT_STMT
    je .decl_mut
    cmp r13, AST_IF_STMT
    je .if_stmt
    cmp r13, AST_WHILE_STMT
    je .while_stmt
    cmp r13, AST_LOOP_STMT
    je .loop_stmt
    pop r13
    pop r12
    ret
.decl:
    mov rdi, r12
    call ast_get_type_tag
    test rax, rax
    jnz .decl_type_flat_ok
    mov rax, TYPE_I32
.decl_type_flat_ok:
    mov [tmp_type_id], rax
    mov rdi, r12
    call ast_child
    mov rdi, rax
    call ast_child
    mov rdi, rax
    xor rsi, rsi
    mov rdx, [tmp_type_id]
    call symbol_add
    pop r13
    pop r12
    ret
.decl_mut:
    mov rdi, r12
    call ast_get_type_tag
    test rax, rax
    jnz .decl_mut_type_flat_ok
    mov rax, TYPE_I32
.decl_mut_type_flat_ok:
    mov [tmp_type_id], rax
    mov rdi, r12
    call ast_child
    mov rdi, rax
    call ast_child
    mov rdi, rax
    mov rsi, 1
    mov rdx, [tmp_type_id]
    call symbol_add
    pop r13
    pop r12
    ret
.if_stmt:
    ; Get then-block (second child = ast_next(condition))
    mov rdi, r12
    call ast_child
    mov rdi, rax
    call ast_next
    mov rdi, rax          ; rdi = then_block
    push rdi              ; save then_block for else lookup
    call rebuild_block_flat
    ; Walk else-block if present (third child = ast_next(then_block))
    pop rdi               ; rdi = then_block
    call ast_next
    test rax, rax
    jz .if_done
    mov rdi, rax
    call rebuild_block_flat
.if_done:
    pop r13
    pop r12
    ret
.while_stmt:
    ; Walk body (second child = ast_next(condition))
    mov rdi, r12
    call ast_child
    mov rdi, rax
    call ast_next
    mov rdi, rax
    call rebuild_block_flat
    pop r13
    pop r12
    ret
.loop_stmt:
    ; Walk body (first child)
    mov rdi, r12
    call ast_child
    mov rdi, rax
    call rebuild_block_flat
    pop r13
    pop r12
    ret

; semantic_block: walk the child list of a block AST node and check each stmt.
; rdi = block node index.
semantic_block:
    push rbx
    mov rdi, rdi
    call ast_child
    mov rbx, rax
.loop:
    test rbx, rbx
    jz .done
    mov rdi, rbx
    call semantic_stmt
    test rax, rax
    jnz .fail
    mov rdi, rbx
    call ast_next
    mov rbx, rax
    jmp .loop
.done:
    xor rax, rax
    pop rbx
    ret
.fail:
    pop rbx
    ret

; semantic_stmt: check a single statement node.
; rdi = statement node index.
semantic_stmt:
    push r12
    push r13
    mov r12, rdi
    call ast_kind
    mov r13, rax
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
    cmp r13, AST_IF_STMT
    je .if_stmt
    cmp r13, AST_WHILE_STMT
    je .while_stmt
    cmp r13, AST_LOOP_STMT
    je .loop_stmt
    cmp r13, AST_BREAK_STMT
    je .break_stmt
    cmp r13, AST_CONTINUE_STMT
    je .continue_stmt
    cmp r13, AST_PRINT_STMT
    je .print_stmt
    mov rdi, src_path
    mov rsi, err_unsup_ast
    call print_diag
    mov rax, 1
    pop r13
    pop r12
    ret
.ret:
    mov rdi, r12
    call semantic_ret_stmt
    pop r13
    pop r12
    ret
.call:
    mov rdi, r12
    call semantic_load_call
    pop r13
    pop r12
    ret
.let:
    mov rdi, r12
    xor rsi, rsi
    call semantic_decl_stmt
    pop r13
    pop r12
    ret
.mut:
    mov rdi, r12
    mov rsi, 1
    call semantic_decl_stmt
    pop r13
    pop r12
    ret
.assign:
    mov rdi, r12
    call semantic_assign_stmt
    pop r13
    pop r12
    ret
.if_stmt:
    mov rdi, r12
    call semantic_if_stmt
    pop r13
    pop r12
    ret
.while_stmt:
    mov rdi, r12
    call semantic_while_stmt
    pop r13
    pop r12
    ret
.loop_stmt:
    mov rdi, r12
    call semantic_loop_stmt
    pop r13
    pop r12
    ret
.break_stmt:
    mov rdi, r12
    call semantic_loop_control_stmt
    pop r13
    pop r12
    ret
.continue_stmt:
    mov rdi, r12
    call semantic_loop_control_stmt
    pop r13
    pop r12
    ret
.print_stmt:
    mov rdi, r12
    call semantic_print_stmt
    pop r13
    pop r12
    ret
.unsafe_block:
    mov rdi, r12
    call semantic_unsafe_block
    pop r13
    pop r12
    ret

semantic_decl_stmt:
    push rbx
    push r12
    push r13
    mov r12, rdi
    mov r13, rsi
    mov rdi, r12
    call ast_get_type_tag
    test rax, rax
    jnz .decl_type_ok
    mov rax, TYPE_I32
.decl_type_ok:
    mov [tmp_type_id], rax
    mov rdi, r12
    call ast_child
    mov rbx, rax
    test rbx, rbx
    jz .bad
    mov rdi, rbx
    call ast_next
    test rax, rax
    jz .no_initializer
    mov rdi, [tmp_type_id]
    mov [expected_expr_type], rdi
    mov rdi, rax
    call semantic_expr_type
    mov qword [expected_expr_type], 0
    test rax, rax
    jz .fail
    cmp rax, [tmp_type_id]
    jne .type_check_struct
.add_symbol:
    mov rdi, rbx
    call semantic_ident_token
    mov rdi, rax
    mov rsi, r13
    mov rdx, [tmp_type_id]
    call symbol_add
    test rax, rax
    jnz .fail
    xor rax, rax
    pop r13
    pop r12
    pop rbx
    ret
.type_check_struct:
    mov [tmp_ast_c], rax

    ; Check if target is a struct type with single primitive field
    mov r10, [tmp_type_id]
    cmp r10, TYPE_PRIMITIVE_COUNT
    jl .type_bad

    cmp r10, [type_count]
    jae .type_bad

    mov r11, r10
    imul r11, TYPE_DESC_SIZE
    cmp byte [type_table + r11 + TYPE_DESC_KIND], TYPE_KIND_STRUCT
    jne .type_bad

    ; For single-field structs, allow init with matching primitive type
    ; This provides convenient auto-wrapping of single field structs
    mov rdi, r10
    call type_struct_single_field_type
    test rax, rax
    jz .type_bad
    cmp rax, [tmp_ast_c]
    jne .type_bad
    jmp .add_symbol
.no_initializer:
    mov rdi, [tmp_type_id]
    call type_get_element_of_array
    test rax, rax
    jz .bad
    jmp .add_symbol
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
    mov rdi, r12
    call ast_child
    mov rbx, rax
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
    mov rax, [sym_type + rdx]
    mov [tmp_type_id], rax
    mov rdi, rbx
    call ast_next
    test rax, rax
    jz .bad
    mov rdi, [tmp_type_id]
    mov [expected_expr_type], rdi
    mov rdi, rax
    call semantic_expr_type
    mov qword [expected_expr_type], 0
    test rax, rax
    jz .fail
    cmp rax, [tmp_type_id]
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
    push r12
    mov r12, rdi
    mov qword [tmp_ast_a], 0
    mov rdi, r12
    call ast_child
    mov [tmp_ast_a], rax
    mov rdi, rax
    test rdi, rdi
    jz .bad
    mov rax, [current_fn_return_type]
    test rax, rax
    jnz .return_type_ok
    mov rax, TYPE_I32
.return_type_ok:
    mov [tmp_type_id], rax
    mov [expected_expr_type], rax
    call semantic_expr_type
    mov qword [expected_expr_type], 0
    test rax, rax
    jz .fail
    cmp rax, [tmp_type_id]
    jne .bad
    mov byte [return_seen], 1
    xor rax, rax
    pop r12
    ret
.bad:
    mov rdi, [tmp_ast_a]
    test rdi, rdi
    jz .bad_at_ret
    call set_diag_from_expr_node
    jmp .bad_print
.bad_at_ret:
    mov rdi, r12
    call set_diag_from_expr_node
.bad_print:
    mov rdi, src_path
    mov rsi, err_ret
    call print_diag
    mov rax, 1
    pop r12
    ret
.fail:
    mov rax, 1
    pop r12
    ret

semantic_loop_control_stmt:
    cmp qword [semantic_loop_depth], 0
    jne .ok
    push rdi
    call ast_span_start
    mov rdi, rax
    call set_diag_from_start
    pop rdi
    mov rdi, src_path
    mov rsi, err_loop_control
    call print_diag
    mov rax, 1
    ret
.ok:
    xor rax, rax
    ret

semantic_loop_enter:
    mov rax, [semantic_loop_depth]
    cmp rax, SCOPE_CAP
    jae .overflow
    inc qword [semantic_loop_depth]
    xor rax, rax
    ret
.overflow:
    mov rdi, src_path
    mov rsi, err_scope_overflow
    call print_diag
    mov rax, 1
    ret

semantic_loop_leave:
    cmp qword [semantic_loop_depth], 0
    je .done
    dec qword [semantic_loop_depth]
.done:
    xor rax, rax
    ret

semantic_block_returns:
    push rbx
    call ast_child
    mov rbx, rax
.loop:
    test rbx, rbx
    jz .no
    mov rdi, rbx
    call semantic_stmt_returns
    test rax, rax
    jnz .yes
    mov rdi, rbx
    call ast_next
    mov rbx, rax
    jmp .loop
.yes:
    mov rax, 1
    pop rbx
    ret
.no:
    xor rax, rax
    pop rbx
    ret

semantic_stmt_returns:
    push rbx
    push r12
    mov r12, rdi
    call ast_kind
    cmp rax, AST_RET_STMT
    je .yes
    cmp rax, AST_IF_STMT
    je .if_stmt
    cmp rax, AST_UNSAFE_BLOCK
    je .unsafe_block
    jmp .no
.unsafe_block:
    mov rdi, r12
    call ast_child
    test rax, rax
    jz .no
    mov rdi, rax
    call semantic_block_returns
    pop r12
    pop rbx
    ret
.if_stmt:
    mov rdi, r12
    call ast_child
    test rax, rax
    jz .no
    mov rdi, rax
    call ast_next
    test rax, rax
    jz .no
    mov rbx, rax
    mov rdi, rbx
    call semantic_block_returns
    test rax, rax
    jz .no
    mov rdi, rbx
    call ast_next
    test rax, rax
    jz .no
    mov rdi, rax
    call semantic_block_returns
    test rax, rax
    jz .no
.yes:
    mov rax, 1
    pop r12
    pop rbx
    ret
.no:
    xor rax, rax
    pop r12
    pop rbx
    ret

; semantic_if_stmt: AST structure is
;   if_stmt -> child chain: [condition, then_block, (optional else_block)]
semantic_if_stmt:
    push rbx
    push r12
    push r13
    mov r12, rdi
    ; Get condition (first child of if_stmt)
    mov rdi, r12
    call ast_child
    mov rbx, rax
    test rbx, rbx
    jz .bad
    mov rdi, rbx
    call semantic_expr_type
    cmp rax, TYPE_BOOL
    jne .bad_cond
    ; Get then-block (second child = ast_next(condition))
    mov rdi, rbx
    call ast_next
    mov r13, rax
    test r13, r13
    jz .bad
    call scope_push
    test rax, rax
    jnz .fail
    mov rdi, r13
    call semantic_block
    test rax, rax
    jnz .fail_pop
    call scope_pop
    ; Check for else-block (third child = ast_next(then_block))
    mov rdi, r13
    call ast_next
    test rax, rax
    jz .done
    mov r13, rax
    call scope_push
    test rax, rax
    jnz .fail
    mov rdi, r13
    call semantic_block
    test rax, rax
    jnz .fail_pop
    call scope_pop
.done:
    xor rax, rax
    pop r13
    pop r12
    pop rbx
    ret
.bad_cond:
    mov rdi, rbx
    call set_diag_from_expr_node
    mov rdi, src_path
    mov rsi, err_bad_cond
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
    mov rax, 1
    pop r13
    pop r12
    pop rbx
    ret
.fail_pop:
    call scope_pop
.fail:
    mov rax, 1
    pop r13
    pop r12
    pop rbx
    ret

; semantic_while_stmt: AST structure is
;   while_stmt -> child chain: [condition, body_block]
semantic_while_stmt:
    push rbx
    push r12
    push r13
    mov r12, rdi
    mov rdi, r12
    call ast_child
    mov rbx, rax
    test rbx, rbx
    jz .bad
    mov rdi, rbx
    call semantic_expr_type
    cmp rax, TYPE_BOOL
    jne .bad_cond
    ; Get body (second child = ast_next(condition))
    mov rdi, rbx
    call ast_next
    mov r13, rax
    test r13, r13
    jz .bad
    call scope_push
    test rax, rax
    jnz .fail
    call semantic_loop_enter
    test rax, rax
    jnz .fail_scope
    mov rdi, r13
    call semantic_block
    test rax, rax
    jnz .fail_loop
    call semantic_loop_leave
    call scope_pop
    xor rax, rax
    pop r13
    pop r12
    pop rbx
    ret
.bad_cond:
    mov rdi, rbx
    call set_diag_from_expr_node
    mov rdi, src_path
    mov rsi, err_bad_cond
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
    mov rax, 1
    pop r13
    pop r12
    pop rbx
    ret
.fail_scope:
    call scope_pop
    mov rax, 1
    pop r13
    pop r12
    pop rbx
    ret
.fail_loop:
    call semantic_loop_leave
    jmp .fail_scope
.fail:
    mov rax, 1
    pop r13
    pop r12
    pop rbx
    ret

; semantic_loop_stmt: AST structure is
;   loop_stmt -> child chain: [body_block]
semantic_loop_stmt:
    push r12
    push r13
    mov r12, rdi
    mov rdi, r12
    call ast_child
    mov r13, rax
    test r13, r13
    jz .bad
    call scope_push
    test rax, rax
    jnz .fail
    call semantic_loop_enter
    test rax, rax
    jnz .fail_scope
    mov rdi, r13
    call semantic_block
    test rax, rax
    jnz .fail_loop
    call semantic_loop_leave
    call scope_pop
    xor rax, rax
    pop r13
    pop r12
    ret
.bad:
    mov rdi, src_path
    mov rsi, err_unsup_ast
    call print_diag
    mov rax, 1
    pop r13
    pop r12
    ret
.fail_scope:
    call scope_pop
    mov rax, 1
    pop r13
    pop r12
    ret
.fail_loop:
    call semantic_loop_leave
    jmp .fail_scope
.fail:
    mov rax, 1
    pop r13
    pop r12
    ret

; semantic_print_stmt: Validate that 'print expr' has an i32 expression.
; rdi = print_stmt node index.
semantic_print_stmt:
    push r12
    mov r12, rdi
    mov rdi, r12
    call ast_child
    mov rdi, rax
    test rdi, rdi
    jz .bad
    call semantic_expr_type
    test rax, rax
    jz .fail
    cmp rax, TYPE_I32
    jne .bad
    xor rax, rax
    pop r12
    ret
.bad:
    mov rdi, src_path
    mov rsi, err_type
    call print_diag
    mov rax, 1
    pop r12
    ret
.fail:
    mov rax, 1
    pop r12
    ret

semantic_unsafe_enter:
    mov rax, [semantic_unsafe_depth]
    cmp rax, SCOPE_CAP
    jae .overflow
    inc qword [semantic_unsafe_depth]
    xor rax, rax
    ret
.overflow:
    mov rdi, src_path
    mov rsi, err_scope_overflow
    call print_diag
    mov rax, 1
    ret

semantic_unsafe_leave:
    cmp qword [semantic_unsafe_depth], 0
    je .done
    dec qword [semantic_unsafe_depth]
.done:
    xor rax, rax
    ret

semantic_check_unsafe_deref:
    cmp qword [semantic_unsafe_depth], 0
    jne .ok
    push rdi
    call ast_span_start
    mov rdi, rax
    call set_diag_from_start
    pop rdi
    mov rdi, src_path
    mov rsi, err_unsafe_op
    call print_diag
    mov rax, 1
    ret
.ok:
    xor rax, rax
    ret

semantic_unsafe_block:
    push rbx
    push r12
    mov r12, rdi

    call semantic_unsafe_enter
    test rax, rax
    jnz .fail_enter

    mov rdi, r12
    call ast_child
    mov rbx, rax

.block_loop:
    test rbx, rbx
    jz .block_done

    mov rdi, rbx
    call semantic_stmt
    test rax, rax
    jnz .fail_loop

    mov rdi, rbx
    call ast_next
    mov rbx, rax
    jmp .block_loop

.block_done:
    call semantic_unsafe_leave
    xor rax, rax
    pop r12
    pop rbx
    ret

.fail_loop:
    call semantic_unsafe_leave
    jmp .fail_enter
.fail_enter:
    pop r12
    pop rbx
    ret
