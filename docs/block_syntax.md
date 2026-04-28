# SnapSurf Block Syntax

Foundation blocks use an opener plus `end`.

Valid foundation openers:

- `fn ...`

`end` closes the `fn main -> i32` block. Missing `end` and extra `end` are
syntax errors. Indentation is not semantic.

Curly braces are forbidden as foundation block delimiters. They are not
reserved for normal block syntax.

Examples:

```snapsurf
fn main -> i32
    ret 0
end
```

Nested blocks, `if`, `else`, `loop`, `while`, and `unsafe` block syntax are
not implemented in the ASM foundation compiler yet.
