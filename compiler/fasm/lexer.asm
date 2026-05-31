; lexer.asm — Modular lexer entry point.
; The scanner loop, operator handling, comment handling, and literal scanning
; are split into separate files under lexer/ for maintainability.
; They share local labels (.loop, .fail, .eof, etc.) via include within
; the lex_source_subset function scope.

include "compiler/fasm/lexer/scanner.asm"
include "compiler/fasm/lexer/operators.asm"
include "compiler/fasm/lexer/comments.asm"
include "compiler/fasm/lexer/literals.asm"
