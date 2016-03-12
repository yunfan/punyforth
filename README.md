# punyforth

Punyforth is a toy implementation of the FORTH programming language. Most parts of Punyforth is written in itself. Including the outer interpreter and the compiler (that compiles indirect-threaded code). The primitives are implemented in assembly language.

My goal with this project is to develop an understanding about the internals of FORTH.

## Random notes

### About the implementation of *create> does*

```forth
: constant ( n -- ) 
    create , 
    does> @ ;
    
: does>
  ' (does) , ' exit ,
  104 c, dodoes , 195 c,                      \ complile embedded assembly: PUSH ENTERDOES RETN
 ; immediate

: (does)
    rdup r> 1 cells +                         \ address of the embedded assembly code
    lastword 1 cells + dup @ + 2 cells + ! ;  \ change lastword codeword to point to the embedded assembly code

( Examples )

-1 constant TRUE 
0 constant FALSE

```

```assembly
; The ENTERDOES is a similar codeword than ENTERCOL.
; The main difference between ENTERDOES and ENTERCOL is that the former pushes 
; the address of the parameter field of the word.

ENTERDOES:
    mov [ebp], esi          ; save esi (forth instruction pointer) to return stack
    add ebp, CELLS
    mov esi, [eax]          ; [eax] points to the embedded assembly that called ENTERDOES
    add esi, 6              ; length of the embedded assembly code is 6, after that there are the forth code
    add eax, CELLS          ; eax points to the codeword of the defined word, after that there is the param. field
    push eax                ; push the parameter field and jump to the forth code (does> clause) 
    NEXT

```

#### How *does>* it work?

*constant* is a defining word that creates other words like *TRUE* or *FALSE*.

*does>* is an immediate word that is executed at compile time. Its compilation semantics is to compile *(does)* and an embedded assembly code that jumps to *ENTERDOES*.

*(does)* modifies the codeword of the latest word to point to the embedded assembly code compiled by *does>*

The embedded assembly code simply jumps to the codeword *ENTERDOES*. *ENTERDOES* is similar than *ENTERCOL* but it also pushes the datafield of the word created by *create*, before executing the code defined by *does>*.

Here are the dictionary entries of the compiled *constant* and the words (*TRUE* and *FALSE*) created by constant.

<pre>                        
                             address of ENTERCOL                                            jumps to ENTERDOES
                             /                                                             /
                            |                                                             |
+-----+---+----------+---+----+-----------+------+-----------+---------+--------------------+------+---------+
| LNK | 8 | constant | 1 | CW | xt_create | xt_, | xt_(does) | xt_exit | asm: jmp ENTERDOES | xt_@ | xt_exit |
+-----+---+----------+---+----+-----------+------+-----------+---------+--------------------+------+---------+
                                                                            /            /
                                                                           |            |
                                                   +-----+---+------+---+----+----+     |
                                                   | LNK | 4 | TRUE | 1 | CW | -1 |     |
                                                   +-----+---+------+---+----+----+     |
                                                                                        |
                                                                +-----+---+-------+---+----+---+
                                                                | LNK | 5 | FALSE | 1 | CW | 0 |
                                                                +-----+---+-------+---+----+---+

</pre>

### Other examples of create> does

```forth
: array ( size -- ) ( index -- addr )
    create cells allot
    does> swap cells + ;
    
10 array numbers

: fill-numbers ( size )
    0 do i i numbers ! loop ;
    
10 fill-numbers

: print-numbers ( size )
    0 do i numbers @ . cr loop ;
    
10 print-numbers    
```

### Immediate words 

Immediate words are executed at compile time. Loops and control structures are implemented with immediate words that compiles the required semantics.

```forth
: begin
    here >r rswap          \ saves the absolute address of the beginning of the loop at the return stack
 ; immediate
 
: until
    ' branch0 ,            \ compiles a conditional branch
    rswap r>               \ gets the address that was put on the return stack by the word begin
    here -                 \ calculate the relative address (difference between here and begin address)
    1 cells - ,            \ compile the relative address - 1 cell
; immediate
```

### Parsing words

Parsing words can parse the input stream. One example of a parsing word is the comment. There are 2 types of comments.

```forth
( this is a comment )
\ this is an other comment
```

```forth
: (                                 \ comments start with ( character
    begin                           \ consume the stream until ) character is found
        key ')' = 
    until 
 ; immediate
``` 

```forth
: \                                 \ single line comments start with \ character
    begin                           
        key dup 
        'cr' = swap 
        'lf' = 
        or
    until                           \ consume the stream until cr or lf character is found
 ; immediate
``` 
