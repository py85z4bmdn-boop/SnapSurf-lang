# SnapSurf

SnapSurf is a foundation-stage systems language project for Linux x86_64.

Current truthful status:

- ASM/NASM foundation is in progress.
- `build/surf` is now built from NASM/x86_64 assembly in [compiler/asm](compiler/asm).
- The ASM compiler supports the minimal hello-world foundation subset.
- The Rust Stage 0 compiler remains isolated in [prototypes/rust_stage0](prototypes/rust_stage0) and is not used by root `make` or `make test`.

Correct current claim:

> ASM/NASM foundation slice can compile the hello-world package through NASM/ld.

Still forbidden:

> ASM/NASM foundation complete.

## Root Commands

These commands do not use Cargo, Rust, Python, Node, GCC, Clang, Zig, or Go.

```sh
make
./build/surf version
./build/surf check examples/hello
./build/surf emit-asm examples/hello
./build/surf build examples/hello
./build/hello
make test
make clean
```

Expected hello output:

```text
Hello SnapSurf
```

## Implemented In ASM/NASM

- CLI: `version`, `check`, `emit-asm`, `build`, `clean`
- `surf.pkg` read and minimal required field validation
- package layout validation for `src/main.snapsurf`
- `.surf` rejection when it is used instead of `main.snapsurf`
- UTF-8 BOM rejection
- strict UTF-8 validation
- token buffer for the source lexer, with spans and `TokEof`
- AST arena for the parsed source subset
- parser subset for `use core/io`, `fn main -> i32`, `io.write`, `ret 0`, `end`
- semantic/capability checks read AST nodes, not raw-source global flags
- deterministic `build/main.asm` generation from AST-derived string, length, and return literal data
- ELF64 hello binary through `nasm` and `ld`
- default `make test` includes a source-string anti-hardcode check and binary
  origin checks against Cargo/Rust/prototype references
- debug commands: `dump-tokens`, `dump-ast`

## Not Complete

The project is not self-hosting and the foundation is not complete. Remaining
major gaps include full token stream, full AST arena, real Pratt expression
parser, broader semantic checker, ownership checker, lockfile resolver, package
registry, formatter, optimizer, LSP, and self-hosting.

The Rust prototype is still useful as a reference only:

```sh
make test-rust-prototype
```

That target is optional and is not part of root `make` or `make test`.
