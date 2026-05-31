; Status: PARTIAL.
; Semantic diagnostic span helpers over tokens and AST nodes.

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
    call ast_kind
    mov rbx, rax
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
    mov rdi, r12
    call ast_child
    mov rdi, rax
    test rdi, rdi
    jz .done
    call set_diag_from_expr_node
    jmp .done
.token_child:
    mov rdi, r12
    call ast_child
    mov rdi, rax
    call set_diag_from_token
    jmp .done
.span_start:
    mov rdi, r12
    call ast_span_start
    mov rdi, rax
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
