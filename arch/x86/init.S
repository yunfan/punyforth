.intel_syntax noprefix

.macro init_forth
    cld
    mov eax, OFFSET FLAT:input_buffer        
    mov [input_index], eax                      // initialize 'input_index' to the beginning of the input_buffer
    mov eax, OFFSET FLAT:dictionary
    mov [here_var], eax                         // initialzie 'here' to the beginning of the dictionary
    mov [STACK_ORIG], esp
    mov ebp, OFFSET FLAT:rstack                 // ebp is used to track the return stack 
    mov esi, OFFSET FLAT:outer_interpreter      // esi works as an instruction pointer 
    NEXT                                        // start the outer interpreter (repl)
.endm
