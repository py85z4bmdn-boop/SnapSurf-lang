# SnapSurf FASM/CMake Foundation Status

Status: active FASM/CMake foundation regression passes.

The root foundation path is now FASM/CMake only:

- `cmake --build build/cmake` builds `build/surf` from
  `compiler/fasm/main.asm`.
- `build/surf` is a real FASM executable.
- `build/surf version` works.
- `build/surf check <pkg_dir>` verifies package/source layout and runs the
  active lexer, parser, semantic, and capability checks for the current
  foundation subset.
- `build/surf emit-asm <pkg_dir>` emits FASM source to `build/main.asm`.
- `build/surf build <pkg_dir>` assembles generated FASM directly to
  `build/hello`.

This is not self-hosting and not foundation complete. It is a real but narrow
FASM foundation slice that passes the current regression suite.

Implemented in active FASM:

- CMake root entrypoint.
- direct FASM assembly to `build/surf`
- CLI recognition for `version`, `check`, `emit-asm`, `build`, `clean`,
  `dump-tokens`, `dump-ast`, and `colorize`
- file-existence checks for package layout
- bounded source read for `src/main.snapsurf`
- lexer, AST arena, parser, semantic checks, capability checks, and diagnostic
  output for the current foundation subset
- FASM code generation and direct generated executable build
- specific diagnostics for missing package file, missing source file, and path
  overflow
- specific diagnostics for source read failure and oversized source files
- binary origin checks proving the active compiler does not contain
  Cargo/Rust/prototype invocation strings

Still scaffold or intentionally narrow:

- language coverage beyond the current foundation subset
- dynamic symbol table and nested block syntax
- register allocation or expression lowering strategy
- full package dependency resolver
- lockfile handling
- registry/workspace/toolchain manager
- self-hosting
