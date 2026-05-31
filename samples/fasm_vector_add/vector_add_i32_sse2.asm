format ELF64

public snapsurf_vec_add_i32_sse2

section '.text' executable align 16
snapsurf_vec_add_i32_sse2:
    ; SysV AMD64: rdi=dst, rsi=a, rdx=b, rcx=len.
    ; Clobbers caller-saved rax/r8/r9 and xmm0/xmm1. No stack use.
    xor     r8, r8
    cmp     rcx, 4
    jb      .tail

.vector_loop:
    movdqu  xmm0, [rsi + r8*4]
    movdqu  xmm1, [rdx + r8*4]
    paddd   xmm0, xmm1
    movdqu  [rdi + r8*4], xmm0

    add     r8, 4
    mov     r9, rcx
    sub     r9, r8
    cmp     r9, 4
    jae     .vector_loop

.tail:
    cmp     r8, rcx
    jae     .done

.tail_loop:
    mov     eax, [rsi + r8*4]
    add     eax, [rdx + r8*4]
    mov     [rdi + r8*4], eax
    inc     r8
    cmp     r8, rcx
    jb      .tail_loop

.done:
    ret
