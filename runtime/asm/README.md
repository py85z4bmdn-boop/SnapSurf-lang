# SnapSurf ASM Runtime

Status: in progress.

Implemented reference modules:

- `start_linux_x86_64.asm`: `_start`, call `main`, Linux `exit` syscall
- `syscall_linux_x86_64.asm`: minimal write syscall wrapper
- `panic_abort.asm`: minimal abort path

Current compiler behavior:

`build/surf` emits equivalent runtime tiny startup code directly into
`build/main.asm` for the hello-world foundation slice. Splitting generated code
from runtime object linkage is a next step.

