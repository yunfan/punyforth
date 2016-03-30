.macro DPUSH reg    
    addi a15, a15, -CELLS
    s32i \reg, a15, 0
.endm

.macro DPOP reg    
    l32i \reg, a15, 0
    addi a15, a15, CELLS
.endm

.macro RPUSH reg    
    addi a13, a13, -CELLS
    s32i \reg, a13, 0    
.endm

.macro RPOP reg    
    l32i \reg, a13, 0
    addi a13, a13, CELLS
.endm

defprimitive "dup",3,dup,1 /* ( a -- a a ) */
    l32i a8, a15, 0
    DPUSH a8
    NEXT

defprimitive "drop",4,drop,1 /* ( a -- ) */
    DPOP a8
    NEXT

defprimitive "swap",4,swap,1 /* ( a b -- b a ) */
    DPOP a8
    DPOP a9
    DPUSH a8
    DPUSH a9
    NEXT

defprimitive "rot",3,rot,1 /* ( a b c -- b c a ) */    
    DPOP a8
    DPOP a9
    DPOP a10
    DPUSH a9
    DPUSH a8
    DPUSH a10
    NEXT

defprimitive "2swap",5,swap2,1 /* ( a b c d -- c d a b ) */    
    DPOP a8
    DPOP a9
    DPOP a10
    DPOP a11
    DPUSH a9
    DPUSH a8
    DPUSH a11
    DPUSH a10
    NEXT

defprimitive "2over",5,over2,1 /* ( a b c d -- a b c d a b ) */    
    DPOP a8
    DPOP a9
    DPOP a10
    DPOP a11    
    DPUSH a11
    DPUSH a10
    DPUSH a9
    DPUSH a8
    DPUSH a11
    DPUSH a10
    NEXT

defprimitive "+",1,plus,1
    DPOP a8
    DPOP a9
    add a8, a8, a9
    DPUSH a8
    NEXT

defprimitive "-",1,minus,1
    DPOP a9
    DPOP a8
    sub a8, a8, a9
    DPUSH a8
    NEXT

defprimitive "*",1,multiply,1
    DPOP a8
    DPOP a9
    mull a8, a8, a9
    DPUSH a8
    NEXT

.literal_position
defprimitive "/mod",4,divmod,1 /* ( n d -- m q ) */    
    DPOP a8            // denom
    DPOP a9            // numer
    mov a3, a8        // parameter denom
    mov a2, a9        // parameter numer
    CCALL forth_mod
    DPUSH a2           // remainder
    mov a3, a8        // parameter denom
    mov a2, a9        // parameter numer
    CCALL forth_div
    DPUSH a2           // quotient
    NEXT

defprimitive "or",2,or,1
    DPOP a8
    DPOP a9
    or a8, a8, a9
    DPUSH a8
    NEXT

defprimitive "and",3,and,1
    DPOP a8
    DPOP a9
    and a8, a8, a9
    DPUSH a8
    NEXT

defprimitive "xor",3,xor,1
    DPOP a8
    DPOP a9
    xor a8, a8, a9
    DPUSH a8    
    NEXT

defprimitive "invert",6,invert,1
    DPOP a8
    movi a9, TRUE
    xor a8, a8, a9
    DPUSH a8
    NEXT

.literal_position
defprimitive "emit",4,emit,1
    DPOP a2
    CCALL forth_putchar
    NEXT    

defprimitive "abort",5,abort,1
    CCALL forth_abort
    NEXT

defprimitive "@",1,fetch,1
    DPOP a8
    l32i a9, a8, 0
    DPUSH a9
    NEXT

defprimitive "c@",2,fetchbyte,1
    DPOP a8
    l8ui a9, a8, 0
    DPUSH a9
    NEXT

defprimitive "!",1,store,1
    DPOP a8
    DPOP a9
    s32i a9, a8, 0
    NEXT

defprimitive "c!",2,storebyte,1
    DPOP a8
    DPOP a9
    s8i a9, a8, 0
    NEXT

defprimitive "[']",3,btick,1    // compile only
    l32i a8, a14, 0
    addi a14, a14, CELLS
    DPUSH a8
    NEXT

defprimitive "<",1,lt,1         // only need to define this, all other comparisions are implemented in terms of lt
    DPOP a8
    DPOP a9
    movi a10, FALSE
    bge a9, a8, L4              // a9 >= a8 ?
    movi a10, TRUE
L4: DPUSH a10
    NEXT

defprimitive "branch",6,branch,1
    l32i a8, a14, 0                 // read relative address as the next instruction
    addi a14, a14, CELLS             // x86 uses lodsd that increments forth PC, consider changing this
    add a14, a14, a8                // advance forth PC
    NEXT

defprimitive "branch0",7,branch0,1
    l32i a8, a14, 0                 // read relative address
    addi a14, a14, CELLS
    DPOP a9
    bnez a9, nobranch0
    add a14, a14, a8
nobranch0:
    NEXT

defprimitive "litstring",9,litstring,1
    l32i a8, a14, 0                           // read the length of the string as the next instruction
    addi a14, a14, CELLS
    DPUSH a14                                 // after the length there is the address of the string
    DPUSH a8                                  // length of the string
    add a14, a14, a8                          // skip the string
    movi a8, 3                                // alignation
    add a14, a14, a8
    movi a9, TRUE                             // invert a8
    xor a8, a8, a9
    and a14, a14, a8
    NEXT

defprimitive ">r",2,rpush,1
    DPOP a8
    RPUSH a8
    NEXT

defprimitive "r>",2, rpop,1
    RPOP a8
    DPUSH a8
    NEXT

defprimitive "i",1,i,1
    l32i a8, a13, 0
    DPUSH a8
    NEXT

defprimitive "j",1,j,1
    l32i a8, a13, 2*CELLS
    DPUSH a8
    NEXT

defprimitive "execute",7,execute,1    
    DPOP a8                             // xt
    l32i a9, a8, 0                      // fetch codeword the same way as the inner interpreter does
    jx a9  

defprimitive "exit",4,exit,1
    RPOP a14                            // pop forth PC from the return stack
    NEXT

defprimitive "sp@",3,spat,1
    mov a8, a15
    DPUSH a8
    NEXT

defprimitive "sp!",3,spstore,1
    DPOP a8
    mov a15, a8
    NEXT

defprimitive "rp@",3,rpat,1
    DPUSH a13
    NEXT

defprimitive "rp!",3,rpstore,1
    DPOP a8
    mov a13, a8
    NEXT

defprimitive "readchar",8,readchar,1
    CCALL forth_getchar
    DPUSH a2
    NEXT    

// Different types of code words

.section .irom0.text
.align 4

ENTERCOL:                       // codeword for word (colon) definitions
    RPUSH a14                   // save program counter before entering the word
    addi a14, a8, CELLS         // a8 points to the ENTERCOL, skip this cell    
    NEXT

ENTERDOES:
    RPUSH a14                   // save program counter before entering the word
    addi a8, a8, CELLS          // a8 is on the codeword after there is the behaviour pointer
    l32i a14, a8, 0     // set the FORTH PC to the behaviour
    addi a8, a8, CELLS          // after the behaviour there is the data
    DPUSH a8                    // invoke behavour with the data pointer on the stack
    NEXT

