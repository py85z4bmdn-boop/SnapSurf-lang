; SnapSurf panic abort for runtime tiny.
; Implemented minimal abort path: exit(101).

global snapsurf_panic_abort

section .text
snapsurf_panic_abort:
    mov edi, 101
    mov eax, 60
    syscall

