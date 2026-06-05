#!/bin/sh
set -eu

mkdir -p build/test-output

if [ -e Cargo.toml ] || [ -e Cargo.lock ] || [ -e package.json ] || [ -e tsconfig.json ] || [ -e pyproject.toml ] || [ -e setup.py ] || [ -e Makefile ] || [ -e build.zig ] || [ -e go.mod ]; then
    echo "forbidden root build metadata exists"
    exit 1
fi

file build/surf > build/test-output/surf.file
grep "ELF 64-bit" build/test-output/surf.file > /dev/null

if strings build/surf | grep -i "cargo" > /dev/null; then
    echo "build/surf contains cargo reference"
    exit 1
fi
if strings build/surf | grep -i "nasm" > /dev/null; then
    echo "build/surf contains nasm reference"
    exit 1
fi
if strings build/surf | grep -i "rust" > /dev/null; then
    echo "build/surf contains rust reference"
    exit 1
fi
if strings build/surf | grep -i "prototypes" > /dev/null; then
    echo "build/surf contains prototypes reference"
    exit 1
fi
if strings build/surf | grep -i "rust_stage0" > /dev/null; then
    echo "build/surf contains rust_stage0 reference"
    exit 1
fi

./build/surf check examples/hello
./build/surf check examples/test_if > build/test-output/example_test_if.check
./build/surf check examples/test_bool > build/test-output/example_test_bool.check
./build/surf check examples/simple_compare > build/test-output/example_simple_compare.check

./build/surf dump-tokens examples/hello > build/test-output/hello.tokens
cmp build/test-output/hello.tokens tests/lexer/hello.tokens.expected
grep '^TokEof$' build/test-output/hello.tokens > /dev/null
hello_token_count="$(grep -c '^Tok' build/test-output/hello.tokens)"
if [ "$hello_token_count" != "25" ]; then
    echo "unexpected hello token count: $hello_token_count"
    exit 1
fi

./build/surf dump-tokens tests/compile_fail/missing_end > build/test-output/missing_end.tokens
cmp build/test-output/missing_end.tokens tests/lexer/missing_end.tokens.expected

./build/surf dump-ast examples/hello > build/test-output/hello.ast
cmp build/test-output/hello.ast tests/parser/hello.ast.expected
grep '^AstSourceFile$' build/test-output/hello.ast > /dev/null
grep '^AstUseDecl$' build/test-output/hello.ast > /dev/null
grep '^AstFnDecl$' build/test-output/hello.ast > /dev/null
grep '^AstCallStmt$' build/test-output/hello.ast > /dev/null
grep '^AstRetStmt$' build/test-output/hello.ast > /dev/null

./build/surf emit-asm examples/hello
cmp build/main.asm tests/golden_asm/hello.asm.expected

./build/surf build examples/hello
./build/hello > build/test-output/hello.out
diff -u tests/expected/hello.out build/test-output/hello.out

rm -rf build/test-output/anti
mkdir -p build/test-output/anti/src
cp examples/hello/surf.pkg build/test-output/anti/surf.pkg
cp examples/hello/src/main.snapsurf build/test-output/anti/src/main.snapsurf
./build/surf build build/test-output/anti
cp build/main.asm build/test-output/anti_hello.asm
./build/hello > build/test-output/anti_hello.out
diff -u tests/expected/hello.out build/test-output/anti_hello.out

cp tests/anti_hardcode/main_alt.snapsurf build/test-output/anti/src/main.snapsurf
./build/surf build build/test-output/anti
if cmp build/test-output/anti_hello.asm build/main.asm > /dev/null; then
    echo "anti-hardcode failed: generated ASM did not change"
    exit 1
fi
./build/hello > build/test-output/anti_alt.out
diff -u tests/expected/anti_hardcode.out build/test-output/anti_alt.out

run_exit() {
    name="$1"
    expected="$2"
    ./build/surf build "tests/pass/$name" > "build/test-output/$name.build"
    set +e
    ./build/hello > "build/test-output/$name.out"
    code="$?"
    set -e
    if [ "$code" != "$expected" ]; then
        echo "unexpected exit for $name: got $code expected $expected"
        exit 1
    fi
}

run_stderr() {
    name="$1"
    expected="$2"
    ./build/surf build "tests/pass/$name" > "build/test-output/$name.build"
    ./build/hello > "build/test-output/$name.stdout" 2> "build/test-output/$name.stderr"
    test ! -s "build/test-output/$name.stdout"
    diff -u "$expected" "build/test-output/$name.stderr"
}

run_stdout() {
    name="$1"
    expected="$2"
    ./build/surf build "tests/pass/$name" > "build/test-output/$name.build"
    ./build/hello > "build/test-output/$name.stdout" 2> "build/test-output/$name.stderr"
    test ! -s "build/test-output/$name.stderr"
    diff -u "$expected" "build/test-output/$name.stdout"
}

run_raw_binary() {
    name="$1"
    expected_hex="$2"
    ./build/surf build-raw "tests/pass/$name" > "build/test-output/$name.build"
    actual_hex="$(od -An -tx1 -v build/raw.bin)"
    if [ "$actual_hex" != "$expected_hex" ]; then
        echo "unexpected raw bytes for $name: $actual_hex"
        exit 1
    fi
}

run_raw_hex_compact() {
    name="$1"
    expected_hex="$2"
    ./build/surf build-raw "tests/pass/$name" > "build/test-output/$name.build"
    actual_hex="$(od -An -tx1 -v build/raw.bin | tr -d ' \n')"
    if [ "$actual_hex" != "$expected_hex" ]; then
        echo "unexpected compact raw bytes for $name: $actual_hex"
        exit 1
    fi
}

run_fasm_hex_compact() {
    name="$1"
    expected_hex="$2"
    ./build/surf build-fasm "tests/pass/$name" > "build/test-output/$name.build"
    actual_hex="$(od -An -tx1 -v build/fasm.bin | tr -d ' \n')"
    if [ "$actual_hex" != "$expected_hex" ]; then
        echo "unexpected compact build-fasm bytes for $name: $actual_hex"
        exit 1
    fi
}

run_boot_sector() {
    name="$1"
    ./build/surf build-raw "tests/pass/$name" > "build/test-output/$name.build"
    size="$(wc -c < build/raw.bin)"
    first_bytes="$(od -An -tx1 -N2 build/raw.bin)"
    signature="$(od -An -tx1 -j510 -N2 build/raw.bin)"
    if [ "$size" != "512" ] || [ "$first_bytes" != " fa f4" ] || [ "$signature" != " 55 aa" ]; then
        echo "unexpected boot sector for $name: size=$size first=$first_bytes sig=$signature"
        exit 1
    fi
}

run_pe64_import() {
    name="$1"
    ./build/surf build-fasm "tests/pass/$name" > "build/test-output/$name.build"
    mz="$(od -An -tx1 -N2 build/fasm.bin)"
    pe_off="$(od -An -tu4 -j60 -N4 build/fasm.bin | tr -d ' ')"
    pe_sig="$(od -An -tx1 -j "$pe_off" -N4 build/fasm.bin)"
    machine_off=$((pe_off + 4))
    optional_off=$((pe_off + 24))
    machine="$(od -An -tx1 -j "$machine_off" -N2 build/fasm.bin)"
    optional_magic="$(od -An -tx1 -j "$optional_off" -N2 build/fasm.bin)"
    if [ "$mz" != " 4d 5a" ] || [ "$pe_sig" != " 50 45 00 00" ] || [ "$machine" != " 64 86" ] || [ "$optional_magic" != " 0b 02" ]; then
        echo "unexpected PE64 header for $name: mz=$mz pe=$pe_sig machine=$machine magic=$optional_magic"
        exit 1
    fi
    strings -a build/fasm.bin | grep "KERNEL32.DLL" > /dev/null
    strings -a build/fasm.bin | grep "ExitProcess" > /dev/null
    strings -a build/fasm.bin | grep ".idata" > /dev/null
}

run_exit let_integer 10
run_exit inline_asm_exit 37
run_exit inline_asm_data_calc 42
run_raw_binary raw_binary_format " 7f 53 53 00"
run_raw_hex_compact raw_mode_layout "b844332211887766559090909090909048b888776655443322110807060504030201"
run_boot_sector raw_boot_sector
run_pe64_import fasm_pe64_import
run_fasm_hex_compact fasm_metaprogram "2a534601020304050607"
run_exit mut_arithmetic 16
run_exit precedence 7
run_exit paren_expr 9
run_exit binary_sub_var 7
run_exit div_mod 8
run_exit unary_minus 2
run_exit function_call 42
run_exit function_recursion 120
run_exit function_mutual_recursion 11
run_exit main_after_helper 0
run_exit elif_chain 2
run_stdout print_builtin tests/expected/print.out
run_stdout print_i64 tests/expected/print_i64.out
run_stdout print_u64 tests/expected/print_u64.out
run_exit while_simple 10
run_exit while_break 5
run_exit while_continue 45
run_exit loop_break 7
run_exit scoping 10
run_exit const_folding_simple 14
run_exit arithmetic_pow 32
run_exit math_builtins 8
run_exit math_unsigned_builtins 0
run_exit bitcount_builtins 192
run_exit bitcount_widths 165
run_exit gcd_lcm_builtins 6
run_exit integer_sqrt_builtin 0
run_exit integer_cbrt_builtin 0
run_exit runtime_lcm_overflow 108
run_stderr eprint_builtin tests/expected/eprint.out
run_stderr eprint_i64 tests/expected/eprint_i64.out
run_stderr eprint_u64 tests/expected/eprint_u64.out
run_stderr io_write_stderr_fd tests/expected/io_write_stderr.out
run_stdout io_write_multiple_strings tests/expected/io_write_multiple.out
run_exit bitwise_not 15
run_exit bitwise_not_width 0
run_exit bitwise_and 8
run_exit bitwise_or 15
run_exit bitwise_xor 9
run_exit bitwise_shl 16
run_exit bitwise_shr 10
run_exit bitwise_rol 1
run_exit bitwise_ror 16
run_exit bitwise_rotate_width 0
run_exit pointer_deref 100
run_exit pointer_to_pointer 77
run_exit array_index_basic 0
run_exit array_index_usize 0
run_exit array_index_expr_preserves_base 0
run_exit array_index_runtime_oob 101
run_exit array_index_runtime_negative 101
run_exit primitive_i64 0
run_exit primitive_pointer_sized 0
run_exit typed_int_literal_compare 0
run_exit integer_literal_boundaries 0
run_exit negative_integer_literals 0
run_exit integer_width_wrap 0
run_exit integer_width_param 0
run_exit integer_width_return 0
run_exit integer_unsigned_ordering 0
run_exit integer_width_expr 0
run_exit integer_unsigned_div_mod 0
run_exit runtime_division_by_zero 102
run_exit runtime_modulo_by_zero 102
run_exit runtime_division_overflow 103
run_exit runtime_modulo_overflow 103
run_exit runtime_add_overflow 104
run_exit runtime_sub_no_overflow 0
run_exit runtime_sub_overflow 105
run_exit runtime_mul_no_overflow 0
run_exit runtime_mul_overflow 106
run_exit runtime_pow_no_overflow 0
run_exit runtime_pow_overflow 107
run_exit runtime_upow_no_overflow 0
run_exit runtime_upow_overflow 113
run_exit runtime_abs_overflow 109
run_exit runtime_unsigned_arith_no_overflow 0
run_exit runtime_uadd_overflow 110
run_exit runtime_usub_overflow 111
run_exit runtime_umul_overflow 112
run_exit constant_add_overflow 104
run_exit constant_mul_overflow 106
run_exit constant_pow_overflow 107
run_exit constant_unsigned_no_overflow 0
run_exit constant_uadd_overflow 110
run_exit constant_usub_overflow 111
run_exit constant_umul_overflow 112
run_exit constant_upow_overflow 113
run_exit wrapping_arithmetic 0
run_exit wrapping_pow_arithmetic 0
run_exit wrapping_div_mod_arithmetic 0
run_exit saturating_arithmetic 0
run_exit saturating_signed_arithmetic 0
run_exit saturating_narrow_arithmetic 0
run_exit saturating_pow_arithmetic 0
run_exit saturating_div_mod_arithmetic 0
run_exit struct_field_access 0

run_fail() {
    name="$1"
    if ./build/surf check "tests/compile_fail/$name" > "build/test-output/$name.out" 2>&1; then
        echo "expected failure for $name"
        exit 1
    fi
    diff -u "tests/compile_fail/$name.expected" "build/test-output/$name.out"
}

run_fail wrong_extension
run_fail missing_pkg
run_fail missing_main
run_fail missing_end
run_fail no_syscall
run_fail invalid_bom
# run_fail invalid_char
run_fail unterminated_string
run_fail invalid_escape
run_fail invalid_use
run_fail invalid_main_signature
run_fail unsupported_expression
run_fail immutable_assign
run_fail undefined_symbol
run_fail duplicate_symbol
run_fail symbol_overflow
run_fail let_mut_rejected
run_fail bool_arithmetic
run_fail function_arity
run_fail break_outside_loop
run_fail continue_outside_loop
run_fail extra_top_level_end
run_fail conditional_return_missing
run_fail primitive_mismatch
run_fail array_index_literal_oob
run_fail array_index_negative_literal
run_fail integer_literal_range
run_fail integer_literal_overflow
run_fail negative_integer_literal_range
run_fail division_by_zero_literal
run_fail modulo_by_zero_literal
run_fail division_by_zero_const_expr
run_fail modulo_by_zero_const_expr
run_fail division_by_zero_nested_const_expr
run_fail modulo_by_zero_nested_const_expr
run_fail unsupported_i128_type
run_fail unsupported_u128_type
run_fail unsupported_f32_type
run_fail unsupported_f64_type
run_fail unsupported_char_type
run_fail unsupported_unit_type
run_fail unsupported_param_i128_type
run_fail unsupported_return_f32_type
run_fail unsupported_for_loop
run_fail unsupported_goto
run_fail unsupported_match
run_fail unsupported_switch
run_fail fn_arg_type_mismatch
run_fail fn_struct_arg_mismatch

run_struct_sample() {
    name="$1"
    ./build/surf check "samples/$name" > "build/test-output/sample_$name.out" 2>&1
    grep '^check ok$' "build/test-output/sample_$name.out" > /dev/null
}

run_struct_sample_fail() {
    name="$1"
    expected="$2"
    if ./build/surf check "samples/$name" > "build/test-output/sample_$name.out" 2>&1; then
        echo "expected struct sample failure for $name"
        exit 1
    fi
    grep "$expected" "build/test-output/sample_$name.out" > /dev/null
}

run_struct_sample struct_assign_prim
run_struct_sample struct_basic
run_struct_sample struct_field
run_struct_sample struct_field_types
run_struct_sample struct_literal_fields
run_struct_sample struct_literal_init
run_struct_sample struct_literal_multi
run_struct_sample struct_minimal
run_struct_sample struct_multi
run_struct_sample struct_multi_types
run_struct_sample struct_param
run_struct_sample struct_param_assign
run_struct_sample struct_return
run_struct_sample struct_short
run_struct_sample struct_single_field
run_struct_sample struct_two_field_test
run_struct_sample struct_two_fields
run_struct_sample struct_var
run_struct_sample test_struct_field
run_struct_sample_fail struct_invalid "E0206 invalid struct declaration"
run_struct_sample_fail struct_type_mismatch "E0403 return type mismatch"

echo "foundation fasm tests passed"
