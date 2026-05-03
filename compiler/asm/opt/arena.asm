; opt/arena.asm — Cache-optimized arena allocator for AST nodes.
; Bump allocator with alignment guarantees for optimal cache line usage.
; Zero-overhead: no free, no fragmentation, single pointer increment.

section .text

; arena_alloc: Allocate rdi bytes from the AST arena.
; Returns pointer in rax, or 0 on overflow.
; Aligns to 8 bytes for optimal qword access.
arena_alloc:
    ; Align size up to 8 bytes
    add rdi, 7
    and rdi, ~7
    mov rax, [arena_cursor]
    lea rcx, [rax + rdi]
    cmp rcx, arena_end
    ja .overflow
    mov [arena_cursor], rcx
    ret
.overflow:
    xor rax, rax
    ret

; arena_reset: Reset arena to beginning. Invalidates all pointers.
arena_reset:
    lea rax, [arena_buf]
    mov [arena_cursor], rax
    ret

; arena_used: Return number of bytes currently allocated.
arena_used:
    mov rax, [arena_cursor]
    sub rax, arena_buf
    ret

section .bss
alignb 64                            ; Align to cache line
arena_buf: resb 262144              ; 256KB arena
arena_end equ arena_buf + 262144
arena_cursor: resq 1
