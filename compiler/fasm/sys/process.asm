; Process execution for the FASM generated-program backend.

run_tool:
    mov rax, SYS_FORK
    syscall
    test rax, rax
    js .fail
    jz .child
    mov rdi, rax
    mov rsi, wait_status
    xor rdx, rdx
    xor r10, r10
    mov rax, SYS_WAIT4
    syscall
    test rax, rax
    js .fail
    cmp dword [wait_status], 0
    jne .fail
    xor rax, rax
    ret
.child:
    mov rax, SYS_EXECVE
    syscall
    mov rdi, 127
    jmp exit_process
.fail:
    mov rax, 1
    ret

run_fasm_build:
    mov rdi, fasm_path
    mov rsi, fasm_argv
    xor rdx, rdx
    call run_tool
    test rax, rax
    jnz .fail
    xor rax, rax
    ret
.fail:
    mov rdi, asm_path
    mov rsi, err_build_failed
    call print_diag
    mov rax, 1
    ret
