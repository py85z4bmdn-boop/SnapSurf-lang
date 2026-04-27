ASM_COMPILER_SOURCES = \
	compiler/asm/main.asm \
	compiler/asm/cli.asm \
	compiler/asm/diagnostics.asm \
	compiler/asm/source_reader.asm \
	compiler/asm/utf8.asm \
	compiler/asm/lexer.asm \
	compiler/asm/parser_pkg.asm \
	compiler/asm/parser_source.asm \
	compiler/asm/ast.asm \
	compiler/asm/semantic.asm \
	compiler/asm/capability.asm \
	compiler/asm/emitter_nasm.asm \
	compiler/inc/constants.inc \
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
