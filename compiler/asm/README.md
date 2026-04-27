# SnapSurf ASM/NASM Foundation Compiler

Status: in progress.

Implemented now:

- `main.asm` builds `build/surf`.
- CLI supports `version`, `check`, `emit-asm`, `build`, `clean`,
  `dump-tokens`, and `dump-ast`.
- `source_reader.asm` reads `surf.pkg` and `src/main.snapsurf`.
- `utf8.asm` rejects BOM and invalid UTF-8.
- `parser_pkg.asm` validates the minimal `surf.pkg` shape.
- `lexer.asm` emits a real token buffer for the implemented source subset.
- `ast.asm` provides a real AST arena for the implemented source subset.
- `parser_source.asm` consumes token buffer entries and creates AST nodes.
- `semantic.asm` reads AST nodes for return/call/string-length checks.
- `capability.asm` reads AST state and enforces `io.write` requiring `requires syscall`.
- `emitter_nasm.asm` emits deterministic NASM from AST-derived literal data.

Still deliberately narrow:

- no full token stream beyond the foundation subset yet
- no full AST arena beyond the foundation subset yet
- no full expression parser yet
- no full semantic checker yet
- no multi-module compilation yet

This is an ASM/NASM foundation slice, not a complete foundation.
