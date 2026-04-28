section .data
cmd_version: db "version", 0
cmd_check: db "check", 0
cmd_emit_asm: db "emit-asm", 0
cmd_build: db "build", 0
cmd_clean: db "clean", 0
cmd_dump_tokens: db "dump-tokens", 0
cmd_dump_ast: db "dump-ast", 0

version_msg: db "surf asm-foundation 0.1-in-progress", 10, 0
usage_msg: db "usage: surf <version|check|emit-asm|build|clean|dump-tokens|dump-ast> [package_dir]", 10, 0
check_ok_msg: db "check ok", 10, 0
emit_ok_msg: db "build/main.asm", 10, 0
build_ok_msg: db "build/hello", 10, 0
clean_msg: db "clean is handled by make clean", 10, 0
