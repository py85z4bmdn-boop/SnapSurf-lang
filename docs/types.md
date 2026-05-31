# SnapSurf Foundation Types

The FASM foundation has explicit type IDs and a fixed-capacity descriptor table
defined in `compiler/fasm/inc/types.inc`.

Implemented semantic behavior:

- Integer local declarations accept the implemented primitive widths parsed by
  `parse_type_keyword`; implicit width coercion is rejected.
- `TYPE_BOOL` exists for `true` and `false` literals so bool-vs-i32 errors are
  explicit instead of accidental.
- Symbol table entries store a type tag in `sym_type`.
- `type_init` pre-populates primitive descriptors in `type_table`.
- `type_check_binary` is the single compatibility gate for implemented
  arithmetic operators.
- `type_intern_ptr` and `type_intern_array` intern descriptor-table entries for
  pointer and fixed-size array source syntax.

Reserved but not implemented yet:

- floats
- `char`, `str`, unit, never
- reference, slice, tuple, function, and enum tags

The reserved IDs and descriptor layout are not a capability claim. They prevent
the semantic layer from hardcoding a one-type universe while the compiler is
still narrow.
