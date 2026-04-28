section .data
suffix_pkg: db "/surf.pkg", 0
suffix_main: db "/src/main.snapsurf", 0
suffix_bad_surf: db "/src/main.surf", 0
build_dir: db "build", 0
asm_path: db "build/main.asm", 0
obj_path: db "build/main.o", 0
hello_path: db "build/hello", 0
nasm_path: db "/usr/bin/nasm", 0
ld_path: db "/usr/bin/ld", 0
nasm_arg0: db "nasm", 0
nasm_arg1: db "-f", 0
nasm_arg2: db "elf64", 0
nasm_arg3: db "-o", 0
ld_arg0: db "ld", 0
ld_arg1: db "-o", 0
nasm_argv: dq nasm_arg0, nasm_arg1, nasm_arg2, asm_path, nasm_arg3, obj_path, 0
ld_argv: dq ld_arg0, ld_arg1, hello_path, obj_path, 0
