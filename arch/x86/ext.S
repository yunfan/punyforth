.intel_syntax noprefix

defprimitive "=",1,eq,REGULAR         // optional
    pop eax
    pop ebx
    cmp eax, ebx
    setz al
    movzbd eax, al
    neg eax
    push eax
    NEXT

defprimitive ">",1,gt,REGULAR         // optional
    pop eax
    pop ebx
    cmp ebx, eax
    setg al
    movzbd eax, al
    neg eax
    push eax
    NEXT
    
defprimitive ">=",2,gte,REGULAR       // optional
    pop eax
    pop ebx
    cmp ebx, eax
    setge al
    movzbd eax, al
    neg eax
    push eax
    NEXT
    
defprimitive "<=",2,lte,REGULAR       // optional
    pop eax
    pop ebx
    cmp ebx, eax
    setle al
    movzbd eax, al
    neg eax
    push eax
    NEXT

defprimitive "0=",2,eq0,REGULAR
    pop eax
    test eax, eax
    setz al
    movzbd eax, al
    neg eax
    push eax
    NEXT

defprimitive "1=",2,eq1,REGULAR
    pop eax
    dec eax
    setz al
    movzbd eax, al
    neg eax
    push eax
    NEXT

defprimitive "1+",2,inc,REGULAR
    pop eax
    inc eax
    push eax
    NEXT

defprimitive "1-",2,dec,REGULAR
    pop eax
    dec eax
    push eax
    NEXT

defprimitive "0<",2,lt0,REGULAR
    pop eax
    cmp eax, 0
    setl al
    movzbd eax, al
    neg eax
    push eax
    NEXT

defprimitive "0>",2,gt0,REGULAR
    pop eax
    cmp eax, 0
    setg al
    movzbd eax, al
    neg eax
    push eax
    NEXT

defprimitive "over",4,over,REGULAR    // optional
    mov eax, [esp + CELLS]
    push eax
    NEXT

defprimitive "time",4,time,REGULAR /* ( -- unixtime ) */
    mov eax, 13
    mov ebx, OFFSET FLAT:var0
    int 0x80
    mov eax, [var0]
    push eax
    NEXT
