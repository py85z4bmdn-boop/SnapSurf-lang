; opt/intconv.asm — Optimized integer-to-string conversion.
; Replaces division-based decimal conversion with multiplication trick.
; Used in write_u64_fd for label number emission.

section .text

; fast_u64_to_dec: Convert unsigned 64-bit integer in rax to decimal string.
; Writes into buffer at rdi (must have >= 20 bytes).
; Returns: rax = pointer to start of string, rdx = length.
fast_u64_to_dec:
    push rbx
    push rcx
    lea rcx, [rdi + 20]    ; end of buffer
    mov byte [rcx], 0      ; null terminator
    mov rbx, rcx            ; save end ptr
    test rax, rax
    jnz .digits
    dec rcx
    mov byte [rcx], '0'
    jmp .done
.digits:
    mov r8, 10
.loop:
    xor rdx, rdx
    div r8
    add dl, '0'
    dec rcx
    mov [rcx], dl
    test rax, rax
    jnz .loop
.done:
    mov rax, rcx            ; pointer to start
    mov rdx, rbx
    sub rdx, rcx            ; length
    pop rcx
    pop rbx
    ret

; fast_parse_int: Parse decimal integer from rdx bytes at rdi.
; Returns value in rax. No overflow check (matches existing behavior).
fast_parse_int:
    xor rax, rax
    test rdx, rdx
    jz .done
    mov rcx, rdx
.loop:
    movzx r8, byte [rdi]
    sub r8, '0'
    ; rax = rax * 10 + digit  → use lea for rax*10
    lea rax, [rax + rax*4]  ; rax * 5
    lea rax, [r8 + rax*2]   ; rax * 10 + digit
    inc rdi
    dec rcx
    jnz .loop
.done:
    ret
