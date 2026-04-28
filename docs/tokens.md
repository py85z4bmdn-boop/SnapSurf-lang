# SnapSurf Token Types v0.1 Foundation

Implemented source keyword tokens:

`TokFn`, `TokLet`, `TokMut`, `TokRet`, `TokUse`, `TokEnd`, `TokTrue`,
`TokFalse`.

Literal tokens:

`TokIdent`, `TokIntLit`, `TokStrLit`.

Operator tokens:

`TokPlus`, `TokMinus`, `TokStar`, `TokSlash`, `TokPercent`, `TokEq`,
`TokArrow`.

Delimiter tokens:

`TokLParen`, `TokRParen`, `TokComma`, `TokDot`.

Special tokens:

`TokNewline`, `TokEof`, `TokError`.

Boolean literals are represented by `TokTrue` and `TokFalse`, not by a generic
boolean literal token.

Package-file keywords are still validated by the package parser, not by the
source token stream.
