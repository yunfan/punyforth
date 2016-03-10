# punyforth

Punyforth is a toy implementation of the FORTH programming language. Most parts of Punyforth is written in itself. Including the outer interpreter and the compiler (that compiles indirect-threaded code). The primitives are implemented in assembly language.

## Notes to myself:

### Demonstration of *create> does*

```forth
: constant ( n -- ) 
    word create , 
    does> @ ;
    
: does>
  lit (does) , lit exit ,
  104 c, dodoes , 195 c,                     ( complile embedded assembly: opcode PUSH, address dodoes, opcode RETN )
; immediate

: (does)
    rdup r> 1 cells +                         ( address of the embedded assembly code )
    lastword 1 cells + dup @ + 2 cells + ! ;  ( change lastword codeword to point to the embedded assembly code )

-1 constant TRUE 
0 constant FALSE

```





