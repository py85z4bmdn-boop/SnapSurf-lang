#!/bin/sh
set -eu

case "$(uname -s)" in
    Linux) ;;
    *)
        echo "samples/fasm_vector_add requires Linux x86_64" >&2
        exit 1
        ;;
esac

case "$(uname -m)" in
    x86_64) ;;
    *)
        echo "samples/fasm_vector_add requires Linux x86_64" >&2
        exit 1
        ;;
esac

cd "$(dirname "$0")"

cc_bin="${CC:-cc}"
build_dir="../../build/prompt-demo"
obj_file="$build_dir/vector_add_i32_sse2.o"
exe_file="$build_dir/vector_add_bench"

mkdir -p "$build_dir"

fasm vector_add_i32_sse2.asm "$obj_file"
"$cc_bin" \
    -std=c11 \
    -O2 \
    -Wall \
    -Wextra \
    -Werror \
    -fno-tree-vectorize \
    vector_add_bench.c \
    "$obj_file" \
    -o "$exe_file"

"$exe_file"
