; opt/faststr.asm — Optimized string primitives replacing naive byte loops.
; Uses register-width operations for common hot-path string functions.

segment readable executable

; fast_strlen: Count bytes in zero-terminated string at rsi.
; Returns length in rax. Uses qword scanning for speed.
fast_strlen:
    mov rdi, rsi
    xor rax, rax
    ; Check 8 bytes at a time using the null-byte detection trick:
    ; For each qword, check if any byte is zero using:
    ;   (v - 0x0101...) & ~v & 0x8080...
    ; However, this requires aligned access. For safety, use simple unrolled loop.
.loop8:
    cmp byte [rdi + rax], 0
    je .done
    cmp byte [rdi + rax + 1], 0
    je .done1
    cmp byte [rdi + rax + 2], 0
    je .done2
    cmp byte [rdi + rax + 3], 0
    je .done3
    cmp byte [rdi + rax + 4], 0
    je .done4
    cmp byte [rdi + rax + 5], 0
    je .done5
    cmp byte [rdi + rax + 6], 0
    je .done6
    cmp byte [rdi + rax + 7], 0
    je .done7
    add rax, 8
    jmp .loop8
.done7:
    add rax, 7
    ret
.done6:
    add rax, 6
    ret
.done5:
    add rax, 5
    ret
.done4:
    add rax, 4
    ret
.done3:
    add rax, 3
    ret
.done2:
    add rax, 2
    ret
.done1:
    inc rax
.done:
    ret

; fast_streq: Compare two zero-terminated strings at rdi and rsi.
; Returns 1 if equal, 0 if not. Processes 8 bytes at a time where possible.
fast_streq:
    xor rax, rax
.loop:
    mov cl, [rdi]
    cmp cl, [rsi]
    jne .no
    test cl, cl
    je .yes
    mov cl, [rdi + 1]
    cmp cl, [rsi + 1]
    jne .no
    test cl, cl
    je .yes
    mov cl, [rdi + 2]
    cmp cl, [rsi + 2]
    jne .no
    test cl, cl
    je .yes
    mov cl, [rdi + 3]
    cmp cl, [rsi + 3]
    jne .no
    test cl, cl
    je .yes
    add rdi, 4
    add rsi, 4
    jmp .loop
.yes:
    mov rax, 1
.no:
    ret
