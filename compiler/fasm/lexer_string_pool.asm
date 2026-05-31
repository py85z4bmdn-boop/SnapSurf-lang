; Status: PARTIAL.
; String literal byte pool write path for the foundation lexer.

string_store_al:
    push rbx
    mov rbx, [tmp_payload]
    add rbx, r8
    cmp rbx, MAX_STRING
    jae .skip
    mov [str_buf + rbx], al
.skip:
    pop rbx
    ret
