# SnapSurf FASM Migration Plan

Goal: replace the active root compiler and generated program backend with careful FASM-only code while preserving verified language behavior.

Order:

1. Establish durable execution state and flat `context.jsonl` checkpoints.
2. Build a fresh FASM core under `compiler/fasm/`.
3. Port enough root entry, data, diagnostics, file/process, lexer, parser, semantic, capability, and emitter behavior to match current tests.
4. Use root CMake as the only active build orchestration.
5. Remove active NASM dependency and update docs/tests to enforce FASM-only.
6. Only after FASM parity, resume compiler-profile and aggressive optimizer work.

Milestone 1 definition (completed earlier):

- CMake can build `build/surf` through FASM.
- `./build/surf version` works.
- `./build/surf check <pkg_dir>` performed real package-file discovery and
  source read before the full FASM port landed.
- `check-discovery` target passes.

Milestone 1 was not enough to claim:

- `check examples/hello` succeeds.
- `emit-asm` works.
- `build examples/hello` works.
- Generated `build/hello` is produced through FASM and runs.
- Active path contains no NASM invocation.

Milestone 2 definition:

- `full-regression` passes through the FASM compiler.
- Compile-fail diagnostics remain stable unless intentionally updated.
- `dump-ast` names cover implemented AST nodes instead of reporting supported nodes as unknown.

Milestone 2 status:

- DONE: active root CMake builds `build/surf` through FASM.
- DONE: `check`, `dump-tokens`, `dump-ast`, `emit-asm`, and `build` run through
  active FASM compiler code for the current foundation subset.
- DONE: generated `build/main.asm` is FASM syntax.
- DONE: generated `build/hello` is assembled directly by FASM.
- DONE: `full-regression` passes.

Prompt.jsonl delivery slice:

- Keep the active compiler path untouched unless a verified blocker appears.
- Add an isolated Linux x86_64 FASM/SSE2 vector-add demo under `samples/`.
- Use a C wrapper only inside that isolated sample, not as a root compiler
  dependency.
- Add a high-density Markdown report under `docs/` that maps the requested
  assembly/C/high-level mindsets to the current SnapSurf/FASM checkout reality.
- Verify the sample with its own build/run script and then re-run the active
  FASM full regression.

Stop if:

- A file is edited without post-file audit.
- A fix only passes the narrow command.
- A performance-sensitive change lacks baseline comparison.
- Any active path still depends on NASM after the switch.
- A narrow smoke or discovery target is used as a substitute for full regression.
