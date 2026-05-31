# SnapSurf Foundation Semantic Rules

Foundation semantic checks run before code generation. Code generation refuses
any AST with errors.

Implemented checks:

- `main` exists for executable packages.
- Foundation executable `main` signature is exactly `fn main -> i32`.
- A variable must be declared before use.
- Shadowing and redeclaration in a scope are forbidden.
- `let` variables cannot be assigned.
- All variables are initialized at declaration.
- Return expressions must be `i32`.
- `main` must contain at least one return statement.
- The implemented arithmetic operators require `i32` operands.
- The implemented local declarations are `i32` only.
- Mutable declarations use the standalone `mut x i32 = expr` form; `let mut`
  is rejected in the FASM foundation grammar.
- Symbol table entries store explicit type tags from `compiler/fasm/inc/types.inc`.
- Primitive type descriptors are pre-populated in `type_table`, and arithmetic
  operators route through `type_check_binary`.
- The fixed-capacity symbol table rejects insertion past `SYM_CAP` with `E0505`.
- A fixed-capacity scope stack exists and rejects insertion past `SCOPE_CAP`
  with `E0506`; current source syntax has only the function-root scope.
- Recognized call targets include the foundation builtin `io.write` and
  registered user functions in the current subset.
- `io.write` string length must match the explicit length argument.
- `io.write` requires package capability `syscall`.

Not implemented: complete trait checks, unsafe semantics, lifetimes, borrow
checking, and the final language-wide type system.
