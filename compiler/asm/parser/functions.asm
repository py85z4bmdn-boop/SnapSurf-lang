; parser/functions.asm — Function declaration and parameter parsing.
; Handles: fn name [params] -> return_type, parameter lists.
; Status: NEW for multi-function support.

; parse_function: Parse a single function declaration.
; Expects: Current token is TOK_FN
; Returns: rax = 0 on success, 1 on error
; Preserves: r12-r15
parse_function:
    push rbx
    push r12
    push r13
    push r14
    push r15
    
    call skip_newline_tokens
    call current_token_kind
    cmp rax, TOK_FN
    jne .no_fn
    
    ; Capture function name start position
    call current_token_addr
    mov r12, [rax + TOKEN_START]
    mov r15, [rax + TOKEN_LINE]
    call advance_token
    
    ; Check if current token is an identifier (function name)
    call current_token_kind
    cmp rax, TOK_IDENT
    jne .bad_fn_name
    
    ; Store function name for later
    mov r13, [token_index]
    call advance_token
    
    ; Now we should have either:
    ; - TOK_ARROW -> i32 (no parameters, main-like signature)
    ; - TOK_IDENT or TOK_LPAREN -> parameter list
    
    xor r14, r14  ; Initialize parameter count
    
    call current_token_kind
    cmp rax, TOK_LPAREN
    je .with_parens
    
    ; Check if it's a parameter without parens (like: add a i32 b i32 -> i32)
    cmp rax, TOK_IDENT
    je .with_params
    
    cmp rax, TOK_ARROW
    je .no_params
    
    jmp .bad_fn_sig

.with_parens:
    ; TODO: Implement parenthesized parameter lists: fn foo(a i32, b i32) -> i32
    call advance_token
    call parse_param_list_paren
    test rax, rax
    jnz .fail
    jmp .after_params

.with_params:
    ; Parse space-separated parameters: add a i32 b i32 -> i32
    call parse_param_list_bare
    test rax, rax
    jnz .fail
    ; r14 now contains param count
    jmp .after_params

.no_params:
    xor r14, r14  ; 0 parameters
    jmp .after_params

.after_params:
    call current_token_kind
    cmp rax, TOK_ARROW
    jne .bad_fn_sig
    call advance_token
    
    ; Expect return type identifier (i32, bool, etc.)
    call current_token_kind
    cmp rax, TOK_IDENT
    jne .bad_return_type
    
    ; For now, we only allow i32 as return type
    call expect_ident_text_i32
    test rax, rax
    ; TODO: Allow other return types in future
    ; For now, just skip the check and advance
    call current_token_addr
    mov r13, [rax + TOKEN_START]
    add r13, [rax + TOKEN_LEN]
    call advance_token
    
    ; Create FnDecl AST node
    mov rdi, AST_FN_DECL
    mov rsi, r12
    mov rdx, r13
    xor rcx, rcx
    xor r8, r8
    call ast_new
    test rax, rax
    jz .ast_overflow
    mov rbx, rax
    
    ; Add to source file
    mov rdi, [ast_root]
    mov rsi, rbx
    call ast_append_child
    
    ; Create block node for function body
    mov rdi, AST_BLOCK
    mov rsi, r13
    mov rdx, r13
    xor rcx, rcx
    xor r8, r8
    call ast_new
    test rax, rax
    jz .ast_overflow
    
    ; Add block to function declaration
    mov rdi, rbx
    mov rsi, rax
    call ast_append_child
    mov [ast_block_node], rax
    mov [ast_main_fn], rbx
    
    ; Parse function body (block of statements)
    call parse_block
    test rax, rax
    jnz .fail
    
    xor rax, rax
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

.no_fn:
    mov rax, 1
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.bad_fn_name:
    call set_diag_from_current
    mov rdi, src_path
    mov rsi, err_bad_fn_name
    call print_diag
    mov rax, 1
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.bad_fn_sig:
    call set_diag_from_current
    mov rdi, src_path
    mov rsi, err_bad_fn_sig
    call print_diag
    mov rax, 1
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.bad_return_type:
    call set_diag_from_current
    mov rdi, src_path
    mov rsi, err_bad_return_type
    call print_diag
    mov rax, 1
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.ast_overflow:
    mov rdi, src_path
    mov rsi, err_ast_overflow
    call print_diag
    mov rax, 1
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.fail:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; parse_param_list_bare: Parse parameters without parentheses
; Input: r14 = parameter count accumulator
; Output: r14 = final parameter count, rax = 0 on success
parse_param_list_bare:
    push rbx
    push r12
    
    xor r12, r12  ; Local param count
    
.loop:
    call current_token_kind
    cmp rax, TOK_ARROW
    je .done
    cmp rax, TOK_EOF
    je .missing_arrow
    
    ; Expect identifier (parameter name)
    cmp rax, TOK_IDENT
    jne .bad_param
    call advance_token
    
    ; Expect identifier (parameter type)
    call current_token_kind
    cmp rax, TOK_IDENT
    jne .bad_param_type
    call advance_token
    
    inc r12
    jmp .loop

.done:
    mov r14, r12
    xor rax, rax
    pop r12
    pop rbx
    ret
.missing_arrow:
    call set_diag_from_current
    mov rdi, src_path
    mov rsi, err_missing_arrow
    call print_diag
    mov rax, 1
    pop r12
    pop rbx
    ret
.bad_param:
    call set_diag_from_current
    mov rdi, src_path
    mov rsi, err_bad_param_name
    call print_diag
    mov rax, 1
    pop r12
    pop rbx
    ret
.bad_param_type:
    call set_diag_from_current
    mov rdi, src_path
    mov rsi, err_bad_param_type
    call print_diag
    mov rax, 1
    pop r12
    pop rbx
    ret

; parse_param_list_paren: Parse parameters with parentheses and commas
; Currently not implemented (returns success for compatibility)
parse_param_list_paren:
    ; TODO: Implement (a i32, b i32) style parameter parsing
    xor rax, rax
    ret
