// This is the outer text interpreter (REPL) implemented in binary forth.

.section .rodata
.align 4

outer_interpreter:
    .int xt_word                           // ( a len )
    .int xt_token_eval
    .int xt_branch
    lbl outer_interpreter
