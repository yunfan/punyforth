.intel_syntax noprefix

// Primitives are implemented in assembly language

defprimitive "dup",3,dup,1 /* ( a -- a a ) */
    mov eax, [esp]
    push eax
    NEXT
    
defprimitive "drop",4,drop,1 /* ( a -- ) */
    pop eax
    NEXT

defprimitive "swap",4,swap,1 /* ( a b -- b a ) */
    pop eax
    pop ebx
    push eax
    push ebx
    NEXT

defprimitive "rot",3,rot,1 /* ( a b c -- b c a ) */
    pop ecx
    pop ebx
    pop eax
    push ebx
    push ecx
    push eax
    NEXT

defprimitive "2swap",5,swap2,1 /* ( a b c d -- c d a b ) */
    pop edx
    pop ecx
    pop ebx
    pop eax
    push ecx
    push edx
    push eax
    push ebx
    NEXT

defprimitive "2over",5,over2,1 /* ( a b c d -- a b c d a b ) */
    pop edx
    pop ecx
    pop ebx
    pop eax    
    push eax
    push ebx
    push ecx
    push edx
    push eax
    push ebx
    NEXT

defprimitive "+",1,plus,1
    pop eax
    add [esp], eax
    NEXT    
    
defprimitive "-",1,minus,1
    pop eax
    sub [esp], eax
    NEXT        
    
defprimitive "*",1,multiply,1
    pop eax
    pop ebx
    imul ebx
    push eax
    NEXT

defprimitive "/mod",4,divmod,1 /* ( n d -- m q ) */
    pop ebx
    pop eax
    xor edx, edx
    cdq
    idiv ebx
    push edx
    push eax
    NEXT
    
defprimitive "or",2,or,1
    pop eax
    pop ebx
    or eax, ebx
    push eax
    NEXT
    
defprimitive "and",3,and,1
    pop eax
    pop ebx
    and eax, ebx
    push eax
    NEXT    

defprimitive "xor",3,xor,1
    pop eax
    pop ebx
    xor eax, ebx
    push eax
    NEXT    

defprimitive "emit",4,emit,1
    mov edx, 1     // length
    pop eax
    mov [var0], eax
    mov ecx, OFFSET FLAT:var0
    mov ebx, 1      // stdout
    mov eax, 4      // sys_write
    int 0x80
    NEXT
    
defprimitive "abort",5,abort,1
    mov esp, [STACK_ORIG]
    mov eax, 1
    int 0x80
    
defprimitive "@",1,fetch,1
    pop eax
    mov ebx, [eax]
    push ebx
    NEXT
    
defprimitive "!",1,store,1
    pop edi
    pop eax
    stosd
    NEXT

defprimitive "c!",2,storebyte,1
    pop edi
    pop eax
    stosb
    NEXT
        
defprimitive "[']",3,btick,1    // compile only
    lodsd
    push eax
    NEXT
   
defprimitive "<",1,lt,1         // only need to define this, all other comparisions are implemented in terms of lt
    pop eax
    pop ebx
    cmp ebx, eax
    setl al
    movzbd eax, al
    neg eax
    push eax
    NEXT

defprimitive "invert",6,invert,1
    pop eax
    not eax
    push eax
    NEXT
    
defprimitive "branch",6,branch,1
    lodsd
    add esi, eax
    NEXT

defprimitive "branch0",7,branch0,1
    lodsd
    pop ebx
    test ebx, ebx
    jnz nobranch0
    add esi, eax
nobranch0:
    NEXT

defprimitive "litstring",9,litstring,1
    lodsd
    push esi                            // address of the string
    push eax                            // length of the string
    add esi, eax                        // skip string
    NEXT
    
defprimitive ">r",2,rpush,1
    pop eax
    sub ebp, CELLS
    mov [ebp], eax
    NEXT
    
defprimitive "r>",2, rpop,1
    mov eax, [ebp]
    add ebp, CELLS
    push eax
    NEXT    

defprimitive "i",1,i,1
    mov eax, [ebp]
    push eax
    NEXT    

defprimitive "j",1,j,1
    mov eax, [ebp + 2 * CELLS]
    push eax
    NEXT

defprimitive "execute",7,execute,1
    pop eax
    jmp [eax]

defprimitive "exit",4,exit,1
    mov esi, [ebp]
    add ebp, CELLS
    NEXT

defprimitive "sp@",3,spat,1
    mov eax, esp
    push eax
    NEXT

defprimitive "sp!",3,spstore,1
    pop eax
    mov esp, eax
    NEXT

defprimitive "rp@",3,rpat,1
    push ebp
    NEXT

defprimitive "rp!",3,rpstore,1
    pop ebp
    NEXT

.macro prompt
    push edx
    push ecx
    push ebx
    push eax
    mov edx, 4
    mov ecx, OFFSET FLAT:prompt_str
    mov ebx, 1    
    mov eax, 4    
    int 0x80
    pop eax
    pop ebx
    pop ecx
    pop edx
.endm

defprimitive "key",3,key,1
    push esi
    mov edi, OFFSET FLAT:input_buffer   
    add edi, [input_size]                                               // input buffer end position   
    mov esi, [input_index]
    cmp esi, edi
    jb read_one_char_from_buffer
    prompt
    lea ecx, [input_buffer -1]                                          // store the input in buffer
    mov dword ptr [input_size], 0
refill_buffer:
    inc ecx
    inc dword ptr [input_size]
    xor ebx, ebx                                                        // reads from stdin (FD 0)
    mov eax, 3                                                          // use syscall 3 (read) to read from stdin
    mov edx, 1                                                          // read one character
    int 0x80                                                            // invoke system call to read from stdin
    cmp byte ptr [ecx], 10
    jnz refill_buffer
    mov esi, OFFSET FLAT:input_buffer    
read_one_char_from_buffer:
    xor eax, eax
    lodsb
    mov [input_index], esi
    pop esi    
    push eax
    NEXT

// Different types of code words

ENTERCOL:                   // codeword for word (colon) definitions
    sub ebp, CELLS
    mov [ebp], esi          // save esi (forth instruction pointer) to the return stack
    add eax, CELLS          // eax points to the ENTERCOL, skip this cell
    mov esi, eax            // set the instruction pointer to the body of this word
    NEXT

ENTERDOES:
    sub ebp, CELLS
    mov [ebp], esi          // save esi to return stack
    mov esi, [eax]          // [eax] points to ENTERDOES call in assembly
    add esi, 6              // length of the embedded assembly code is 6, after that there are the forth code
    add eax, CELLS          // eax points to the codeword of the defined word, after that there is the param. field
    push eax
    NEXT
