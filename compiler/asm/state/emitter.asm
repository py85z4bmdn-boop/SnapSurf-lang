section .bss
emit_requested: resb 1
out_fd: resq 1
num_buf: resb 32
break_label_stack: resq SCOPE_CAP
continue_label_stack: resq SCOPE_CAP
loop_depth: resq 1
