; Status: PARTIAL.
; Type table and primitive expression compatibility for the foundation checker.

type_init:
    mov qword [type_count], TYPE_PRIMITIVE_COUNT
    mov rcx, 1
.loop:
    cmp rcx, TYPE_PRIMITIVE_COUNT
    jae .done
    mov rax, rcx
    imul rax, TYPE_DESC_SIZE
    mov byte [type_table + rax + TYPE_DESC_KIND], TYPE_KIND_PRIM
    mov byte [type_table + rax + TYPE_DESC_MUT], TYPE_MUT_CONST
    mov dword [type_table + rax + TYPE_DESC_INNER], ecx
    mov qword [type_table + rax + TYPE_DESC_SIZE_PARAM], 0
    inc rcx
    jmp .loop
.done:
    ret

type_check_binary:
    cmp rdx, AST_BIN_ADD
    je .arith
    cmp rdx, AST_BIN_SUB
    je .arith
    cmp rdx, AST_BIN_MUL
    je .arith
    cmp rdx, AST_BIN_DIV
    je .arith
    cmp rdx, AST_BIN_MOD
    je .arith
    xor rax, rax
    ret
.arith:
    cmp rdi, TYPE_I32
    jne .bad
    cmp rsi, TYPE_I32
    jne .bad
    mov rax, TYPE_I32
    ret
.bad:
    xor rax, rax
    ret

type_intern_ptr:
    push rbx
    push r12
    push r13
    mov r12, rdi
    mov r13, rsi
    mov rbx, [type_count]
    cmp rbx, TYPE_TBL_CAP
    jae .overflow
    mov rax, rbx
    imul rax, TYPE_DESC_SIZE
    mov byte [type_table + rax + TYPE_DESC_KIND], TYPE_KIND_PTR
    mov byte [type_table + rax + TYPE_DESC_MUT], r13b
    mov dword [type_table + rax + TYPE_DESC_INNER], r12d
    mov qword [type_table + rax + TYPE_DESC_SIZE_PARAM], 0
    mov rax, rbx
    inc qword [type_count]
    pop r13
    pop r12
    pop rbx
    ret
.overflow:
    xor rax, rax
    pop r13
    pop r12
    pop rbx
    ret
