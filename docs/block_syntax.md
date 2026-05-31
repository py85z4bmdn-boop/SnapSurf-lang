# SnapSurf Block Syntax

Foundation blocks use an opener plus `end`.

Valid foundation openers:

- `fn ...`
- `if ... ->`
- `elif ... ->`
- `else ->`
- `while ... ->`
- `loop ->`

`end` closes the active block. Missing `end` and extra `end` are syntax
errors. Indentation is not semantic.

Curly braces are forbidden as foundation block delimiters. They are not
reserved for normal block syntax.

Examples:

```snapsurf
fn main -> i32
    ret 0
end
```

Generalized block syntax beyond the current foundation control-flow subset is
not complete yet.
