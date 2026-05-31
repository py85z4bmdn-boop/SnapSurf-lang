segment readable writeable
suffix_pkg: db "/surf.pkg", 0
suffix_main: db "/src/main.snapsurf", 0
suffix_bad_surf: db "/src/main.surf", 0
build_dir: db "build", 0
asm_path: db "build/main.asm", 0
hello_path: db "build/hello", 0
fasm_path: db "/usr/bin/fasm", 0
fasm_arg0: db "fasm", 0
fasm_argv: dq fasm_arg0, asm_path, hello_path, 0
