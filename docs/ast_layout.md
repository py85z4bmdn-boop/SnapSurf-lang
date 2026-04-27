# SnapSurf AST Layout

ASM foundation status: PARTIAL AST arena implemented for the hello-world
foundation subset.

AST node layout:

- `kind`
- `span_start`
- `span_end`
- `first_child_or_data`
- `next_sibling_or_extra`

Capacity: 1024 nodes.

Overflow diagnostic: `E0301`.

Implemented node kinds:

- `AstSourceFile`
- `AstUseDecl`
- `AstFnDecl`
- `AstBlock`
- `AstRetStmt`
- `AstCallStmt`
- `AstIntLit`
- `AstStrLit`
- `AstIdent`
- `AstPath`
- `AstError`

Foundation debug command:

```sh
./build/surf dump-ast examples/hello
```

The full AST for all future SnapSurf syntax remains NOT IMPLEMENTED.
