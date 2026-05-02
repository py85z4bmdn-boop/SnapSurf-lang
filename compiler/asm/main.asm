%include "compiler/inc/syscalls.inc"
%include "compiler/inc/calling_conv.inc"
%include "compiler/inc/constants.inc"
%include "compiler/inc/types.inc"
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

%include "compiler/asm/core/string.asm"
%include "compiler/asm/core/io.asm"
%include "compiler/asm/sys/file.asm"
%include "compiler/asm/sys/process.asm"

%include "compiler/asm/diagnostics.asm"
%include "compiler/asm/cli.asm"
%include "compiler/asm/ast.asm"
%include "compiler/asm/ast_traversal.asm"
%include "compiler/asm/source_reader.asm"
%include "compiler/asm/utf8.asm"
%include "compiler/asm/parser_pkg.asm"
%include "compiler/asm/lexer.asm"
%include "compiler/asm/lexer_string_pool.asm"
%include "compiler/asm/token_buffer.asm"
%include "compiler/asm/lexer_keywords.asm"
%include "compiler/asm/lexer_debug.asm"
%include "compiler/asm/parser_source.asm"
%include "compiler/asm/parser_expr.asm"
%include "compiler/asm/parser_nodes.asm"
%include "compiler/asm/parser_match.asm"
%include "compiler/asm/semantic.asm"
%include "compiler/asm/semantic_types.asm"
%include "compiler/asm/semantic_scope.asm"
%include "compiler/asm/semantic_expr.asm"
%include "compiler/asm/semantic_calls.asm"
%include "compiler/asm/semantic_symbols.asm"
%include "compiler/asm/semantic_diagnostics.asm"
%include "compiler/asm/capability.asm"
%include "compiler/asm/emitter_nasm.asm"
%include "compiler/asm/emitter_expr.asm"
%include "compiler/asm/emitter_control.asm"
%include "compiler/asm/emitter_instructions.asm"
%include "compiler/asm/emitter_writer.asm"

; Optimization passes
%include "compiler/asm/opt/dead_code_elimination.asm"
%include "compiler/asm/opt/optimizer.asm"

; Performance optimization modules
%include "compiler/asm/opt/memops.asm"
%include "compiler/asm/opt/strtab.asm"
%include "compiler/asm/opt/hash.asm"
%include "compiler/asm/opt/arena.asm"
%include "compiler/asm/opt/chartab.asm"
%include "compiler/asm/opt/writebuf.asm"
%include "compiler/asm/opt/faststr.asm"
%include "compiler/asm/opt/intconv.asm"

%include "compiler/asm/data/cli.asm"
%include "compiler/asm/data/paths.asm"
%include "compiler/asm/data/pkg_grammar.asm"
%include "compiler/asm/data/diagnostics.asm"
%include "compiler/asm/data/emitter_templates.asm"
%include "compiler/asm/data/source_text.asm"
%include "compiler/asm/data/token_names.asm"
%include "compiler/asm/data/ast_names.asm"

%include "compiler/asm/state/files.asm"
%include "compiler/asm/state/diagnostics.asm"
%include "compiler/asm/state/tokens.asm"
%include "compiler/asm/state/ast.asm"
%include "compiler/asm/state/semantic.asm"
%include "compiler/asm/state/emitter.asm"
%include "compiler/asm/state/process.asm"
%include "compiler/asm/state/scratch.asm"
