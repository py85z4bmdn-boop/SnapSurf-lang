; opt/memops.asm — Cache-optimized memory operations using pure x86_64.
; These replace naive byte-by-byte loops with register-width operations.
; All functions follow System V AMD64 ABI: rdi, rsi, rdx as args.

section .text

; fast_memcpy: Copy rdx bytes from rsi to rdi.
; Uses 8-byte moves for bulk, then byte-by-byte for remainder.
; Preserves: rbx, r12-r15.
fast_memcpy:
    mov rcx, rdx
    shr rcx, 3           ; rcx = count / 8
    test rcx, rcx
    jz .tail
.qword_loop:
    mov rax, [rsi]
    mov [rdi], rax
    add rsi, 8
    add rdi, 8
    dec rcx
    jnz .qword_loop
.tail:
    mov rcx, rdx
    and rcx, 7           ; remainder
    test rcx, rcx
    jz .done
.byte_loop:
    mov al, [rsi]
    mov [rdi], al
    inc rsi
    inc rdi
    dec rcx
    jnz .byte_loop
.done:
    ret

; fast_memset: Set rdx bytes at rdi to value sil.
; Uses 8-byte stores for bulk, then byte-by-byte for remainder.
fast_memset:
    movzx rax, sil
    ; Broadcast byte to all 8 bytes of rax: 0x0101010101010101 * al
    mov rcx, 0x0101010101010101
    imul rax, rcx
    mov rcx, rdx
    shr rcx, 3
    test rcx, rcx
    jz .tail
.qword_loop:
    mov [rdi], rax
    add rdi, 8
    dec rcx
    jnz .qword_loop
.tail:
    mov rcx, rdx
    and rcx, 7
    test rcx, rcx
    jz .done
.byte_loop:
    mov [rdi], sil
    inc rdi
    dec rcx
    jnz .byte_loop
.done:
    ret

; fast_memcmp: Compare rdx bytes at rdi and rsi.
; Returns 0 if equal, 1 if different.
; Uses 8-byte compares for bulk.
fast_memcmp:
    mov rcx, rdx
    shr rcx, 3
    test rcx, rcx
    jz .tail
.qword_loop:
    mov rax, [rdi]
    cmp rax, [rsi]
    jne .diff
    add rdi, 8
    add rsi, 8
    dec rcx
    jnz .qword_loop
.tail:
    mov rcx, rdx
    and rcx, 7
    test rcx, rcx
    jz .equal
.byte_loop:
    mov al, [rdi]
    cmp al, [rsi]
    jne .diff
    inc rdi
    inc rsi
    dec rcx
    jnz .byte_loop
.equal:
    xor rax, rax
    ret
.diff:
    mov rax, 1
    ret
