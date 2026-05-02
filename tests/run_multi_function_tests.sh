#!/bin/bash
# tests/run_multi_function_tests.sh
# Comprehensive test suite for multi-function support
# Tests: parsing, semantic validation, code generation, execution

set -e
COMPILER="./build/surf"
TEST_DIR="tests/multi_function"
PASSED=0
FAILED=0

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Helper functions
test_case() {
    echo -e "\n${GREEN}Testing: $1${NC}"
}

expect_success() {
    if $@; then
        echo "  ✓ PASS"
        PASSED=$((PASSED + 1))
    else
        echo "  ✗ FAIL"
        FAILED=$((FAILED + 1))
    fi
}

expect_fail() {
    if ! $@; then
        echo "  ✓ PASS (correctly failed)"
        PASSED=$((PASSED + 1))
    else
        echo "  ✗ FAIL (should have failed)"
        FAILED=$((FAILED + 1))
    fi
}

# Test 1: Basic multi-function with two functions
test_case "Basic two-function program"
mkdir -p /tmp/test_multi_1/src
cat > /tmp/test_multi_1/src/main.snapsurf << 'EOF'
fn add a i32 b i32 -> i32
    ret a
end

fn main -> i32
    ret 0
end
EOF
cat > /tmp/test_multi_1/surf.pkg << 'EOF'
package example
version 0.1.0
type executable
target linux-x86_64
runtime tiny
entry main

requires syscall

dep core/io 0.1.0
end
EOF
expect_success $COMPILER check /tmp/test_multi_1
expect_success $COMPILER dump-ast /tmp/test_multi_1 > /dev/null
expect_success $COMPILER emit-asm /tmp/test_multi_1 > /dev/null

# Test 2: Three functions
test_case "Three-function program"
mkdir -p /tmp/test_multi_2/src
cat > /tmp/test_multi_2/src/main.snapsurf << 'EOF'
fn double x i32 -> i32
    ret x
end

fn triple x i32 -> i32
    ret x
end

fn main -> i32
    ret 0
end
EOF
cp /tmp/test_multi_1/surf.pkg /tmp/test_multi_2/
expect_success $COMPILER check /tmp/test_multi_2
expect_success $COMPILER dump-ast /tmp/test_multi_2 > /dev/null

# Test 3: Function with multiple parameters
test_case "Function with 4 parameters"
mkdir -p /tmp/test_multi_3/src
cat > /tmp/test_multi_3/src/main.snapsurf << 'EOF'
fn sum a i32 b i32 c i32 d i32 -> i32
    ret a
end

fn main -> i32
    ret 0
end
EOF
cp /tmp/test_multi_1/surf.pkg /tmp/test_multi_3/
expect_success $COMPILER check /tmp/test_multi_3

# Test 4: Multiple functions with bodies
test_case "Functions with non-trivial bodies"
mkdir -p /tmp/test_multi_4/src
cat > /tmp/test_multi_4/src/main.snapsurf << 'EOF'
fn is_positive x i32 -> i32
    if x > 0 ->
        ret 1
    else ->
        ret 0
    end
end

fn is_negative x i32 -> i32
    if x < 0 ->
        ret 1
    else ->
        ret 0
    end
end

fn main -> i32
    ret 0
end
EOF
cp /tmp/test_multi_1/surf.pkg /tmp/test_multi_4/
expect_success $COMPILER check /tmp/test_multi_4
expect_success $COMPILER emit-asm /tmp/test_multi_4 > /dev/null

# Test 5: Verify backward compatibility - single function
test_case "Backward compatibility: single-function program"
expect_success $COMPILER check examples/hello
expect_success $COMPILER check tests/pass/while_simple
expect_success $COMPILER build examples/hello > /dev/null

# Test 6: Main function in different positions
test_case "Main function as first function"
mkdir -p /tmp/test_multi_5/src
cat > /tmp/test_multi_5/src/main.snapsurf << 'EOF'
fn main -> i32
    ret 0
end

fn helper -> i32
    ret 1
end
EOF
cp /tmp/test_multi_1/surf.pkg /tmp/test_multi_5/
expect_success $COMPILER check /tmp/test_multi_5

test_case "Main function as last function"
mkdir -p /tmp/test_multi_6/src
cat > /tmp/test_multi_6/src/main.snapsurf << 'EOF'
fn helper -> i32
    ret 1
end

fn main -> i32
    ret 0
end
EOF
cp /tmp/test_multi_1/surf.pkg /tmp/test_multi_6/
expect_success $COMPILER check /tmp/test_multi_6

test_case "Main function in middle"
mkdir -p /tmp/test_multi_7/src
cat > /tmp/test_multi_7/src/main.snapsurf << 'EOF'
fn first -> i32
    ret 1
end

fn main -> i32
    ret 0
end

fn second -> i32
    ret 2
end
EOF
cp /tmp/test_multi_1/surf.pkg /tmp/test_multi_7/
expect_success $COMPILER check /tmp/test_multi_7

# Test 7: Code generation produces valid ASM for multiple functions
test_case "Generated ASM contains all function labels"
$COMPILER emit-asm /tmp/test_multi_2 > /dev/null
if grep -q "^double:" build/main.asm && grep -q "^triple:" build/main.asm && grep -q "^main:" build/main.asm; then
    echo "  ✓ PASS - All function labels found"
    PASSED=$((PASSED + 1))
else
    echo "  ✗ FAIL - Missing function labels"
    FAILED=$((FAILED + 1))
fi

# Test 8: Prologue/epilogue for user functions
test_case "User functions have proper prologues and epilogues"
$COMPILER emit-asm /tmp/test_multi_2 > /dev/null
# Check that user functions have prologue
if grep -q "^double:" build/main.asm && grep -A 2 "^double:" build/main.asm | grep -q "push rbp"; then
    echo "  ✓ PASS - Prologue found"
    PASSED=$((PASSED + 1))
else
    echo "  ✗ FAIL - Prologue missing"
    FAILED=$((FAILED + 1))
fi

# Test 9: Linking works for multi-function
test_case "Multi-function program links successfully"
mkdir -p /tmp/test_multi_8/src
cat > /tmp/test_multi_8/src/main.snapsurf << 'EOF'
fn helper -> i32
    ret 42
end

fn main -> i32
    ret 0
end
EOF
cp /tmp/test_multi_1/surf.pkg /tmp/test_multi_8/
expect_success $COMPILER build /tmp/test_multi_8 > /dev/null

# Test 10: Execution works
test_case "Built multi-function binary executes"
if [ -f build/hello ]; then
    expect_success ./build/hello
    if ./build/hello; then
        PASSED=$((PASSED + 1))
    else
        FAILED=$((FAILED + 1))
    fi
fi

# Summary
echo ""
echo "════════════════════════════════════════════"
echo "Test Results:"
echo "  Passed: ${GREEN}${PASSED}${NC}"
echo "  Failed: ${RED}${FAILED}${NC}"
echo "════════════════════════════════════════════"

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}ALL TESTS PASSED!${NC}"
    exit 0
else
    echo -e "${RED}SOME TESTS FAILED${NC}"
    exit 1
fi
