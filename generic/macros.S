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


