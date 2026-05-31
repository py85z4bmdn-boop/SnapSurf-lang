segment readable writeable
sym_count: rq 1
local_count: rq 1
slot_cursor: rq 1
scope_depth: rq 1
semantic_loop_depth: rq 1
semantic_unsafe_depth: rq 1
return_seen: rb 1
sym_start: rq SYM_CAP
sym_len: rq SYM_CAP
sym_mut: rq SYM_CAP
sym_type: rq SYM_CAP
sym_slot: rq SYM_CAP
scope_sym_base: rq SCOPE_CAP
scope_slot_base: rq SCOPE_CAP
type_count: rq 1
type_table: rb TYPE_TBL_CAP * TYPE_DESC_SIZE
parsed_str_len: rq 1
parsed_io_len: rq 1
parsed_ret_value: rq 1
has_syscall: rb 1
has_io_write: rb 1

; Multi-function support: function registry
fn_registry_count: rq 1
fn_name_start: rq 256
fn_name_len: rq 256
fn_param_count: rq 256
fn_return_type: rq 256
fn_ast_node: rq 256
fn_emit_counter: rq 1
current_fn_param_count: rq 1
current_fn_return_type: rq 1
tmp_saved_block: rq 1

; Struct registry: track defined struct types
struct_registry_count: rq 1
struct_name_start: rq 256
struct_name_len: rq 256
struct_type_id: rq 256
struct_field_count: rq 256
struct_ast_node: rq 256
struct_first_field_node: rq 256    ; Node ID of first field node (bypass ast_child)

; Field registry: store field information for field lookup
; Flat table: max 256 structs * max 10 fields = 2560 field entries
field_registry_count: rq 1
field_struct_id: rq 2560           ; Which struct this field belongs to
field_name_buf_pos: rq 1           ; Current position in field_name_buf  
field_name_start: rq 2560          ; Field name offset in field_name_buf (not src_buf!)
field_name_len: rq 2560            ; Field name length
field_type: rq 2560                ; Field type ID
field_name_buf: rb 25600           ; 10KB buffer for field names
