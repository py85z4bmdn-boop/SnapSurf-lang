; emitter_control.asm — Modular control flow emission entry point.
; Sub-modules handle specific responsibilities:
;   emitter/loop_context.asm  — loop stack push/pop
;   emitter/break_continue.asm — break/continue statement emission
;   emitter/comparison.asm    — comparison and logical operator emission
; This file contains: emit_if_stmt, emit_while_stmt, emit_loop_stmt.

include "compiler/fasm/emitter/loop_context.asm"
include "compiler/fasm/emitter/break_continue.asm"
include "compiler/fasm/emitter/comparison.asm"

; emit_if_stmt: AST structure is
;   if_stmt -> child chain: [condition, then_block, (optional else_block)]
emit_if_stmt:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r13, [label_counter]
    inc qword [label_counter]
    mov r14, [label_counter]
    inc qword [label_counter]

    ; Get condition (first child of if_stmt)
    mov rdi, r12
    call ast_child
    mov r15, rax
    mov rdi, r15
    call emit_expr
    test rax, rax
    jnz .fail

    ; Emit: test rax,rax / jz .Lelse
    mov rdi, [out_fd]
    mov rsi, asm_jz_pre
    mov rdx, asm_jz_pre_len
    call write_all
    mov rax, r13
    mov rdi, [out_fd]
    call write_u64_fd
    mov rdi, [out_fd]
    mov rsi, asm_jz_post
    mov rdx, asm_jz_post_len
    call write_all

    ; Get then-block (second child = ast_next(condition))
    mov rdi, r15
    call ast_next
    mov r15, rax
    mov rdi, r15
    call emit_block
    test rax, rax
    jnz .fail

    ; Check for else-block (third child = ast_next(then_block))
    mov rdi, r15
    call ast_next
    test rax, rax
    jz .no_else
    mov r15, rax

    ; Emit: jmp .Lend (skip else)
    mov rdi, [out_fd]
    mov rsi, asm_jmp_pre
    mov rdx, asm_jmp_pre_len
    call write_all
    mov rax, r14
    mov rdi, [out_fd]
    call write_u64_fd
    mov rdi, [out_fd]
    mov rsi, asm_jz_post
    mov rdx, asm_jz_post_len
    call write_all

    ; Emit: .Lelse:
    mov rdi, [out_fd]
    mov rsi, asm_label_pre
    mov rdx, asm_label_pre_len
    call write_all
    mov rax, r13
    mov rdi, [out_fd]
    call write_u64_fd
    mov rdi, [out_fd]
    mov rsi, asm_label_post
    mov rdx, asm_label_post_len
    call write_all

    ; Emit else body
    mov rdi, r15
    call emit_block
    test rax, rax
    jnz .fail

    ; Emit: .Lend:
    mov rdi, [out_fd]
    mov rsi, asm_label_pre
    mov rdx, asm_label_pre_len
    call write_all
    mov rax, r14
    mov rdi, [out_fd]
    call write_u64_fd
    mov rdi, [out_fd]
    mov rsi, asm_label_post
    mov rdx, asm_label_post_len
    call write_all

    xor rax, rax
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

.no_else:
    ; Emit: .Lelse: (no else body, just the label)
    mov rdi, [out_fd]
    mov rsi, asm_label_pre
    mov rdx, asm_label_pre_len
    call write_all
    mov rax, r13
    mov rdi, [out_fd]
    call write_u64_fd
    mov rdi, [out_fd]
    mov rsi, asm_label_post
    mov rdx, asm_label_post_len
    call write_all

    xor rax, rax
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

.fail:
    mov rax, 1
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; emit_while_stmt: AST structure is
;   while_stmt -> child chain: [condition, body_block]
emit_while_stmt:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r13, [label_counter]
    inc qword [label_counter]
    mov r14, [label_counter]
    inc qword [label_counter]

    ; Push loop context: break -> r14 (exit), continue -> r13 (top)
    mov rdi, r14
    mov rsi, r13
    call loop_context_push

    ; Emit loop-top label: .Ltop:
    mov rdi, [out_fd]
    mov rsi, asm_label_pre
    mov rdx, asm_label_pre_len
    call write_all
    mov rax, r13
    mov rdi, [out_fd]
    call write_u64_fd
    mov rdi, [out_fd]
    mov rsi, asm_label_post
    mov rdx, asm_label_post_len
    call write_all

    ; Get condition (first child of while_stmt)
    mov rdi, r12
    call ast_child
    mov r15, rax
    mov rdi, r15
    call emit_expr
    test rax, rax
    jnz .fail

    ; Emit: test rax,rax / jz .Lexit
    mov rdi, [out_fd]
    mov rsi, asm_jz_pre
    mov rdx, asm_jz_pre_len
    call write_all
    mov rax, r14
    mov rdi, [out_fd]
    call write_u64_fd
    mov rdi, [out_fd]
    mov rsi, asm_jz_post
    mov rdx, asm_jz_post_len
    call write_all

    ; Get body (second child = ast_next(condition))
    mov rdi, r15
    call ast_next
    mov rdi, rax
    call emit_block
    test rax, rax
    jnz .fail

    ; Emit: jmp .Ltop
    mov rdi, [out_fd]
    mov rsi, asm_jmp_pre
    mov rdx, asm_jmp_pre_len
    call write_all
    mov rax, r13
    mov rdi, [out_fd]
    call write_u64_fd
    mov rdi, [out_fd]
    mov rsi, asm_jz_post
    mov rdx, asm_jz_post_len
    call write_all

    ; Emit exit label: .Lexit:
    mov rdi, [out_fd]
    mov rsi, asm_label_pre
    mov rdx, asm_label_pre_len
    call write_all
    mov rax, r14
    mov rdi, [out_fd]
    call write_u64_fd
    mov rdi, [out_fd]
    mov rsi, asm_label_post
    mov rdx, asm_label_post_len
    call write_all

    call loop_context_pop
    xor rax, rax
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

.fail:
    call loop_context_pop
    mov rax, 1
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; emit_loop_stmt: AST structure is
;   loop_stmt -> child chain: [body_block]
emit_loop_stmt:
    push rbx
    push r12
    push r13
    push r14
    mov r12, rdi
    mov r13, [label_counter]
    inc qword [label_counter]
    mov r14, [label_counter]
    inc qword [label_counter]

    ; Push loop context: break -> r14 (exit), continue -> r13 (top)
    mov rdi, r14
    mov rsi, r13
    call loop_context_push

    ; Emit loop-top label: .Ltop:
    mov rdi, [out_fd]
    mov rsi, asm_label_pre
    mov rdx, asm_label_pre_len
    call write_all
    mov rax, r13
    mov rdi, [out_fd]
    call write_u64_fd
    mov rdi, [out_fd]
    mov rsi, asm_label_post
    mov rdx, asm_label_post_len
    call write_all

    ; Get body (first child of loop_stmt)
    mov rdi, r12
    call ast_child
    mov rdi, rax
    call emit_block
    test rax, rax
    jnz .fail

    ; Emit: jmp .Ltop
    mov rdi, [out_fd]
    mov rsi, asm_jmp_pre
    mov rdx, asm_jmp_pre_len
    call write_all
    mov rax, r13
    mov rdi, [out_fd]
    call write_u64_fd
    mov rdi, [out_fd]
    mov rsi, asm_jz_post
    mov rdx, asm_jz_post_len
    call write_all

    ; Emit exit label: .Lexit:
    mov rdi, [out_fd]
    mov rsi, asm_label_pre
    mov rdx, asm_label_pre_len
    call write_all
    mov rax, r14
    mov rdi, [out_fd]
    call write_u64_fd
    mov rdi, [out_fd]
    mov rsi, asm_label_post
    mov rdx, asm_label_post_len
    call write_all

    call loop_context_pop
    xor rax, rax
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

.fail:
    call loop_context_pop
    mov rax, 1
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
