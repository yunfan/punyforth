.macro init_forth
    l32r a8, input_buffer
    l32r a9, input_index
    s32i a8, a9, 0

    l32r a8, dictionary
    l32r a9, here_var
    s32i a8, a9, 0

    l32r a15, stack
    l32r a13, rstack

    l32r a14, outer_interpreter
    NEXT
.endm
