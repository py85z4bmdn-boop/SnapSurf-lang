; Status: PARTIAL.
; Single-function lexical scope stack for fixed-capacity symbol storage.

scope_push:
    mov rax, [scope_depth]
    cmp rax, SCOPE_CAP
    jae .overflow
    mov rdx, rax
    imul rdx, 8
    mov rcx, [sym_count]
    mov [scope_sym_base + rdx], rcx
    mov rcx, [slot_cursor]
    mov [scope_slot_base + rdx], rcx
    inc qword [scope_depth]
    xor rax, rax
    ret
.overflow:
    mov rdi, src_path
    mov rsi, err_scope_overflow
    call print_diag
    mov rax, 1
    ret

scope_pop:
    mov rax, [scope_depth]
    test rax, rax
    jz .done
    dec rax
    mov [scope_depth], rax
    imul rax, 8
    mov rcx, [scope_sym_base + rax]
    mov [sym_count], rcx
    mov rcx, [scope_slot_base + rax]
    mov [slot_cursor], rcx
.done:
    xor rax, rax
    ret
