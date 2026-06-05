; Status: PARTIAL.
; Numeric and DB-string writers for FASM source generation.

write_u64_fd:
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
    jmp .write
.digits:
    xor rdx, rdx
    div rbx
    add dl, '0'
    dec rsi
    mov [rsi], dl
    test rax, rax
    jne .digits
.write:
    mov rdi, r8
    push rsi
    call strlen
    mov rdx, rax
    pop rsi
    mov rax, SYS_WRITE
    syscall
    pop r8
    pop rdx
    pop rcx
    pop rbx
    ret

write_db_string:
    push rbx
    push r12
    push r13
    push r14
    mov r12, rdi
    mov r13, [parsed_str_len]
    mov r14, [tmp_payload]
    xor rbx, rbx
    cmp r13, 0
    jne .loop
    mov rdi, r12
    xor rax, rax
    call write_u64_fd
    jmp .done
.loop:
    cmp rbx, 0
    je .num
    mov rdi, r12
    mov rsi, comma_space
    mov rdx, 2
    call write_all
.num:
    movzx rax, byte [str_buf + r14 + rbx]
    mov rdi, r12
    call write_u64_fd
    inc rbx
    cmp rbx, r13
    jb .loop
    ; Add null terminator after string bytes
    mov rdi, r12
    mov rsi, comma_space
    mov rdx, 2
    call write_all
    mov rdi, r12
    xor rax, rax
    call write_u64_fd
.done:
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; write_raw_string: rdi = fd, rsi = str_buf offset, rdx = byte length.
write_raw_string:
    add rsi, str_buf
    mov rax, SYS_WRITE
    syscall
    ret

; write_function_name: Write function name from source pointer
; Input: rdi = file descriptor, rsi = name pointer
; Writes until whitespace or null terminator
write_function_name:
    push r11
    push r12
    push rcx
    mov r11, rdi        ; r11 = file descriptor
    mov r12, rsi        ; r12 = name pointer
    mov rcx, 0          ; rcx = count
.count:
    mov al, [r12 + rcx]
    cmp al, ' '
    je .write_it
    cmp al, 9           ; tab
    je .write_it
    cmp al, 10          ; newline
    je .write_it
    cmp al, 0
    je .write_it
    inc rcx
    cmp rcx, 255
    jl .count
.write_it:
    mov rdi, r11        ; rdi = file descriptor
    mov rsi, r12        ; rsi = name pointer
    mov rdx, rcx        ; rdx = length
    mov rax, SYS_WRITE
    syscall
    pop rcx
    pop r12
    pop r11
    ret

write_src_span:
    push rdi
    push rsi
    push rdx
    add rsi, src_buf
    mov rax, SYS_WRITE
    syscall
    pop rdx
    pop rsi
    pop rdi
    ret
