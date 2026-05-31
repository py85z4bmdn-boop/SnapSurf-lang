# SnapSurf Agent State

Status: active execution state for long FASM migration.

Current contract:

- SnapSurf root compiler must become FASM-only.
- Active build must not call NASM.
- Root build orchestration is CMake, not Makefile.
- Generated program assembly must be FASM syntax.
- `ld` is not part of the target active foundation if FASM can emit the final executable directly.
- `compiler/asm/` is reference material only during migration.

Current checkout reality:

- Root `Makefile` has been removed.
- Root `CMakeLists.txt` builds `build/surf` from `compiler/fasm/main.asm`.
- Full regression passes through active CMake/FASM.
- Generated programs are emitted as FASM and assembled directly by FASM to
  `build/hello`.
- No local `AGENTS.md` file exists in this checkout; the user-provided directives remain binding.
- `fasm` is installed and can emit both ELF64 executable and ELF64 relocatable output.

Execution rule:

- Do not edit a second source file until the previous edited file has been re-read, diffed, symbol-searched, forbidden-term checked, and checkpointed in `context.jsonl`.
