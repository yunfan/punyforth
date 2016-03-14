.intel_syntax noprefix

.macro NEXT
    lodsd
    jmp [eax]
.endm

