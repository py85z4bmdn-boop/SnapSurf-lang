section .bss
token_count: resq 1
token_index: resq 1
token_buf: resb TOKEN_CAP * TOKEN_SIZE
string_pool_len: resq 1
str_buf: resb MAX_STRING
