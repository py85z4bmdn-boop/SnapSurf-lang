# SnapSurf

SnapSurf is a foundation-stage systems language project for Linux x86_64.

Current truthful status:

- FASM/CMake foundation migration has reached regression parity for the
  current foundation test suite.
- `build/surf` is built from [compiler/fasm/main.asm](compiler/fasm/main.asm)
  through root [CMakeLists.txt](CMakeLists.txt).
- The active FASM compiler supports `version`, `check`, `emit-asm`, `build`,
  `dump-tokens`, `dump-ast`, `colorize`, package/source validation, lexer,
  parser, semantic checks, diagnostics, and generated FASM program builds for
  the current foundation subset.
- The old [compiler/asm](compiler/asm) NASM stack remains reference material
  only; it is not the active root build path.
- The Rust Stage 0 compiler remains isolated in
  [prototypes/rust_stage0](prototypes/rust_stage0) and is not used by root
  CMake targets.

Correct current claim:

> FASM/CMake root build produces `build/surf`, and `check` can verify package
> file presence, lex, parse, run semantic checks, and generate FASM programs
> for the current foundation regression suite.

Still forbidden:

> FASM foundation compiler complete.
> SnapSurf is self-hosting.
> SnapSurf language design is complete.

## Root Commands

These commands do not use Cargo, Rust, Python, Node, GCC, Clang, Zig, Go, NASM,
or `ld` for the active root compiler build.

```sh
cmake -S . -B build/cmake -G Ninja
cmake --build build/cmake
./build/surf version
./build/surf check examples/hello
cmake --build build/cmake --target check-discovery
cmake --build build/cmake --target full-regression
cmake --build build/cmake --target clean
```

Current `check examples/hello` output:

```text
check ok
```

`full-regression` is the hard gate and currently passes through the active
FASM/CMake path.

## Implemented In Active FASM

- CMake root build for `build/surf`.
- Direct FASM assembly of the compiler executable.
- CLI command recognition for `version`, `check`, `emit-asm`, `build`,
  `clean`, `dump-tokens`, `dump-ast`, and `colorize`.
- `check <pkg_dir>` verifies `surf.pkg` and `src/main.snapsurf`, then runs the
  active lexer/parser/semantic path.
- `emit-asm <pkg_dir>` emits FASM source to `build/main.asm`.
- `build <pkg_dir>` assembles generated FASM directly to `build/hello`.
- Specific diagnostics for missing `surf.pkg`, missing `src/main.snapsurf`,
  path overflow, source read failure, and oversized source files.

## Not Complete

The project is not self-hosting and the foundation is not complete. Remaining
major gaps include complete language semantics beyond the current foundation
subset, module resolution, richer type checking, MIR, register allocation or
non-stack expression lowering, ownership checker, lockfile resolver, package
registry, formatter, optimizer, LSP, and self-hosting.

The Rust prototype is still useful as a reference only:

```sh
cd prototypes/rust_stage0 && cargo test
```

That command is optional and is not part of root CMake build/test targets.

## LICENSE
This project is using Apache 2.0 License.

## Author
The author of this project is đặng gia minh.
