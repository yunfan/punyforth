defprimitive "dup",3,dup,1 /* ( a -- a a ) */
    ldr r0, [sp]
    push {r0}
    NEXT

defprimitive "drop",4,drop,1 /* ( a -- ) */
    add sp, #CELLS
    NEXT

defprimitive "swap",4,swap,1 /* ( a b -- b a ) */
    pop {r0, r1}
    push {r0}
    push {r1}
    NEXT

defprimitive "rot",3,rot,1 /* ( a b c -- b c a ) */    
    pop {r0, r1, r2}
    push {r1}
    push {r0}
    push {r2}
    NEXT

defprimitive "2swap",5,swap2,1 /* ( a b c d -- c d a b ) */
    pop {r0, r1, r2, r3}
    push {r1}
    push {r0}
    push {r3}
    push {r2}
    NEXT

defprimitive "2over",5,over2,1 /* ( a b c d -- a b c d a b ) */
    pop {r0, r1, r2, r3}
    push {r3}
    push {r2}
    push {r1}
    push {r0}
    push {r3}
    push {r2}
    NEXT

defprimitive "+",1,plus,1
    pop {r1}
    pop {r0}
    add r0, r1
    push {r0}
    NEXT

defprimitive "-",1,minus,1
    pop {r1}
    pop {r0}
    sub r0, r1
    push {r0}
    NEXT

defprimitive "*",1,multiply,1
    pop {r0}
    pop {r1}
    mul r0, r1
    push {r0}
    NEXT

defprimitive "/mod",4,divmod,1 /* ( n d -- m q ) */
    pop {r1}
    pop {r0}
    sdiv r2, r0, r1
    mls r0, r1, r2, r0
    push {r0}
    push {r2}
    NEXT

defprimitive "or",2,or,1
    pop {r1}
    pop {r0}
    orr r0, r1
    push {r0}
    NEXT

defprimitive "and",3,and,1
    pop {r1}
    pop {r0}
    and r0, r1
    push {r0}
    NEXT

defprimitive "xor",3,xor,1
    pop {r1}
    pop {r0}
    eor r0, r1
    push {r0}
    NEXT

defprimitive "invert",6,invert,1
    ldr r0, [sp]
    mvns r0, r0
    str r0, [sp]
    NEXT

defprimitive "emit",4,emit,1
    pop {r0}
    push {r6, r7}
    ldr r1, =var0
    str r0, [r1]
    mov r0, #1                      // fd <- stdout
    mov r2, #1                      // length
    mov r7, #4                      // syscall <- sys_write
    swi 0                           // system call
    pop {r6, r7}
    NEXT    

defprimitive "abort",5,abort,1
    mov r0, #0     // set exit code to 0
    mov r7, #1     // syscall for exit
    swi 0          // invoke the syscall from linux
    NEXT

defprimitive "@",1,fetch,1
    pop {r0}
    ldr r1, [r0]
    push {r1}
    NEXT

defprimitive "!",1,store,1
    pop {r1}
    pop {r0}
    str r0, [r1]
    NEXT

defprimitive "c!",2,storebyte,1
    pop {r1}
    pop {r0}
    strb r0, [r1]
    NEXT

defprimitive "[']",3,btick,1    // compile only
    ldr r0, [r7]
    add r7, #CELLS
    push {r0}
    NEXT

defprimitive "<",1,lt,1         // only need to define this, all other comparisions are implemented in terms of lt
    pop {r1}
    pop {r0}
    mov r2, #0
    cmp r0, r1
    movlt r2, #TRUE
    push {r2}
    NEXT

defprimitive "branch",6,branch,1
    ldr r0, [r7]
    add r7, #CELLS
    add r7, r0
    NEXT

defprimitive "branch0",7,branch0,1
    ldr r0, [r7]                              // load relative address to be jump
    add r7, #CELLS
    pop {r1}                                  // check condition
    cmp r1, #0                                  
    addeq r7, r0                              // advance pc if condition was satisfied
    NEXT

defprimitive "litstring",9,litstring,1
    ldr r0, [r7]
    add r7, #CELLS
    push {r7}                                 // address of the string
    push {r0}                                 // length of the string
    add r7, r0                                // skip the string
    mov r0, #3                                // alignation
    add r7, r0
    mvns r0, r0
    and r7, r0
    NEXT

defprimitive ">r",2,rpush,1
    pop {r0}
    sub r6, #CELLS
    str r0, [r6]
    NEXT

defprimitive "r>",2, rpop,1
    ldr r0, [r6]
    add r6, #CELLS
    push {r0}
    NEXT

defprimitive "i",1,i,1
    ldr r0, [r6]
    push {r0}
    NEXT

defprimitive "j",1,j,1
    ldr r0, [r6, #2*CELLS]
    push {r0}
    NEXT

defprimitive "execute",7,execute,1
    pop {r0}
    ldr r1, [r0]
    mov pc, r1

defprimitive "exit",4,exit,1
    ldr r7, [r6]
    add r6, #CELLS
    NEXT

defprimitive "sp@",3,spat,1
    mov r0, sp
    push {r0}
    NEXT

defprimitive "sp!",3,spstore,1
    pop {r0}
    mov sp, r0
    NEXT

defprimitive "rp@",3,rpat,1
    push {r6}
    NEXT

defprimitive "rp!",3,rpstore,1
    pop {r6}
    NEXT

defprimitive "readchar",8,readchar,1
    push {r7}
    ldr r1, =var0           // buffer for one character
    mov r0, #0              // read system call
    str r0, [r1]
    mov r2, #1              // length
    mov r7, #3
    swi 0
    pop {r7}
    ldr r0, [r1]
//    ble r0, #0, code_abort  // TODO check number of bytes read
    push {r0}
    NEXT

// Different types of code words

ENTERCOL:                   // codeword for word (colon) definitions
    sub r6, #CELLS
    str r7, [r6]            // save r7 (forth instruction pointer) to the return stack
    add r7, r0, #CELLS      // r0 points to the ENTERCOL, skip this cell and set the instruction pointer to the body of this word
    NEXT

ENTERDOES:
    sub r6, #CELLS
    str r7, [r6]            // save r7 (forth instruction pointer) to the return stack
    add r0, #CELLS         
    ldr r7, [r0]            // load the behaviour pointer to FORTH PC
    add r0, #CELLS          // after the behaviour pointer there is the data
    push {r0}               // invoke behaviour with data pointer on the stack
    NEXT

