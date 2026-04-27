# SnapSurf Foundation AST

Every AST node carries:

- `node_kind`
- `span_start`
- `span_end`
- `source_file_id`

No AST node has an optional span. Parser recovery may create error statements,
but error nodes must not reach code generation.

Foundation nodes:

- `SourceFile`
- `UseDecl`
- `FnDecl`
- `Param`
- `Block`
- `LetStmt`
- `MutStmt`
- `AssignStmt`
- `RetStmt`
- `IfStmt`
- `LoopStmt`
- `WhileStmt`
- `BreakStmt`
- `ContinueStmt`
- `UnsafeBlock`
- `ExprStmt`
- `BinaryExpr`
- `UnaryExpr`
- `CallExpr`
- `IdentExpr`
- `PathExpr`
- `IntLitExpr`
- `StrLitExpr`
- `BoolLitExpr`
- `TypeName`

The AST separates items, statements, expressions, and type references. Syntax
that exists only for parser convenience is not encoded as semantic structure.

