format ELF64 executable 3
entry _start
include "compiler/fasm/inc/syscalls.inc"
include "compiler/fasm/inc/calling_conv.inc"
include "compiler/fasm/inc/constants.inc"
include "compiler/fasm/inc/types.inc"
include "compiler/fasm/inc/errors.inc"
include "compiler/fasm/inc/tokens.inc"
include "compiler/fasm/inc/ast.inc"


segment readable executable
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
    mov rsi, cmd_build_raw
    call streq
    test rax, rax
    jnz .build_raw

    mov rdi, [r13 + 8]
    mov rsi, cmd_build_fasm
    call streq
    test rax, rax
    jnz .build_fasm

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

    mov rdi, [r13 + 8]
    mov rsi, cmd_colorize
    call streq
    test rax, rax
    jnz .colorize

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
    call run_fasm_build
    test rax, rax
    jnz .err
    mov rdi, build_ok_msg
    call print_stdout_z
    xor rdi, rdi
    jmp exit_process

.build_raw:
    mov byte [emit_requested], 1
    mov rdi, [r13 + 16]
    call compile_package
    test rax, rax
    jnz .err
    call emit_raw_binary_asm
    test rax, rax
    jnz .err
    call run_fasm_raw_build
    test rax, rax
    jnz .err
    mov rdi, build_raw_ok_msg
    call print_stdout_z
    xor rdi, rdi
    jmp exit_process

.build_fasm:
    mov byte [emit_requested], 1
    mov rdi, [r13 + 16]
    call compile_package
    test rax, rax
    jnz .err
    call emit_fasm_direct_asm
    test rax, rax
    jnz .err
    call run_fasm_direct_build
    test rax, rax
    jnz .err
    mov rdi, build_fasm_ok_msg
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

.colorize:
    mov rdi, [r13 + 16]
    call load_package_and_lex
    test rax, rax
    jnz .err
    call colorize_source
    xor rdi, rdi
    jmp exit_process

.err:
    mov rdi, EXIT_ERR
    jmp exit_process

exit_process:
    mov rax, SYS_EXIT
    syscall

include "compiler/fasm/core/string.asm"
include "compiler/fasm/core/io.asm"
include "compiler/fasm/sys/file.asm"
include "compiler/fasm/sys/process.asm"

include "compiler/fasm/diagnostics.asm"
include "compiler/fasm/cli.asm"
include "compiler/fasm/ast.asm"
include "compiler/fasm/ast_traversal.asm"
include "compiler/fasm/source_reader.asm"
include "compiler/fasm/utf8.asm"
include "compiler/fasm/parser_pkg.asm"
include "compiler/fasm/lexer.asm"
include "compiler/fasm/lexer_string_pool.asm"
include "compiler/fasm/token_buffer.asm"
include "compiler/fasm/lexer_keywords.asm"
include "compiler/fasm/lexer_debug.asm"
include "compiler/fasm/parser_source.asm"
include "compiler/fasm/parser_expr.asm"
include "compiler/fasm/parser_nodes.asm"
include "compiler/fasm/parser_match.asm"
include "compiler/fasm/semantic.asm"
include "compiler/fasm/semantic_types.asm"
include "compiler/fasm/semantic_scope.asm"
include "compiler/fasm/semantic_expr.asm"
include "compiler/fasm/semantic_calls.asm"
include "compiler/fasm/semantic_symbols.asm"
include "compiler/fasm/semantic_diagnostics.asm"
include "compiler/fasm/capability.asm"
include "compiler/fasm/emitter_fasm.asm"
include "compiler/fasm/emitter_expr.asm"
include "compiler/fasm/emitter_control.asm"
include "compiler/fasm/emitter_instructions.asm"
include "compiler/fasm/emitter_writer.asm"

; Syntax coloring
include "compiler/fasm/colorize.asm"

; Optimization passes
include "compiler/fasm/opt/dead_code_elimination.asm"
include "compiler/fasm/opt/optimizer.asm"

; Performance optimization modules
include "compiler/fasm/opt/memops.asm"
include "compiler/fasm/opt/strtab.asm"
include "compiler/fasm/opt/hash.asm"
include "compiler/fasm/opt/arena.asm"
include "compiler/fasm/opt/chartab.asm"
include "compiler/fasm/opt/writebuf.asm"
include "compiler/fasm/opt/faststr.asm"
include "compiler/fasm/opt/intconv.asm"

include "compiler/fasm/data/cli.asm"
include "compiler/fasm/data/paths.asm"
include "compiler/fasm/data/pkg_grammar.asm"
include "compiler/fasm/data/diagnostics.asm"
include "compiler/fasm/data/emitter_templates.asm"
include "compiler/fasm/data/source_text.asm"
include "compiler/fasm/data/token_names.asm"
include "compiler/fasm/data/ast_names.asm"
include "compiler/fasm/data/ansi_colors.asm"

include "compiler/fasm/state/files.asm"
include "compiler/fasm/state/diagnostics.asm"
include "compiler/fasm/state/tokens.asm"
include "compiler/fasm/state/ast.asm"
include "compiler/fasm/state/semantic.asm"
include "compiler/fasm/state/emitter.asm"
include "compiler/fasm/state/process.asm"
include "compiler/fasm/state/scratch.asm"
