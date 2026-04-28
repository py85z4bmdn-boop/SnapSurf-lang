# SnapSurf Foundation AST

Implemented AST node layout:

- `kind`
- `span_start`
- `span_end`
- `first_child_or_data`
- `next_sibling_or_extra`

Parser recovery remains minimal. Error nodes must not reach code generation.

Foundation nodes:

- `SourceFile`
- `UseDecl`
- `FnDecl`
- `Block`
- `LetStmt`
- `MutStmt`
- `AssignStmt`
- `RetStmt`
- `CallStmt`
- `Path`
- `Ident`
- `VarRef`
- `IntLit`
- `StrLit`
- `BoolLit`
- `BinAdd`
- `BinSub`
- `BinMul`
- `BinDiv`
- `BinMod`
- `UnaryNeg`

The AST separates implemented items, statements, and expressions. Full
functions, parameters, control flow, user types, and type references are not
implemented in the ASM foundation AST yet.
