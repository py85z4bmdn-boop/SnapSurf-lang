; SnapSurf linux-x86_64 syscall helpers.
; Implemented reference wrapper for write(fd, ptr, len).

global snapsurf_sys_write

section .text
snapsurf_sys_write:
    mov eax, 1
    syscall
    ret

