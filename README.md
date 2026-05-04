# SnapSurf

SnapSurf is a foundation-stage systems language project for Linux x86_64.

Current truthful status:

- ASM/NASM foundation is in progress.
- `build/surf` is now built from NASM/x86_64 assembly in [compiler/asm](compiler/asm).
- The ASM compiler supports the foundation v0 expression/local subset.
- The Rust Stage 0 compiler remains isolated in [prototypes/rust_stage0](prototypes/rust_stage0) and is not used by root `make` or `make test`.

Correct current claim:

> ASM/NASM foundation slice can compile hello-world and small integer/local packages through NASM/ld.

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
- parser subset for `use core/io`, `fn main -> i32`, `io.write`, `let`, `mut`, assignment, `ret expr`, and `end`
- Pratt expression parser for integer literals, variable references, parentheses, unary `-`, and `+ - * / %`
- semantic support for same-width primitive integer locals beyond `i32`, with no implicit integer-width coercion
- pointer type interning plus `&x`/`*p` expression checking and stack-address codegen
- fixed-size array type interning, stack slot reservation, and `arr[i]` address-based load codegen
- strict top-level token rejection after function declarations
- fixed-capacity single-function symbol table for local bindings, duplicate detection, undefined-symbol detection, immutable-assignment rejection, and fail-closed overflow diagnostics
- semantic validation for `break`/`continue` placement and conservative function return-path coverage
- explicit foundation type ID and descriptor table in [compiler/inc/types.inc](compiler/inc/types.inc); only `i32` locals are accepted today
- fixed-capacity scope stack primitives exist for future nested blocks, but source syntax still has only the function-root scope
- documented internal register convention in [compiler/inc/calling_conv.inc](compiler/inc/calling_conv.inc)
- semantic/capability checks read AST nodes, not raw-source global flags
- deterministic `build/main.asm` generation from AST-derived string data, stack locals, load/store operations, arithmetic instructions, and return expressions
- mutable declarations use `mut x i32 = expr`; `let mut x ...` is intentionally rejected in v0
- ELF64 hello binary through `nasm` and `ld`
- default `make test` includes a source-string anti-hardcode check and binary
  origin checks against Cargo/Rust/prototype references
- debug commands: `dump-tokens`, `dump-ast`

## Not Complete

The project is not self-hosting and the foundation is not complete. Remaining
major gaps include full token stream, full AST arena, complete control-flow and
function semantics, nested block syntax, structs/enums, module resolution, richer
type checking, MIR, register allocation or non-stack expression lowering,
ownership checker, lockfile resolver, package registry, formatter, optimizer,
LSP, and self-hosting.

The Rust prototype is still useful as a reference only:

```sh
make test-rust-prototype
```

That target is optional and is not part of root `make` or `make test`.

## LICENSE
This project is using Apache 2.0 License

## Author
The author of this project is đặng gia minh
