# punyforth

Punyforth is a toy (and buggy incomplete at this moment) implementation of the FORTH programming language. Most parts of Punyforth is written in itself. Including the outer interpreter and the compiler (that compiles indirect-threaded code). The primitives are implemented in assembly language.

My goal with this project is to develop an understanding about the internals of FORTH.

## Random notes

FORTH is a simple and extensible stack-based language.

```forth

2 3 dup * swap dup * + .  \ 3 * 3 + 2 * 2 prints out 13

```
Stack visualization:
<pre>
2 3  3  9  2   2 4 13
  2  3  2  9   2 9
     2         9
</pre>     

### Defining words

```forth
: square ( n -- nsquared ) dup * ;

4 square .      \ prints 16
```
Word definitions start with colon character and end with a semicolon. The *n -- nsquared* is the optional stack effect comment.

### Immediate words 

Immediate words are executed at compile time. Loops and control structures are implemented with immediate words that compile the required semantics.

```forth
: begin
    here >r rswap          \ saves the absolute address of the beginning of the loop at the return stack
 ; immediate
 
: until
    ['] branch0 ,          \ compiles a conditional branch
    rswap r>               \ gets the address that was put on the return stack by the word begin
    here -                 \ calculate the relative address (difference between here and begin address)
    cell - ,               \ compile the relative address - 1 cell
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
        'lf' = or
    until                           \ consume the stream until cr or lf character is found
 ; immediate
``` 

### About the implementation of *create does>*

```forth
: constant ( n -- ) 
    create , 
    does> @ ;
    
: does>
    ['] (does) , ['] exit ,
    104 c, enterdoes , 195 c,                   \ complile embedded assembly: PUSH ENTERDOES RETN
 ; immediate

: (does)
    rdup r> cell +                         \ address of the embedded assembly code
    lastword cell + dup @ + 2 cells + ! ;  \ change lastword codeword to point to the embedded assembly code

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

### Other examples of create does>

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

```forth
struct 
  cell field width 
  cell field height
constant Rect

: new-rect
  Rect create allot does> ;
  
: area ( rect -- area ) 
  x @ swap y @ * ;  
  
new-rect r1
  
3 r1 width !
5 r1 height !  
  
r1 area .  
  
```

### Exceptions

This is based on the idea of William Mitch Bradley.

```forth
\ this points to the nearest exception handler
variable handler           

: catch ( xt -- errcode | 0 )        
    sp@ >r handler @ >r  	\ save current stack pointer and the nearest handler (RS: sp h)
    rp@ handler !  		    \ update current handler to this
    execute        		    \ execute word that potentially throws exception (*)
    r> handler !   		    \ word returned without throwing exception, restore the nearest handler
    r> drop        		    \ we don't need the saved stack pointet since there was no error
    0              		    \ return with 0 indicating no error
 ;

: throw ( i*x errcode -- i*x errcode | i*x errcode ) ( RS: -- sp hlr i*adr )
    dup 0= if              \ throwing 0 means no error
      drop                 \ drop error code
      exit                 \ exit from execute (*)
    then
    handler @ rp!          \ restore return stack, now it is the same as it was right before the execute (*) (RS: sp h)
    r> handler !           \ restore the previous handler
    r>                     \ get the saved data stack pointer
    swap                   \ (sp errcode)
    >r                     \ move errcode to the returnstack temporally
    sp!                    \ restore data stack to the same as it was before the most recent catch
    drop r>                \ move the errorcode to the stack
 ;                         \ This will return to the caller of most recent catch    
 

\ usage

99 constant division_by_zero

: div ( q d -- r ) 
    dup 0 = if 
      division_by_zero throw 
    else 
      / 
    then ;

: test-div ( q d -- r )
  ['] div catch dup 0 <> if           \ call div in a "catch block". if no exception was thrown, the error code is 0
      dup division_by_zero = if       \ error code is 99 indicating division by zero
        ." Error: division by zero"
      else
        throw                         \ there was an other error, rethrow it
      then
    then drop ; 
```


