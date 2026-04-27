# SnapSurf Foundation Identity

Status: foundation contract, ASM/NASM implementation in progress.

The official language name is `SnapSurf`.

Official file and tool names:

- Source file: `.snapsurf`
- Package file: `surf.pkg`
- Lock file: `surf.lock`
- Build script: `build.snapsurf`
- CLI tool: `surf`
- Compiler entry: `surf compile` may be added later; foundation uses `surf build`

The `.surf` extension is forbidden for source. The compiler must reject source
paths that do not end in `.snapsurf`; it must not rename, guess, normalize, or
convert input paths.

Foundation target identity:

- Target: `linux-x86_64`
- Backend: NASM x86_64
- Object format: ELF64
- Linker: `ld`
- Runtime modes in foundation: `tiny`, `none`

Implementation identity:

SnapSurf is ASM/NASM-first as a foundation implementation policy.

Current repository reality:

- `compiler/asm/` now contains the ASM/NASM hello-world foundation slice.
- `runtime/asm/` contains the tiny runtime reference modules.
- `build/surf` is produced from NASM/x86_64 assembly by the root Makefile.
- `prototypes/rust_stage0/` is a Rust Stage 0 bootstrap prototype only.
- That prototype emits NASM and invokes `nasm` plus `ld`.
- The Rust prototype is not used by the foundation build path.

Correct current claim:

`ASM/NASM foundation slice can compile the hello-world package through NASM/ld.`

Forbidden current claim:

`ASM/NASM foundation complete.`

The Rust prototype has no external crates and does not introduce JS, TS,
Python, Node, npm, a VM, bytecode runtime, GC, hidden allocator, or parser
generator. It remains prototype-only and does not satisfy or replace any
remaining foundation implementation requirement.
