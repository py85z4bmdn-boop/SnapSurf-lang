; Implemented foundation subset: command recognition for the tiny CLI.

cli_known_command:
    push rdi
    mov rsi, cmd_version
    call streq
    test rax, rax
    jnz .yes_pop

    pop rdi
    push rdi
    mov rsi, cmd_check
    call streq
    test rax, rax
    jnz .yes_pop

    pop rdi
    push rdi
    mov rsi, cmd_emit_asm
    call streq
    test rax, rax
    jnz .yes_pop

    pop rdi
    push rdi
    mov rsi, cmd_build
    call streq
    test rax, rax
    jnz .yes_pop

    pop rdi
    push rdi
    mov rsi, cmd_build_raw
    call streq
    test rax, rax
    jnz .yes_pop

    pop rdi
    push rdi
    mov rsi, cmd_build_fasm
    call streq
    test rax, rax
    jnz .yes_pop

    pop rdi
    push rdi
    mov rsi, cmd_clean
    call streq
    test rax, rax
    jnz .yes_pop

    pop rdi
    push rdi
    mov rsi, cmd_dump_tokens
    call streq
    test rax, rax
    jnz .yes_pop

    pop rdi
    push rdi
    mov rsi, cmd_dump_ast
    call streq
    test rax, rax
    jnz .yes_pop

    pop rdi
    push rdi
    mov rsi, cmd_colorize
    call streq
    test rax, rax
    jnz .yes_pop

    pop rdi
    xor rax, rax
    ret

.yes_pop:
    pop rdi
    mov rax, 1
    ret
