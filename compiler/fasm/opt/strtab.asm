; opt/strtab.asm — Branchless and cache-friendly string table operations.
; Optimized string comparison for hot paths: keyword lookup, symbol find.

segment readable executable

; fast_streq_fixed: Compare exactly rdx bytes at rdi and rsi.
; Returns 1 if equal, 0 if not. Branchless on match for short strings.
; rdi = ptr_a, rsi = ptr_b, rdx = length.
fast_streq_fixed:
    test rdx, rdx
    jz .yes
    cmp rdx, 8
    jbe .short
    ; Long path: fall through to qword loop
    jmp fast_memcmp  ; reuse memcmp, then invert
.short:
    ; For <=8 bytes: load into registers and compare
    ; Zero-extend partial loads to avoid reading past buffer
    xor rax, rax
    xor rcx, rcx
.byte_loop:
    cmp rcx, rdx
    jae .compare
    movzx r8d, byte [rdi + rcx]
    shl r8, cl       ; shift not needed for cmp, use simple approach
    movzx r9d, byte [rsi + rcx]
    cmp r8b, r9b
    jne .no
    inc rcx
    jmp .byte_loop
.compare:
.yes:
    mov rax, 1
    ret
.no:
    xor rax, rax
    ret

; fast_token_text_eq: Compare token text against symbol table entry.
; rdi = token_index, rsi = sym_text_ptr, rdx = sym_len.
; Loads token text from src_buf and compares.
fast_token_text_eq:
    push rbx
    push r12
    push r13
    mov r12, rsi            ; sym_text_ptr
    mov r13, rdx            ; sym_len
    call token_addr
    mov rbx, rax            ; token struct addr
    mov rcx, [rbx + TOKEN_LEN]
    cmp rcx, r13
    jne .no                 ; lengths differ → not equal
    mov rdi, src_buf
    add rdi, [rbx + TOKEN_START]
    mov rsi, r12
    mov rdx, r13
    call fast_memcmp
    test rax, rax
    jnz .no
    mov rax, 1
    pop r13
    pop r12
    pop rbx
    ret
.no:
    xor rax, rax
    pop r13
    pop r12
    pop rbx
    ret
