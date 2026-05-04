section .bss
ast_count: resq 1
ast_root: resq 1
ast_main_fn: resq 1
ast_block_node: resq 1
ast_block_node_saved: resq 1
ast_call_stmt: resq 1
ast_ret_stmt: resq 1
ast_error_flag: resq 1
ast_buf: resb AST_CAP * AST_SIZE
ast_type_tag: resq AST_CAP
