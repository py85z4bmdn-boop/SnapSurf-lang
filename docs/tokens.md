# SnapSurf Token Types v0.1 Foundation

Keyword tokens:

`TokFn`, `TokLet`, `TokMut`, `TokConst`, `TokStatic`, `TokRet`, `TokIf`,
`TokElse`, `TokLoop`, `TokWhile`, `TokBreak`, `TokContinue`, `TokUse`,
`TokModule`, `TokPackage`, `TokVersion`, `TokType`, `TokTarget`, `TokRuntime`,
`TokEntry`, `TokRequires`, `TokDep`, `TokEnd`, `TokUnsafe`, `TokExtern`,
`TokAsm`, `TokTrue`, `TokFalse`, `TokAnd`, `TokOr`, `TokNot`.

Literal tokens:

`TokIdent`, `TokIntLit`, `TokStrLit`, `TokByteLit`.

Operator tokens:

`TokPlus`, `TokMinus`, `TokStar`, `TokSlash`, `TokPercent`, `TokEq`,
`TokEqEq`, `TokBangEq`, `TokLt`, `TokLtEq`, `TokGt`, `TokGtEq`, `TokArrow`.

Delimiter tokens:

`TokLParen`, `TokRParen`, `TokLBracket`, `TokRBracket`, `TokComma`, `TokDot`,
`TokColon`.

Special tokens:

`TokNewline`, `TokEof`, `TokError`, `TokComment`.

Boolean literals are represented by `TokTrue` and `TokFalse`, not by a generic
boolean literal token.

