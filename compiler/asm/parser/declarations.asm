; parser/declarations.asm — Declaration and assignment statement parsers.
; Handles: let, mut, assignment.

parse_decl_stmt:
    call current_token_addr
    mov r12, [rax + TOKEN_START]
    call current_token_kind
    cmp rax, TOK_MUT
    je .mut_head
    mov r15, AST_LET_STMT
    call advance_token
    jmp .name
.mut_head:
    mov r15, AST_MUT_STMT
    call advance_token
.name:
    call parse_ident_node
    test rax, rax
    jz .bad
    mov [tmp_ast_a], rax

    call parse_any_type
    test rax, rax
    jz .bad
    mov [tmp_type_id], rax
    call advance_token
    call current_token_kind
    cmp rax, TOK_EQ
    jne .bad
    call advance_token

    xor rdi, rdi
    call parse_expr_min
    test rax, rax
    jz .fail
    mov [tmp_ast_b], rax

    mov rdi, r15
    mov rsi, r12
    mov rdx, r12
    xor rcx, rcx
    xor r8, r8
    call ast_new
    mov r14, rax
    mov rdi, r14
    mov rsi, [tmp_ast_a]
    call ast_append_child
    mov rdi, r14
    mov rsi, [tmp_ast_b]
    call ast_append_child
    mov rdi, [ast_block_node]
    mov rsi, r14
    call ast_append_child
    xor rax, rax
    ret
.bad:
    call print_unsupported_current
.fail:
    mov rax, 1
    ret

parse_assign_stmt:
    call current_token_addr
    mov r12, [rax + TOKEN_START]
    call parse_ident_node
    test rax, rax
    jz .bad
    mov [tmp_ast_a], rax
    call current_token_kind
    cmp rax, TOK_EQ
    jne .bad
    call advance_token

    xor rdi, rdi
    call parse_expr_min
    test rax, rax
    jz .fail
    mov [tmp_ast_b], rax

    mov rdi, AST_ASSIGN_STMT
    mov rsi, r12
    mov rdx, r12
    xor rcx, rcx
    xor r8, r8
    call ast_new
    mov r14, rax
    mov rdi, r14
    mov rsi, [tmp_ast_a]
    call ast_append_child
    mov rdi, r14
    mov rsi, [tmp_ast_b]
    call ast_append_child
    mov rdi, [ast_block_node]
    mov rsi, r14
    call ast_append_child
    xor rax, rax
    ret
.bad:
    call print_unsupported_current
.fail:
    mov rax, 1
    ret
