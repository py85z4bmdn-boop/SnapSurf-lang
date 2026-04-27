# SnapSurf Block Syntax

Foundation blocks use an opener plus `end`.

Valid foundation openers:

- `fn ...`
- `if ... ->`
- `else ->`
- `loop ->`
- `while ... ->`
- `unsafe ->`

`end` closes the nearest open block. Missing `end`, extra `end`, and `else`
outside an `if` are syntax errors. Indentation is not semantic.

Curly braces are forbidden as foundation block delimiters. They are not
reserved for normal block syntax.

Examples:

```snapsurf
fn main -> i32
    ret 0
end
```

```snapsurf
if x > 0 ->
    ret x
else ->
    ret 0
end
```

