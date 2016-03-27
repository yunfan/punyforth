defprimitive "=",1,eq,1
    pop {r1}
    pop {r0}
    mov r2, #FALSE
    cmp r0, r1
    moveq r2, #TRUE
    push {r2}
    NEXT

defprimitive ">",1,gt,1
    pop {r1}
    pop {r0}
    mov r2, #FALSE
    cmp r0, r1
    movgt r2, #TRUE
    push {r2}
    NEXT

defprimitive ">=",2,gte,1
    pop {r1}
    pop {r0}
    mov r2, #FALSE
    cmp r0, r1
    movge r2, #TRUE
    push {r2}
    NEXT

defprimitive "<=",2,lte,1
    pop {r1}
    pop {r0}
    mov r2, #FALSE
    cmp r0, r1
    movle r2, #TRUE
    push {r2}
    NEXT

defprimitive "0=",2,eq0,1
    pop {r0}
    mov r1, #FALSE
    cmp r0, #0
    moveq r1, #TRUE
    push {r1}
    NEXT

defprimitive "1=",2,eq1,1
    pop {r0}
    mov r1, #FALSE
    cmp r0, #1
    moveq r1, #TRUE
    push {r1}
    NEXT

defprimitive "1+",2,inc,1
    pop {r0}
    add r0, #1
    push {r0}
    NEXT

defprimitive "1-",2,dec,1
    pop {r0}
    sub r0, #1
    push {r0}
    NEXT

defprimitive "0<",2,lt0,1
    pop {r0}
    mov r1, #FALSE
    cmp r0, #0
    movlt r1, #TRUE
    push {r1}
    NEXT

defprimitive "0>",2,gt0,1
    pop {r0}
    mov r1, #FALSE
    cmp r0, #0
    movgt r1, #TRUE
    push {r1}
    NEXT

defprimitive "over",4,over,1 
    ldr r0, [SP, #CELLS]
    push {r0}
    NEXT

// defprimitive "type",4,type,1            // ( a len -- )

// TODO
defprimitive "time",4,time,1 /* ( -- unixtime ) */
    push {r0}
    NEXT
