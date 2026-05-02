%define AST_NONE 0
%define AST_SOURCE_FILE 1
%define AST_USE_DECL 2
%define AST_FN_DECL 3
%define AST_BLOCK 4
%define AST_RET_STMT 5
%define AST_CALL_STMT 6
%define AST_INT_LIT 7
%define AST_STR_LIT 8
%define AST_IDENT 9
%define AST_PATH 10
%define AST_ERROR 11
%define AST_LET_STMT 12
%define AST_MUT_STMT 13
%define AST_ASSIGN_STMT 14
%define AST_VAR_REF 15
%define AST_BOOL_LIT 16
%define AST_BIN_ADD 17
%define AST_BIN_SUB 18
%define AST_BIN_MUL 19
%define AST_BIN_DIV 20
%define AST_BIN_MOD 21
%define AST_UNARY_NEG 22
%define AST_BIN_GT 23
%define AST_BIN_LT 24
%define AST_BIN_GE 25
%define AST_BIN_LE 26
%define AST_BIN_EE 27
%define AST_BIN_NE 28
%define AST_BIN_AND 29
%define AST_BIN_OR 30
%define AST_UNARY_NOT 31
%define AST_IF_STMT 32
%define AST_WHILE_STMT 33
%define AST_LOOP_STMT 34
%define AST_BREAK_STMT 35
%define AST_CONTINUE_STMT 42

; Multi-function support additions
%define AST_FN_PARAM 43
%define AST_FN_CALL_EXPR 44
%define AST_UNSAFE_FN 45
%define AST_UNSAFE_BLOCK 46

; Pointer operations
%define AST_ADDR_OF 47
%define AST_DEREF 48

; Array operations
%define AST_ARRAY_INDEX 49

; New language features
%define AST_ELIF_CLAUSE 50
%define AST_CONST_DECL 51
%define AST_PRINT_STMT 52

; Foundation v0 extensions (manual memory + raw pointer ops)
%define AST_MEM_MALLOC_EXPR 36
%define AST_MEM_LOAD_I32_EXPR 37
%define AST_MEM_FREE_STMT 38
%define AST_MEM_STORE_I32_STMT 39

%define AST_CAP 1024
%define AST_KIND 0
%define AST_SPAN_START 8
%define AST_SPAN_END 16
%define AST_CHILD_OR_DATA 24
%define AST_NEXT_OR_EXTRA 32
%define AST_SIZE 40

%define FN_REG_CAP 256
