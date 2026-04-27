%include "compiler/inc/syscalls.inc"
%include "compiler/inc/constants.inc"
%include "compiler/inc/errors.inc"
%include "compiler/inc/tokens.inc"
%include "compiler/inc/ast.inc"

global _start

section .text
_start:
    mov r12, [rsp]
    lea r13, [rsp + 8]
    cmp r12, 2
    jl .usage

    mov rdi, [r13 + 8]
    call cli_known_command
    test rax, rax
    jz .usage

    mov rdi, [r13 + 8]
    mov rsi, cmd_version
    call streq
    test rax, rax
    jnz .version

    mov rdi, [r13 + 8]
    mov rsi, cmd_clean
    call streq
    test rax, rax
    jnz .clean

    cmp r12, 3
    jl .usage

    mov rdi, [r13 + 8]
    mov rsi, cmd_check
    call streq
    test rax, rax
    jnz .check

    mov rdi, [r13 + 8]
    mov rsi, cmd_emit_asm
    call streq
    test rax, rax
    jnz .emit_asm

    mov rdi, [r13 + 8]
    mov rsi, cmd_build
    call streq
    test rax, rax
    jnz .build

    mov rdi, [r13 + 8]
    mov rsi, cmd_dump_tokens
    call streq
    test rax, rax
    jnz .dump_tokens

    mov rdi, [r13 + 8]
    mov rsi, cmd_dump_ast
    call streq
    test rax, rax
    jnz .dump_ast

.usage:
    mov rdi, usage_msg
    call print_stderr_z
    mov rdi, EXIT_USAGE
    jmp exit_process

.version:
    mov rdi, version_msg
    call print_stdout_z
    xor rdi, rdi
    jmp exit_process

.clean:
    mov rdi, clean_msg
    call print_stdout_z
    xor rdi, rdi
    jmp exit_process

.check:
    mov byte [emit_requested], 0
    mov rdi, [r13 + 16]
    call compile_package
    test rax, rax
    jnz .err
    mov rdi, check_ok_msg
    call print_stdout_z
    xor rdi, rdi
    jmp exit_process

.emit_asm:
    mov byte [emit_requested], 1
    mov rdi, [r13 + 16]
    call compile_package
    test rax, rax
    jnz .err
    call emit_main_asm
    test rax, rax
    jnz .err
    mov rdi, emit_ok_msg
    call print_stdout_z
    xor rdi, rdi
    jmp exit_process

.build:
    mov byte [emit_requested], 1
    mov rdi, [r13 + 16]
    call compile_package
    test rax, rax
    jnz .err
    call emit_main_asm
    test rax, rax
    jnz .err
    call run_nasm_and_ld
    test rax, rax
    jnz .err
    mov rdi, build_ok_msg
    call print_stdout_z
    xor rdi, rdi
    jmp exit_process

.dump_tokens:
    mov rdi, [r13 + 16]
    call load_package_and_lex
    test rax, rax
    jnz .err
    call dump_tokens
    xor rdi, rdi
    jmp exit_process

.dump_ast:
    mov rdi, [r13 + 16]
    call compile_package
    test rax, rax
    jnz .err
    call dump_ast
    xor rdi, rdi
    jmp exit_process

.err:
    mov rdi, EXIT_ERR
    jmp exit_process

exit_process:
    mov rax, SYS_EXIT
    syscall

print_stdout_z:
    mov rsi, rdi
    call strlen
    mov rdx, rax
    mov rdi, 1
    mov rax, SYS_WRITE
    syscall
    ret

print_stderr_z:
    mov rsi, rdi
    call strlen
    mov rdx, rax
    mov rdi, 2
    mov rax, SYS_WRITE
    syscall
    ret

write_all:
    mov rax, SYS_WRITE
    syscall
    ret

strlen:
    xor rax, rax
.loop:
    cmp byte [rsi + rax], 0
    je .done
    inc rax
    jmp .loop
.done:
    ret

streq:
    xor rax, rax
.loop:
    mov bl, [rdi]
    cmp bl, [rsi]
    jne .no
    test bl, bl
    je .yes
    inc rdi
    inc rsi
    jmp .loop
.yes:
    mov rax, 1
.no:
    ret

contains:
    push rbx
    push r12
    push r13
    mov r12, rdi
    mov r13, rsi
    cmp rcx, 0
    je .not_found
    cmp r13, rcx
    jb .not_found
.outer:
    mov rbx, 0
.inner:
    cmp rbx, rcx
    je .found
    mov al, [r12 + rbx]
    cmp al, [rdx + rbx]
    jne .next
    inc rbx
    jmp .inner
.next:
    inc r12
    dec r13
    cmp r13, rcx
    jae .outer
.not_found:
    xor rax, rax
    pop r13
    pop r12
    pop rbx
    ret
.found:
    mov rax, r12
    pop r13
    pop r12
    pop rbx
    ret

copy_z:
    xor rax, rax
.loop:
    mov bl, [rsi + rax]
    mov [rdi + rax], bl
    inc rax
    test bl, bl
    jne .loop
    dec rax
    ret

append_z:
    push rdi
    push rsi
    mov rsi, rdi
    call strlen
    pop rsi
    pop rdi
    add rdi, rax
    call copy_z
    ret

make_path:
    push rsi
    push rdx
    mov rsi, rdi
    mov rdi, rdx
    call copy_z
    pop rdx
    pop rsi
    mov rdi, rdx
    call append_z
    ret

open_read:
    mov rax, SYS_OPEN
    mov rsi, O_RDONLY
    xor rdx, rdx
    syscall
    ret

file_exists:
    call open_read
    test rax, rax
    js .no
    mov rdi, rax
    mov rax, SYS_CLOSE
    syscall
    mov rax, 1
    ret
.no:
    xor rax, rax
    ret

read_file:
    push r12
    push r13
    mov r12, rsi
    mov r13, rdx
    call open_read
    test rax, rax
    js .fail
    mov r8, rax
    mov rax, SYS_READ
    mov rdi, r8
    mov rsi, r12
    mov rdx, r13
    syscall
    push rax
    mov rdi, r8
    mov rax, SYS_CLOSE
    syscall
    pop rax
    test rax, rax
    js .fail
    pop r13
    pop r12
    ret
.fail:
    mov rax, -1
    pop r13
    pop r12
    ret

mkdir_build:
    mov rax, SYS_MKDIR
    mov rdi, build_dir
    mov rsi, 0755o
    syscall
    ret

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

run_nasm_and_ld:
    mov rdi, nasm_path
    mov rsi, nasm_argv
    xor rdx, rdx
    call run_tool
    test rax, rax
    jnz .fail
    mov rdi, ld_path
    mov rsi, ld_argv
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

%include "compiler/asm/diagnostics.asm"
%include "compiler/asm/cli.asm"
%include "compiler/asm/ast.asm"
%include "compiler/asm/source_reader.asm"
%include "compiler/asm/utf8.asm"
%include "compiler/asm/parser_pkg.asm"
%include "compiler/asm/lexer.asm"
%include "compiler/asm/parser_source.asm"
%include "compiler/asm/semantic.asm"
%include "compiler/asm/capability.asm"
%include "compiler/asm/emitter_nasm.asm"

section .data
cmd_version: db "version", 0
cmd_check: db "check", 0
cmd_emit_asm: db "emit-asm", 0
cmd_build: db "build", 0
cmd_clean: db "clean", 0
cmd_dump_tokens: db "dump-tokens", 0
cmd_dump_ast: db "dump-ast", 0

version_msg: db "surf asm-foundation 0.1-in-progress", 10, 0
usage_msg: db "usage: surf <version|check|emit-asm|build|clean|dump-tokens|dump-ast> [package_dir]", 10, 0
check_ok_msg: db "check ok", 10, 0
emit_ok_msg: db "build/main.asm", 10, 0
build_ok_msg: db "build/hello", 10, 0
clean_msg: db "clean is handled by make clean", 10, 0

suffix_pkg: db "/surf.pkg", 0
suffix_main: db "/src/main.snapsurf", 0
suffix_bad_surf: db "/src/main.surf", 0
build_dir: db "build", 0
asm_path: db "build/main.asm", 0
obj_path: db "build/main.o", 0
hello_path: db "build/hello", 0
nasm_path: db "/usr/bin/nasm", 0
ld_path: db "/usr/bin/ld", 0
nasm_arg0: db "nasm", 0
nasm_arg1: db "-f", 0
nasm_arg2: db "elf64", 0
nasm_arg3: db "-o", 0
ld_arg0: db "ld", 0
ld_arg1: db "-o", 0
nasm_argv: dq nasm_arg0, nasm_arg1, nasm_arg2, asm_path, nasm_arg3, obj_path, 0
ld_argv: dq ld_arg0, ld_arg1, hello_path, obj_path, 0

needle_package: db "package ", 0
needle_version: db "version ", 0
needle_type: db "type executable", 0
needle_type_any: db "type ", 0
needle_target: db "target linux-x86_64", 0
needle_target_any: db "target ", 0
needle_runtime: db "runtime tiny", 0
needle_runtime_any: db "runtime ", 0
needle_entry: db "entry main", 0
needle_requires_syscall: db "requires syscall", 0
needle_end: db "end", 0

needle_use_io: db "use core/io", 0
needle_fn_main_i32: db "fn main -> i32", 0
needle_fn_main: db "fn main", 0
needle_io_write: db "io.write", 0
needle_ret_0: db "ret 0", 0
needle_lbrace: db "{", 0
needle_rbrace: db "}", 0

err_bom: db "E0001 UTF-8 BOM is not allowed", 0
err_utf8: db "E0002 invalid UTF-8 sequence", 0
err_ext: db "E0003 source file must use .snapsurf extension", 0
err_unterm_string: db "E0101 unterminated string literal", 0
err_bad_escape: db "E0102 invalid escape sequence", 0
err_bad_char: db "E0103 invalid character", 0
err_eof: db "E0104 unexpected EOF", 0
err_token_overflow: db "E0105 token buffer overflow", 0
err_expected: db "E0201 expected token", 0
err_missing_end: db "E0202 missing end", 0
err_unexpected_end: db "E0203 unexpected end", 0
err_bad_fn: db "E0204 invalid function declaration", 0
err_bad_use: db "E0205 invalid use declaration", 0
err_no_main: db "E0401 main function not found", 0
err_bad_main: db "E0402 invalid main signature", 0
err_ret: db "E0403 return type mismatch", 0
err_unsup_expr: db "E0404 unsupported expression in foundation", 0
err_len_mismatch: db "E0404 string literal length does not match explicit io.write length", 0
err_ast_overflow: db "E0301 AST arena overflow", 0
err_cap: db "E0801 missing required capability", 0
err_syscall_cap: db "E0802 syscall used without requires syscall", 0
err_no_pkg: db "E0901 surf.pkg not found", 0
err_bad_pkg: db "E0902 invalid surf.pkg", 0
err_missing_field: db "E0903 missing required package field", 0
err_bad_target: db "E0904 unsupported target", 0
err_bad_runtime: db "E0905 unsupported runtime", 0
err_no_main_src: db "E0906 executable package requires src/main.snapsurf", 0
err_emit_failed: db "E1001 NASM emit failed", 0
err_artifact: db "E1002 build artifact path error", 0
err_build_failed: db "E1001 NASM emit failed", 0

colon_z: db ":", 0
space_z: db " ", 0
newline_z: db 10, 0

asm_pre: db "default rel",10,"global _start",10,"section .text",10,"_start:",10,"    call main",10,"    mov edi, eax",10,"    mov eax, 60",10,"    syscall",10,10,"main:",10,"    push rbp",10,"    mov rbp, rsp",10
asm_pre_len: equ $ - asm_pre
asm_write_pre: db "    mov rax, 1",10,"    mov rdi, 1",10,"    lea rsi, [rel .Lstr0]",10,"    mov rdx, "
asm_write_pre_len: equ $ - asm_write_pre
asm_write_post: db 10,"    syscall",10
asm_write_post_len: equ $ - asm_write_post
asm_ret_pre: db "    mov eax, "
asm_ret_pre_len: equ $ - asm_ret_pre
asm_ret_post: db 10,"    mov rsp, rbp",10,"    pop rbp",10,"    ret",10,10,"section .rodata",10,".Lstr0:",10,"    db "
asm_ret_post_len: equ $ - asm_ret_post
asm_final_newline: db 10
comma_space: db ", "
text_core: db "core", 0
text_io: db "io", 0
text_main: db "main", 0
text_i32: db "i32", 0
text_write: db "write", 0

tok_name_eof: db "TokEof", 10, 0
tok_name_ident: db "TokIdent", 10, 0
tok_name_int: db "TokIntLit", 10, 0
tok_name_str: db "TokStrLit", 10, 0
tok_name_error: db "TokError", 10, 0
tok_name_use: db "TokUse", 10, 0
tok_name_fn: db "TokFn", 10, 0
tok_name_ret: db "TokRet", 10, 0
tok_name_end: db "TokEnd", 10, 0
tok_name_true: db "TokTrue", 10, 0
tok_name_false: db "TokFalse", 10, 0
tok_name_arrow: db "TokArrow", 10, 0
tok_name_dot: db "TokDot", 10, 0
tok_name_slash: db "TokSlash", 10, 0
tok_name_comma: db "TokComma", 10, 0
tok_name_eq: db "TokEq", 10, 0
tok_name_newline: db "TokNewline", 10, 0
tok_name_unknown: db "TokUnknown", 10, 0

ast_name_source: db "AstSourceFile", 10, 0
ast_name_use: db "AstUseDecl", 10, 0
ast_name_fn: db "AstFnDecl", 10, 0
ast_name_block: db "AstBlock", 10, 0
ast_name_ret: db "AstRetStmt", 10, 0
ast_name_call: db "AstCallStmt", 10, 0
ast_name_int: db "AstIntLit", 10, 0
ast_name_str: db "AstStrLit", 10, 0
ast_name_ident: db "AstIdent", 10, 0
ast_name_path: db "AstPath", 10, 0
ast_name_error: db "AstError", 10, 0
ast_name_unknown: db "AstUnknown", 10, 0

section .bss
pkg_path: resb MAX_PATH
src_path: resb MAX_PATH
surf_path: resb MAX_PATH
pkg_buf: resb MAX_FILE
src_buf: resb MAX_FILE
str_buf: resb MAX_STRING
num_buf: resb 32
pkg_len: resq 1
src_len: resq 1
parsed_str_len: resq 1
parsed_io_len: resq 1
has_syscall: resb 1
has_io_write: resb 1
emit_requested: resb 1
out_fd: resq 1
wait_status: resq 1
diag_line: resq 1
diag_col: resq 1
token_count: resq 1
token_index: resq 1
token_buf: resb TOKEN_CAP * TOKEN_SIZE
string_pool_len: resq 1
ast_count: resq 1
ast_root: resq 1
ast_main_fn: resq 1
ast_block_node: resq 1
ast_call_stmt: resq 1
ast_ret_stmt: resq 1
ast_error_flag: resq 1
tmp_payload: resq 1
tmp_ast_a: resq 1
tmp_ast_b: resq 1
tmp_ast_c: resq 1
parsed_ret_value: resq 1
ast_buf: resb AST_CAP * AST_SIZE
