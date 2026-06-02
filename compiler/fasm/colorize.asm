; colorize.asm — ANSI syntax coloring for SnapSurf source files.
; Walks the token buffer and emits ANSI escape sequences around each token
; to produce syntax-highlighted output on the terminal.
;
; KEY DESIGN: For each token, we compute the actual source-level end position
; by looking at the next token's start. This avoids issues with tokens like
; strings where TOKEN_LEN is the decoded content length, not source span.

colorize_source:
    push rbx
    push r12
    push r13
    push r14
    push r15

    xor r12, r12            ; r12 = current token index
    xor r14, r14            ; r14 = last source offset emitted

.token_loop:
    cmp r12, [token_count]
    jae .done

    ; Get token address
    mov rdi, r12
    call token_addr
    mov rbx, rax            ; rbx = token address

    ; Get token fields
    mov r13, [rbx + TOKEN_TYPE]     ; token type
    mov r15, [rbx + TOKEN_START]    ; start offset in source

    ; Emit any gap between last emitted and current token start (whitespace)
    cmp r15, r14
    jbe .no_gap
    mov rdi, 1              ; stdout
    lea rsi, [src_buf + r14]
    mov rdx, r15
    sub rdx, r14
    mov rax, SYS_WRITE
    syscall
.no_gap:

    ; Skip newline tokens — they are included in the gap whitespace
    cmp r13, TOK_NEWLINE
    je .advance_newline
    cmp r13, TOK_EOF
    je .done

    ; Calculate actual source-level token length
    ; For strings, scan to find closing quote instead of using TOKEN_LEN
    cmp r13, TOK_STRING
    je .calc_string_span
    ; For all other tokens, TOKEN_LEN is the correct source span
    mov rax, [rbx + TOKEN_LEN]
    mov [color_src_span], rax
    jmp .dispatch_color

.calc_string_span:
    ; String tokens: TOKEN_START points to opening '"'
    ; We need to scan forward to find the closing '"' (handling escapes)
    push rbx
    mov rcx, r15
    inc rcx                 ; skip opening '"'
.string_scan:
    cmp rcx, [src_len]
    jae .string_scan_done
    cmp byte [src_buf + rcx], '"'
    je .string_scan_found
    cmp byte [src_buf + rcx], 92    ; backslash
    jne .string_scan_next
    inc rcx                 ; skip escaped char
.string_scan_next:
    inc rcx
    jmp .string_scan
.string_scan_found:
    inc rcx                 ; include closing '"'
.string_scan_done:
    mov rax, rcx
    sub rax, r15
    mov [color_src_span], rax
    pop rbx
    jmp .dispatch_color

.dispatch_color:
    ; Select color based on token type
    cmp r13, TOK_FN
    je .color_keyword
    cmp r13, TOK_RET
    je .color_keyword
    cmp r13, TOK_LET
    je .color_keyword
    cmp r13, TOK_MUT
    je .color_keyword
    cmp r13, TOK_IF
    je .color_keyword
    cmp r13, TOK_ELIF
    je .color_keyword
    cmp r13, TOK_ELSE
    je .color_keyword
    cmp r13, TOK_WHILE
    je .color_keyword
    cmp r13, TOK_LOOP
    je .color_keyword
    cmp r13, TOK_BREAK
    je .color_keyword
    cmp r13, TOK_CONTINUE
    je .color_keyword
    cmp r13, TOK_END
    je .color_keyword
    cmp r13, TOK_USE
    je .color_keyword
    cmp r13, TOK_UNSAFE
    je .color_keyword
    cmp r13, TOK_AND
    je .color_keyword
    cmp r13, TOK_OR
    je .color_keyword
    cmp r13, TOK_XOR
    je .color_keyword
    cmp r13, TOK_SHL
    je .color_keyword
    cmp r13, TOK_SHR
    je .color_keyword
    cmp r13, TOK_ROL
    je .color_keyword
    cmp r13, TOK_ROR
    je .color_keyword
    cmp r13, TOK_POW
    je .color_keyword
    cmp r13, TOK_NOT
    je .color_keyword
    cmp r13, TOK_CALL
    je .color_keyword
    cmp r13, TOK_CONST
    je .color_keyword
    cmp r13, TOK_PRINT
    je .color_keyword
    cmp r13, TOK_EPRINT
    je .color_keyword

    cmp r13, TOK_TRUE
    je .color_bool
    cmp r13, TOK_FALSE
    je .color_bool

    cmp r13, TOK_INT
    je .color_int
    cmp r13, TOK_STRING
    je .color_string

    cmp r13, TOK_ARROW
    je .color_operator
    cmp r13, TOK_PLUS
    je .color_operator
    cmp r13, TOK_MINUS
    je .color_operator
    cmp r13, TOK_STAR
    je .color_operator
    cmp r13, TOK_SLASH
    je .color_operator
    cmp r13, TOK_PERCENT
    je .color_operator
    cmp r13, TOK_EQ
    je .color_operator
    cmp r13, TOK_EE
    je .color_operator
    cmp r13, TOK_NE
    je .color_operator
    cmp r13, TOK_GT
    je .color_operator
    cmp r13, TOK_LT
    je .color_operator
    cmp r13, TOK_GE
    je .color_operator
    cmp r13, TOK_LE
    je .color_operator
    cmp r13, TOK_AMP
    je .color_operator
    cmp r13, TOK_DOT
    je .color_operator

    ; Check if identifier is a type name (i32, i64, bool, etc.)
    cmp r13, TOK_IDENT
    je .check_type_ident

    ; Default: emit raw
    jmp .emit_token_raw

.color_keyword:
    mov rdi, ansi_bold_magenta
    mov rsi, ansi_bold_magenta_len
    jmp .emit_colored

.color_bool:
    mov rdi, ansi_bold_blue
    mov rsi, ansi_bold_blue_len
    jmp .emit_colored

.color_int:
    mov rdi, ansi_yellow
    mov rsi, ansi_yellow_len
    jmp .emit_colored

.color_string:
    mov rdi, ansi_green
    mov rsi, ansi_green_len
    jmp .emit_colored

.color_operator:
    mov rdi, ansi_bold_white
    mov rsi, ansi_bold_white_len
    jmp .emit_colored

.check_type_ident:
    ; Check if this identifier is a type keyword
    push rbx
    mov rdi, [rbx + TOKEN_START]
    mov rsi, [rbx + TOKEN_LEN]
    call colorize_is_type_name
    pop rbx
    test rax, rax
    jnz .color_type
    jmp .emit_token_raw

.color_type:
    mov rdi, ansi_bold_cyan
    mov rsi, ansi_bold_cyan_len
    jmp .emit_colored

.emit_colored:
    ; Input: rdi = color escape ptr, rsi = color escape len
    ; Write color escape
    push rdi
    push rsi
    mov rdx, rsi
    mov rsi, rdi
    mov rdi, 1
    mov rax, SYS_WRITE
    syscall
    pop rsi
    pop rdi
    ; Write token text from source
    mov rdi, 1
    lea rsi, [src_buf + r15]
    mov rdx, [color_src_span]
    mov rax, SYS_WRITE
    syscall
    ; Write reset escape
    mov rdi, 1
    mov rsi, ansi_reset
    mov rdx, ansi_reset_len
    mov rax, SYS_WRITE
    syscall
    ; Update last emitted offset
    mov r14, r15
    add r14, [color_src_span]
    inc r12
    jmp .token_loop

.emit_token_raw:
    ; No color — emit token text as-is
    mov rdi, 1
    lea rsi, [src_buf + r15]
    mov rdx, [color_src_span]
    mov rax, SYS_WRITE
    syscall
    mov r14, r15
    add r14, [color_src_span]
    inc r12
    jmp .token_loop

.advance_newline:
    ; Emit the newline character(s) from source
    mov rdi, 1
    lea rsi, [src_buf + r15]
    mov rdx, [rbx + TOKEN_LEN]
    mov rax, SYS_WRITE
    syscall
    ; Advance past the newline
    mov r14, r15
    add r14, [rbx + TOKEN_LEN]
    inc r12
    jmp .token_loop

.done:
    ; Emit any remaining source after last token
    mov rax, [src_len]
    cmp r14, rax
    jae .final
    mov rdi, 1
    lea rsi, [src_buf + r14]
    mov rdx, rax
    sub rdx, r14
    mov rax, SYS_WRITE
    syscall
.final:
    ; Ensure final reset
    mov rdi, 1
    mov rsi, ansi_reset
    mov rdx, ansi_reset_len
    mov rax, SYS_WRITE
    syscall

    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; colorize_is_type_name: Check if source span [rdi..rdi+rsi) is a type keyword.
; Input: rdi = source offset, rsi = length
; Returns: rax = 1 if type, 0 otherwise
colorize_is_type_name:
    cmp rsi, 2
    je .len2
    cmp rsi, 3
    je .len3
    cmp rsi, 4
    je .len4
    cmp rsi, 5
    je .len5
    xor rax, rax
    ret
.len2:
    ; Check "i8", "u8"
    cmp byte [src_buf + rdi], 'i'
    jne .u8_check
    cmp byte [src_buf + rdi + 1], '8'
    jne .notype
    mov rax, 1
    ret
.u8_check:
    cmp byte [src_buf + rdi], 'u'
    jne .notype
    cmp byte [src_buf + rdi + 1], '8'
    jne .notype
    mov rax, 1
    ret
.len3:
    ; Check "i32", "i64", "i16", "u32", "u64", "u16", "str"
    cmp byte [src_buf + rdi], 'i'
    je .i_prefix_3
    cmp byte [src_buf + rdi], 'u'
    je .u_prefix_3
    cmp byte [src_buf + rdi], 's'
    je .str_check
    xor rax, rax
    ret
.str_check:
    cmp byte [src_buf + rdi + 1], 't'
    jne .notype
    cmp byte [src_buf + rdi + 2], 'r'
    jne .notype
    mov rax, 1
    ret
.i_prefix_3:
    cmp byte [src_buf + rdi + 1], '3'
    jne .i16_check
    cmp byte [src_buf + rdi + 2], '2'
    jne .notype
    mov rax, 1
    ret
.i16_check:
    cmp byte [src_buf + rdi + 1], '1'
    jne .i64_check
    cmp byte [src_buf + rdi + 2], '6'
    jne .notype
    mov rax, 1
    ret
.i64_check:
    cmp byte [src_buf + rdi + 1], '6'
    jne .notype
    cmp byte [src_buf + rdi + 2], '4'
    jne .notype
    mov rax, 1
    ret
.u_prefix_3:
    cmp byte [src_buf + rdi + 1], '3'
    jne .u16_check
    cmp byte [src_buf + rdi + 2], '2'
    jne .notype
    mov rax, 1
    ret
.u16_check:
    cmp byte [src_buf + rdi + 1], '1'
    jne .u64_check
    cmp byte [src_buf + rdi + 2], '6'
    jne .notype
    mov rax, 1
    ret
.u64_check:
    cmp byte [src_buf + rdi + 1], '6'
    jne .notype
    cmp byte [src_buf + rdi + 2], '4'
    jne .notype
    mov rax, 1
    ret
.len4:
    ; Check "bool", "i128", "u128", "char"
    cmp byte [src_buf + rdi], 'b'
    je .bool_check
    cmp byte [src_buf + rdi], 'c'
    je .char_check
    xor rax, rax
    ret
.bool_check:
    cmp byte [src_buf + rdi + 1], 'o'
    jne .notype
    cmp byte [src_buf + rdi + 2], 'o'
    jne .notype
    cmp byte [src_buf + rdi + 3], 'l'
    jne .notype
    mov rax, 1
    ret
.char_check:
    cmp byte [src_buf + rdi + 1], 'h'
    jne .notype
    cmp byte [src_buf + rdi + 2], 'a'
    jne .notype
    cmp byte [src_buf + rdi + 3], 'r'
    jne .notype
    mov rax, 1
    ret
.len5:
    ; Check "isize", "usize"
    cmp byte [src_buf + rdi], 'i'
    je .isize_check
    cmp byte [src_buf + rdi], 'u'
    je .usize_check
    xor rax, rax
    ret
.isize_check:
    cmp byte [src_buf + rdi + 1], 's'
    jne .notype
    cmp byte [src_buf + rdi + 2], 'i'
    jne .notype
    cmp byte [src_buf + rdi + 3], 'z'
    jne .notype
    cmp byte [src_buf + rdi + 4], 'e'
    jne .notype
    mov rax, 1
    ret
.usize_check:
    cmp byte [src_buf + rdi + 1], 's'
    jne .notype
    cmp byte [src_buf + rdi + 2], 'i'
    jne .notype
    cmp byte [src_buf + rdi + 3], 'z'
    jne .notype
    cmp byte [src_buf + rdi + 4], 'e'
    jne .notype
    mov rax, 1
    ret
.notype:
    xor rax, rax
    ret

segment readable writeable
color_src_span: rq 1
