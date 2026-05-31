; data/ansi_colors.asm — ANSI escape sequences for terminal syntax coloring.

segment readable writeable

; Bold Magenta — for keywords (fn, ret, let, mut, if, else, while, etc.)
ansi_bold_magenta: db 27, "[1;35m"
ansi_bold_magenta_len = $ - ansi_bold_magenta

; Bold Cyan — for type names (i32, i64, bool, etc.)
ansi_bold_cyan: db 27, "[1;36m"
ansi_bold_cyan_len = $ - ansi_bold_cyan

; Green — for string literals
ansi_green: db 27, "[32m"
ansi_green_len = $ - ansi_green

; Yellow — for integer literals
ansi_yellow: db 27, "[33m"
ansi_yellow_len = $ - ansi_yellow

; Bold Blue — for boolean literals (true, false)
ansi_bold_blue: db 27, "[1;34m"
ansi_bold_blue_len = $ - ansi_bold_blue

; Bold White — for operators
ansi_bold_white: db 27, "[1;37m"
ansi_bold_white_len = $ - ansi_bold_white

; Dark Gray — for comments
ansi_dark_gray: db 27, "[90m"
ansi_dark_gray_len = $ - ansi_dark_gray

; Reset — return to default terminal color
ansi_reset: db 27, "[0m"
ansi_reset_len = $ - ansi_reset
