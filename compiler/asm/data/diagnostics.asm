section .data
err_bom: db "E0001 UTF-8 BOM is not allowed", 0
err_utf8: db "E0002 invalid UTF-8 sequence", 0
err_ext: db "E0003 source file must use .snapsurf extension", 0
err_unterm_string: db "E0101 unterminated string literal", 0
err_bad_escape: db "E0102 invalid escape sequence", 0
err_bad_char: db "E0103 invalid character", 0
err_eof: db "E0104 unexpected EOF", 0
err_token_overflow: db "E0105 token buffer overflow", 0
err_expected: db "E0201 expected token", 0
err_missing_end: db "E0202 missing end", 0
err_unexpected_end: db "E0203 unexpected end", 0
err_bad_fn: db "E0204 invalid function declaration", 0
err_bad_fn_name: db "E0204 function name expected", 0
err_bad_fn_sig: db "E0204 invalid function signature", 0
err_bad_return_type: db "E0204 invalid return type", 0
err_bad_param_name: db "E0204 parameter name expected", 0
err_bad_param_type: db "E0204 parameter type expected", 0
err_missing_arrow: db "E0204 '->' expected in function signature", 0
err_bad_use: db "E0205 invalid use declaration", 0
err_fn_registry_overflow: db "E0301 function registry overflow (max 128 functions)", 0
err_fn_not_found: db "E0404 function not found", 0
err_fn_param_mismatch: db "E0404 function call argument count mismatch", 0
err_no_functions: db "E0400 no functions found in source file", 0
err_no_main: db "E0401 main function not found", 0
err_bad_main: db "E0402 invalid main signature", 0
err_ret: db "E0403 return type mismatch", 0
err_bad_cond: db "E0403 condition must be boolean", 0
err_unsup_expr: db "E0404 unsupported token in foundation: ", 0
err_unsup_ast: db "E0404 unsupported AST in foundation", 0
err_len_mismatch: db "E0404 string literal length does not match explicit io.write length", 0
err_type: db "E0501 type mismatch", 0
err_duplicate: db "E0502 duplicate definition", 0
err_undefined: db "E0503 undefined symbol", 0
err_immutable: db "E0504 cannot assign immutable binding", 0
err_symbol_overflow: db "E0505 symbol table overflow", 0
err_scope_overflow: db "E0506 scope depth exceeded", 0
err_ast_overflow: db "E0301 AST arena overflow", 0
err_cap: db "E0801 missing required capability", 0
err_syscall_cap: db "E0802 syscall used without requires syscall", 0
err_no_pkg: db "E0901 surf.pkg not found", 0
err_bad_pkg: db "E0902 invalid surf.pkg", 0
err_missing_field: db "E0903 missing required package field", 0
err_bad_target: db "E0904 unsupported target", 0
err_bad_runtime: db "E0905 unsupported runtime", 0
err_no_main_src: db "E0906 executable package requires src/main.snapsurf", 0
err_emit_failed: db "E1001 NASM emit failed", 0
err_artifact: db "E1002 build artifact path error", 0
err_build_failed: db "E1001 NASM emit failed", 0

colon_z: db ":", 0
space_z: db " ", 0
newline_z: db 10, 0
