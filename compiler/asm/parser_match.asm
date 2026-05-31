; Status: PARTIAL.
; Token lookahead, identifier matching, and parser diagnostic positions.

current_is_io_write:
    call expect_ident_text_io
    test rax, rax
    jz .no
    call next_token_kind
    cmp rax, TOK_DOT
    jne .no
    mov rax, 1
    ret
.no:
    xor rax, rax
    ret

next_token_kind:
    mov rdi, [token_index]
    inc rdi
    cmp rdi, [token_count]
    jae .eof
    call token_addr
    mov rax, [rax + TOKEN_TYPE]
    ret
.eof:
    mov rax, TOK_EOF
    ret

expect_ident_text_core:
    mov rsi, text_core
    mov rdx, 4
    jmp current_ident_text_eq
expect_ident_text_io:
    mov rsi, text_io
    mov rdx, 2
    jmp current_ident_text_eq
expect_ident_text_main:
    mov rsi, text_main
    mov rdx, 4
    jmp current_ident_text_eq
expect_ident_text_i32:
    mov rsi, text_i32
    mov rdx, 3
    jmp current_ident_text_eq
expect_ident_text_write:
    mov rsi, text_write
    mov rdx, 5
    jmp current_ident_text_eq

; parse_type_keyword: Parse type identifier and return type ID
; Input: current token should be type identifier
; Output: rax = TYPE_* constant, or 0 if not a recognized type
parse_type_keyword:
    call current_token_kind
    cmp rax, TOK_IDENT
    jne .not_type
    
    call current_token_addr
    mov r8, [rax + TOKEN_START]
    mov r9, [rax + TOKEN_LEN]
    
    ; Check length for dispatch
    cmp r9, 2
    je .len2
    cmp r9, 3
    je .len3
    cmp r9, 4
    je .len4
    jmp .not_type

.len2:
    ; i8, u8
    mov al, byte [src_buf + r8]
    cmp al, 'i'
    je .type_i8
    cmp al, 'u'
    je .type_u8
    jmp .not_type

.type_i8:
    mov al, byte [src_buf + r8 + 1]
    cmp al, '8'
    jne .not_type
    mov rax, TYPE_I8
    ret

.type_u8:
    mov al, byte [src_buf + r8 + 1]
    cmp al, '8'
    jne .not_type
    mov rax, TYPE_U8
    ret

.len3:
    ; i32, u32, i64, u64, i16, u16
    mov al, byte [src_buf + r8]
    cmp al, 'i'
    je .check_i_len3
    cmp al, 'u'
    je .check_u_len3
    jmp .not_type

.check_i_len3:
    mov al, byte [src_buf + r8 + 1]
    cmp al, '3'
    je .type_i32_or_i16
    cmp al, '6'
    je .type_i64
    cmp al, '1'
    je .type_i16
    jmp .not_type

.type_i32_or_i16:
    mov al, byte [src_buf + r8 + 2]
    cmp al, '2'
    je .type_i32
    jmp .not_type

.type_i32:
    mov rax, TYPE_I32
    ret

.type_i16:
    mov al, byte [src_buf + r8 + 2]
    cmp al, '6'
    jne .not_type
    mov rax, TYPE_I16
    ret

.type_i64:
    mov al, byte [src_buf + r8 + 2]
    cmp al, '4'
    jne .not_type
    mov rax, TYPE_I64
    ret

.check_u_len3:
    mov al, byte [src_buf + r8 + 1]
    cmp al, '3'
    je .type_u32_or_u16
    cmp al, '6'
    je .type_u64
    cmp al, '1'
    je .type_u16
    jmp .not_type

.type_u32_or_u16:
    mov al, byte [src_buf + r8 + 2]
    cmp al, '2'
    je .type_u32
    jmp .not_type

.type_u32:
    mov rax, TYPE_U32
    ret

.type_u16:
    mov al, byte [src_buf + r8 + 2]
    cmp al, '6'
    jne .not_type
    mov rax, TYPE_U16
    ret

.type_u64:
    mov al, byte [src_buf + r8 + 2]
    cmp al, '4'
    jne .not_type
    mov rax, TYPE_U64
    ret

.len4:
    ; bool
    mov al, byte [src_buf + r8]
    cmp al, 'b'
    jne .not_type
    mov al, byte [src_buf + r8 + 1]
    cmp al, 'o'
    jne .not_type
    mov al, byte [src_buf + r8 + 2]
    cmp al, 'o'
    jne .not_type
    mov al, byte [src_buf + r8 + 3]
    cmp al, 'l'
    jne .not_type
    mov rax, TYPE_BOOL
    ret

.not_type:
    xor rax, rax
    ret

; parse_pointer_type: Parse pointer type syntax (*i32, *u64, etc.)
; Input: current token should be * (TOK_STAR)
; Output: rax = TYPE_* constant for pointer type, or 0 if invalid
parse_pointer_type:
    call current_token_kind
    cmp rax, TOK_STAR
    jne .not_ptr
    
    ; Consume *
    call advance_token
    
    ; Parse the inner type; recursive so **T is valid.
    call parse_any_type
    test rax, rax
    jz .not_ptr          ; Inner type must be valid
    
    ; rax now has inner type ID
    ; Create pointer type: type_intern_ptr(inner_type, TYPE_MUT_CONST)
    mov rdi, rax        ; inner type in rdi
    xor rsi, rsi        ; mutable flag = TYPE_MUT_CONST (0)
    call type_intern_ptr
    
    ; rax now has the new pointer type ID (or 0 if overflow)
    ret

.not_ptr:
    xor rax, rax
    ret

; parse_any_type: Parse any type (primitive or pointer or array)
; Input: current token should be type identifier or * or [
; Output: rax = TYPE_* constant, or 0 if not a recognized type
parse_any_type:
    call current_token_kind
    
    cmp rax, TOK_STAR
    je .try_ptr
    
    cmp rax, TOK_LBRACKET
    je .try_array
    
    cmp rax, TOK_IDENT
    jne .not_type
    
    call parse_type_keyword
    test rax, rax
    jnz .primitive_found

    call current_token_addr
    mov rdi, [rax + TOKEN_START]
    mov rsi, [rax + TOKEN_LEN]
    call type_lookup_struct_by_name
    test rax, rax
    jz .not_type
    
.primitive_found:
    push rax                      ; save type ID on stack
    
    call current_token_kind
    cmp rax, TOK_LBRACKET
    jne .done_type_pop
    
    pop rdi                       ; restore type ID as arg
    call parse_array_type_suffix
    ret

.try_ptr:
    call parse_pointer_type
    test rax, rax
    jz .not_type
    
    push rax                      ; save ptr type ID on stack
    
    call current_token_kind
    cmp rax, TOK_LBRACKET
    jne .done_type_pop
    
    pop rdi                       ; restore ptr type ID as arg
    call parse_array_type_suffix
    ret

.try_array:
    call parse_array_type
    ret

.not_type:
    xor rax, rax
    ret

.done_type_pop:
    pop rax                       ; restore type ID
    ret


; parse_array_type: Parse array type starting from [
; Input: current token should be [
; Output: rax = array TYPE_* constant, or 0 if invalid
parse_array_type:
    call current_token_kind
    cmp rax, TOK_LBRACKET
    jne .bad
    
    call advance_token
    
    ; Parse element type (can be primitive, pointer, or nested array)
    call parse_any_type
    test rax, rax
    jz .bad
    
    mov [tmp_type_id], rax    ; Save element type
    call advance_token
    call current_token_kind
    cmp rax, TOK_SEMICOLON
    jne .bad
    
    call advance_token
    
    ; Parse array size (must be integer literal)
    call current_token_kind
    cmp rax, TOK_INT
    jne .bad
    
    mov rdi, [token_index]
    call parse_int_node_at
    test rax, rax
    jz .bad
    
    mov rdi, rax
    call ast_child
    mov rdi, rax
    call token_addr
    mov rbx, [rax + TOKEN_PAYLOAD]   ; Size value
    call advance_token
    
    ; Expect ]
    call current_token_kind
    cmp rax, TOK_RBRACKET
    jne .bad

    ; Create array type
    mov rdi, [tmp_type_id]
    mov rsi, rbx
    call type_intern_array
    ret

.bad:
    xor rax, rax
    ret

; parse_array_type_suffix: Parse [N] suffix for array
; Input: rdi = element type ID
; Output: rax = array TYPE_* constant, or 0 if invalid
parse_array_type_suffix:
    push rdi            ; Save element type
    
    call current_token_kind
    cmp rax, TOK_LBRACKET
    jne .bad
    
    call advance_token
    
    ; Parse array size
    call current_token_kind
    cmp rax, TOK_INT
    jne .bad
    
    mov rdi, [token_index]
    call parse_int_node_at
    test rax, rax
    jz .bad
    
    mov rdi, rax
    call ast_child
    mov rdi, rax
    call token_addr
    mov rbx, [rax + TOKEN_PAYLOAD]   ; Size value
    call advance_token
    
    ; Expect ]
    call current_token_kind
    cmp rax, TOK_RBRACKET
    jne .bad
    
    call advance_token
    
    ; Create array type
    pop rdi              ; Restore element type
    mov rsi, rbx
    call type_intern_array
    ret

.bad:
    pop rdi
    xor rax, rax
    ret



current_ident_text_eq:
    call current_token_kind
    cmp rax, TOK_IDENT
    jne .no
    mov rdi, [token_index]
    call token_text_eq
    ret
.no:
    xor rax, rax
    ret

token_text_eq:
    push rbx
    push r12
    mov r12, rsi
    mov rbx, rdx
    call token_addr
    cmp [rax + TOKEN_LEN], rbx
    jne .no
    mov rdi, src_buf
    add rdi, [rax + TOKEN_START]
    xor rcx, rcx
.loop:
    cmp rcx, rbx
    je .yes
    mov dl, [rdi + rcx]
    cmp dl, [r12 + rcx]
    jne .no
    inc rcx
    jmp .loop
.yes:
    mov rax, 1
    pop r12
    pop rbx
    ret
.no:
    xor rax, rax
    pop r12
    pop rbx
    ret

set_diag_from_current:
    call current_token_addr
    mov rbx, [rax + TOKEN_LINE]
    mov [diag_line], rbx
    mov rbx, [rax + TOKEN_COL]
    mov [diag_col], rbx
    ret
