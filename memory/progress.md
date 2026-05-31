# SnapSurf Progress

## Current Phase

DONE: completed the `Prompt.jsonl` deliverable without changing the active
compiler path.

## Checklist

- DONE: verify `fasm` exists in the environment.
- DONE: confirm current root build is still NASM-based.
- DONE: confirm current worktree was dirty before this task.
- DONE: create `compiler/fasm/` first buildable FASM source slice.
- DONE: audit first FASM source file line by line.
- DONE: add non-active FASM build target without breaking existing dirty changes.
- DONE: keep FASM CLI recognition aligned with current commands: `version`, `check`, `emit-asm`, `build`, `clean`, `dump-tokens`, `dump-ast`, `colorize`.
- DONE: port the first real FASM `check` behavior: verify `surf.pkg` and `src/main.snapsurf` exist before lexer work.
- DONE: remove root `Makefile`.
- DONE: add root `CMakeLists.txt` that builds `build/surf` through FASM.
- DONE: update regression metadata checks to allow CMake and forbid root Makefile.
- DONE: make active FASM `check` read `src/main.snapsurf` into a bounded source buffer after package discovery.
- DONE: port the reference lexer/parser/semantic/capability/emitter path into active FASM source.
- DONE: generated program assembly is FASM syntax, not NASM syntax.
- DONE: generated programs are assembled directly by FASM to `build/hello`.
- DONE: fix generated user function labels with `fn_` prefix so FASM reserved instruction names cannot become labels.
- DONE: make `full-regression` pass through the active FASM compiler.
- TODO: replace the mechanical reference-port shape with smaller hand-audited FASM modules over time.
- DONE: add isolated FASM/SSE2 vector-add demo with C wrapper benchmark.
- DONE: add high-density technical report requested by `Prompt.jsonl`.
- DONE: run the prompt demo script.
- DONE: re-run active CMake/FASM full regression.

## Dirty Worktree At Start

- `compiler/asm/data/diagnostics.asm`
- `compiler/asm/emitter_expr.asm`
- `compiler/asm/parser_match.asm`
- `compiler/asm/parser_source.asm`
- `compiler/asm/semantic.asm`
- `compiler/asm/semantic_types.asm`
- `tests/run_all.sh`
- new tests under `tests/compile_fail/` and `tests/pass/struct_field_access/`

Do not revert these unless the user explicitly asks.
