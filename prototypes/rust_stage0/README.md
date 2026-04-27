# SnapSurf Rust Stage 0 Bootstrap Prototype

Status: `PROTOTYPE ONLY -- NOT FOUNDATION IMPLEMENTATION`.

This directory contains a Rust bootstrap prototype that can compile the
foundation hello world path through NASM and `ld`.

Correct claim:

> Rust Stage 0 bootstrap prototype đã chạy được hello world qua NASM/ld.

Forbidden claim:

> ASM/NASM foundation đã dựng xong.

The compiler implementation in this directory is Rust. NASM is only the emitted
backend artifact plus assembler input. This prototype exists to test language
contracts, diagnostics, package checks, and generated assembly before a real
ASM/NASM compiler implementation exists.

Run from this directory:

```sh
cargo test
cargo build
target/debug/surf init
target/debug/surf check
target/debug/surf emit asm
target/debug/surf build
target/debug/surf run
```

