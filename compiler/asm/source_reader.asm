; Implemented foundation subset: package/source path construction and reads.

compile_package:
    call load_package_and_lex
    test rax, rax
    jnz .fail

    call parse_source_subset
    test rax, rax
    jnz .fail

    call semantic_check_subset
    test rax, rax
    jnz .fail

    call capability_check_subset
    test rax, rax
    jnz .fail

    xor rax, rax
    ret
.fail:
    mov rax, 1
    ret

load_package_and_lex:
    push r12
    mov r12, rdi
    mov byte [has_syscall], 0
    call ast_reset
    mov qword [diag_line], 1
    mov qword [diag_col], 1

    mov rdi, r12
    mov rsi, suffix_pkg
    mov rdx, pkg_path
    call make_path

    mov rdi, pkg_path
    mov rsi, pkg_buf
    mov rdx, MAX_FILE - 1
    call read_file
    test rax, rax
    js .no_pkg
    mov [pkg_len], rax
    mov byte [pkg_buf + rax], 0

    call parse_surf_pkg
    test rax, rax
    jnz .fail

    mov rdi, r12
    mov rsi, suffix_main
    mov rdx, src_path
    call make_path

    mov rdi, src_path
    mov rsi, src_buf
    mov rdx, MAX_FILE - 1
    call read_file
    test rax, rax
    js .missing_source
    mov [src_len], rax
    mov byte [src_buf + rax], 0

    call validate_source_bytes
    test rax, rax
    jnz .fail

    call lex_source_subset
    test rax, rax
    jnz .fail

    xor rax, rax
    pop r12
    ret

.no_pkg:
    mov rdi, pkg_path
    mov rsi, err_no_pkg
    call print_diag
    mov rax, 1
    pop r12
    ret

.missing_source:
    mov rdi, r12
    mov rsi, suffix_bad_surf
    mov rdx, surf_path
    call make_path
    mov rdi, surf_path
    call file_exists
    test rax, rax
    jnz .bad_extension
    mov rdi, src_path
    mov rsi, err_no_main_src
    call print_diag
    mov rax, 1
    pop r12
    ret

.bad_extension:
    mov rdi, surf_path
    mov rsi, err_ext
    call print_diag
    mov rax, 1
    pop r12
    ret

.fail:
    mov rax, 1
    pop r12
    ret

