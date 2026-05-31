# SnapSurf Foundation Identity

Status: foundation contract, active FASM/CMake regression passes.

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
- Backend: FASM x86_64
- Active compiler output format: ELF64 executable
- Linker: none in the active root compiler build
- Runtime modes in foundation: `tiny`, `none`

Implementation identity:

SnapSurf is FASM-first as a foundation implementation policy.

Current repository reality:

- `compiler/fasm/` contains the active FASM compiler path.
- `compiler/asm/` remains old reference material and is not the active root
  build path.
- `runtime/asm/` contains the tiny runtime reference modules.
- `build/surf` is produced from FASM/x86_64 assembly by root CMake.
- `prototypes/rust_stage0/` is a Rust Stage 0 bootstrap prototype only.
- The Rust prototype is not used by the foundation build path.

Correct current claim:

`FASM/CMake root build produces build/surf, and check can verify package-file
presence, lex, parse, run semantic checks, and generate FASM programs for the
current foundation regression suite.`

Forbidden current claim:

`FASM foundation complete.`
`SnapSurf is self-hosting.`
`SnapSurf language design is complete.`

The Rust prototype has no external crates and does not introduce JS, TS,
Python, Node, npm, a VM, bytecode runtime, GC, hidden allocator, or parser
generator. It remains prototype-only and does not satisfy or replace any
remaining foundation implementation requirement.
