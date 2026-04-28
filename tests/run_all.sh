#!/bin/sh
set -eu

mkdir -p build/test-output

if [ -e Cargo.toml ] || [ -e Cargo.lock ] || [ -e package.json ] || [ -e tsconfig.json ] || [ -e pyproject.toml ] || [ -e setup.py ] || [ -e CMakeLists.txt ] || [ -e build.zig ] || [ -e go.mod ]; then
    echo "forbidden root build metadata exists"
    exit 1
fi

file build/surf > build/test-output/surf.file
grep "ELF 64-bit" build/test-output/surf.file > /dev/null

if strings build/surf | grep -i "cargo" > /dev/null; then
    echo "build/surf contains cargo reference"
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

run_exit let_integer 10
run_exit mut_arithmetic 16
run_exit precedence 7
run_exit paren_expr 9
run_exit div_mod 8
run_exit unary_minus 2

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
run_fail invalid_char
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

echo "foundation asm tests passed"
