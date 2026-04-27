# SnapSurf Lexical Grammar

The lexer receives raw bytes only after source validation confirms:

- source path ends with `.snapsurf`
- bytes are valid UTF-8
- bytes do not start with UTF-8 BOM

Line numbers and columns are 1-based. A tab counts as one column. Spans keep
byte offsets from the original file; line endings are not normalized.

Identifier:

```ebnf
IdentStart = "A".."Z" | "a".."z" | "_" ;
IdentRest  = IdentStart | "0".."9" ;
Ident      = IdentStart IdentRest* ;
```

Unicode identifiers are forbidden in foundation.

Integer literal:

```ebnf
DecInt = Digit (("_"? Digit))* ;
HexInt = "0x" HexDigit (("_"? HexDigit))* ;
BinInt = "0b" BinDigit (("_"? BinDigit))* ;
OctInt = "0o" OctDigit (("_"? OctDigit))* ;
IntLit = DecInt | HexInt | BinInt | OctInt ;
```

Underscores are allowed only between digits. `_100`, `100_`, `1__000`, and
`0x_ff` are invalid.

String literal:

```ebnf
StrLit   = '"' StrChar* '"' ;
StrChar  = NonQuoteBackslashNewline | Escape ;
Escape   = "\\n" | "\\t" | "\\r" | "\\\\" | "\\\"" | "\\'" | "\\0" | HexEsc ;
HexEsc   = "\\x" HexDigit HexDigit ;
```

Comments:

```ebnf
LineComment  = "//" any-until-newline-or-eof ;
BlockComment = "/*" any-until-first-"*/" ;
```

Nested block comments are forbidden as syntax, but `/*` inside a block comment
is treated as text. Unterminated block comments emit `E0101`.

