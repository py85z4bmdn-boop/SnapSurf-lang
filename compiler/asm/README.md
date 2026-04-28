# SnapSurf ASM/NASM Foundation Compiler

Status: in progress.

Implemented now:

- `main.asm` builds `build/surf`.
- CLI supports `version`, `check`, `emit-asm`, `build`, `clean`,
  `dump-tokens`, and `dump-ast`.
- `source_reader.asm` reads `surf.pkg` and `src/main.snapsurf`.
- `utf8.asm` rejects BOM and invalid UTF-8.
- `parser_pkg.asm` validates the minimal `surf.pkg` shape.
- `lexer.asm` emits a real token buffer for the implemented source subset,
  including arithmetic operators and comments.
- `ast.asm` provides a real AST arena for the implemented source subset.
- `parser_source.asm` consumes token buffer entries and creates AST nodes,
  including a Pratt parser for the implemented arithmetic expressions.
- `semantic.asm` reads AST nodes for locals, assignment, return, call, and
  string-length checks, using explicit type IDs/descriptors from
  `compiler/inc/types.inc`.
- `capability.asm` reads AST state and enforces `io.write` requiring `requires syscall`.
- `emitter_nasm.asm` emits deterministic NASM from AST-derived string data,
  stack locals, load/store operations, arithmetic instructions, and return
  expressions.
- `compiler/inc/calling_conv.inc` documents the internal register convention
  and recursive parser stack protocol.

Still deliberately narrow:

- no full token stream beyond the foundation subset yet
- no full AST arena beyond the foundation subset yet
- no control-flow or multi-function parser/codegen yet
- no full semantic checker yet
- no dynamic symbol table yet; the current fixed-capacity table fails closed at
  `SYM_CAP`
- no nested block syntax yet; scope stack primitives exist for future control
  flow
- no multi-module compilation yet

This is an ASM/NASM foundation slice, not a complete foundation.
