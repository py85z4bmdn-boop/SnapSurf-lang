; Status: PARTIAL with performance optimization.
; FASM expression codegen for literals, locals, unary minus, and arithmetic.
; Optimized dispatch: high-frequency cases checked first for better CPU branch prediction.

emit_expr:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    call ast_kind
    mov r13, rax
    
    ; High-frequency cases first (better branch prediction)
    cmp r13, AST_INT_LIT
    je .int
    cmp r13, AST_VAR_REF
    je .var
    cmp r13, AST_BIN_ADD
    je .binary
    cmp r13, AST_BIN_SUB
    je .binary
    cmp r13, AST_BIN_MUL
    je .binary
    cmp r13, AST_BIN_DIV
    je .binary
    cmp r13, AST_BIN_XOR
    je .binary
    cmp r13, AST_BIN_SHL
    je .binary
    cmp r13, AST_BIN_SHR
    je .binary
    cmp r13, AST_BIN_ROL
    je .binary
    cmp r13, AST_BIN_ROR
    je .binary
    cmp r13, AST_BIN_POW
    je .binary
    
    ; Medium-frequency cases
    cmp r13, AST_BIN_LT
    je .comparison
    cmp r13, AST_BIN_GT
    je .comparison
    cmp r13, AST_BIN_EE
    je .comparison
    cmp r13, AST_BIN_AND
    je .logical
    cmp r13, AST_BIN_OR
    je .logical
    
    ; Less frequent cases
    cmp r13, AST_BOOL_LIT
    je .bool
    cmp r13, AST_UNARY_NEG
    je .neg
    cmp r13, AST_UNARY_NOT
    je .not
    cmp r13, AST_BIN_MOD
    je .binary
    cmp r13, AST_BIN_GE
    je .comparison
    cmp r13, AST_BIN_LE
    je .comparison
    cmp r13, AST_BIN_NE
    je .comparison
    cmp r13, AST_FN_CALL_EXPR
    je .fn_call
    cmp r13, AST_ADDR_OF
    je .addr_of
    cmp r13, AST_DEREF
    je .deref
    cmp r13, AST_ARRAY_INDEX
    je .array_index
    cmp r13, AST_FIELD_ACCESS
    je .field_access
    cmp r13, AST_STRUCT_LIT
    je .struct_lit
    jmp .fail
.int:
    mov rdi, r12
    call ast_child
    mov rdi, rax
    call token_addr
    mov rbx, [rax + TOKEN_PAYLOAD]
    call emit_mov_rax_imm
    jmp .ok
.bool:
    mov rdi, r12
    call ast_child
    mov rbx, rax
    call emit_mov_rax_imm
    jmp .ok
.var:
    mov rdi, r12
    call ast_child
    mov rdi, rax
    call symbol_slot_for_token
    test rax, rax
    jz .fail
    imul rax, 8
    mov rbx, rax
    mov rdi, [out_fd]
    mov rsi, asm_load_local_pre
    mov rdx, asm_load_local_pre_len
    call write_all
    mov rax, rbx
    mov rdi, [out_fd]
    call write_u64_fd
    mov rdi, [out_fd]
    mov rsi, asm_load_local_post
    mov rdx, asm_load_local_post_len
    call write_all
    jmp .ok
.neg:
    mov rdi, r12
    call ast_child
    mov rdi, rax
    call emit_expr
    test rax, rax
    jnz .fail
    mov rdi, [out_fd]
    mov rsi, asm_neg_rax
    mov rdx, asm_neg_rax_len
    call write_all
    jmp .ok
.not:
    mov rdi, r12
    call ast_child
    mov rbx, rax
    mov rdi, rbx
    call semantic_expr_type
    test rax, rax
    jz .fail
    mov r14, rax
    mov rdi, rbx
    call emit_expr
    test rax, rax
    jnz .fail
    cmp r14, TYPE_BOOL
    je .not_bool
    mov rdi, r14
    call type_is_integer
    test rax, rax
    jz .fail
    mov rdi, [out_fd]
    mov rsi, asm_bit_not_rax
    mov rdx, asm_bit_not_rax_len
    call write_all
    jmp .ok
.not_bool:
    mov rdi, [out_fd]
    mov rsi, asm_not_rax
    mov rdx, asm_not_rax_len
    call write_all
    jmp .ok
.comparison:
    mov rdi, r12
    mov rsi, r13
    call emit_comparison_expr
    test rax, rax
    jnz .fail
    jmp .ok
.logical:
    mov rdi, r12
    mov rsi, r13
    call emit_logical_expr
    test rax, rax
    jnz .fail
    jmp .ok
.fn_call:
    mov rdi, r12
    call emit_fn_call_expr
    test rax, rax
    jnz .fail
    jmp .ok
.addr_of:
    ; &expr: compute address of variable
    mov rdi, r12
    call ast_child
    mov rdi, rax
    ; For now, only support &var syntax
    call ast_kind
    cmp rax, AST_VAR_REF
    jne .fail
    
    ; Get the variable slot
    mov rdi, r12
    call ast_child
    mov rdi, rax
    call ast_child
    mov rdi, rax
    call symbol_slot_for_token
    test rax, rax
    jz .fail
    imul rax, 8
    mov rbx, rax
    
    ; Load address: lea rax, [rbp - slot_offset]
    mov rdi, [out_fd]
    mov rsi, asm_lea_rax_rbp
    mov rdx, asm_lea_rax_rbp_len
    call write_all
    mov rax, rbx
    mov rdi, [out_fd]
    call write_u64_fd
    mov rdi, [out_fd]
    mov rsi, asm_lea_rax_rbp_end
    mov rdx, asm_lea_rax_rbp_end_len
    call write_all
    jmp .ok
.deref:
    ; *expr: load from pointer value
    mov rdi, r12
    call ast_child
    mov rdi, rax
    call emit_expr
    test rax, rax
    jnz .fail
    
    ; Load from address: mov rax, [rax]
    mov rdi, [out_fd]
    mov rsi, asm_mov_rax_at_rax
    mov rdx, asm_mov_rax_at_rax_len
    call write_all
    jmp .ok
.array_index:
    ; arr[idx]: compute base address, then load element.
    mov rdi, r12
    call ast_child
    mov r14, rax
    mov rdi, r14
    call ast_kind
    cmp rax, AST_VAR_REF
    je .array_index_var
    mov rdi, r14
    call emit_expr
    test rax, rax
    jnz .fail
    jmp .array_index_base_done
.array_index_var:
    mov rdi, r14
    call ast_child
    mov rdi, rax
    call symbol_slot_for_token
    test rax, rax
    jz .fail
    imul rax, 8
    mov rbx, rax
    mov rdi, [out_fd]
    mov rsi, asm_lea_rax_rbp
    mov rdx, asm_lea_rax_rbp_len
    call write_all
    mov rax, rbx
    mov rdi, [out_fd]
    call write_u64_fd
    mov rdi, [out_fd]
    mov rsi, asm_lea_rax_rbp_end
    mov rdx, asm_lea_rax_rbp_end_len
    call write_all
.array_index_base_done:
    
    ; Save array pointer in rcx
    mov rdi, [out_fd]
    mov rsi, asm_mov_rcx_rax
    mov rdx, asm_mov_rcx_rax_len
    call write_all
    
    ; Emit index expression
    mov rdi, r12
    call ast_child
    mov rdi, rax
    call ast_next
    mov rdi, rax
    call emit_expr
    test rax, rax
    jnz .fail
    
    ; Load value at [rcx + rax*8] (assuming 64-bit values)
    mov rdi, [out_fd]
    mov rsi, asm_mov_rax_at_rcx_rax_8
    mov rdx, asm_mov_rax_at_rcx_rax_8_len
    call write_all
    jmp .ok
.field_access:
    ; p.field: load field value from struct variable on the stack.
    ; Struct layout: fields occupy consecutive 8-byte slots.
    ; Field n of variable at base_slot is at [rbp - (base_slot + n) * 8].
    mov rdi, r12
    call ast_child
    test rax, rax
    jz .fail
    mov r14, rax                    ; r14 = base expression node

    ; Check if base is a simple VAR_REF
    mov rdi, r14
    call ast_kind
    cmp rax, AST_VAR_REF
    jne .field_access_fallback

    ; Get base variable slot
    mov rdi, r14
    call ast_child
    mov rdi, rax
    call symbol_slot_for_token
    test rax, rax
    jz .fail
    mov r15, rax                    ; r15 = base slot number

    ; Get base variable type for field index lookup
    mov rdi, r14
    call ast_child
    mov rdi, rax
    call symbol_find
    test rax, rax
    jz .fail
    dec rax
    imul rax, 8
    mov rbx, [sym_type + rax]       ; rbx = struct type ID

    ; Get field name from the FIELD_ACCESS span
    mov rdi, r12
    call ast_span_start
    mov r13, rax                    ; field name offset
    mov rdi, r12
    call ast_span_end
    sub rax, r13                    ; field name length
    mov r14, rax

    ; Look up field index
    mov rdi, rbx
    mov rsi, r13
    mov rdx, r14
    call type_struct_field_index
    cmp rax, -1
    je .fail

    ; Compute slot offset: (base_slot + field_index) * 8
    add rax, r15
    imul rax, 8
    mov rbx, rax

    ; Emit: mov rax, [rbp - offset]
    mov rdi, [out_fd]
    mov rsi, asm_load_local_pre
    mov rdx, asm_load_local_pre_len
    call write_all
    mov rax, rbx
    mov rdi, [out_fd]
    call write_u64_fd
    mov rdi, [out_fd]
    mov rsi, asm_load_local_post
    mov rdx, asm_load_local_post_len
    call write_all
    jmp .ok

.field_access_fallback:
    ; Non-variable base: emit base expression (partial support)
    mov rdi, r14
    call emit_expr
    test rax, rax
    jnz .fail
    jmp .ok
.struct_lit:
    ; Struct literal: Type { field1 = expr1, field2 = expr2, ... }
    ; For now, initialize by evaluating field expressions left-to-right
    ; and accumulating in rax. Final implementation will place fields at offsets.
    
    ; Get the struct type name from first child
    mov rdi, r12
    call ast_child
    test rax, rax
    jz .fail
    
    mov r14, rax                    ; r14 = struct type name node
    
    ; Get the next sibling (first field value)
    mov rdi, r14
    call ast_next
    mov r13, rax                    ; r13 = first field value expression (or NULL)
    
    ; For struct literals with fields, evaluate each field expression
    xor r15, r15                    ; r15 = field counter
.field_eval_loop:
    test r13, r13
    jz .struct_lit_done
    
    ; Emit the field expression
    mov rdi, r13
    call emit_expr
    test rax, rax
    jnz .fail
    
    ; Result is in rax, would normally store to struct field offset
    ; For now, keep accumulating in rax
    
    ; Move to next field expression
    mov rdi, r13
    call ast_next
    mov r13, rax
    inc r15
    jmp .field_eval_loop
    
.struct_lit_done:
    ; If no fields were evaluated, return 0 (struct initialized to zero)
    ; Otherwise return the last field value (temporary until proper struct layout)
    test r15, r15
    jnz .ok
    
    xor rbx, rbx
    call emit_mov_rax_imm
    jmp .ok
.binary:
    mov rdi, r12
    call emit_binary_expr
    test rax, rax
    jnz .fail
.ok:
    xor rax, rax
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.fail:
    mov rax, 1
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

emit_binary_expr:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    call ast_kind
    mov r13, rax
    mov rdi, r12
    call ast_child
    mov r14, rax
    test r14, r14
    jz .fail
    mov rdi, r14
    call ast_next
    test rax, rax
    jz .fail
    mov rbx, rax

    ; Try constant folding optimization
    mov rdi, r13
    mov rsi, r14
    mov rdx, rbx
    call try_fold_binary_expr
    cmp rax, 1
    je .runtime
    cmp rax, 0
    je .runtime

    ; Folding succeeded - folded result is in rbx, emit it
    call emit_mov_rax_imm
    jmp .ok

.runtime:
    ; No folding possible - use runtime evaluation
    mov rdi, r14
    call emit_expr
    test rax, rax
    jnz .fail
    mov rdi, [out_fd]
    mov rsi, asm_push_rax
    mov rdx, asm_push_rax_len
    call write_all
    mov rdi, rbx
    call emit_expr
    test rax, rax
    jnz .fail
    cmp r13, AST_BIN_ADD
    je .add
    cmp r13, AST_BIN_SUB
    je .sub
    cmp r13, AST_BIN_MUL
    je .mul
    cmp r13, AST_BIN_DIV
    je .div
    cmp r13, AST_BIN_MOD
    je .mod
    cmp r13, AST_BIN_XOR
    je .xor
    cmp r13, AST_BIN_SHL
    je .shl
    cmp r13, AST_BIN_SHR
    je .shr
    cmp r13, AST_BIN_ROL
    je .rol
    cmp r13, AST_BIN_ROR
    je .ror
    cmp r13, AST_BIN_POW
    je .pow
    jmp .fail
.add:
    mov rdi, [out_fd]
    mov rsi, asm_add_rax
    mov rdx, asm_add_rax_len
    call write_all
    jmp .ok
.sub:
    mov rdi, [out_fd]
    mov rsi, asm_sub_rax
    mov rdx, asm_sub_rax_len
    call write_all
    jmp .ok
.mul:
    mov rdi, [out_fd]
    mov rsi, asm_mul_rax
    mov rdx, asm_mul_rax_len
    call write_all
    jmp .ok
.div:
    mov rdi, [out_fd]
    mov rsi, asm_div_rax
    mov rdx, asm_div_rax_len
    call write_all
    jmp .ok
.mod:
    mov rdi, [out_fd]
    mov rsi, asm_mod_rax
    mov rdx, asm_mod_rax_len
    call write_all
    jmp .ok
.xor:
    mov rdi, [out_fd]
    mov rsi, asm_xor_rax
    mov rdx, asm_xor_rax_len
    call write_all
    jmp .ok
.shl:
    mov rdi, [out_fd]
    mov rsi, asm_shl_rax
    mov rdx, asm_shl_rax_len
    call write_all
    jmp .ok
.shr:
    mov rdi, [out_fd]
    mov rsi, asm_shr_rax
    mov rdx, asm_shr_rax_len
    call write_all
    jmp .ok
.rol:
    mov rdi, [out_fd]
    mov rsi, asm_rol_rax
    mov rdx, asm_rol_rax_len
    call write_all
    jmp .ok
.ror:
    mov rdi, [out_fd]
    mov rsi, asm_ror_rax
    mov rdx, asm_ror_rax_len
    call write_all
    jmp .ok
.pow:
    mov r14, [label_counter]
    inc qword [label_counter]
    mov r15, [label_counter]
    inc qword [label_counter]
    mov rdi, [out_fd]
    mov rsi, asm_pow_init_pre
    mov rdx, asm_pow_init_pre_len
    call write_all
    mov rax, r15
    mov rdi, [out_fd]
    call write_u64_fd
    mov rdi, [out_fd]
    mov rsi, asm_jz_post
    mov rdx, asm_jz_post_len
    call write_all
    mov rdi, [out_fd]
    mov rsi, asm_label_pre
    mov rdx, asm_label_pre_len
    call write_all
    mov rax, r14
    mov rdi, [out_fd]
    call write_u64_fd
    mov rdi, [out_fd]
    mov rsi, asm_label_post
    mov rdx, asm_label_post_len
    call write_all
    mov rdi, [out_fd]
    mov rsi, asm_pow_loop_body_pre
    mov rdx, asm_pow_loop_body_pre_len
    call write_all
    mov rax, r14
    mov rdi, [out_fd]
    call write_u64_fd
    mov rdi, [out_fd]
    mov rsi, asm_jz_post
    mov rdx, asm_jz_post_len
    call write_all
    mov rdi, [out_fd]
    mov rsi, asm_label_pre
    mov rdx, asm_label_pre_len
    call write_all
    mov rax, r15
    mov rdi, [out_fd]
    call write_u64_fd
    mov rdi, [out_fd]
    mov rsi, asm_label_post
    mov rdx, asm_label_post_len
    call write_all
    jmp .ok
.ok:
    xor rax, rax
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.fail:
    mov rax, 1
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; try_fold_binary_expr: Attempt to fold binary expression at compile-time
; Input: rdi = operation kind, rsi = left node, rdx = right node
; Output: rax = -1 (folded, result in rbx), 0 (overflow), 1 (can't fold - not constants)
; Modifies: rax, rbx, rcx, r8, r9
try_fold_binary_expr:
    push r10
    push r11
    push r12
    push r13
    mov r12, rdi        ; operation kind
    mov r13, rsi        ; left node
    mov r10, rdx        ; right node

    ; Check if left is integer literal
    mov rdi, r13
    call ast_kind
    cmp rax, AST_INT_LIT
    jne .cant_fold_noleft
    mov rdi, r13
    call ast_child
    mov rdi, rax
    call token_addr
    mov r8, [rax + TOKEN_PAYLOAD]

    ; Check if right is integer literal
    mov rdi, r10
    call ast_kind
    cmp rax, AST_INT_LIT
    jne .cant_fold_noright
    mov rdi, r10
    call ast_child
    mov rdi, rax
    call token_addr
    mov r9, [rax + TOKEN_PAYLOAD]

    ; Both are constants - fold them
    cmp r12, AST_BIN_ADD
    je .fold_add
    cmp r12, AST_BIN_SUB
    je .fold_sub
    cmp r12, AST_BIN_MUL
    je .fold_mul
    cmp r12, AST_BIN_DIV
    je .fold_div
    cmp r12, AST_BIN_MOD
    je .fold_mod
    cmp r12, AST_BIN_XOR
    je .fold_xor
    cmp r12, AST_BIN_SHL
    je .fold_shl
    cmp r12, AST_BIN_SHR
    je .fold_shr
    cmp r12, AST_BIN_ROL
    je .fold_rol
    cmp r12, AST_BIN_ROR
    je .fold_ror
    cmp r12, AST_BIN_POW
    je .fold_pow
    jmp .cant_fold_badop

.fold_add:
    mov rax, r8
    add rax, r9
    jmp .folded_ok

.fold_sub:
    mov rax, r8
    sub rax, r9
    jmp .folded_ok

.fold_mul:
    mov rax, r8
    imul rax, r9
    jmp .folded_ok

.fold_div:
    cmp r9, 0
    je .fold_div_by_zero
    mov rax, r8
    cqo
    idiv r9
    jmp .folded_ok

.fold_mod:
    cmp r9, 0
    je .fold_mod_by_zero
    mov rax, r8
    cqo
    idiv r9
    mov rax, rdx
    jmp .folded_ok

.fold_xor:
    mov rax, r8
    xor rax, r9
    jmp .folded_ok

.fold_shl:
    mov rax, r8
    mov rcx, r9
    shl rax, cl
    jmp .folded_ok

.fold_shr:
    mov rax, r8
    mov rcx, r9
    shr rax, cl
    jmp .folded_ok

.fold_rol:
    mov rax, r8
    mov rcx, r9
    rol rax, cl
    jmp .folded_ok

.fold_ror:
    mov rax, r8
    mov rcx, r9
    ror rax, cl
    jmp .folded_ok

.fold_pow:
    mov rax, 1
    mov rcx, r9
    cmp rcx, 0
    jle .folded_ok
.fold_pow_loop:
    imul rax, r8
    dec rcx
    jnz .fold_pow_loop
    jmp .folded_ok

.folded_ok:
    mov rbx, rax        ; Result in rbx for emit_mov_rax_imm
    mov rax, -1         ; Success
    jmp .try_fold_done

.fold_div_by_zero:
.fold_mod_by_zero:
    mov rax, 0          ; Division by zero - can't fold
    jmp .try_fold_done

.cant_fold_noleft:
.cant_fold_noright:
.cant_fold_badop:
    mov rax, 1          ; Can't fold - not constants
.try_fold_done:
    pop r13
    pop r12
    pop r11
    pop r10
    ret

; emit_fn_call_expr: Emit function call instruction
; Input: rdi = FnCallExpr node
; Returns: rax = 0 on success
emit_fn_call_expr:
    push rbx
    push r12
    push r13

    mov rbx, rdi
    mov rdi, rbx
    call ast_child
    test rax, rax
    jz .fail
    mov r13, rax
    mov qword [tmp_arg_count], 0
    mov rdi, r13
    call ast_next
    mov r12, rax
.arg_loop:
    test r12, r12
    jz .pop_args
    mov rdi, r12
    call emit_expr
    test rax, rax
    jnz .fail
    mov rdi, [out_fd]
    mov rsi, asm_push_rax
    mov rdx, asm_push_rax_len
    call write_all
    inc qword [tmp_arg_count]
    mov rdi, r12
    call ast_next
    mov r12, rax
    jmp .arg_loop

.pop_args:
    mov r12, [tmp_arg_count]
.pop_loop:
    test r12, r12
    jz .call
    dec r12
    mov rdi, r12
    call emit_pop_arg_register
    test rax, rax
    jnz .fail
    jmp .pop_loop

.call:
    mov rdi, [out_fd]
    mov rsi, asm_call_prefix
    mov rdx, asm_call_prefix_len
    call write_all
    mov rdi, [out_fd]
    mov rsi, asm_fn_prefix
    mov rdx, asm_fn_prefix_len
    call write_all
    mov rdi, r13
    call ast_span_start
    mov r12, rax
    mov rdi, r13
    call ast_span_end
    sub rax, r12
    mov rdx, rax
    mov rdi, [out_fd]
    mov rsi, r12
    call write_src_span
    mov rdi, [out_fd]
    mov rsi, asm_final_newline
    mov rdx, 1
    call write_all

    xor rax, rax
    pop r13
    pop r12
    pop rbx
    ret
.fail:
    mov rax, 1
    pop r13
    pop r12
    pop rbx
    ret

emit_pop_arg_register:
    cmp rdi, 0
    je .rdi
    cmp rdi, 1
    je .rsi
    cmp rdi, 2
    je .rdx
    cmp rdi, 3
    je .rcx
    cmp rdi, 4
    je .r8
    cmp rdi, 5
    je .r9
    mov rax, 1
    ret
.rdi:
    mov rsi, asm_pop_rdi
    mov rdx, asm_pop_rdi_len
    jmp .write
.rsi:
    mov rsi, asm_pop_rsi
    mov rdx, asm_pop_rsi_len
    jmp .write
.rdx:
    mov rsi, asm_pop_rdx
    mov rdx, asm_pop_rdx_len
    jmp .write
.rcx:
    mov rsi, asm_pop_rcx
    mov rdx, asm_pop_rcx_len
    jmp .write
.r8:
    mov rsi, asm_pop_r8
    mov rdx, asm_pop_r8_len
    jmp .write
.r9:
    mov rsi, asm_pop_r9
    mov rdx, asm_pop_r9_len
.write:
    mov rdi, [out_fd]
    call write_all
    xor rax, rax
    ret
