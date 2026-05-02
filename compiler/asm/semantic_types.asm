; Status: PARTIAL.
; Type table and primitive expression compatibility for the foundation checker.

type_init:
    mov qword [type_count], TYPE_PRIMITIVE_COUNT
    mov rcx, 1
.loop:
    cmp rcx, TYPE_PRIMITIVE_COUNT
    jae .done
    mov rax, rcx
    imul rax, TYPE_DESC_SIZE
    mov byte [type_table + rax + TYPE_DESC_KIND], TYPE_KIND_PRIM
    mov byte [type_table + rax + TYPE_DESC_MUT], TYPE_MUT_CONST
    mov dword [type_table + rax + TYPE_DESC_INNER], ecx
    mov qword [type_table + rax + TYPE_DESC_SIZE_PARAM], 0
    inc rcx
    jmp .loop
.done:
    ret

type_check_binary:
    cmp rdx, AST_BIN_ADD
    je .arith
    cmp rdx, AST_BIN_SUB
    je .arith
    cmp rdx, AST_BIN_MUL
    je .arith
    cmp rdx, AST_BIN_DIV
    je .arith
    cmp rdx, AST_BIN_MOD
    je .arith
    xor rax, rax
    ret
.arith:
    ; Accept integer types: i8, i16, i32, i64, u8, u16, u32, u64
    cmp rdi, TYPE_I8
    je .left_ok
    cmp rdi, TYPE_I16
    je .left_ok
    cmp rdi, TYPE_I32
    je .left_ok
    cmp rdi, TYPE_I64
    je .left_ok
    cmp rdi, TYPE_U8
    je .left_ok
    cmp rdi, TYPE_U16
    je .left_ok
    cmp rdi, TYPE_U32
    je .left_ok
    cmp rdi, TYPE_U64
    je .left_ok
    jmp .bad

.left_ok:
    ; Check right operand matches left
    cmp rsi, rdi
    jne .bad
    mov rax, rdi        ; Return left type
    ret
.bad:
    xor rax, rax
    ret

type_intern_ptr:
    push rbx
    push r12
    push r13
    mov r12, rdi
    mov r13, rsi
    mov rbx, [type_count]
    cmp rbx, TYPE_TBL_CAP
    jae .overflow
    mov rax, rbx
    imul rax, TYPE_DESC_SIZE
    mov byte [type_table + rax + TYPE_DESC_KIND], TYPE_KIND_PTR
    mov byte [type_table + rax + TYPE_DESC_MUT], r13b
    mov dword [type_table + rax + TYPE_DESC_INNER], r12d
    mov qword [type_table + rax + TYPE_DESC_SIZE_PARAM], 0
    mov rax, rbx
    inc qword [type_count]
    pop r13
    pop r12
    pop rbx
    ret
.overflow:
    xor rax, rax
    pop r13
    pop r12
    pop rbx
    ret

type_get_inner:
    ; Input: rdi = pointer type ID
    ; Output: rax = inner type ID, or 0 if not a pointer
    push rbx
    cmp rdi, TYPE_PRIMITIVE_COUNT
    jb .not_ptr      ; Primitive types are 0-19
    
    ; Derived types (pointers, arrays, etc) start at TYPE_PRIMITIVE_COUNT
    mov rax, rdi
    sub rax, TYPE_PRIMITIVE_COUNT
    cmp rax, [type_count]
    jae .not_ptr     ; Out of range
    
    mov rax, rdi
    sub rax, TYPE_PRIMITIVE_COUNT
    imul rax, TYPE_DESC_SIZE
    mov rbx, [type_table + rax + TYPE_DESC_KIND]
    cmp rbx, TYPE_KIND_PTR
    jne .not_ptr
    
    ; It's a pointer, get the inner type
    mov rax, rdi
    sub rax, TYPE_PRIMITIVE_COUNT
    imul rax, TYPE_DESC_SIZE
    mov rax, [type_table + rax + TYPE_DESC_INNER]
    pop rbx
    ret

.not_ptr:
    xor rax, rax
    pop rbx
    ret

type_intern_array:
    ; Input: rdi = element type ID, rsi = size (qword)
    ; Output: rax = array type ID, or 0 if overflow
    push rbx
    push r12
    push r13
    mov r12, rdi
    mov r13, rsi
    mov rbx, [type_count]
    cmp rbx, TYPE_TBL_CAP
    jae .overflow
    mov rax, rbx
    imul rax, TYPE_DESC_SIZE
    mov byte [type_table + rax + TYPE_DESC_KIND], TYPE_KIND_ARRAY
    mov byte [type_table + rax + TYPE_DESC_MUT], TYPE_MUT_CONST
    mov dword [type_table + rax + TYPE_DESC_INNER], r12d
    mov qword [type_table + rax + TYPE_DESC_SIZE_PARAM], r13
    mov rax, rbx
    inc qword [type_count]
    pop r13
    pop r12
    pop rbx
    ret
.overflow:
    xor rax, rax
    pop r13
    pop r12
    pop rbx
    ret

; type_get_element_of_array: Get element type of an array type
; Input: rdi = array type ID
; Output: rax = element type ID, or 0 if not an array type
type_get_element_of_array:
    ; Array types have TYPE_KIND_ARRAY (3) and inner type in INNER field
    cmp rdi, TYPE_PRIMITIVE_COUNT
    jl .not_derived
    
    ; Check type_table for this type ID
    mov rax, rdi
    sub rax, TYPE_PRIMITIVE_COUNT
    imul rax, TYPE_DESC_SIZE
    mov al, byte [type_table + rax + TYPE_DESC_KIND]
    cmp al, TYPE_KIND_ARRAY
    jne .not_array
    
    ; It's an array, extract element type from INNER
    mov rax, rdi
    sub rax, TYPE_PRIMITIVE_COUNT
    imul rax, TYPE_DESC_SIZE
    mov eax, dword [type_table + rax + TYPE_DESC_INNER]
    ret

.not_array:
.not_derived:
    xor rax, rax
    ret

