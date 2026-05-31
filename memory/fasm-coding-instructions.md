# FASM Coding Instructions

Every FASM line must justify itself.

## Routine Contract

Before writing or changing a routine, define:

- input registers
- output registers
- clobbered registers
- preserved registers
- stack delta
- memory state read
- memory state written
- failure path
- invariants

## Instruction Review

- `mov`: source, destination, and width must be intentional.
- `lea`: address math must be cheaper or clearer than alternatives.
- `push`/`pop`: stack must be balanced on every exit path.
- `call`: caller-saved registers must be treated as clobbered.
- `syscall`: `rax` and argument registers must match Linux x86_64 ABI.
- `cmp`/jump: signedness must match the data.
- memory access: base/index/scale/offset must match the layout constant.

## Forbidden In Active FASM Path

- NASM invocation
- `%include`
- `%define`
- `global`
- `extern`
- `default rel`
- `[rel ...]`

## File Completion

A file is not done until:

- it has been re-read after editing
- `git diff -- <file>` has been inspected
- relevant symbols have been searched
- forbidden terms have been checked
- the narrowest meaningful command has run
- `context.jsonl` has an after-file audit line

## Long Task Rule

If context becomes low, stop coding and append a flat JSONL checkpoint before continuing.
