; Status: PARTIAL.
; AST traversal/accessor API for passes that should not duplicate arena offsets.

ast_kind:
    call ast_addr
    mov rax, [rax + AST_KIND]
    ret

ast_child:
    call ast_addr
    mov rax, [rax + AST_CHILD_OR_DATA]
    ret

ast_next:
    call ast_addr
    mov rax, [rax + AST_NEXT_OR_EXTRA]
    ret

ast_span_start:
    call ast_addr
    mov rax, [rax + AST_SPAN_START]
    ret

ast_span_end:
    call ast_addr
    mov rax, [rax + AST_SPAN_END]
    ret

ast_child_at:
    push rbx
    push r12
    mov r12, rsi
    call ast_child
    mov rbx, rax
.loop:
    test rbx, rbx
    jz .done
    test r12, r12
    jz .done
    mov rdi, rbx
    call ast_next
    mov rbx, rax
    dec r12
    jmp .loop
.done:
    mov rax, rbx
    pop r12
    pop rbx
    ret
