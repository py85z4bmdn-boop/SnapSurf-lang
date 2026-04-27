# SnapSurf Diagnostics and Error Registry

Every diagnostic contains:

- error code
- severity
- message
- file path
- source file id
- byte span
- line and column span
- optional note
- optional help
- optional related span

Default max errors: 100. After that the compiler emits `E9999`.

Registered foundation codes:

- `E0001`: UTF-8 BOM is not allowed
- `E0002`: invalid UTF-8 sequence
- `E0003`: SnapSurf source file must use `.snapsurf` extension
- `E0004`: source path is not valid UTF-8
- `E0101`: unterminated block comment
- `E0102`: invalid character
- `E1001`: invalid escape sequence
- `E1002`: unterminated string literal
- `E1003`: invalid integer literal
- `E0201`: missing function name
- `E0202`: missing return type
- `E0203`: expected `end`
- `E0204`: unexpected `end`
- `E0205`: `else` without matching `if`
- `E0206`: invalid expression
- `E0207`: parser made no progress
- `E0301`: error node reached validation boundary
- `E0401`: undeclared variable
- `E0402`: type mismatch
- `E0403`: function call target does not exist
- `E0404`: argument count mismatch
- `E4001`: integer literal does not fit in target type
- `E4101`: not all control paths return required type
- `E4201`: cannot assign to immutable variable
- `E4202`: variable shadowing is forbidden in foundation
- `E4301`: condition must be bool
- `E0501`: break outside loop
- `E0502`: continue outside loop
- `E0701`: unsafe operation requires unsafe scope
- `E0801`: package capability is missing
- `E0901`: missing `surf.pkg`
- `E0902`: invalid `surf.pkg` schema
- `E0903`: missing package source entry
- `E0904`: unsupported package target or runtime
- `E1000`: external tool failed
- `E2001`: package declares insufficient capability for `core/io` syscall use
- `E9999`: too many errors, stopping

Design decision for an internal spec conflict: the registry keeps the normal
capability range at `E0800-E0899`, but also reserves `E2001` because the
foundation spec explicitly mandates that code for `core/io` syscall capability
leaks. The compiler uses `E2001` for `io.write` without `requires syscall`.

