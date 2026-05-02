; semantic/functions.asm — Function registry and multi-function semantic analysis
; Status: NEW for multi-function support
; Handles: Function registry, parameter binding, function call validation

; Function registry structure (in memory section):
; Each entry: 32 bytes
;   [0:8]   name_start       - offset into src_buf
;   [8:8]   name_len         - length of function name
;   [16:8]  param_count      - number of parameters
;   [24:8]  ast_node         - pointer to FnDecl AST node
; Total capacity: 128 functions

; Function parameter info (stored per-function):
; Each param: 16 bytes
;   [0:8]   param_name_start - offset into src_buf
;   [8:8]   param_name_len   - length of parameter name
; Stored in: fn_params[] array

section .bss
    fn_registry: resq 128 * 4       ; 128 functions, 32 bytes each
    fn_registry_count: resq 1
    fn_params: resq 256 * 2         ; Max 256 parameters total
    fn_params_count: resq 1         ; Current parameter count
    current_fn_idx: resq 1          ; Current function being checked

section .text

; semantic_init_fn_registry: Initialize function registry
; Returns: rax = 0 on success
semantic_init_fn_registry:
    mov qword [fn_registry_count], 0
    mov qword [fn_params_count], 0
    xor rax, rax
    ret

; semantic_register_function: Add function to registry
; Input: rdi = FnDecl AST node
; Returns: rax = 0 on success, 1 on overflow
semantic_register_function:
    push rbx
    push r12
    push r13
    
    mov r12, rdi        ; r12 = FnDecl node
    
    ; Get function count
    mov r13, [fn_registry_count]
    cmp r13, 128
    jae .overflow
    
    ; Get function name from AST node
    ; FnDecl node structure: [kind, span_start, span_end, first_child, next_sibling]
    ; span_start contains name start in source
    mov rax, [r12 + AST_SPAN_START]
    mov rbx, [r12 + AST_SPAN_END]
    
    ; Calculate name length (span_end - span_start)
    sub rbx, rax
    
    ; Store in registry
    mov rcx, r13
    imul rcx, 32        ; offset = index * 32
    
    mov [fn_registry + rcx + 0], rax   ; name_start
    mov [fn_registry + rcx + 8], rbx   ; name_len
    mov qword [fn_registry + rcx + 16], 0   ; param_count (will update later)
    mov [fn_registry + rcx + 24], r12  ; ast_node
    
    ; Increment function count
    inc r13
    mov [fn_registry_count], r13
    
    xor rax, rax
    pop r13
    pop r12
    pop rbx
    ret

.overflow:
    mov rdi, src_path
    mov rsi, err_fn_registry_overflow
    call print_diag
    mov rax, 1
    pop r13
    pop r12
    pop rbx
    ret

; semantic_add_fn_params: Extract and store parameters for a function
; Input: rdi = FnDecl AST node, rsi = fn_registry index
; Returns: rax = param count, or 1 on error
semantic_add_fn_params:
    push rbx
    push r12
    push r13
    push r14
    
    mov r12, rdi        ; r12 = FnDecl node
    mov r13, rsi        ; r13 = registry index
    xor r14, r14        ; r14 = parameter count
    
    ; For now, parameters are hard-coded in the AST
    ; Parse from source based on function signature
    ; Get first child (parameters or block)
    mov rdi, r12
    call ast_child
    test rax, rax
    jz .no_params
    
    ; TODO: Walk AST children looking for AstFnParam nodes
    ; For now, extract from source between ( and ) or spaces before ->
    
    ; For this v0, we'll use a simplified approach:
    ; Count parameter nodes in the AST
    
.no_params:
    ; Update registry with param count
    mov rcx, r13
    imul rcx, 32
    mov [fn_registry + rcx + 16], r14   ; param_count
    
    mov rax, r14
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; semantic_find_function: Find function in registry by name
; Input: rdi = name_start (in src_buf), rsi = name_len
; Returns: rax = registry index, or -1 if not found
semantic_find_function:
    push rbx
    push r12
    push r13
    
    mov r12, rdi        ; r12 = name_start
    mov r13, rsi        ; r13 = name_len
    xor rbx, rbx        ; rbx = current index
    
.loop:
    mov rax, [fn_registry_count]
    cmp rbx, rax
    jae .not_found
    
    ; Get registry entry
    mov rcx, rbx
    imul rcx, 32
    
    ; Compare name_len
    mov rax, [fn_registry + rcx + 8]
    cmp rax, r13
    jne .next
    
    ; Compare name bytes
    mov rdi, src_buf
    add rdi, [fn_registry + rcx + 0]  ; name_start in registry
    mov rsi, r12
    mov rdx, r13
    call memcmp_bytes
    test rax, rax
    jz .found
    
.next:
    inc rbx
    jmp .loop

.found:
    mov rax, rbx
    pop r13
    pop r12
    pop rbx
    ret

.not_found:
    mov rax, -1
    pop r13
    pop r12
    pop rbx
    ret

; memcmp_bytes: Compare two memory regions byte-by-byte
; Input: rdi = ptr1, rsi = ptr2, rdx = length
; Returns: rax = 0 if equal, 1 if different
memcmp_bytes:
    push rcx
    xor rcx, rcx
.loop:
    cmp rcx, rdx
    je .equal
    mov al, [rdi + rcx]
    mov bl, [rsi + rcx]
    cmp al, bl
    jne .different
    inc rcx
    jmp .loop
.equal:
    xor rax, rax
    pop rcx
    ret
.different:
    mov rax, 1
    pop rcx
    ret

; semantic_validate_fn_call: Validate a function call
; Input: rdi = callee path/identifier, rsi = argument count, rdx = argument types array
; Returns: rax = 0 on success, 1 on error
semantic_validate_fn_call:
    push rbx
    push r12
    push r13
    
    mov r12, rdi        ; r12 = callee identifier
    mov r13, rsi        ; r13 = argument count
    
    ; Extract name from identifier (currently just span-based)
    ; For now, validate if function is in registry
    
    ; TODO: Check if callee exists in function registry
    ; TODO: Check if argument count matches parameter count
    ; TODO: Check if argument types match parameter types
    
    xor rax, rax
    pop r13
    pop r12
    pop rbx
    ret
