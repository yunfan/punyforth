.macro defprimitive name, namelen, label, flags
    .section .rodata
     .align WORD_ALIGN
    .globl name_\label
name_\label :
    .int link
    .set link,name_\label
    .int \namelen
    .ascii "\name"
     .align WORD_ALIGN
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
     .align WORD_ALIGN
    .globl name_\label
name_\label :
    .int link
    .set link,name_\label
    .int \namelen
    .ascii "\name"
     .align WORD_ALIGN
    .int \flags
    .globl xt_\label
xt_\label :
    .int ENTERCOL
.endm

.macro lbl label
    .int \label - . - CELLS
.endm
