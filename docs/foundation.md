# SnapSurf ASM/NASM Foundation Status

Status: in progress.

The root foundation path is now NASM/x86_64 only:

- `make` builds `build/surf` from `compiler/asm/main.asm`.
- `build/surf` implements the minimal hello-world compiler subset in assembly.
- `build/surf` emits `build/main.asm`.
- `build/surf build examples/hello` invokes `nasm` and `ld` to produce
  `build/hello`.

This is not self-hosting and not foundation complete. It is the first real
ASM/NASM foundation slice.

Implemented in ASM/NASM:

- CLI: `version`, `check`, `emit-asm`, `build`, `clean`
- `surf.pkg` read and strict field checks for the hello-world package shape
- `src/main.snapsurf` read and `.surf` rejection when used instead
- UTF-8 BOM rejection
- strict UTF-8 validation
- real source token buffer for the implemented subset
- AST arena for the implemented subset
- minimal source parser for:
  - `use core/io`
  - `fn main -> i32`
  - `io.write 1 "..." len`
  - `ret 0`
  - `end`
- capability check for `io.write` requiring `requires syscall`
- semantic checks read AST nodes for `io.write`, `ret`, string length, and return value
- deterministic NASM emission for hello world
- tiny runtime logic emitted into generated assembly
- anti-hardcode test proves changing the source string changes generated ASM
  and executable output
- binary origin test checks `build/surf` is ELF64 and contains no Cargo/Rust
  prototype invocation strings

Still scaffold or intentionally narrow:

- full token stream beyond the implemented foundation subset
- full AST layout beyond the implemented foundation subset
- full Pratt expression parser
- full semantic checker
- full package dependency resolver
- lockfile handling
- registry/workspace/toolchain manager
- self-hosting
