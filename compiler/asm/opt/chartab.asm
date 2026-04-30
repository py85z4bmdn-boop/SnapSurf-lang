; opt/chartab.asm — Branchless character classification via lookup table.

; Replaces branchy is_ident_start/is_ident_rest/is_digit with single
; table lookups: O(1) per char, zero branches, fully pipelined.

section .data
align 64
; char_class_table: 256-byte LUT, one byte per ASCII value.
; Bit 0 = is_digit        (0-9)
; Bit 1 = is_ident_start  (a-z, A-Z, _)
; Bit 2 = is_ident_rest   (a-z, A-Z, 0-9, _)
; Bit 3 = is_whitespace   (space, tab)
; Bit 4 = is_newline      (LF, CR)

char_class_table:
; 0x00-0x08: control chars
    db 0, 0, 0, 0, 0, 0, 0, 0, 0
; 0x09: TAB
    db 8                    ; is_whitespace
; 0x0A: LF
    db 16                   ; is_newline
; 0x0B-0x0C
    db 0, 0
; 0x0D: CR
    db 16                   ; is_newline
; 0x0E-0x1F
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
; 0x20: space
    db 8                    ; is_whitespace
; 0x21-0x2F: !"#$%&'()*+,-./
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
; 0x30-0x39: digits 0-9
    db 5, 5, 5, 5, 5, 5, 5, 5, 5, 5  ; is_digit | is_ident_rest
; 0x3A-0x40: :;<=>?@
    db 0, 0, 0, 0, 0, 0, 0
; 0x41-0x5A: uppercase A-Z
    db 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6 ; is_ident_start | is_ident_rest
    db 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6
; 0x5B-0x5E: [\]^
    db 0, 0, 0, 0
; 0x5F: underscore _
    db 6                    ; is_ident_start | is_ident_rest
; 0x60: backtick
    db 0
; 0x61-0x7A: lowercase a-z
    db 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6 ; is_ident_start | is_ident_rest
    db 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6
; 0x7B-0x7F: {|}~ DEL
    db 0, 0, 0, 0, 0
; 0x80-0xFF: extended ASCII (128 bytes, all 0)
    times 128 db 0

section .text

; char_class: Return class bits for byte in al.
; Branchless: single indexed load.
char_class:
    movzx rax, al
    movzx rax, byte [char_class_table + rax]
    ret

; opt_is_digit: Branchless digit check. al = char, returns 1/0 in rax.
opt_is_digit:
    movzx rax, al
    movzx rax, byte [char_class_table + rax]
    and rax, 1              ; bit 0 = is_digit
    ret

; opt_is_ident_start: Branchless ident start check.
opt_is_ident_start:
    movzx rax, al
    movzx rax, byte [char_class_table + rax]
    and rax, 2              ; bit 1 = is_ident_start
    shr rax, 1
    ret

; opt_is_ident_rest: Branchless ident continuation check.
opt_is_ident_rest:
    movzx rax, al
    movzx rax, byte [char_class_table + rax]
    and rax, 4              ; bit 2 = is_ident_rest
    shr rax, 2
    ret

; opt_is_whitespace: Branchless whitespace check.
opt_is_whitespace:
    movzx rax, al
    movzx rax, byte [char_class_table + rax]
    and rax, 8              ; bit 3 = is_whitespace
    shr rax, 3
    ret

; opt_is_newline: Branchless newline check.
opt_is_newline:
    movzx rax, al
    movzx rax, byte [char_class_table + rax]
    and rax, 16             ; bit 4 = is_newline
    shr rax, 4
    ret
