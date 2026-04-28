# SnapSurf Foundation Types

The ASM foundation has explicit type IDs and a fixed-capacity descriptor table
defined in `compiler/inc/types.inc`.

Implemented semantic behavior:

- `TYPE_I32` is the only accepted local declaration type.
- `TYPE_BOOL` exists for `true` and `false` literals so bool-vs-i32 errors are
  explicit instead of accidental.
- Symbol table entries store a type tag in `sym_type`.
- `type_init` pre-populates primitive descriptors in `type_table`.
- `type_check_binary` is the single compatibility gate for implemented
  arithmetic operators.
- `type_intern_ptr` exists as the first descriptor-table insertion path, but no
  source syntax reaches pointer types yet.

Reserved but not implemented yet:

- signed and unsigned integer widths
- floats
- `char`, `str`, unit, never
- pointer, reference, array, slice, tuple, function, struct, and enum tags

The reserved IDs and descriptor layout are not a capability claim. They prevent
the semantic layer from hardcoding a one-type universe while the compiler is
still narrow.
