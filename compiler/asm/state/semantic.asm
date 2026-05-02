section .bss
sym_count: resq 1
local_count: resq 1
slot_cursor: resq 1
scope_depth: resq 1
return_seen: resb 1
sym_start: resq SYM_CAP
sym_len: resq SYM_CAP
sym_mut: resq SYM_CAP
sym_type: resq SYM_CAP
sym_slot: resq SYM_CAP
scope_sym_base: resq SCOPE_CAP
scope_slot_base: resq SCOPE_CAP
type_count: resq 1
type_table: resb TYPE_TBL_CAP * TYPE_DESC_SIZE
parsed_str_len: resq 1
parsed_io_len: resq 1
parsed_ret_value: resq 1
has_syscall: resb 1
has_io_write: resb 1

; Multi-function support: function registry
fn_registry_count: resq 1
fn_name_start: resq 256
fn_name_len: resq 256
fn_param_count: resq 256
fn_ast_node: resq 256
fn_emit_counter: resq 1
current_fn_param_count: resq 1
tmp_saved_block: resq 1
