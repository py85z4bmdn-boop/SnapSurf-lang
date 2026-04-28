; Internal compiler register convention for handwritten NASM.
;
; Every procedure must be readable against this contract before it is extended.
;
; Scratch across internal calls:
;   rax, rcx, rdx, rsi, rdi, r8, r9, r10, r11
;
; Preserved by procedures that use them:
;   rbx, r12, r13, r14, r15, rbp, rsp
;
; Current compiler-wide state lives in memory, not in long-lived registers:
;   token_index, token_count, ast_count, sym_count, local_count
;
; Recursive parser rule:
;   State that must survive a recursive parse call must be pushed on the stack
;   or stored in an explicit memory slot. Do not rely on r12-r15 for recursive
;   parser state unless the procedure saves and restores them around every call.
;
; Generated program ABI:
;   System V AMD64. Integer return values are emitted in rax. The foundation
;   emitter currently allocates i32 locals as 8-byte stack slots under rbp.
