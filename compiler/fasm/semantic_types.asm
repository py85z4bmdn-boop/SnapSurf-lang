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
    cmp rdx, AST_BIN_XOR
    je .arith
    cmp rdx, AST_BIN_SHL
    je .arith
    cmp rdx, AST_BIN_SHR
    je .arith
    cmp rdx, AST_BIN_ROL
    je .arith
    cmp rdx, AST_BIN_ROR
    je .arith
    cmp rdx, AST_BIN_POW
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
type_element_size:
    ; Input: rdi = array type ID
    ; Output: rax = element size in bytes (1, 2, 4, or 8), or 0 if not array
    push rbx
    mov rbx, rdi
    call type_get_element_of_array
    test rax, rax
    jz .fail
    
    ; Now rax = element type ID, determine size
    cmp rax, TYPE_U8
    je .size_1
    cmp rax, TYPE_I8
    je .size_1
    
    cmp rax, TYPE_U16
    je .size_2
    cmp rax, TYPE_I16
    je .size_2
    
    cmp rax, TYPE_U32
    je .size_4
    cmp rax, TYPE_I32
    je .size_4
    
    ; All other types are 8 bytes (i64, u64, isize, usize, pointers, etc.)
    mov rax, 8
    pop rbx
    ret

.size_1:
    mov rax, 1
    pop rbx
    ret

.size_2:
    mov rax, 2
    pop rbx
    ret

.size_4:
    mov rax, 4
    pop rbx
    ret

.fail:
    xor rax, rax
    pop rbx
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

; semantic_find_struct: Find struct type ID by name
; Input: rdi = struct name offset in src_buf, rsi = name length
; Output: rax = struct type ID, or 0 if not found
semantic_find_struct:
    push rbx
    push r12
    push r13
    push r14

    mov r12, rdi                    ; r12 = name offset
    mov r13, rsi                    ; r13 = name length

    xor rbx, rbx                    ; rbx = loop counter
.loop:
    cmp rbx, [struct_registry_count]
    jge .not_found

    mov rax, rbx
    imul rax, 8
    cmp [struct_name_len + rax], r13
    jne .next

    ; Length matches, compare bytes
    mov r14, [struct_name_start + rax]
    xor rcx, rcx
.compare:
    cmp rcx, r13
    jge .found
    mov al, [src_buf + r12 + rcx]
    mov dl, [src_buf + r14 + rcx]
    cmp al, dl
    jne .next
    inc rcx
    jmp .compare

.next:
    inc rbx
    jmp .loop

.found:
    mov rax, rbx
    imul rax, 8
    mov rax, [struct_type_id + rax]
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

.not_found:
    xor rax, rax
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; type_lookup_struct_field: Find field type in a struct by field name
; Input: rdi = struct type ID, rsi = field name offset (src_buf), rdx = field name length
; Output: rax = field type ID, or 0 if not found
type_lookup_struct_field:
    push rbx
    push r12
    push r13
    push r14

    mov r12, rdi                    ; r12 = struct type ID
    mov r13, rsi                    ; r13 = field name offset (src_buf)
    mov r14, rdx                    ; r14 = field name length

    ; First, check if field_registry_count is positive
    mov rax, [field_registry_count]
    test rax, rax
    jz .not_found

    xor rbx, rbx                    ; rbx = field registry index
.search_loop:
    cmp rbx, [field_registry_count]
    jge .not_found

    ; Bounds check on array index
    cmp rbx, 2560
    jae .not_found

    ; Check if this field belongs to our struct
    mov rax, rbx
    imul rax, 8

    ; Defensive check: make sure array access won't go out of bounds
    mov rcx, [field_struct_id + rax]
    cmp rcx, r12
    jne .next_field

    ; Check field name length
    mov rcx, [field_name_len + rax]
    cmp rcx, r14
    jne .next_field

    ; Compare field names byte-by-byte
    ; Registry stores name in field_name_buf at offset [field_name_start]
    mov r10, [field_name_start + rax]    ; r10 = offset in field_name_buf

    ; Bounds check: field_name_buf[r10..r10+r14) must stay inside the buffer.
    mov rax, r10
    add rax, r14
    jc .next_field
    cmp rax, 25600
    ja .next_field

    mov rcx, r14
    xor r11, r11                    ; r11 = byte counter
.name_compare:
    cmp r11, rcx
    jge .found

    ; Compare src_buf[r13+r11] with field_name_buf[r10+r11]
    mov al, [src_buf + r13 + r11]
    mov dl, [field_name_buf + r10 + r11]
    cmp al, dl
    jne .next_field

    inc r11
    jmp .name_compare

.found:
    ; Return the field type
    mov rax, rbx
    imul rax, 8
    mov rax, [field_type + rax]
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

.next_field:
    inc rbx
    jmp .search_loop

.not_found:
    xor rax, rax
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; type_struct_single_field_type: return the primitive field type for one-field structs
; Input: rdi = struct type ID
; Output: rax = field type ID if exactly one field exists, otherwise 0
type_struct_single_field_type:
    push rbx
    push r12
    push r13
    push r14

    mov r12, rdi
    xor r13, r13                    ; matching field count
    xor r14, r14                    ; matching field type
    xor rbx, rbx
.loop:
    cmp rbx, [field_registry_count]
    jae .done
    cmp rbx, 2560
    jae .done

    mov rax, rbx
    imul rax, 8
    cmp [field_struct_id + rax], r12
    jne .next

    inc r13
    mov r14, [field_type + rax]
.next:
    inc rbx
    jmp .loop

.done:
    cmp r13, 1
    jne .not_single
    mov rax, r14
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

.not_single:
    xor rax, rax
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; type_struct_field_index: return 0-based field index within a struct
; Input: rdi = struct type ID, rsi = field name offset (src_buf), rdx = field name length
; Output: rax = field index (0-based), or -1 if not found
type_struct_field_index:
    push rbx
    push r12
    push r13
    push r14
    push r15

    mov r12, rdi                    ; struct type ID
    mov r13, rsi                    ; field name offset (src_buf)
    mov r14, rdx                    ; field name length
    xor r15, r15                    ; field index counter within this struct

    xor rbx, rbx
.loop:
    cmp rbx, [field_registry_count]
    jae .not_found
    cmp rbx, 2560
    jae .not_found

    mov rax, rbx
    imul rax, 8

    cmp [field_struct_id + rax], r12
    jne .next

    ; This field belongs to our struct — check name
    mov rcx, [field_name_len + rax]
    cmp rcx, r14
    jne .next_same_struct

    mov r10, [field_name_start + rax]
    mov rax, r10
    add rax, r14
    jc .next_same_struct
    cmp rax, 25600
    ja .next_same_struct

    xor r11, r11
.cmp:
    cmp r11, r14
    jge .found

    mov al, [src_buf + r13 + r11]
    mov dl, [field_name_buf + r10 + r11]
    cmp al, dl
    jne .next_same_struct

    inc r11
    jmp .cmp

.found:
    mov rax, r15
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

.next_same_struct:
    inc r15
.next:
    inc rbx
    jmp .loop

.not_found:
    mov rax, -1
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
