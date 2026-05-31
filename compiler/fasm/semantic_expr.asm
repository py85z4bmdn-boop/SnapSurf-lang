; Status: PARTIAL.
; Expression type checking for the foundation AST.

semantic_expr_type:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r14, rdi
    call ast_kind
    mov r13, rax
    cmp r13, AST_INT_LIT
    je .i32
    cmp r13, AST_BOOL_LIT
    je .bool
    cmp r13, AST_VAR_REF
    je .var
    cmp r13, AST_FN_CALL_EXPR
    je .fn_call
    cmp r13, AST_UNARY_NEG
    je .unary_neg
    cmp r13, AST_UNARY_NOT
    je .unary_bool_or_int
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
    cmp r13, AST_BIN_XOR
    je .binary_i32
    cmp r13, AST_BIN_SHL
    je .binary_i32
    cmp r13, AST_BIN_SHR
    je .binary_i32
    cmp r13, AST_BIN_ROL
    je .binary_i32
    cmp r13, AST_BIN_ROR
    je .binary_i32
    cmp r13, AST_BIN_POW
    je .binary_i32
    cmp r13, AST_BIN_GT
    je .binary_bool
    cmp r13, AST_BIN_LT
    je .binary_bool
    cmp r13, AST_BIN_GE
    je .binary_bool
    cmp r13, AST_BIN_LE
    je .binary_bool
    cmp r13, AST_BIN_EE
    je .binary_bool
    cmp r13, AST_BIN_NE
    je .binary_bool
    cmp r13, AST_BIN_AND
    je .binary_bool_or_int
    cmp r13, AST_BIN_OR
    je .binary_bool_or_int
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
    jmp .bad
.i32:
    cmp qword [expected_expr_type], 0
    je .i32_default
    mov rdi, [expected_expr_type]
    call type_is_integer
    test rax, rax
    jz .i32_default
    mov rdi, r12
    mov rsi, [expected_expr_type]
    call semantic_int_literal_fits_type
    test rax, rax
    jz .bad_type_current
    mov rax, [expected_expr_type]
    jmp .done
.i32_default:
    mov rdi, r12
    mov rsi, TYPE_I32
    call semantic_int_literal_fits_type
    test rax, rax
    jz .bad_type_current
    mov rax, TYPE_I32
    jmp .done
.bool:
    mov rax, TYPE_BOOL
    jmp .done
.var:
    mov rdi, r12
    call ast_child
    mov rdi, rax
    mov [tmp_token], rdi
    call symbol_find
    test rax, rax
    jz .undefined
    dec rax
    imul rax, 8
    mov rax, [sym_type + rax]
    jmp .done
.fn_call:
    mov rdi, r12
    call semantic_fn_call_type
    jmp .done
.unary_neg:
    mov rdi, r12
    call ast_child
    mov rbx, rax
    test rbx, rbx
    jz .bad
    cmp qword [expected_expr_type], 0
    je .unary_neg_default
    mov rdi, [expected_expr_type]
    call semantic_type_is_signed_integer
    test rax, rax
    jz .bad_type_current
    mov rdi, rbx
    call ast_kind
    cmp rax, AST_INT_LIT
    je .unary_neg_lit_expected
    mov rdi, rbx
    call semantic_expr_type
    test rax, rax
    jz .done
    cmp rax, [expected_expr_type]
    jne .bad_type_current
    mov rax, [expected_expr_type]
    jmp .done
.unary_neg_lit_expected:
    mov rdi, rbx
    mov rsi, [expected_expr_type]
    call semantic_neg_int_literal_fits_type
    test rax, rax
    jz .bad_type_current
    mov rax, [expected_expr_type]
    jmp .done
.unary_neg_default:
    mov rdi, rbx
    call ast_kind
    cmp rax, AST_INT_LIT
    je .unary_neg_lit_default
    mov rdi, rbx
    call semantic_expr_type
    test rax, rax
    jz .done
    mov r15, rax
    mov rdi, r15
    call semantic_type_is_signed_integer
    test rax, rax
    jz .bad_type_current
    mov rax, r15
    jmp .done
.unary_neg_lit_default:
    mov rdi, rbx
    mov rsi, TYPE_I32
    call semantic_neg_int_literal_fits_type
    test rax, rax
    jz .bad_type_current
    mov rax, TYPE_I32
    jmp .done
.unary_bool:
    mov rdi, r12
    call ast_child
    mov rdi, rax
    test rdi, rdi
    jz .bad
    call semantic_expr_type
    cmp rax, TYPE_BOOL
    jne .bad_type_current
    mov rax, TYPE_BOOL
    jmp .done
.unary_bool_or_int:
    mov rdi, r12
    call ast_child
    mov rdi, rax
    test rdi, rdi
    jz .bad
    call semantic_expr_type
    cmp rax, TYPE_BOOL
    je .unary_bool_or_int_bool
    mov r12, rax
    mov rdi, rax
    call type_is_integer
    test rax, rax
    jz .bad_type_current
    mov rax, r12
    jmp .done
.unary_bool_or_int_bool:
    mov rax, TYPE_BOOL
    jmp .done
.binary_i32:
    mov rdi, r12
    call ast_kind
    mov r13, rax
    mov rdi, r12
    call ast_child
    mov rbx, rax
    test rbx, rbx
    jz .bad
    mov rdi, rbx
    call ast_kind
    mov r15, rax
    mov rdi, rbx
    call semantic_expr_type
    test rax, rax
    jz .done
    mov r12, rax
    mov rdi, rbx
    call ast_next
    mov r11, rax
    test r11, r11
    jz .bad
    mov rax, [expected_expr_type]
    push rax
    push r11
    mov [expected_expr_type], r12
    mov rdi, r11
    call semantic_expr_type
    pop r11
    pop qword [expected_expr_type]
    test rax, rax
    jz .done
    cmp r15, AST_INT_LIT
    je .binary_i32_store_right_and_retype_left
    cmp r15, AST_UNARY_NEG
    jne .binary_i32_no_retype
.binary_i32_store_right_and_retype_left:
    mov r15, rax
    cmp r12, r15
    je .binary_i32_check
    push r11
    push r15
    mov rax, [expected_expr_type]
    push rax
    mov [expected_expr_type], r15
    mov rdi, rbx
    call semantic_expr_type
    pop qword [expected_expr_type]
    pop r15
    pop r11
    test rax, rax
    jz .done
    mov r12, rax
    jmp .binary_i32_check
.binary_i32_no_retype:
    mov r15, rax
.binary_i32_check:
    mov rdi, r12
    mov rsi, r15
    mov rdx, r13
    push r11
    call type_check_binary
    pop r11
    test rax, rax
    jz .bad_type_current
    cmp r13, AST_BIN_DIV
    je .binary_i32_check_zero_divisor
    cmp r13, AST_BIN_MOD
    je .binary_i32_check_zero_divisor
    mov rax, r12
    jmp .done
.binary_i32_check_zero_divisor:
    push r11
    mov rdi, r11
    call semantic_expr_is_zero_int_const
    pop r11
    test rax, rax
    jnz .bad_div_zero
    mov rax, r12
    jmp .done
.binary_bool_or_int:
    mov rdi, r12
    call ast_kind
    mov r13, rax
    mov rdi, r12
    call ast_child
    mov rbx, rax
    test rbx, rbx
    jz .bad
    mov rdi, rbx
    call ast_kind
    mov r15, rax
    mov rdi, rbx
    call semantic_expr_type
    test rax, rax
    jz .done
    mov r12, rax
    mov rdi, rbx
    call ast_next
    mov r11, rax
    test r11, r11
    jz .bad
    cmp r12, TYPE_BOOL
    je .binary_bool_or_int_right_no_expected
    mov rax, [expected_expr_type]
    push rax
    mov [expected_expr_type], r12
    mov rdi, r11
    call semantic_expr_type
    pop qword [expected_expr_type]
    jmp .binary_bool_or_int_right_typed
.binary_bool_or_int_right_no_expected:
    mov rdi, r11
    call semantic_expr_type
.binary_bool_or_int_right_typed:
    test rax, rax
    jz .done
    mov r13, rax
    cmp r12, TYPE_BOOL
    je .check_bool_or_int_right_bool
    mov rdi, r12
    call type_is_integer
    test rax, rax
    jz .bad_type_current
    mov rdi, r13
    call type_is_integer
    test rax, rax
    jz .bad_type_current
    cmp r15, AST_INT_LIT
    je .binary_bool_or_int_retype_left
    cmp r15, AST_UNARY_NEG
    jne .binary_bool_or_int_compare
.binary_bool_or_int_retype_left:
    cmp r13, r12
    je .binary_bool_or_int_compare
    push r13
    mov rax, [expected_expr_type]
    push rax
    mov [expected_expr_type], r13
    mov rdi, rbx
    call semantic_expr_type
    pop qword [expected_expr_type]
    pop r13
    test rax, rax
    jz .done
    mov r12, rax
.binary_bool_or_int_compare:
    cmp r13, r12
    jne .bad_type_current
    mov rax, r12
    jmp .done
.check_bool_or_int_right_bool:
    cmp r13, TYPE_BOOL
    jne .bad_type_current
    mov rax, TYPE_BOOL
    jmp .done
.binary_bool:
    mov rdi, r12
    call ast_kind
    mov r13, rax
    mov rdi, r12
    call ast_child
    mov rbx, rax
    test rbx, rbx
    jz .bad
    mov rdi, rbx
    call ast_kind
    mov r15, rax
    mov rdi, rbx
    call semantic_expr_type
    mov r12, rax
    cmp r13, AST_BIN_AND
    je .check_bool_operands
    cmp r13, AST_BIN_OR
    je .check_bool_operands
    mov rdi, rax
    call type_is_integer
    test rax, rax
    jz .bad_type_current
    jmp .continue_comparison
.check_bool_operands:
    cmp rax, TYPE_BOOL
    jne .bad_type_current
.continue_comparison:
    mov rdi, rbx
    call ast_next
    test rax, rax
    jz .bad
    mov rdi, rax
    cmp r13, AST_BIN_AND
    je .right_no_expected
    cmp r13, AST_BIN_OR
    je .right_no_expected
    mov rax, [expected_expr_type]
    push rax
    mov [expected_expr_type], r12
    call semantic_expr_type
    pop qword [expected_expr_type]
    jmp .right_typed
.right_no_expected:
    call semantic_expr_type
.right_typed:
    mov rsi, rax
    cmp r13, AST_BIN_AND
    je .check_bool_op2
    cmp r13, AST_BIN_OR
    je .check_bool_op2
    mov rdi, rsi
    call type_is_integer
    test rax, rax
    jz .bad_type_current
    cmp r15, AST_INT_LIT
    je .retype_left_literal
    cmp r15, AST_UNARY_NEG
    jne .compare_types
.retype_left_literal:
    cmp r12, rsi
    je .compare_types
    push rsi
    mov rax, [expected_expr_type]
    push rax
    mov [expected_expr_type], rsi
    mov rdi, rbx
    call semantic_expr_type
    pop qword [expected_expr_type]
    pop rsi
    test rax, rax
    jz .done
    mov r12, rax
.compare_types:
    cmp rsi, r12
    jne .bad_type_current
    jmp .bool_result
.check_bool_op2:
    cmp rsi, TYPE_BOOL
    jne .bad_type_current
.bool_result:
    mov rax, TYPE_BOOL
    jmp .done
.addr_of:
    mov rdi, r12
    call ast_child
    mov rdi, rax
    test rdi, rdi
    jz .bad
    call semantic_expr_type
    test rax, rax
    jz .done
    mov rdi, rax
    xor rsi, rsi
    call type_intern_ptr
    jmp .done
.deref:
    mov rdi, r12
    call ast_child
    mov rdi, rax
    test rdi, rdi
    jz .bad
    call semantic_expr_type
    test rax, rax
    jz .done
    cmp rax, TYPE_PRIMITIVE_COUNT
    jl .bad_pointer_type
    mov rdi, rax
    call type_get_inner
    test rax, rax
    jz .bad_pointer_type
    jmp .done
.bad_pointer_type:
    mov rdi, r14
    call set_diag_from_expr_node
    mov rdi, src_path
    mov rsi, err_type
    call print_diag
    xor rax, rax
    jmp .done
.array_index:
    ; arr[idx]: expr must be array type, index must be integer
    mov rdi, r12
    call ast_child
    mov rdi, rax
    test rdi, rdi
    jz .bad
    call semantic_expr_type
    mov rbx, rax        ; Save array type
    test rax, rax
    jz .done            ; Propagate error
    
    ; Check that it's an array type
    ; Array types start after pointers, we need type_get_element
    ; For now, assume TYPE_KIND_ARRAY check
    mov rdi, rbx
    call type_get_element_of_array
    test rax, rax
    jz .bad_array_type  ; Not an array type
    
    ; Get index expression
    mov rdi, r12
    call ast_child
    mov rdi, rax
    call ast_next
    mov rdi, rax
    test rdi, rdi
    jz .bad
    call semantic_expr_type
    ; Index must be integer type
    cmp rax, TYPE_I32
    jne .bad_array_index ; Index not integer
    
    ; Result type is the element type
    mov rdi, rbx
    call type_get_element_of_array
    jmp .done
.bad_array_type:
    mov rdi, r14
    call set_diag_from_expr_node
    mov rdi, src_path
    mov rsi, err_type
    call print_diag
    xor rax, rax
    jmp .done
.bad_array_index:
    mov rdi, r14
    call set_diag_from_expr_node
    mov rdi, src_path
    mov rsi, err_type
    call print_diag
    xor rax, rax
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
.bad_div_zero:
    mov rdi, r11
    call set_diag_from_expr_node
    mov rdi, src_path
    mov rsi, err_div_zero
    call print_diag
    xor rax, rax
    jmp .done
.field_access:
    ; Get base expression type
    mov rdi, r12
    call ast_child
    test rax, rax
    jz .bad
    mov rdi, rax
    call semantic_expr_type
    test rax, rax
    jz .done
    
    ; Check if it's a struct type
    mov rbx, rax                ; struct type ID
    cmp rbx, TYPE_PRIMITIVE_COUNT
    jl .bad_struct_type
    cmp rbx, [type_count]
    jae .bad_struct_type
    
    mov rax, rbx
    imul rax, TYPE_DESC_SIZE
    cmp byte [type_table + rax + TYPE_DESC_KIND], TYPE_KIND_STRUCT
    jne .bad_struct_type
    
    ; Get field name from AST node (span)
    mov rdi, r12
    call ast_span_start
    mov r13, rax                ; field name offset
    mov rdi, r12
    call ast_span_end
    sub rax, r13                ; field name length
    mov r10, rax                ; Use r10 for field name length (NOT r14!)
    
    ; Look up field type
    mov rdi, rbx                ; struct type ID
    mov rsi, r13                ; field name offset
    mov rdx, r10                ; field name length
    call type_lookup_struct_field
    ; rax now has the field type (or 0 if not found)
    test rax, rax
    jz .bad_struct_type
    
    jmp .done
    
.bad_struct_type:
    mov rdi, r14
    call set_diag_from_expr_node
    mov rdi, src_path
    mov rsi, err_type
    call print_diag
    xor rax, rax
    jmp .done
.struct_lit:
    ; Struct literal: Type { field = expr, ... }
    ; Get struct type name from first child (identifier node)
    mov rdi, r12
    call ast_child
    test rax, rax
    jz .bad
    
    mov rbx, rax                    ; rbx = identifier AST node
    
    ; Get name span from the node
    mov rdi, rbx
    call ast_span_start
    mov [tmp_ast_a], rax            ; struct name offset
    
    mov rdi, rbx
    call ast_span_end
    sub rax, [tmp_ast_a]
    mov [tmp_ast_b], rax            ; struct name length
    
    ; Look up struct type by name
    mov rdi, [tmp_ast_a]
    mov rsi, [tmp_ast_b]
    call semantic_find_struct
    test rax, rax
    jz .bad
    
    mov rbx, rax                    ; rbx = struct type ID
    
    ; Verify it's actually a struct type in the type table
    imul rax, TYPE_DESC_SIZE
    cmp byte [type_table + rax + TYPE_DESC_KIND], TYPE_KIND_STRUCT
    jne .bad
    
    ; Return the struct type ID, rejecting mismatched expected struct types.
    cmp qword [expected_expr_type], 0
    je .struct_lit_no_expected
    
    mov rax, [expected_expr_type]
    cmp rax, rbx
    jne .bad_struct_type
    jmp .done
    
.struct_lit_no_expected:
    mov rax, rbx
    jmp .done
.bad:
    mov rdi, src_path
    mov rsi, err_unsup_ast
    call print_diag
    xor rax, rax
.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

semantic_int_literal_fits_type:
    push rbx
    push r12
    push r13
    mov r12, rdi
    mov r13, rsi
    mov rdi, r12
    call ast_child
    mov rdi, rax
    call token_addr
    mov rbx, [rax + TOKEN_PAYLOAD]
    cmp r13, TYPE_I8
    je .signed8
    cmp r13, TYPE_I16
    je .signed16
    cmp r13, TYPE_I32
    je .signed32
    cmp r13, TYPE_I64
    je .signed64
    cmp r13, TYPE_ISIZE
    je .signed64
    cmp r13, TYPE_U8
    je .unsigned8
    cmp r13, TYPE_U16
    je .unsigned16
    cmp r13, TYPE_U32
    je .unsigned32
    mov rax, 1
    jmp .done
.signed8:
    cmp rbx, 127
    jbe .ok
    jmp .bad
.signed16:
    cmp rbx, 32767
    jbe .ok
    jmp .bad
.signed32:
    mov rax, 2147483647
    cmp rbx, rax
    jbe .ok
    jmp .bad
.signed64:
    mov rax, 0x7fffffffffffffff
    cmp rbx, rax
    jbe .ok
    jmp .bad
.unsigned8:
    cmp rbx, 255
    jbe .ok
    jmp .bad
.unsigned16:
    cmp rbx, 65535
    jbe .ok
    jmp .bad
.unsigned32:
    mov rax, 4294967295
    cmp rbx, rax
    jbe .ok
    jmp .bad
.ok:
    mov rax, 1
    jmp .done
.bad:
    xor rax, rax
.done:
    pop r13
    pop r12
    pop rbx
    ret

semantic_neg_int_literal_fits_type:
    push rbx
    push r12
    push r13
    mov r12, rdi
    mov r13, rsi
    mov rdi, r12
    call ast_child
    mov rdi, rax
    call token_addr
    mov rbx, [rax + TOKEN_PAYLOAD]
    cmp r13, TYPE_I8
    je .signed8
    cmp r13, TYPE_I16
    je .signed16
    cmp r13, TYPE_I32
    je .signed32
    cmp r13, TYPE_I64
    je .signed64
    cmp r13, TYPE_ISIZE
    je .signed64
    xor rax, rax
    jmp .done
.signed8:
    cmp rbx, 128
    jbe .ok
    jmp .bad
.signed16:
    cmp rbx, 32768
    jbe .ok
    jmp .bad
.signed32:
    mov rax, 2147483648
    cmp rbx, rax
    jbe .ok
    jmp .bad
.signed64:
    mov rax, 0x8000000000000000
    cmp rbx, rax
    jbe .ok
    jmp .bad
.ok:
    mov rax, 1
    jmp .done
.bad:
    xor rax, rax
.done:
    pop r13
    pop r12
    pop rbx
    ret

semantic_expr_is_zero_int_const:
    call semantic_expr_const_int_value
    test rax, rax
    jz .no
    test rdx, rdx
    jnz .no
    mov rax, 1
    ret
.no:
    xor rax, rax
    ret

semantic_expr_const_int_value:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    test r12, r12
    jz .no
    mov rdi, r12
    call ast_kind
    mov r13, rax
    cmp r13, AST_INT_LIT
    je .int_lit
    cmp r13, AST_UNARY_NEG
    je .unary_neg
    cmp r13, AST_BIN_ADD
    je .binary
    cmp r13, AST_BIN_SUB
    je .binary
    cmp r13, AST_BIN_MUL
    je .binary
    cmp r13, AST_BIN_DIV
    je .binary
    cmp r13, AST_BIN_MOD
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
    jmp .no
.int_lit:
    mov rdi, r12
    call ast_child
    mov rdi, rax
    call token_addr
    mov rdx, [rax + TOKEN_PAYLOAD]
    mov rax, 1
    jmp .done
.unary_neg:
    mov rdi, r12
    call ast_child
    mov rdi, rax
    call semantic_expr_const_int_value
    test rax, rax
    jz .no
    neg rdx
    mov rax, 1
    jmp .done
.binary:
    mov rdi, r12
    call ast_child
    mov rbx, rax
    test rbx, rbx
    jz .no
    mov rdi, rbx
    call ast_next
    mov r15, rax
    test r15, r15
    jz .no
    mov rdi, rbx
    call semantic_expr_const_int_value
    test rax, rax
    jz .no
    mov r14, rdx
    mov rdi, r15
    call semantic_expr_const_int_value
    test rax, rax
    jz .no
    mov r15, rdx
    cmp r13, AST_BIN_ADD
    je .fold_add
    cmp r13, AST_BIN_SUB
    je .fold_sub
    cmp r13, AST_BIN_MUL
    je .fold_mul
    cmp r13, AST_BIN_DIV
    je .fold_div
    cmp r13, AST_BIN_MOD
    je .fold_mod
    cmp r13, AST_BIN_XOR
    je .fold_xor
    cmp r13, AST_BIN_SHL
    je .fold_shl
    cmp r13, AST_BIN_SHR
    je .fold_shr
    cmp r13, AST_BIN_ROL
    je .fold_rol
    cmp r13, AST_BIN_ROR
    je .fold_ror
    cmp r13, AST_BIN_POW
    je .fold_pow
    jmp .no
.fold_add:
    mov rdx, r14
    add rdx, r15
    jmp .yes
.fold_sub:
    mov rdx, r14
    sub rdx, r15
    jmp .yes
.fold_mul:
    mov rdx, r14
    imul rdx, r15
    jmp .yes
.fold_div:
    test r15, r15
    jz .no
    mov rax, 0x8000000000000000
    cmp r14, rax
    jne .fold_div_safe
    cmp r15, -1
    je .no
.fold_div_safe:
    mov rax, r14
    cqo
    idiv r15
    mov rdx, rax
    jmp .yes
.fold_mod:
    test r15, r15
    jz .no
    mov rax, 0x8000000000000000
    cmp r14, rax
    jne .fold_mod_safe
    cmp r15, -1
    je .no
.fold_mod_safe:
    mov rax, r14
    cqo
    idiv r15
    jmp .yes
.fold_xor:
    mov rdx, r14
    xor rdx, r15
    jmp .yes
.fold_shl:
    mov rdx, r14
    mov rcx, r15
    shl rdx, cl
    jmp .yes
.fold_shr:
    mov rdx, r14
    mov rcx, r15
    shr rdx, cl
    jmp .yes
.fold_rol:
    mov rdx, r14
    mov rcx, r15
    rol rdx, cl
    jmp .yes
.fold_ror:
    mov rdx, r14
    mov rcx, r15
    ror rdx, cl
    jmp .yes
.fold_pow:
    mov rdx, 1
    mov rcx, r15
    cmp rcx, 0
    jle .yes
.fold_pow_loop:
    imul rdx, r14
    dec rcx
    jnz .fold_pow_loop
    jmp .yes
.yes:
    mov rax, 1
    jmp .done
.no:
    xor rax, rax
.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

semantic_type_is_signed_integer:
    cmp rdi, TYPE_I8
    je .yes
    cmp rdi, TYPE_I16
    je .yes
    cmp rdi, TYPE_I32
    je .yes
    cmp rdi, TYPE_I64
    je .yes
    cmp rdi, TYPE_ISIZE
    je .yes
    xor rax, rax
    ret
.yes:
    mov rax, 1
    ret
