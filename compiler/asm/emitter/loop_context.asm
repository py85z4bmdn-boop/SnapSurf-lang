; emitter/loop_context.asm — Nested loop context stack management.
; Tracks break/continue label targets for nested loop emission.

loop_context_push:
    ; rdi = break label, rsi = continue label
    push rbx
    mov rbx, [loop_depth]
    cmp rbx, SCOPE_CAP
    jae .overflow
    imul rbx, 8
    mov [break_label_stack + rbx], rdi
    mov [continue_label_stack + rbx], rsi
    inc qword [loop_depth]
    pop rbx
    ret
.overflow:
    pop rbx
    ret

loop_context_pop:
    cmp qword [loop_depth], 0
    je .done
    dec qword [loop_depth]
.done:
    ret
