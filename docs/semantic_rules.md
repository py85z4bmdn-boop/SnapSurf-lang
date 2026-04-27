# SnapSurf Foundation Semantic Rules

Foundation semantic checks run before code generation. Code generation refuses
any AST with errors.

Required checks:

- `main` exists for executable packages.
- Foundation executable `main` signature is exactly `fn main -> i32`.
- A variable must be declared before use.
- Shadowing and redeclaration in a scope are forbidden.
- `let` variables cannot be assigned.
- All variables are initialized at declaration.
- `if` and `while` conditions must be `bool`.
- Return expressions must match the function return type.
- Non-void functions must return on all control paths.
- `break` and `continue` are valid only inside loops.
- Function call targets must exist or be recognized foundation builtins.
- Argument count and basic argument types must match.
- `io.write` requires package capability `syscall`.
- `mem.alloc` requires package capability `heap` and an unsafe context in the
  foundation bootstrap.
- Calling an unsafe function requires an `unsafe -> ... end` block.
- Unsafe code still type checks and still obeys package capabilities.

Foundation deliberately does not claim a Rust-level borrow checker. The checker
is conservative: if safe behavior cannot be proven, safe code is rejected or an
unsafe scope is required.

