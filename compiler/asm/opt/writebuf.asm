; opt/writebuf.asm — Buffered output writer for NASM code generation.
; Instead of issuing a syscall per write_all, accumulate output into a
; buffer and flush once. Reduces syscall overhead by ~10-50x for emitter.

section .bss
write_buf: resb 65536       ; 64KB output buffer
write_buf_pos: resq 1       ; current write position

section .text

; writebuf_init: Reset buffer position. Call before emission starts.
writebuf_init:
    mov qword [write_buf_pos], 0
    ret

; writebuf_flush: Write entire buffer to fd in rdi, then reset.
writebuf_flush:
    push rbx
    mov rbx, rdi
    mov rdx, [write_buf_pos]
    test rdx, rdx
    jz .done
    mov rsi, write_buf
    mov rdi, rbx
    mov rax, SYS_WRITE
    syscall
    mov qword [write_buf_pos], 0
.done:
    pop rbx
    ret

; writebuf_append: Append rdx bytes from rsi to buffer.
; If buffer would overflow, flush first. rdi = fd (for auto-flush).
writebuf_append:
    push rbx
    push r12
    push r13
    mov rbx, rdi            ; fd
    mov r12, rsi            ; src ptr
    mov r13, rdx            ; src len
    mov rax, [write_buf_pos]
    add rax, r13
    cmp rax, 65536
    jbe .no_flush
    ; Flush current buffer first
    mov rdi, rbx
    call writebuf_flush
.no_flush:
    ; Copy r13 bytes from r12 into write_buf at pos
    mov rdi, write_buf
    add rdi, [write_buf_pos]
    mov rsi, r12
    mov rdx, r13
    ; Inline copy for small sizes
    mov rcx, r13
    shr rcx, 3
    test rcx, rcx
    jz .tail
.qword:
    mov rax, [rsi]
    mov [rdi], rax
    add rsi, 8
    add rdi, 8
    dec rcx
    jnz .qword
.tail:
    mov rcx, r13
    and rcx, 7
    test rcx, rcx
    jz .update
.byte:
    mov al, [rsi]
    mov [rdi], al
    inc rsi
    inc rdi
    dec rcx
    jnz .byte
.update:
    add [write_buf_pos], r13
    pop r13
    pop r12
    pop rbx
    ret

; writebuf_byte: Append a single byte (in sil) to buffer.
writebuf_byte:
    mov rax, [write_buf_pos]
    cmp rax, 65536
    jb .store
    push rsi
    call writebuf_flush
    pop rsi
    xor rax, rax
.store:
    mov [write_buf + rax], sil
    inc qword [write_buf_pos]
    ret

; writebuf_u64: Write decimal representation of rax to buffer.
; rdi = fd (for auto-flush).
writebuf_u64:
    push rbx
    push rcx
    push rdx
    push r8
    mov r8, rdi
    mov rbx, 10
    lea rsi, [num_buf + 31]
    mov byte [rsi], 0
    cmp rax, 0
    jne .digits
    dec rsi
    mov byte [rsi], '0'
    jmp .write_it
.digits:
    xor rdx, rdx
    div rbx
    add dl, '0'
    dec rsi
    mov [rsi], dl
    test rax, rax
    jne .digits
.write_it:
    ; Calculate length
    lea rdx, [num_buf + 31]
    sub rdx, rsi
    mov rdi, r8
    mov r12, rsi
    call writebuf_append
    pop r8
    pop rdx
    pop rcx
    pop rbx
    ret
