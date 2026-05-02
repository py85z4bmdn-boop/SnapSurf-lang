; opt/dead_code_elimination.asm
; Status: NEW
; Dead Code Elimination - removes statements unreachable after return

; dce_analyze_block: Analyze a block and mark unreachable statements
; Input: rdi = block AST node
; Output: rax = number of unreachable statements found
; This function walks through statements and stops processing after a return
dce_analyze_block:
    push rbx
    push r12
    push r13
    
    mov r12, rdi        ; r12 = block node
    xor r13, r13        ; r13 = unreachable count
    
    mov rdi, r12
    call ast_child
    mov rbx, rax
    
.loop:
    test rbx, rbx
    jz .done
    
    mov rdi, rbx
    call ast_kind
    
    ; Check if this statement is a return
    cmp rax, AST_RET_STMT
    je .found_return
    cmp rax, AST_BREAK_STMT
    je .found_break
    cmp rax, AST_CONTINUE_STMT
    je .found_continue
    
    ; Continue to next statement
    mov rdi, rbx
    call ast_next
    mov rbx, rax
    jmp .loop

.found_return:
    ; This is a return - mark all following statements as unreachable
    mov rdi, rbx
    call ast_next
    mov rbx, rax
    
    ; Count and skip all remaining statements
.count_unreachable:
    test rbx, rbx
    jz .done
    inc r13
    mov rdi, rbx
    call ast_next
    mov rbx, rax
    jmp .count_unreachable

.found_break:
.found_continue:
    ; Break/continue can also end execution in certain contexts
    ; For now, treat like return (conservative approach)
    mov rdi, rbx
    call ast_next
    mov rbx, rax
    jmp .count_unreachable

.done:
    mov rax, r13
    pop r13
    pop r12
    pop rbx
    ret

; dce_block_has_unreachable: Quick check if block has unreachable code
; Input: rdi = block AST node
; Output: rax = 1 if has unreachable, 0 otherwise
dce_block_has_unreachable:
    push rdi
    call dce_analyze_block
    cmp rax, 0
    jne .has
    xor rax, rax
    pop rdi
    ret
.has:
    mov rax, 1
    pop rdi
    ret

; dce_optimization_pass: Run dead code elimination on entire AST
; Input: none (uses [ast_root])
; Output: rax = number of unreachable statements found
dce_optimization_pass:
    push rbx
    mov rdi, [ast_root]
    call ast_child
    mov rbx, rax
    xor r8, r8          ; r8 = total unreachable count
    
.fn_loop:
    test rbx, rbx
    jz .done
    
    mov rdi, rbx
    call ast_kind
    cmp rax, AST_FN_DECL
    jne .next
    
    ; Get function block
    mov rdi, rbx
    call semantic_fn_block
    test rax, rax
    jz .next
    
    mov rdi, rax
    call dce_analyze_block
    add r8, rax
    
.next:
    mov rdi, rbx
    call ast_next
    mov rbx, rax
    jmp .fn_loop
    
.done:
    mov rax, r8
    pop rbx
    ret
