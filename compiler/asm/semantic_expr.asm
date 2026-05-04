; Status: PARTIAL.
; Expression type checking for the foundation AST.

semantic_expr_type:
    push rbx
    push r12
    push r13
    push r14
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
    je .unary_i32
    cmp r13, AST_UNARY_NOT
    je .unary_bool
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
    je .binary_bool
    cmp r13, AST_BIN_OR
    je .binary_bool
    cmp r13, AST_ADDR_OF
    je .addr_of
    cmp r13, AST_DEREF
    je .deref
    cmp r13, AST_ARRAY_INDEX
    je .array_index
    cmp r13, AST_FIELD_ACCESS
    je .field_access
    jmp .bad
.i32:
    cmp qword [expected_expr_type], 0
    je .i32_default
    mov rdi, [expected_expr_type]
    call type_is_integer
    test rax, rax
    jz .i32_default
    mov rax, [expected_expr_type]
    jmp .done
.i32_default:
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
.unary_i32:
    mov rdi, r12
    call ast_child
    mov rdi, rax
    test rdi, rdi
    jz .bad
    call semantic_expr_type
    cmp rax, TYPE_I32
    jne .bad_type_current
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
    call semantic_expr_type
    mov rsi, rax
    cmp r13, AST_BIN_AND
    je .check_bool_op2
    cmp r13, AST_BIN_OR
    je .check_bool_op2
    mov rdi, rsi
    call type_is_integer
    test rax, rax
    jz .bad_type_current
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
