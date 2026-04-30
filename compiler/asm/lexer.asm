; lexer.asm — Modular lexer entry point.
; The scanner loop, operator handling, comment handling, and literal scanning
; are split into separate files under lexer/ for maintainability.
; They share local labels (.loop, .fail, .eof, etc.) via %include within
; the lex_source_subset function scope.

%include "compiler/asm/lexer/scanner.asm"
%include "compiler/asm/lexer/operators.asm"
%include "compiler/asm/lexer/comments.asm"
%include "compiler/asm/lexer/literals.asm"
