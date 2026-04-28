; Status: PARTIAL.
; Zero-terminated string and path buffer primitives used by the ASM compiler.

strlen:
    xor rax, rax
.loop:
    cmp byte [rsi + rax], 0
    je .done
    inc rax
    jmp .loop
.done:
    ret

streq:
    xor rax, rax
.loop:
    mov bl, [rdi]
    cmp bl, [rsi]
    jne .no
    test bl, bl
    je .yes
    inc rdi
    inc rsi
    jmp .loop
.yes:
    mov rax, 1
.no:
    ret

contains:
    push rbx
    push r12
    push r13
    mov r12, rdi
    mov r13, rsi
    cmp rcx, 0
    je .not_found
    cmp r13, rcx
    jb .not_found
.outer:
    mov rbx, 0
.inner:
    cmp rbx, rcx
    je .found
    mov al, [r12 + rbx]
    cmp al, [rdx + rbx]
    jne .next
    inc rbx
    jmp .inner
.next:
    inc r12
    dec r13
    cmp r13, rcx
    jae .outer
.not_found:
    xor rax, rax
    pop r13
    pop r12
    pop rbx
    ret
.found:
    mov rax, r12
    pop r13
    pop r12
    pop rbx
    ret

copy_z:
    xor rax, rax
.loop:
    mov bl, [rsi + rax]
    mov [rdi + rax], bl
    inc rax
    test bl, bl
    jne .loop
    dec rax
    ret

append_z:
    push rdi
    push rsi
    mov rsi, rdi
    call strlen
    pop rsi
    pop rdi
    add rdi, rax
    call copy_z
    ret

make_path:
    push rsi
    push rdx
    mov rsi, rdi
    mov rdi, rdx
    call copy_z
    pop rdx
    pop rsi
    mov rdi, rdx
    call append_z
    ret
