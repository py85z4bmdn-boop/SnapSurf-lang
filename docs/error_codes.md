# SnapSurf Error Codes

Implemented by the FASM foundation slice:

- `E0001` UTF-8 BOM is not allowed
- `E0002` invalid UTF-8 sequence
- `E0003` source file must use `.snapsurf` extension
- `E0101` unterminated string literal
- `E0102` invalid escape sequence
- `E0103` invalid character
- `E0104` unexpected EOF
- `E0105` token buffer overflow
- `E0301` AST arena overflow
- `E0201` expected token
- `E0202` missing end
- `E0203` unexpected end
- `E0204` invalid function declaration
- `E0205` invalid use declaration
- `E0401` main function not found
- `E0402` invalid main signature
- `E0403` return type mismatch
- `E0404` unsupported token or AST in foundation
- `E0501` type mismatch
- `E0502` duplicate definition
- `E0503` undefined symbol
- `E0504` cannot assign immutable binding
- `E0505` symbol table overflow
- `E0506` scope depth exceeded
- `E0801` missing required capability
- `E0802` syscall used without requires syscall
- `E0901` surf.pkg not found
- `E0902` invalid surf.pkg
- `E0903` missing required package field
- `E0904` unsupported target
- `E0905` unsupported runtime
- `E0906` executable package requires src/main.snapsurf
- `E1001` FASM emit/build failed
- `E1002` build artifact path error
