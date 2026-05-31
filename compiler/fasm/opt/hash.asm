; opt/hash.asm — Fast hash function for keyword and symbol lookup.
; FNV-1a 64-bit hash: fast, well-distributed, simple to implement.
; Used to replace linear scans with O(1) hash lookups.

segment readable executable

; fnv1a_hash: Compute FNV-1a 64-bit hash of rdx bytes at rdi.
; Returns hash in rax.
fnv1a_hash:
    mov rax, 0xcbf29ce484222325     ; FNV offset basis
    mov rcx, rdx
    test rcx, rcx
    jz .done
.loop:
    movzx r8, byte [rdi]
    xor rax, r8
    mov r9, 0x100000001b3           ; FNV prime
    imul rax, r9
    inc rdi
    dec rcx
    jnz .loop
.done:
    ret

; fnv1a_hash_z: Hash zero-terminated string at rdi. Returns hash in rax.
fnv1a_hash_z:
    mov rax, 0xcbf29ce484222325     ; FNV offset basis
    mov r9, 0x100000001b3           ; FNV prime
.loop:
    movzx r8, byte [rdi]
    test r8, r8
    jz .done
    xor rax, r8
    imul rax, r9
    inc rdi
    jmp .loop
.done:
    ret
