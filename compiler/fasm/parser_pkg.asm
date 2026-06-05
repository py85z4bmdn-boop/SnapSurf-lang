; Implemented foundation subset: surf.pkg required fields and syscall capability.

parse_surf_pkg:
    mov rdi, pkg_buf
    mov rsi, [pkg_len]
    mov rdx, needle_package
    mov rcx, 8
    call contains
    test rax, rax
    jz .missing

    mov rdi, pkg_buf
    mov rsi, [pkg_len]
    mov rdx, needle_version
    mov rcx, 8
    call contains
    test rax, rax
    jz .missing

    mov rdi, pkg_buf
    mov rsi, [pkg_len]
    mov rdx, needle_type
    mov rcx, 15
    call contains
    test rax, rax
    jz .bad_pkg

    mov rdi, pkg_buf
    mov rsi, [pkg_len]
    mov rdx, needle_target
    mov rcx, 19
    call contains
    test rax, rax
    jnz .target_ok
    mov rdi, pkg_buf
    mov rsi, [pkg_len]
    mov rdx, needle_target_win64
    mov rcx, 12
    call contains
    test rax, rax
    jz .bad_target
.target_ok:

    mov rdi, pkg_buf
    mov rsi, [pkg_len]
    mov rdx, needle_runtime
    mov rcx, 12
    call contains
    test rax, rax
    jz .bad_runtime

    mov rdi, pkg_buf
    mov rsi, [pkg_len]
    mov rdx, needle_entry
    mov rcx, 10
    call contains
    test rax, rax
    jz .missing

    mov rdi, pkg_buf
    mov rsi, [pkg_len]
    mov rdx, needle_end
    mov rcx, 3
    call contains
    test rax, rax
    jz .bad_pkg

    mov rdi, pkg_buf
    mov rsi, [pkg_len]
    mov rdx, needle_requires_syscall
    mov rcx, 16
    call contains
    test rax, rax
    jz .ok
    mov byte [has_syscall], 1
.ok:
    xor rax, rax
    ret
.missing:
    mov rdi, pkg_path
    mov rsi, err_missing_field
    call print_diag
    mov rax, 1
    ret
.bad_pkg:
    mov rdi, pkg_path
    mov rsi, err_bad_pkg
    call print_diag
    mov rax, 1
    ret
.bad_target:
    mov rdi, pkg_path
    mov rsi, err_bad_target
    call print_diag
    mov rax, 1
    ret
.bad_runtime:
    mov rdi, pkg_path
    mov rsi, err_bad_runtime
    call print_diag
    mov rax, 1
    ret
