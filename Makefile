ASM_COMPILER_SOURCES = \
	compiler/asm/main.asm \
	compiler/asm/core/io.asm \
	compiler/asm/core/string.asm \
	compiler/asm/sys/file.asm \
	compiler/asm/sys/process.asm \
	compiler/asm/cli.asm \
	compiler/asm/diagnostics.asm \
	compiler/asm/source_reader.asm \
	compiler/asm/utf8.asm \
	compiler/asm/lexer.asm \
	compiler/asm/lexer_string_pool.asm \
	compiler/asm/token_buffer.asm \
	compiler/asm/lexer_keywords.asm \
	compiler/asm/lexer_debug.asm \
	compiler/asm/parser_pkg.asm \
	compiler/asm/parser_source.asm \
	compiler/asm/parser_expr.asm \
	compiler/asm/parser_nodes.asm \
	compiler/asm/parser_match.asm \
	compiler/asm/ast.asm \
	compiler/asm/ast_traversal.asm \
	compiler/asm/semantic.asm \
	compiler/asm/semantic_types.asm \
	compiler/asm/semantic_scope.asm \
	compiler/asm/semantic_expr.asm \
	compiler/asm/semantic_calls.asm \
	compiler/asm/semantic_symbols.asm \
	compiler/asm/semantic_diagnostics.asm \
	compiler/asm/capability.asm \
	compiler/asm/emitter_nasm.asm \
	compiler/asm/emitter_expr.asm \
	compiler/asm/emitter_control.asm \
	compiler/asm/emitter_instructions.asm \
	compiler/asm/emitter_writer.asm \
	compiler/asm/data/cli.asm \
	compiler/asm/data/paths.asm \
	compiler/asm/data/pkg_grammar.asm \
	compiler/asm/data/diagnostics.asm \
	compiler/asm/data/emitter_templates.asm \
	compiler/asm/data/source_text.asm \
	compiler/asm/data/token_names.asm \
	compiler/asm/data/ast_names.asm \
	compiler/asm/state/files.asm \
	compiler/asm/state/diagnostics.asm \
	compiler/asm/state/tokens.asm \
	compiler/asm/state/ast.asm \
	compiler/asm/state/semantic.asm \
	compiler/asm/state/emitter.asm \
	compiler/asm/state/process.asm \
	compiler/asm/state/scratch.asm \
	compiler/inc/constants.inc \
	compiler/inc/types.inc \
	compiler/inc/calling_conv.inc \
	compiler/inc/errors.inc \
	compiler/inc/tokens.inc \
	compiler/inc/ast.inc \
	compiler/inc/syscalls.inc

.PHONY: all clean check test emit-hello-asm build-hello run-hello test-rust-prototype

all: build/surf

build/surf: $(ASM_COMPILER_SOURCES)
	mkdir -p build
	nasm -f elf64 compiler/asm/main.asm -o build/surf.o
	ld build/surf.o -o build/surf

check: build/surf
	./build/surf check examples/hello

emit-hello-asm: build/surf
	./build/surf emit-asm examples/hello

build-hello: build/surf
	./build/surf build examples/hello

run-hello: build-hello
	./build/hello

test: build/surf
	sh tests/run_all.sh

clean:
	rm -rf build

test-rust-prototype:
	cd prototypes/rust_stage0 && cargo test
