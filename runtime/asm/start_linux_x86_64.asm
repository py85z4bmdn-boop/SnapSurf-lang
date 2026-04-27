; SnapSurf runtime tiny for linux-x86_64.
; Implemented reference runtime module.
; The current foundation compiler emits equivalent _start code directly into
; build/main.asm; this module is kept as the standalone runtime source of truth
; for the next link-split step.

global _start
extern main

section .text
_start:
    call main
    mov edi, eax
    mov eax, 60
    syscall

