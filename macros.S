.macro NEXT
    lodsd
    jmp [eax]
.endm

.macro defprimitive name, namelen, label, flags
    .section .rodata
    .globl name_\label
name_\label :
    .int link
    .set link,name_\label
    .int \namelen
    .ascii "\name"
    .int \flags
    .globl xt_\label
xt_\label :
    .int code_\label
    .text
    .globl code_\label
code_\label :
.endm

.macro defword name, namelen, label, flags
    .section .rodata
    .globl name_\label
name_\label :
    .int link
    .set link,name_\label
    .int \namelen
    .ascii "\name"
    .int \flags
    .globl xt_\label
xt_\label :
    .int ENTERCOL
.endm

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


