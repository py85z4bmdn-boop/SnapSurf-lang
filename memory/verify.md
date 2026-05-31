# SnapSurf Verification Contract

## Current CMake/FASM Gate

```sh
git status --short
command -v fasm
command -v cmake
command -v ninja
cmake -S . -B build/cmake -G Ninja
cmake --build build/cmake
cmake --build build/cmake --target fasm-smoke
cmake --build build/cmake --target check-discovery
file build/surf
strings build/surf | rg -i "nasm|cargo|rust|prototypes|rust_stage0"
```

The `strings | rg` check passes only when it prints nothing and returns no
match.

## Per Edited File

```sh
git diff -- <tracked-file>
git diff --no-index -- /dev/null <new-file>
rg -n "<new-or-changed-symbol>" .
rg -n "nasm|NASM|%include|%define|global|extern|default rel|\\[rel" <active-path>
```

Required manual checks:

- Re-read the full edited file.
- Check every routine contract: inputs, outputs, clobbers, preserved registers, stack delta, failure path.
- Check every `push` has a matching `pop` on all paths.
- Check callee-saved registers are preserved.
- Check syscall numbers and argument registers.
- Check signed vs unsigned jumps.
- Check memory base/index/scale/offset and capacity.

## FASM Smoke

```sh
cmake --build build/cmake --target fasm-smoke
```

## FASM Check Discovery Gate

```sh
cmake --build build/cmake --target check-discovery
```

Expected results in the current phase:

- `examples/hello` prints `check ok` and exits 0.
- `missing_pkg` prints the missing `surf.pkg` diagnostic and exits 1.
- `missing_main` prints the missing `src/main.snapsurf` diagnostic and exits 1.

## FASM Hello Gate

This gate now runs through the active FASM compiler path.

```sh
./build/surf check examples/hello
./build/surf emit-asm examples/hello
./build/surf build examples/hello
./build/hello
```

## Final Regression

Run this after every build/codegen change. Do not use smoke or discovery gates
as a substitute.

```sh
cmake --build build/cmake --target full-regression
```

## Prompt.jsonl Demo Gate

The prompt demo is isolated from the active compiler path. It must compile and
run on Linux x86_64 with local tools only.

```sh
sh samples/fasm_vector_add/run.sh
```

## Performance Gate

A measured regression of 1% or more fails by default. It may only be accepted if the stability/correctness/security gain is concrete and recorded in `context.jsonl` with baseline, new result, and tradeoff.
