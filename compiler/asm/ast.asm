; Status: COMPLETE for foundation v0 subset.
; Real AST arena with complete dump-ast node name dispatch.

ast_reset:
    mov byte [has_io_write], 0
    mov qword [parsed_str_len], 0
    mov qword [parsed_io_len], 0
    mov qword [parsed_ret_value], 0
    mov qword [ast_count], 0
    mov qword [ast_root], 0
    mov qword [ast_main_fn], 0
    mov qword [ast_main_node_idx], 0
    mov qword [ast_block_node], 0
    mov qword [ast_call_stmt], 0
    mov qword [ast_ret_stmt], 0
    mov qword [ast_error_flag], 0
    mov qword [loop_depth], 0
    mov byte [needs_print_int_helper], 0
    ret

ast_new:
    mov r10, [ast_count]
    cmp r10, AST_CAP
    jae .overflow
    inc r10
    mov [ast_count], r10
    mov r11, r10
    dec r11
    mov r9, r11
    imul r9, 8
    mov qword [ast_type_tag + r9], 0
    imul r11, AST_SIZE
    mov [ast_buf + r11 + AST_KIND], rdi
    mov [ast_buf + r11 + AST_SPAN_START], rsi
    mov [ast_buf + r11 + AST_SPAN_END], rdx
    mov [ast_buf + r11 + AST_CHILD_OR_DATA], rcx
    mov [ast_buf + r11 + AST_NEXT_OR_EXTRA], r8
    mov rax, r10
    ret
.overflow:
    mov rdi, src_path
    mov rsi, err_ast_overflow
    call print_diag
    mov qword [ast_error_flag], 1
    xor rax, rax
    ret

ast_set_type_tag:
    test rdi, rdi
    jz .done
    dec rdi
    imul rdi, 8
    mov [ast_type_tag + rdi], rsi
.done:
    ret

ast_get_type_tag:
    test rdi, rdi
    jz .none
    dec rdi
    imul rdi, 8
    mov rax, [ast_type_tag + rdi]
    ret
.none:
    xor rax, rax
    ret

ast_addr:
    mov rax, rdi
    dec rax
    imul rax, AST_SIZE
    add rax, ast_buf
    ret

ast_append_child:
    test rdi, rdi
    jz .done
    test rsi, rsi
    jz .done
    push rbx
    push r12
    mov r12, rsi
    call ast_addr
    mov rbx, [rax + AST_CHILD_OR_DATA]
    test rbx, rbx
    jz .first
.walk:
    mov rdi, rbx
    call ast_addr
    mov rbx, [rax + AST_NEXT_OR_EXTRA]
    test rbx, rbx
    jz .set_next
    jmp .walk
.set_next:
    mov [rax + AST_NEXT_OR_EXTRA], r12
    jmp .out
.first:
    mov [rax + AST_CHILD_OR_DATA], r12
.out:
    pop r12
    pop rbx
.done:
    ret

dump_ast:
    xor r12, r12
    inc r12
.loop:
    cmp r12, [ast_count]
    ja .done
    mov rdi, r12
    call ast_addr
    mov rdi, [rax + AST_KIND]
    call ast_name_ptr
    mov rdi, rax
    call print_stdout_z
    inc r12
    jmp .loop
.done:
    ret

ast_name_ptr:
    cmp rdi, AST_SOURCE_FILE
    je .source
    cmp rdi, AST_USE_DECL
    je .use
    cmp rdi, AST_FN_DECL
    je .fn
    cmp rdi, AST_BLOCK
    je .block
    cmp rdi, AST_RET_STMT
    je .ret
    cmp rdi, AST_CALL_STMT
    je .call
    cmp rdi, AST_INT_LIT
    je .int
    cmp rdi, AST_STR_LIT
    je .str
    cmp rdi, AST_IDENT
    je .ident
    cmp rdi, AST_PATH
    je .path
    cmp rdi, AST_ERROR
    je .err
    cmp rdi, AST_LET_STMT
    je .let
    cmp rdi, AST_MUT_STMT
    je .mut
    cmp rdi, AST_ASSIGN_STMT
    je .assign
    cmp rdi, AST_VAR_REF
    je .var
    cmp rdi, AST_BOOL_LIT
    je .bool
    cmp rdi, AST_BIN_ADD
    je .add
    cmp rdi, AST_BIN_SUB
    je .sub
    cmp rdi, AST_BIN_MUL
    je .mul
    cmp rdi, AST_BIN_DIV
    je .div
    cmp rdi, AST_BIN_MOD
    je .mod
    cmp rdi, AST_UNARY_NEG
    je .neg
    cmp rdi, AST_BIN_GT
    je .gt
    cmp rdi, AST_BIN_LT
    je .lt
    cmp rdi, AST_BIN_GE
    je .ge
    cmp rdi, AST_BIN_LE
    je .le
    cmp rdi, AST_BIN_EE
    je .ee
    cmp rdi, AST_BIN_NE
    je .ne
    cmp rdi, AST_BIN_AND
    je .and
    cmp rdi, AST_BIN_OR
    je .or
    cmp rdi, AST_UNARY_NOT
    je .not
    cmp rdi, AST_IF_STMT
    je .if
    cmp rdi, AST_WHILE_STMT
    je .while
    cmp rdi, AST_LOOP_STMT
    je .loop
    cmp rdi, AST_BREAK_STMT
    je .break
    cmp rdi, AST_CONTINUE_STMT
    je .continue
    cmp rdi, AST_FN_PARAM
    je .fn_param
    cmp rdi, AST_FN_CALL_EXPR
    je .fn_call
    cmp rdi, AST_UNSAFE_FN
    je .unsafe_fn
    cmp rdi, AST_UNSAFE_BLOCK
    je .unsafe_block
    mov rax, ast_name_unknown
    ret
.source:
    mov rax, ast_name_source
    ret
.use:
    mov rax, ast_name_use
    ret
.fn:
    mov rax, ast_name_fn
    ret
.block:
    mov rax, ast_name_block
    ret
.ret:
    mov rax, ast_name_ret
    ret
.call:
    mov rax, ast_name_call
    ret
.int:
    mov rax, ast_name_int
    ret
.str:
    mov rax, ast_name_str
    ret
.ident:
    mov rax, ast_name_ident
    ret
.path:
    mov rax, ast_name_path
    ret
.err:
    mov rax, ast_name_error
    ret
.let:
    mov rax, ast_name_let
    ret
.mut:
    mov rax, ast_name_mut
    ret
.assign:
    mov rax, ast_name_assign
    ret
.var:
    mov rax, ast_name_var
    ret
.bool:
    mov rax, ast_name_bool
    ret
.add:
    mov rax, ast_name_add
    ret
.sub:
    mov rax, ast_name_sub
    ret
.mul:
    mov rax, ast_name_mul
    ret
.div:
    mov rax, ast_name_div
    ret
.mod:
    mov rax, ast_name_mod
    ret
.neg:
    mov rax, ast_name_neg
    ret
.gt:
    mov rax, ast_name_gt
    ret
.lt:
    mov rax, ast_name_lt
    ret
.ge:
    mov rax, ast_name_ge
    ret
.le:
    mov rax, ast_name_le
    ret
.ee:
    mov rax, ast_name_ee
    ret
.ne:
    mov rax, ast_name_ne
    ret
.and:
    mov rax, ast_name_and
    ret
.or:
    mov rax, ast_name_or
    ret
.not:
    mov rax, ast_name_not
    ret
.if:
    mov rax, ast_name_if
    ret
.while:
    mov rax, ast_name_while
    ret
.loop:
    mov rax, ast_name_loop
    ret
.break:
    mov rax, ast_name_break
    ret
.continue:
    mov rax, ast_name_continue
    ret
.fn_param:
    mov rax, ast_name_fn_param
    ret
.fn_call:
    mov rax, ast_name_fn_call
    ret
.unsafe_fn:
    mov rax, ast_name_unsafe_fn
    ret
.unsafe_block:
    mov rax, ast_name_unsafe_block
    ret
