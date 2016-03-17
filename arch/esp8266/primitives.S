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
    l32i a8 a15, 0
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
    DPOP a8
    DPOP a9
    sub a8, a8, a9
    DPUSH a8
    NEXT

defprimitive "*",1,multiply,1
    DPOP a8
    DPOP a9
    mull a8, a8, a9
    DPUSH a8
    NEXT

defprimitive "/mod",4,divmod,1 /* ( n d -- m q ) */
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
    movi a9, 0
    addi a9, a9, -1
    xor a8, a8, a9
    DPUSH a8
    NEXT

defprimitive "emit",4,emit,1
    NEXT    

defprimitive "abort",5,abort,1
    NEXT

defprimitive "@",1,fetch,1
    DPOP a8
    l32i a9, a8, 0
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
    l32i, a8, a14, 0
    add a14, a14, CELLS
    DPUSH a8
    NEXT

defprimitive "<",1,lt,1         // only need to define this, all other comparisions are implemented in terms of lt
    DPOP a8
    DPOP a9
    movi a10, 0         // Set a10 to FALSE
    bge a9, a8, L4          // If a9 >= a8, branch
    movi a10, -1            // Set a10 to TRUE
L4: DPUSH a10
    NEXT

defprimitive "branch",6,branch,1
    l32i a8, a14, 0                 // read relative address
    add a14, a14, CELLS             // x86 uses lodsd that increments forth PC, consider removing this
    add a14, a14, a8    
    NEXT

defprimitive "branch0",7,branch0,1
    l32i a8, a14, 0                 // read relative address
    add a14, a14, CELLS
    POP a8
    bnez a8, nobranch0
    add a14, a14, a8
nobranch0:
    NEXT

defprimitive "litstring",9,litstring,1
    l32i a8, a14, 0
    add a14, a14, CELLS
    DPUSH a14                                 // address of the string
    DPUSH a8                                  // length of the string
    add a14, a14, a8                          // skip the string
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
    l32i a8, a3, 2*CELLS
    DPUSH a8
    NEXT

defprimitive "execute",7,execute,1    
    DPOP a8
    l32i a8, a8, 0
    jx a8  

defprimitive "exit",4,exit,1
    RPOP a14
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
    mov, a13, a8
    NEXT

defprimitive "key",3,key,1
    NEXT


// Different types of code words

ENTERCOL:                       // codeword for word (colon) definitions
    RPUSH a14
    add a14, a8, CELLS          // a8 points to the ENTERCOL, skip this cell    
    NEXT

ENTERDOES:
    RPUSH a14    
    add a9, a9, 8          // a9 points to ENTERDOES call in assembly, skip the embedded assembly instruction
    add a8, a8, CELLS      // a8 points to the codeword of the defined word, after that there is the param. field
    DPUSH a8
    NEXT

