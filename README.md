# punyforth

Punyforth is a toy implementation of the FORTH programming language. Most parts of Punyforth is written in itself. Including the outer interpreter and the compiler (that compiles indirect-threaded code). The primitives are implemented in assembly language.

My goal with this project is to develop an understanding about the internals of FORTH.

## Notes to myself:

### About the implementation of *create> does*

```forth
: constant ( n -- ) 
    create , 
    does> @ ;
    
: does>
  lit (does) , lit exit ,
  104 c, dodoes , 195 c,                      ( complile embedded assembly: PUSH DODOES RETN )
 ; immediate

: (does)
    rdup r> 1 cells +                         ( address of the embedded assembly code )
    lastword 1 cells + dup @ + 2 cells + ! ;  ( change lastword codeword to point to the embedded assembly code )

( Examples )

-1 constant TRUE 
0 constant FALSE

```

```assembly
; The DODOES is a similar codeword than DOCOLON (ENTERCOL in punyforth). 
; The main difference between DODOES and DOCOLON is that the former pushes 
; the address of the parameter field of the word.

DODOES:
    mov [ebp], esi          ; save esi (forth instruction pointer) to return stack
    add ebp, CELLS
    mov esi, [eax]          ; [eax] points to the embedded assembly that called DODOES
    add esi, 6              ; length of the embedded assembly code is 6, after that there are the forth code
    add eax, CELLS          ; eax points to the codeword of the defined word, after that there is the param. field
    push eax                ; push the parameter field and jump to the forth code (does> clause) 
    NEXT

```

#### How *does>* it work?

*constant* is a defining word that creates other words like *TRUE* or *FALSE*.

*does>* is an immediate word that is executed at compile time. Its compilation semantics is to compile *(does)* and an embedded assembly code that jumps to *DODOES*.

*(does)* modifies the codeword of the latest word to point to the embedded assembly code compiled by *does>*

The embedded assembly code simply jumps to the codeword *DODOES*. *DODOES* is similar then *ENTERCOL* but it also pushes the datafield of the word created by *create*, before executing the code defined by *does>*.

Here are the dictionary entries of the compiled *constant* and the words (*TRUE* and *FALSE*) created by constant.

<pre>                        
                             address of ENTERCOL                                            jumps to DODOES
                             /                                                               /
                            |                                                               |
+-----+---+----------+---+----+-----------+------+-----------+---------+----------------------+------+---------+
| LNK | 8 | constant | 1 | CW | xt_create | xt_, | xt_(does) | xt_exit | asm: push dodoes ret | xt_@ | xt_exit |
+-----+---+----------+---+----+-----------+------+-----------+---------+----------------------+------+---------+
                                                                            /             /
                                                                           |             |
                                                   +-----+---+------+---+----+----+      |
                                                   | LNK | 4 | TRUE | 1 | CW | -1 |      |
                                                   +-----+---+------+---+----+----+      |
                                                                                         |
                                                                 +-----+---+-------+---+----+---+
                                                                 | LNK | 5 | FALSE | 1 | CW | 0 |
                                                                 +-----+---+-------+---+----+---+

</pre>

### Other examples of create> does

```forth
: array ( size -- ) ( index -- addr )
    word create cells allot"
    does> swap cells + ;"
    
10 array numbers

: fill-numbers ( size )
    0 do i i numbers ! loop ;
    
10 fill-numbers

: print-numbers ( size )
    0 do i numbers @ . cr loop ;
    
10 print-numbers    
```
