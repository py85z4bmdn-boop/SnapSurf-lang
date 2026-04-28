; SnapSurf foundation type IDs and descriptor layout.
; Current executable subset only accepts TYPE_I32 local declarations and
; TYPE_BOOL literals for diagnostics. The wider primitive tag space is reserved
; now so semantic tables do not bake in a one-type universe.

%define TYPE_DESC_SIZE 16
%define TYPE_DESC_KIND 0
%define TYPE_DESC_MUT 1
%define TYPE_DESC_INNER 4
%define TYPE_DESC_SIZE_PARAM 8

%define TYPE_KIND_INVALID 0
%define TYPE_KIND_PRIM 1
%define TYPE_KIND_PTR 2
%define TYPE_KIND_ARRAY 3
%define TYPE_KIND_SLICE 4
%define TYPE_KIND_TUPLE 5
%define TYPE_KIND_FN 6
%define TYPE_KIND_STRUCT 7
%define TYPE_KIND_ENUM 8

%define TYPE_MUT_CONST 0
%define TYPE_MUT_MUT 1

%define TYPE_TBL_CAP 256
%define TYPE_PRIMITIVE_COUNT 20

%define TYPE_INVALID 0
%define TYPE_I8 1
%define TYPE_I16 2
%define TYPE_I32 3
%define TYPE_I64 4
%define TYPE_I128 5
%define TYPE_ISIZE 6
%define TYPE_U8 7
%define TYPE_U16 8
%define TYPE_U32 9
%define TYPE_U64 10
%define TYPE_U128 11
%define TYPE_USIZE 12
%define TYPE_F32 13
%define TYPE_F64 14
%define TYPE_BOOL 15
%define TYPE_CHAR 16
%define TYPE_STR 17
%define TYPE_UNIT 18
%define TYPE_NEVER 19
%define TYPE_PTR 20
%define TYPE_REF 21
%define TYPE_ARRAY 22
%define TYPE_SLICE 23
%define TYPE_TUPLE 24
%define TYPE_FN 25
%define TYPE_STRUCT 26
%define TYPE_ENUM 27
