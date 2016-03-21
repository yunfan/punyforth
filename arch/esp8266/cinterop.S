.macro CCALL label
    addi sp, sp, -32    // adjust stack pointer
    s32i a0, sp, 28     // save return address
    s32i a8, sp, 20     // save a8
    s32i a12, sp, 16    // save a12
    s32i a13, sp, 12    // save a13
    s32i a14, sp, 8     // save a14
    s32i a15, sp, 4     // save a15
    call0 \label        // call C
    l32i a15, sp, 4     // get saved a15
    l32i a14, sp, 8     // get saved a14
    l32i a13, sp, 12    // get saved a13
    l32i a12, sp, 16    // get saved a12
    l32i a8, sp, 20     // get saved a8
    l32i a0, sp, 28     // get the saved return address
    addi sp, sp, 32     // restore stack pointer
.endm
