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
    jmp .bad
.i32:
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
    cmp rax, TYPE_I32
    jne .bad_type_current
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
    cmp rsi, TYPE_I32
    jne .bad_type_current
    jmp .bool_result
.check_bool_op2:
    cmp rsi, TYPE_BOOL
    jne .bad_type_current
.bool_result:
    mov rax, TYPE_BOOL
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
