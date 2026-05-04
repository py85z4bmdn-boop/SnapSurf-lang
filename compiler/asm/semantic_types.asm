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
    call type_is_integer
    test rax, rax
    jz .bad
    cmp rsi, rdi
    jne .bad
    mov rax, rdi
    ret
.bad:
    xor rax, rax
    ret

type_is_integer:
    cmp rdi, TYPE_I8
    je .yes
    cmp rdi, TYPE_I16
    je .yes
    cmp rdi, TYPE_I32
    je .yes
    cmp rdi, TYPE_I64
    je .yes
    cmp rdi, TYPE_ISIZE
    je .yes
    cmp rdi, TYPE_U8
    je .yes
    cmp rdi, TYPE_U16
    je .yes
    cmp rdi, TYPE_U32
    je .yes
    cmp rdi, TYPE_U64
    je .yes
    cmp rdi, TYPE_USIZE
    je .yes
    xor rax, rax
    ret
.yes:
    mov rax, 1
    ret

type_intern_ptr:
    push rbx
    push r12
    push r13
    mov r12, rdi
    mov r13, rsi
    mov rbx, TYPE_PRIMITIVE_COUNT
.find_ptr:
    cmp rbx, [type_count]
    jae .create
    mov rax, rbx
    imul rax, TYPE_DESC_SIZE
    cmp byte [type_table + rax + TYPE_DESC_KIND], TYPE_KIND_PTR
    jne .next_ptr
    cmp byte [type_table + rax + TYPE_DESC_MUT], r13b
    jne .next_ptr
    cmp dword [type_table + rax + TYPE_DESC_INNER], r12d
    jne .next_ptr
    mov rax, rbx
    pop r13
    pop r12
    pop rbx
    ret
.next_ptr:
    inc rbx
    jmp .find_ptr
.create:
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
    jb .not_ptr
    cmp rdi, [type_count]
    jae .not_ptr

    mov rax, rdi
    imul rax, TYPE_DESC_SIZE
    movzx ebx, byte [type_table + rax + TYPE_DESC_KIND]
    cmp bl, TYPE_KIND_PTR
    jne .not_ptr

    mov rax, rdi
    imul rax, TYPE_DESC_SIZE
    mov eax, dword [type_table + rax + TYPE_DESC_INNER]
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
    mov rbx, TYPE_PRIMITIVE_COUNT
.find_array:
    cmp rbx, [type_count]
    jae .create
    mov rax, rbx
    imul rax, TYPE_DESC_SIZE
    cmp byte [type_table + rax + TYPE_DESC_KIND], TYPE_KIND_ARRAY
    jne .next_array
    cmp dword [type_table + rax + TYPE_DESC_INNER], r12d
    jne .next_array
    cmp qword [type_table + rax + TYPE_DESC_SIZE_PARAM], r13
    jne .next_array
    mov rax, rbx
    pop r13
    pop r12
    pop rbx
    ret
.next_array:
    inc rbx
    jmp .find_array
.create:
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
    jb .not_derived
    cmp rdi, [type_count]
    jae .not_derived
    
    ; Check type_table for this type ID
    mov rax, rdi
    imul rax, TYPE_DESC_SIZE
    mov al, byte [type_table + rax + TYPE_DESC_KIND]
    cmp al, TYPE_KIND_ARRAY
    jne .not_array
    
    ; It's an array, extract element type from INNER
    mov rax, rdi
    imul rax, TYPE_DESC_SIZE
    mov eax, dword [type_table + rax + TYPE_DESC_INNER]
    ret

.not_array:
.not_derived:
    xor rax, rax
    ret

type_array_count:
    cmp rdi, TYPE_PRIMITIVE_COUNT
    jb .not_array
    cmp rdi, [type_count]
    jae .not_array
    mov rax, rdi
    imul rax, TYPE_DESC_SIZE
    cmp byte [type_table + rax + TYPE_DESC_KIND], TYPE_KIND_ARRAY
    jne .not_array
    mov rax, [type_table + rax + TYPE_DESC_SIZE_PARAM]
    ret
.not_array:
    xor rax, rax
    ret

type_slot_count:
    push rbx
    push r12
    mov r12, rdi
    cmp r12, TYPE_PRIMITIVE_COUNT
    jb .one
    cmp r12, [type_count]
    jae .one
    mov rax, r12
    imul rax, TYPE_DESC_SIZE
    cmp byte [type_table + rax + TYPE_DESC_KIND], TYPE_KIND_ARRAY
    jne .one
    mov rdi, r12
    call type_array_count
    test rax, rax
    jz .one
    mov rbx, rax
    mov rdi, r12
    call type_get_element_of_array
    test rax, rax
    jz .one
    mov rdi, rax
    call type_slot_count
    imul rax, rbx
    jmp .done
.one:
    mov rax, 1
.done:
    pop r12
    pop rbx
    ret

; type_lookup_struct_by_name: Find struct type by name
; Input: rdi = name offset (into src_buf), rsi = name length
; Output: rax = struct type ID, or 0 if not found
type_lookup_struct_by_name:
    push rbx
    push r12
    push r13
    mov r12, rdi                ; name offset
    mov r13, rsi                ; name length
    
    ; Defensive: Check that name length is reasonable
    cmp r13, 255
    jae .not_found
    
    xor rbx, rbx
.loop:
    ; Defensive: Check bounds against registry count
    mov rax, [struct_registry_count]
    cmp rbx, rax
    jae .not_found
    
    ; Defensive: Check that index won't overflow arrays (256 entries max)
    cmp rbx, 256
    jae .not_found
    
    ; Compare lengths
    mov rax, [struct_name_len + rbx * 8]
    cmp rax, r13
    jne .next
    
    ; Compare bytes: both name_start fields are offsets into src_buf
    mov rdi, [struct_name_start + rbx * 8]   ; stored name offset
    mov rsi, r12                              ; input name offset
    mov rdx, r13                              ; length to compare
    xor rcx, rcx
.cmp_loop:
    cmp rcx, rdx
    je .found
    mov al, [src_buf + rdi + rcx]
    mov r8b, [src_buf + rsi + rcx]
    cmp al, r8b
    jne .next
    inc rcx
    jmp .cmp_loop
    
.found:
    mov rax, [struct_type_id + rbx * 8]
    pop r13
    pop r12
    pop rbx
    ret
    
.next:
    inc rbx
    jmp .loop
    
.not_found:
    xor rax, rax
    pop r13
    pop r12
    pop rbx
    ret

; type_intern_struct: Create or lookup struct type descriptor
; Input: rdi = struct name offset (into src_buf), rsi = name length
;        rdx = field count, rcx = AST_STRUCT_DECL node
; Output: rax = new struct type ID, or 0 if overflow
type_intern_struct:
    push rbx
    push r12
    push r13
    push r14
    mov r12, rdi                ; struct name offset (into src_buf)
    mov r13, rsi                ; name length
    mov r14, rdx                ; field count
    
    ; Check for existing struct with same name
    xor rbx, rbx                ; Index counter
.find_struct:
    cmp rbx, [struct_registry_count]
    jae .create_new
    
    ; Compare names
    mov rax, [struct_name_len + rbx * 8]
    cmp rax, r13
    jne .next_struct
    
    ; Compare bytes - both are offsets into src_buf
    mov rdi, r12                ; input name offset
    mov rsi, [struct_name_start + rbx * 8]  ; stored name offset
    mov rdx, r13
    xor rcx, rcx
.cmp_loop:
    cmp rcx, rdx
    je .found_existing
    mov al, [src_buf + rdi + rcx]    ; input name byte
    mov r8b, [src_buf + rsi + rcx]   ; stored name byte
    cmp al, r8b
    jne .next_struct
    inc rcx
    jmp .cmp_loop
    
.next_struct:
    inc rbx
    jmp .find_struct

.found_existing:
    ; Return existing type ID
    mov rax, [struct_type_id + rbx * 8]
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

.create_new:
    ; Create new struct type in type_table
    mov rax, [type_count]
    cmp rax, TYPE_TBL_CAP
    jae .overflow
    
    mov rbx, rax
    mov rax, rbx
    imul rax, TYPE_DESC_SIZE
    
    ; Set struct descriptor
    mov byte [type_table + rax + TYPE_DESC_KIND], TYPE_KIND_STRUCT
    mov byte [type_table + rax + TYPE_DESC_MUT], TYPE_MUT_CONST
    mov dword [type_table + rax + TYPE_DESC_INNER], 0
    mov qword [type_table + rax + TYPE_DESC_SIZE_PARAM], r14
    
    mov rax, rbx
    inc qword [type_count]
    
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

.overflow:
    xor rax, rax
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; type_lookup_struct_field: Find field type in a struct by field name
; Input: rdi = struct type ID, rsi = field name offset, rdx = field name length
; Output: rax = field type ID, or 0 if not found
type_lookup_struct_field:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi                ; struct type ID
    mov r13, rsi                ; input field name offset (into src_buf)
    mov r14, rdx                ; input field name length
    
    ; Find struct in registry by type ID
    xor rbx, rbx                ; registry index
.registry_loop:
    cmp rbx, [struct_registry_count]
    jae .registry_not_found
    
    mov rax, [struct_type_id + rbx * 8]
    cmp rax, r12
    je .found_struct
    
    inc rbx
    jmp .registry_loop
    
.registry_not_found:
    ; Struct type ID not in registry - this means struct wasn't registered
    xor rax, rax
    jmp .done
    
.found_struct:
    ; Get the AST node for this struct
    mov r15, [struct_ast_node + rbx * 8]
    test r15, r15
    jz .not_found
    
    ; Traverse struct fields (AST children)
    mov rdi, r15
    call ast_child
    test rax, rax
    jz .debug_no_first_field
    
    mov r12, rax                ; First field
.field_loop:
    test r12, r12
    jz .not_found
    
    ; Check if this is a field node
    mov rdi, r12
    call ast_kind
    cmp rax, AST_STRUCT_FIELD
    jne .debug_not_field_node
    
    ; Get field name from AST node
    mov rdi, r12
    call ast_span_start
    mov r10, rax                ; field name start offset
    mov rdi, r12
    call ast_span_end
    sub rax, r10                ; field name length = end - start
    
    ; Compare field name lengths
    cmp rax, r14                ; stored vs input lengths
    jne .next_field
    
    ; Compare bytes: both are offsets into src_buf
    xor rcx, rcx
.cmp_field_name:
    cmp rcx, r14
    je .field_match
    mov al, [src_buf + r10 + rcx]     ; stored field name byte
    mov r8b, [src_buf + r13 + rcx]    ; input field name byte
    cmp al, r8b
    jne .next_field
    inc rcx
    jmp .cmp_field_name
    
.field_match:
    ; Get field type from type tag
    mov rdi, r12
    call ast_get_type_tag
    jmp .done
    
.next_field:
    mov rdi, r12
    call ast_next
    mov r12, rax
    jmp .field_loop

.debug_no_first_field:
    ; ast_child returned 0 - struct has no fields
    xor rax, rax
    jmp .done

.debug_not_field_node:
    ; Node is not a field - this shouldn't happen in normal cases
    ; but move to next sibling
    jmp .next_field
    
.not_found:
    xor rax, rax
    
.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
