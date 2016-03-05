.intel_syntax noprefix

#include "data.S"
#include "outerinterpreter.S"
#include "macros.S"
#include "primitives.S"
#include "words.S"

.global _start

.text
_start:
    cld
    mov eax, OFFSET FLAT:input_buffer        
    mov [input_index], eax
    mov eax, OFFSET FLAT:dictionary
    mov [here_var], eax
    mov [STACK_ORIG], esp
    mov ebp, OFFSET FLAT:rstack   
    mov esi, OFFSET FLAT:REPL   
    NEXT
