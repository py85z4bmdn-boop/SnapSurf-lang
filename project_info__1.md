# SnapSurf — Codebase Overview (ASM/NASM Foundation Slice)

## Summary
SnapSurf is a **foundation-stage** systems programming language targeting **Linux x86_64**. In the root project, compilation is currently performed **entirely in hand-written NASM/ELF64 assembly** (no Rust/Cargo/Node used by the root `make`), producing a native binary via `nasm` and `ld`. The implemented language slice is narrow: it can compile a **subset centered around `fn ... -> i32`, `let/mut`, assignments, expressions (Pratt), control-flow (some), and the special call `io.write`**; the project is explicitly **not foundation-complete** and is actively being extended (notably multi-function support).

## Architecture

### Primary pattern
This codebase uses a classic **compiler pipeline in assembly** with explicit state in `.bss`:
**load/lex → parse → semantic checks → capability checks → emit deterministic NASM → assemble/link/run**.

### Major subsystems
- **Runtime / System startup**
  - `runtime/asm/start_linux_x86_64.asm` provides `_start` that calls `main` (reference runtime).
- **Compiler frontend**
  - **Package + source reader**: `compiler/asm/source_reader.asm`
  - **Lexer**: `compiler/asm/lexer*.asm` and `compiler/asm/token_buffer.asm`
  - **Parser**: `compiler/asm/parser_pkg.asm`, `parser_source.asm`, `parser_expr.asm`, `parser_nodes.asm`, `parser/declarations.asm`, `parser/control_flow.asm`, `parser/statements.asm`
- **Semantic + capability analysis**
  - **Semantic**: `compiler/asm/semantic.asm`, `semantic_expr.asm`, `semantic_calls.asm`, `semantic_symbols.asm`, `semantic_scope.asm`, `semantic_diagnostics.asm`
  - **Capability checks**: `compiler/asm/capability.asm`
- **Emitter (NASM code generation)**
  - `compiler/asm/emitter_nasm.asm` + expression/statement emitters and instruction templates
  - emission is deterministic and uses an explicit evaluation strategy (push/pop) for expressions
- **State**
  - multiple `.bss` modules hold compiler/intermediate state: `compiler/asm/state/*.asm`

### Technology stack
- Language: **x86_64 NASM assembly**
- Output format: **ELF64**, linked with `ld`
- Build: root `Makefile` only compiles NASM objects and links `build/surf`

### Execution entry point
- `_start` and CLI dispatch: `compiler/asm/main.asm`
  - Parses `argv` directly from the initial stack frame
  - Supported commands: `version`, `check`, `emit-asm`, `build`, `clean`, `dump-tokens`, `dump-ast`
- `compile_package` and pipeline: `compiler/asm/source_reader.asm`
  - `load_package_and_lex`
  - `parse_source_subset`
  - `semantic_check_subset`
  - `semantic_rebuild_for_emit`
  - `capability_check_subset`
- Codegen starts in CLI paths:
  - `emit-asm` and `build` both call `emit_main_asm` from `compiler/asm/emitter_nasm.asm`

## Directory Structure
Annotated tree (only meaningful folders/files):

```
project-root/
├── compiler/
│   └── asm/
│       ├── main.asm (CLI + entrypoint includes)
│       ├── source_reader.asm (package read, lex, parse, semantic, capability orchestration)
│       ├── lexer/ (UTF-8 validation, tokenization, operators, literals, comments, string pool)
│       ├── parser/ (pkg/source parsing, expressions, statements, control-flow)
│       ├── semantic*.asm (type checks, calls checks, symbol + scope checks)
│       ├── capability.asm (enforces capability rules like syscall-required io.write)
│       ├── emitter_nasm.asm + emitter_*.asm (deterministic NASM generation)
│       ├── data/ (string tables + NASM instruction templates + grammar/token/ast names)
│       ├── opt/ (present but not yet central for this foundation slice)
│       └── state/ (compiler global state slots: tokens, AST, semantics, emission)
├── runtime/
│   └── asm/ (reference tiny runtime, currently not used by emit directly)
├── docs/ (grammar + design docs)
├── examples/ (programs in .snapsurf + surf.pkg)
├── samples/ (pass/fail cases and multi-function related samples)
├── tests/ (test harness scripts + expected outputs)
└── prototypes/ (Rust stage0 reference implementation; not used by root make/test)
```

## Key Abstractions

### CLI + compiler driver: `cli_known_command` / `_start`
- **File**: `compiler/asm/main.asm` (line: includes `_start` logic and includes)
- **Responsibility**: dispatches CLI subcommands without external runtime
- **Interface**:
  - command string compare via `streq`
  - sets flags like `emit_requested`
  - calls into pipeline: `compile_package`, `emit_main_asm`, `run_nasm_and_ld`
- **Lifecycle**: process lifetime; all compiler state is global `.bss`
- **Used by**: none (root entrypoint)

### Compilation pipeline: `compile_package`
- **File**: `compiler/asm/source_reader.asm`
- **Responsibility**: orchestrates end-to-end compilation steps
- **Interface**:
  - `load_package_and_lex`: validates pkg shape, reads `src/main.snapsurf`, validates UTF-8, lexes subset
  - `parse_source_subset`: builds AST for subset
  - `semantic_check_subset`: runs semantic checks and sets main function pointer(s)
  - `semantic_rebuild_for_emit`: rebuilds a “flat” symbol table for the emitter
  - `capability_check_subset`: enforces capability rules (e.g. `io.write` needs syscall capability)
- **Non-obvious meaning**: the emitter’s correctness depends on `semantic_rebuild_for_emit`, which currently rebuilds symbols for **one** AST block (see “broken/missing” section).

### AST arena + node layout
- **File**: `compiler/asm/ast.asm`, plus `compiler/inc/ast.inc`
- **Responsibility**: allocates AST nodes in a fixed-capacity arena and forms child/sibling lists
- **Interface**:
  - `ast_new(kind, span_start, span_end, child_or_data, next_or_extra)`
  - `ast_append_child(parent, child)`
  - `dump_ast` and `ast_name_ptr` for debug
- **Lifecycle**: reset per compilation (`ast_reset`)
- **Used by**: parser, semantic, emitter

### Semantic checker: `semantic_check_subset`
- **File**: `compiler/asm/semantic.asm`
- **Responsibility**: validates the AST subset and sets semantic globals (main function, registry, return enforcement)
- **Interface** (from observed structure):
  - `semantic_init_fn_registry`
  - scans AST children for `AST_FN_DECL` nodes
  - registers functions in an in-memory registry (`fn_registry_count`, `fn_registry` in `state/semantic.asm`)
  - picks the **first** `AST_FN_DECL` as `ast_main_fn`
  - enforces return statement presence (via `return_seen`)
- **Non-obvious meaning**: main selection is based on traversal order in the AST, not on function name. If AST order changes, “main” changes.

### Symbol table (locals): `symbol_add`, `symbol_find`, `symbol_slot_for_token`
- **File**: `compiler/asm/semantic_symbols.asm`
- **Responsibility**: fixed-capacity local symbol table used by semantics and emitter
- **Interface**:
  - `symbol_add(name_token, mut_flag, type_id)` (fails on duplicates)
  - `symbol_find(name_token)` and `symbol_slot_for_token(...)` (used by emitter)
- **Non-obvious meaning**: symbol table is currently **flat and rebuild-driven** for codegen. It is not automatically scoped per function during emission.

### Capability enforcement: `capability_check_subset`
- **File**: `compiler/asm/capability.asm` (not deeply read here, but called in pipeline)
- **Responsibility**: ensures privileged operations (like syscall-linked I/O) are allowed
- **Evidence**: `io.write` requires `requires syscall` in README/foundation docs.

### NASM emitter (top-level): `emit_main_asm`
- **File**: `compiler/asm/emitter_nasm.asm`
- **Responsibility**: emits deterministic NASM for the whole program into a file
- **Interface**:
  - emits prologue/stack allocation for main (via templates + emitter blocks)
  - emits “user functions first”
  - uses `emit_block` + `emit_stmt` dispatch on AST kinds
- **Non-obvious meaning**: it emits user functions **without regenerating symbol tables per function**, so local binding correctness for non-main functions depends on global rebuild behavior.

### Expression emitter: `emit_expr` / `emit_fn_call_expr`
- **File**: `compiler/asm/emitter_expr.asm`
- **Responsibility**: converts expression AST into NASM text
- **Interface**:
  - `emit_expr(node)` dispatches on `AST_*`
  - `.binary` uses push/pop evaluation stack
  - `.fn_call` calls `emit_fn_call_expr`
- **Broken behavior visible in code**:
  - `.fn_call` exists, but the implementation currently emits a **hardcoded** label target (`asm_call_target` is `"func\n"`), not a resolved user function label, and does not evaluate arguments.

## Data Flow

1. **User runs CLI** (e.g. `make test`, `./build/surf check examples/hello`)
   - `compiler/asm/main.asm:_start` dispatches to `compile_package`

2. **Package + source load**
   - `source_reader.asm:load_package_and_lex`
   - reads `surf.pkg` + reads `src/main.snapsurf`
   - validates UTF-8 and lexes source subset into token buffer

3. **Parse subset**
   - `parser_source.asm:parse_source_subset`
   - builds AST nodes in arena (`compiler/asm/ast.asm`)
   - multi-function parsing is partially present but wired via `parse_main_fn` / AST fn-decl nodes

4. **Semantic validation**
   - `semantic_check_subset` in `semantic.asm`
   - registers functions into `fn_registry` and checks `return` coverage

5. **Capability checks**
   - `capability_check_subset` called after `semantic_rebuild_for_emit`

6. **Emitter symbol rebuild**
   - `semantic_rebuild_for_emit` in `semantic.asm`
   - rebuilds symbol table from **`ast_block_node`** (important: it is not per-function rebuilt for each emitted function)

7. **NASM emission + assembling/linking**
   - `emitter_nasm.asm:emit_main_asm`:
     - emits non-main functions first (statically labeled `fn{counter}:`)
     - emits main by calling `emit_block` with `ast_block_node`
   - if `build` command: NASM is assembled and linked (templates in `data/emitter_templates.asm`)

## Non-Obvious Behaviors & Design Decisions

### 1) Main function identity is semantic-order-driven, not name-driven
- **What happens**:
  - `parse_source_subset` produces multiple `AST_FN_DECL` nodes.
  - `semantic_check_subset` picks the “main” as the **first** `AST_FN_DECL` encountered while scanning the AST child list.
- **Why it matters**:
  - If AST insertion order changes (parser changes, AST arena append behavior), “main” can silently switch.
  - This makes multi-function programs fragile unless the compiler later enforces `fn main`.

### 2) There is a multi-function “registry”, but the emitter/call path does not use it
- `fn_registry` exists in `state/semantic.asm` and `semantic_register_function` exists.
- However:
  - expression-call emission (`emit_fn_call_expr`) currently does not resolve function names nor emit correct call targets
  - `semantic_validate_fn_call` is a stub and does not validate callee existence/argument matching

### 3) Local symbol table for codegen is “single-block rebuild”
- `semantic_rebuild_for_emit` rebuilds locals by walking a block starting from a single global `ast_block_node`.
- `emit_main_asm` then emits **multiple functions**, but the emitter still uses `symbol_slot_for_token` which consults the rebuilt flat table.
- **Impact**:
  - locals inside user functions can be missing or mismatched
  - this can lead to incorrect codegen or hard failures when trying to store/load locals in non-main functions

### 4) Function call expression support is present as AST kinds, but is logically disconnected
- AST kinds include `AST_FN_CALL_EXPR`, but:
  - `parser/function_calls.asm:parse_fn_call_expr` does not construct an `FnCallExpr` node; it simply returns the callee node.
  - `emitter_expr.asm:emit_fn_call_expr` emits a generic hardcoded call target (`func:`), and does not emit argument expressions.
  - `semantic/functions.asm` contains stubs for validation, and the integrated semantic call validation path currently only validates `io.write`.

### 5) There are multiple “multi-function” implementations—some appear not to be wired
- `compiler/asm/parser/functions.asm` and `compiler/asm/semantic/functions.asm` appear to be separate “new” files.
- The root build includes `compiler/asm/semantic.asm`, `parser_source.asm`, and other parser modules but **not** (in `Makefile`) `parser/functions.asm` as a direct include unit.
- This creates a risk of “dead code” or partially integrated multi-function work:
  - the compiler may parse/semantic using older logic while new stubs remain unused.

## Non-complete / Broken Code & Missing Logic (Concrete Findings)

### A) Function call expression parsing is broken/incomplete
- **File**: `compiler/asm/parser/function_calls.asm`
- **Observed issue**:
  - `parse_fn_call_expr`:
    - checks for `TOK_LPAREN`
    - **skips parsing arguments** entirely
    - **returns only the callee** (`mov rax, r12`) instead of returning an `AST_FN_CALL_EXPR` node.
- **Effect**:
  - The AST will not contain `AST_FN_CALL_EXPR` for calls, or it will be wrong, so:
    - expression type checking for calls cannot work
    - emitter call expression codegen cannot work

### B) Function call expression emission is effectively stubbed
- **File**: `compiler/asm/emitter_expr.asm:emit_fn_call_expr`
- **Observed issue**:
  - It emits:
    - `call func:` (via `asm_call_prefix` + `asm_call_target`)
  - It does **not**:
    - evaluate call arguments
    - load parameters into calling-convention registers
    - resolve correct function label generated for that function
- **Effect**:
  - Any user-defined function call cannot produce correct assembly.

### C) Semantic validation for function calls is not implemented
- **File**: `compiler/asm/semantic/functions.asm:semantic_validate_fn_call`
- **Observed issue**:
  - Contains TODOs:
    - check callee exists in registry
    - check argument count matches
    - check argument types match
- **Effect**:
  - Even if call expressions were parsed/emitted correctly, type/symbol validation for calls remains incomplete.

### D) Emitter label scheme for user functions does not match call target scheme
- **File**: `compiler/asm/emitter_nasm.asm:emit_user_function`
  - labels user functions as `fn{counter}:` (e.g. `fn0:`)
- **File**: `compiler/asm/emitter_expr.asm:emit_fn_call_expr`
  - emits call target as hardcoded `func:`
- **Effect**:
  - There is currently **no mapping** between the emitted user function labels and call-site labels.

### E) User function local symbols likely missing due to single-block rebuild
- **File**: `compiler/asm/semantic.asm:semantic_rebuild_for_emit`
  - rebuilds locals for one `ast_block_node`
- **File**: `compiler/asm/emitter_nasm.asm:emit_user_function`
  - emits user function blocks but does not rebuild symbol table per user function
- **Effect**:
  - `emit_store_stmt` uses `symbol_slot_for_token`, which can’t find local bindings declared in that user function unless the rebuilt symbol table corresponds to that same block.

### F) Multi-function parsing exists but has likely “adapter mismatch” between parser and semantic/emitter expectations
- **File**: `compiler/asm/parser_source.asm`
  - the entrypoint is `parse_main_fn` but it accepts any identifier (multi-fn parsing is done by repeatedly calling it).
  - it appends `AST_FN_DECL` nodes and adds `AST_PATH` child for function name.
- **File**: `compiler/asm/semantic.asm`
  - registers functions by scanning `AST_FN_DECL` nodes and reading the function name from the `AstPath` child.
- **Risk**:
  - if parser’s AST span/child structure differs from semantic’s assumptions, function name extraction may be wrong (the register stores a pointer+length extracted by counting characters until whitespace).

### G) Observed “build/main.asm” is a placeholder artifact in the repo snapshot
- **File**: `build/main.asm` in this environment
- **Observed issue**:
  - It contains a simplistic `main` + `fn0` stub, not the expected emitted hello program.
- **Interpretation**:
  - this likely represents either:
    - a checked-in placeholder
    - or a previous incomplete emission run
  - It is consistent with the repository status stating that foundation is incomplete and some tests/build outputs are known-broken.

## Module Reference (significant files)
| File | Purpose |
|---|---|
| `compiler/asm/main.asm` | CLI entrypoint and command dispatch |
| `compiler/asm/source_reader.asm` | Package/source loading + full pipeline orchestration |
| `compiler/asm/parser_source.asm` | Top-level subset parser (`parse_source_subset`, `parse_main_fn`, `parse_block`) |
| `compiler/asm/parser_expr.asm` | Pratt expression parser (literals, vars, unary, arithmetic, grouping) |
| `compiler/asm/parser/statements.asm` | `ret` and `io.write` call statement parsing (no generic calls) |
| `compiler/asm/semantic.asm` | Multi-function aware semantic validation driver + main selection + return enforcement |
| `compiler/asm/semantic_expr.asm` | Expression type checking (only subset; no call validation) |
| `compiler/asm/semantic_calls.asm` | Semantic checks for `io.write` (string length vs int literal) |
| `compiler/asm/semantic_symbols.asm` | Fixed-capacity symbol table for locals used by emitter |
| `compiler/asm/capability.asm` | Capability checks (`requires syscall` for syscall-linked operations) |
| `compiler/asm/emitter_nasm.asm` | Top-level deterministic NASM emitter for main + user functions |
| `compiler/asm/emitter_expr.asm` | Expression codegen; contains stubbed fn-call emission |
| `compiler/asm/emitter_writer.asm` | Writers for numeric/DB strings into NASM output file |
| `compiler/inc/ast.inc`, `compiler/inc/tokens.inc`, `compiler/inc/types.inc` | Shared enums/IDs and type descriptors |

## Suggested Reading Order
1. `compiler/asm/main.asm` — start here to see how compilation is invoked and how `emit-asm/build` paths work
2. `compiler/asm/source_reader.asm:compile_package` — understand the pipeline sequencing and global state assumptions
3. `compiler/asm/parser_source.asm` — understand AST shape expectations (FnDecl/Block child chains)
4. `compiler/asm/semantic.asm` — understand how “main” is selected, how return_seen is enforced, how symbol rebuild hooks emitter correctness
5. `compiler/asm/semantic_symbols.asm` — understand fixed-capacity locals and how emitter loads/stores locals
6. `compiler/asm/emitter_nasm.asm` + `compiler/asm/emitter_expr.asm` — see where multi-function emission begins and where function-call paths are disconnected

## What a developer should know to work effectively (today)
- This is not a complete compiler: the “multi-function + calls” pipeline has partial scaffolding, but **function call parsing/emission/semantic validation are disconnected**.
- The compiler uses **global fixed-capacity arenas** for AST and symbols; failures often manifest as overflow/fail-closed diagnostics.
- Code generation relies on `semantic_rebuild_for_emit`, and right now it appears designed for a **single block**, making multi-function emission correctness dependent on global rebuild behavior.
- When extending functionality, check wiring across:
  - parser produces the right AST nodes
  - semantic validates those nodes and sets registry/flags
  - emitter uses the same mapping (labels + symbol locations + ABI rules)

## Next targets (based on broken pieces discovered)
- Fix `parse_fn_call_expr` to actually create `AST_FN_CALL_EXPR` nodes and parse argument expressions.
- Implement `semantic_validate_fn_call` to consult `fn_registry` and validate parameter counts/types.
- Implement `emit_fn_call_expr` to:
  - resolve the correct callee label produced by the emitter
  - evaluate arguments and move them into System V ABI registers
  - handle stack alignment before `call`
- Fix symbol-table rebuild for codegen so **each emitted function** has correct locals in `sym_*` before emission (or implement per-function symbol scoping during emission).
