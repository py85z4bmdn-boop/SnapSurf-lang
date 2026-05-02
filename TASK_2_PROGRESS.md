# Multi-Function Support Implementation Progress

**Status**: Partially Complete - Architectural Foundation Laid  
**Date**: May 1, 2026

---

## Summary

I have completed **Task 2.1** (Token/AST Additions) and made progress on **Task 2.2** (Parser Improvements). The analysis revealed that implementing multi-function support in pure NASM assembly requires more substantial architectural changes than initially apparent, as the current compiler is tightly coupled around a single `main` function.

---

## Completed Work

### ✅ Task 2.1: AST/Token Additions for Multi-Function Support

**Lexer/Token Changes:**
- Added `TOK_UNSAFE` token (value 27) for `unsafe` keyword recognition
- Lexer now correctly tokenizes "unsafe" as a keyword
- Existing tokens used: `TOK_COMMA` (33), `TOK_ARROW` (30), `TOK_LPAREN` (39), `TOK_RPAREN` (40)

**AST Node Type Additions:**
- `AST_FN_PARAM` (43) - Represents function parameters  
- `AST_FN_CALL_EXPR` (44) - Represents function call expressions
- `AST_UNSAFE_FN` (45) - Marks unsafe function declarations
- `AST_UNSAFE_BLOCK` (46) - Marks unsafe code blocks

**Files Modified:**
- [compiler/inc/ast.inc](compiler/inc/ast.inc) - Added node types
- [compiler/inc/tokens.inc](compiler/inc/tokens.inc) - Added TOK_UNSAFE
- [compiler/asm/lexer_keywords.asm](compiler/asm/lexer_keywords.asm) - Added "unsafe" keyword recognition

**Verification:**
- ✅ Compiler builds successfully
- ✅ Existing tests still pass (hello world compiles and runs)

---

### ⚠️ Task 2.2: Parser Improvements (Partial Implementation)

**Completed:**
1. Created [compiler/asm/parser/functions.asm](compiler/asm/parser/functions.asm)
   - `parse_function` - Generic function parser (foundation)
   - `parse_param_list_bare` - Space-separated parameter parsing (`add a i32 b i32`)
   - `parse_param_list_paren` - Skeleton for parenthesized parameters

2. Added diagnostic error strings in [compiler/asm/data/diagnostics.asm](compiler/asm/data/diagnostics.asm):
   - `err_bad_fn_name` - Function name parsing error
   - `err_bad_fn_sig` - Function signature parsing error
   - `err_bad_return_type` - Return type parsing error
   - `err_bad_param_name` - Parameter name parsing error
   - `err_bad_param_type` - Parameter type parsing error
   - `err_missing_arrow` - Missing `->` in function signature

3. Updated [compiler/asm/parser_source.asm](compiler/asm/parser_source.asm):
   - Prepared infrastructure for multiple function parsing
   - Added `parse_function` include directive
   - Currently falls back to `parse_main_fn` for compatibility

**Current Approach (Conservative):**
Rather than replacing `parse_main_fn` with untested `parse_function`, the current implementation maintains backward compatibility by:
- Keeping `parse_main_fn` as the active parser
- Providing new `parse_function` as foundation for future enhancement
- Ensuring zero regression in existing functionality

---

## Critical Design Insights

### Why Multi-Function Support is Complex

The current SnapSurf compiler has several architectural dependencies on a single-function model:

1. **Parser Level**
   - `parse_main_fn` specifically looks for "main" function name
   - AST nodes have hardcoded references to `[ast_main_fn]` and `[ast_block_node]`
   - Single function assumption throughout parser

2. **Semantic Level**
   - `semantic_subset` processes single AST main function
   - Symbol table is scoped to one function
   - Function registry doesn't exist yet

3. **Code Generation Level**
   - `emit_main_asm` directly emits main function's AST
   - No function name/address mapping
   - No inter-function call code generation

### Architectural Changes Needed

To fully support multi-functions with parameters, the following must be refactored:

#### In Parser
```
OLD: parse_main_fn (specific to main)
NEW: parse_source_subset should loop through multiple parse_function calls
     Each parse_function call creates FnDecl node with params
```

#### In Semantic Analysis
```
OLD: Single function, all symbols in one table
NEW: Function registry (map name -> metadata)
     Per-function symbol scopes
     Parameter binding at function entry
     Cross-function call resolution
```

#### In Code Generation
```
OLD: emit_main_asm(ast_main_fn) -> generates "main:" label
NEW: For each FnDecl in AST:
     - Generate prologue (push rbp, mov rbp rsp, sub rsp ...)
     - Bind parameters to stack locations (rdi/rsi/rdx/rcx/r8/r9)
     - Emit function body statements
     - Generate epilogue (mov rsp rbp, pop rbp, ret)
     - Generate function calls with "call FUNCNAME"
```

---

## What Still Needs Implementation

### Task 2.3: Semantic Analysis (Function Registry & Parameter Binding)

**Required:**
1. Function metadata structure (in memory):
   ```
   fn_registry[] = {
     name_offset,     // offset into string pool
     name_len,        // length of name
     return_type,     // TYPE_I32, etc
     param_count,     // number of parameters
     param_types[],   // array of parameter types
     first_param_offset  // location in sym_table or stack offset
   }
   ```

2. Register-based parameter binding during semantic analysis:
   - Extract parameters from `FnDecl` AST node
   - Create symbol table entries for each parameter
   - Map parameter names to stack/register locations
   - Call sites validate parameter count and types

### Task 2.4: Code Emitter (Function Prologue/Epilogue & Calls)

**Required:**
1. Per-function prologue generation:
   ```asm
   fname:
       push rbp                    ; save old frame pointer
       mov rbp, rsp                ; establish new frame
       sub rsp, STACK_SIZE         ; allocate locals
   ```

2. Parameter setup (first 6 params via registers):
   ```asm
   ; Parameters already in: rdi, rsi, rdx, rcx, r8, r9
   ; Must store to stack under local_offset + param offset
   mov [rbp - 8], rdi              ; first param
   mov [rbp - 16], rsi             ; second param
   ; ... etc for all parameters
   ```

3. Function call code generation:
   ```asm
   ; Before calling function, push arguments in reverse order
   ; For parameters in registers: mov rdi, arg1; mov rsi, arg2; ...
   ; For spilled params: push on stack
   call function_name
   ; Return value now in rax
   ```

4. Epilogue generation:
   ```asm
   mov rsp, rbp                    ; restore stack pointer
   pop rbp                         ; restore old frame pointer
   ret                             ; return to caller
   ```

---

## Recommended Next Steps

### Option A: Complete Implementation (Effort: ~4-6 hours)
1. Fix and test `parse_function` to replace `parse_main_fn`
2. Implement `semantic_fn_registry` for function metadata
3. Update `semantic_subset` to populate registry and bind parameters
4. Enhance `emit_main_asm` to iterate through all functions
5. Add prologue/epilogue and call instruction generation

### Option B: Partial Implementation (Effort: ~2-3 hours) 
1. Keep `parse_main_fn` but extend it to accept any function name
2. Add parameter parsing to `parse_main_fn`
3. Focus initially on parsing only (semantic/codegen in later phase)
4. Create sample test for multi-function parsing

### Option C: Reference Implementation
- Check Rust prototype in [prototypes/rust_stage0](prototypes/rust_stage0) for function handling patterns
- Reference Codegen::emit_fn and Codegen::emit_call methods
- Adapt logic to NASM assembly constraints

---

## Files Ready for Implementation

| File | Status | Purpose |
|------|--------|---------|
| [compiler/asm/parser/functions.asm](compiler/asm/parser/functions.asm) | ✅ Created | Multi-function parser (needs testing) |
| [compiler/asm/parser_source.asm](compiler/asm/parser_source.asm) | ⚠️ Updated | Source parser with function loop |
| [compiler/inc/ast.inc](compiler/inc/ast.inc) | ✅ Updated | AST node types added |
| [compiler/inc/tokens.inc](compiler/inc/tokens.inc) | ✅ Updated | TOK_UNSAFE added |
| [compiler/asm/lexer_keywords.asm](compiler/asm/lexer_keywords.asm) | ✅ Updated | "unsafe" keyword recognition |
| [compiler/asm/data/diagnostics.asm](compiler/asm/data/diagnostics.asm) | ✅ Updated | Error messages added |
| [compiler/asm/semantic.asm](compiler/asm/semantic.asm) | ⏳ TODO | Function registry needed |
| [compiler/asm/emitter_nasm.asm](compiler/asm/emitter_nasm.asm) | ⏳ TODO | Prologue/epilogue generation |

---

## Assembly-Level Critical Points

When implementing the remaining tasks, pay careful attention to:

1. **Calling Convention (x86-64 System V ABI)**
   - Parameter passing: rdi, rsi, rdx, rcx, r8, r9 (then stack)
   - Return value: rax
   - Caller cleanup (not callee)
   - Preserved registers: rbx, r12-r15, rbp, rsp

2. **Stack Frame Management**
   - rbp points to old frame pointer (at end of prologue)
   - rsp points to allocated local space
   - Parameters accessed at negative offsets from rbp
   - Ensure 16-byte stack alignment before `call` instruction

3. **Register Clobbering**
   - Caller-saved: rax, rcx, rdx, rsi, rdi, r8-r11
   - Callee-saved: rbx, r12-r15, rbp, rsp
   - Document which registers are used where

---

## Testing Strategy

Once implementation is complete, test in this order:

1. **Parser Tests** (samples/08_function_params.snapsurf, samples/09_function_call.snapsurf)
   ```bash
   ./build/surf check samples/08_function_params.snapsurf
   ./build/surf dump-ast samples/08_function_params.snapsurf
   ```

2. **Compilation Tests**
   ```bash
   ./build/surf build samples/08_function_params.snapsurf
   ./build/hello  # Should produce correct output
   ```

3. **Integration Tests**
   ```bash
   make test  # Run full test suite
   ```

4. **Regression Tests**
   ```bash
   ./build/surf build examples/hello
   ./build/hello  # Verify still produces "Hello SnapSurf\n"
   ```

---

**Next Update**: Awaiting guidance on whether to pursue Option A (full implementation), Option B (parser-only), or continue with different task.

