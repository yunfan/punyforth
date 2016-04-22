# Punyforth

Punyforth is a simple and portable implementation of the Forth programming language. Most parts of Punyforth is written in itself. Including the outer interpreter and the compiler (that compiles indirect-threaded code). The primitives are implemented in assembly language. Punyforth runs on x86 (Linux), ARM (Raspberry PI) and Xtensa LX3 (ESP8266). This latter one is the primary supported target.

Please note that at this stage punyforth is still incomplete.

## About the language

Forth is a simple imperative stack-based programming language and interactive environment with good metaprogramming support and extensibility.

The Forth environment combines the compiler with an interactive shell (REPL), where the user can define functions called words.

Punyforth does not have local variables, instead values are kept on a stack. This stack is used only for storing data. There is a separate return stack that stores information about nested subroutin calls. Both stacks are first-class in the language.

As a consequence of the stack, Punyforth uses a form of syntax known as Reverse Polish or Postfix Notation.

If you type the following code in the REPL:

```forth

1 2 +

```

The interpreter pushes the number 1 then the number 2 onto the data stack. It executes the word *+*, which removes the two top level items from the stack, calculates their sum, and pushes the result to the stack.


The following code calculates *3 * 3 + 2 * 2* and prints out *13*.

```forth

2 3 dup * swap dup * + .

```

The word *dup* duplicates the top level item of the stack. The word *swap* xchanges the two top level items of the stack.

Stack visualization:
<pre>
2 3  3  9  2   2 4 13
  2  3  2  9   2 9
     2         9
</pre>     

### Programming

During programming, the user uses the REPL to write and test small piece of codes or to extend the languge with new words (which are called subroutines or functions in other languages). 

The REPL (also known as the Forth Outer/Text Interpreter) operates in 2 modes. In interpretation mode, it immediately executes the words that the user typed in. In compilation mode (when you start a new word definition), its action depends on the compilation semantic of the current word. In most cases it compiles the execution token (pointer to the word) into the word to be defined. If the current word is flagged as immediate, the compiler executes the word at compile time so the word can define its own compilation semantic. This is a bit similar than Lisp macros. Control structures are implemented as immediate words in Forth.

### The syntax

Forth has almost no syntax. It grabs tokens separated by whitespace, looks them up in a dictionary then executes either their compilation or interpretation semantic. If the token is not found in the dictionary, it tries to convert it to a number. Because of the postfix notation there are no precedence rules and parentheses. Punyforth, unlike most other Forth systems, is case-sensitive.

### Control structures

Punyforth supports the regular Forth conditional and loop words.

#### Conditionals

General form of *if else then*.

```forth
<bool> if <consequent> else <alternative> then
```

For example:
```forth
: max ( a b -- max ) 
  2dup < if nip else drop then ;
  
10 100 max . \ prints 100
```

The else part can be omitted.

```forth
<bool> if <consequent> then
```

For example:

```forth
: abs ( n -- absn ) 
  dup 0< if -1 * then ;
  
-10 abs . \ prints 10  
```

#### Count-controlled loops

The *limit* and *start* before the word *do* defines the number of times the loop will run.

```forth
<limit> <start> do <loop-body> loop
```

*Do* loops iterate through integers by starting at *start* and incrementing until you reach the *limit*. The word "i" pushes the loop index onto the stack.

For example:
```forth
5 0 do i . loop \ prints 01234
```

There is an other version of the *do* loop where you can define the increment (which can be negative as well).

```forth
<limit> <start> do <loop-body> <increment> +loop
```

For example:

```forth
10 0 do i . 2 +loop \ prints 02468
```

If the increment is negative then *limit* is inclusive.

```forth
0 8 do i . -2 +loop \ prints 86420
```

#### Condition-controlled loops

```forth
begin <loop-body> <bool> until
```
The *begin*...*until* loop repeats until a condition is true. For example.

```forth
: countdown ( n -- )
  begin 
    dup .
    1- dup
  0= until
  drop ;
  
5 countdown
\ prints 54321  
```


If you replace *until* with *again* and omit the condition then the loop will run indefinitely.

```forth
begin <loop-body> again
```

You can use the *exit* word to exit from the current word as well from the loop.

Control structres are compile time words therefore they can be used only in compilation mode (inside a word definition).

### Exceptions

TODO

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
    here                   \ saves the absolute address of the beginning of the loop to the stack
 ; immediate
 
: until
    ['] branch0 ,          \ compiles a conditional branch
    here - cell - ,        \ calculate then compile the relative address 
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

: create 
    createheader enterdoes , 0 , ;     \ write enterdoes to the code field and store a dummy addres for the behavior
    
: does>
    r> lastword link>body ! ;          \ store the pointer to the behavior into the body of the lastword

( Examples )

-1 constant TRUE 
0 constant FALSE

```

#### How *does>* it work?

*constant* is a defining word that creates other words like *TRUE* or *FALSE*.

The word *does>* writes the pointer to the behavior (e.g. @) into the first cell of the recently defined word (e.g. TRUE).

*ENTERDOES* is similar than *ENTERCOL*. It pushes the data field (e.g. -1) to the stack before invoking the behavior.

Here are the dictionary entries of the compiled *constant* and the word *TRUE* created by constant.

<pre>                
                             address of ENTERCOL                
                             /                                  
                            |                                                                behavior
+-----+---+----------+---+----+-----------+------+-------+-------------+--------------+------+------+---------+
| LNK | 8 | constant | 1 | CW | xt_create | xt_, | xt_r> | xt_lastword | xt_link>body | xt_! | xt_@ | xt_exit |
+-----+---+----------+---+----+-----------+------+-------+-------------+--------------+------+------+---------+
                                                                                               /
                                             behavior pointer  /```````````````````````````````
                                                              |    
                                  +-----+---+------+---+----+----+----+     
                                  | LNK | 4 | TRUE | 1 | CW | bp | -1 |     
                                  +-----+---+------+---+----+----+----+     
                                                         /        data       
                                                        |
                                              address of ENTERDOES
</pre>

```assembly
ENTERDOES:
    sub ebp, CELLS
    mov [ebp], esi          // save esi to return stack
    add eax, CELLS          // eax points to the codeword field, skip this
    mov esi, [eax]          // after the codeword there is the behavior pointer
    add eax, CELLS          // after the behavior pointer there is the data field
    push eax               
    NEXT                    // jump to behavour
```

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
: struct 0 ;

: field 
  create over , + 
  does> @ + ;

struct 
  cell field width 
  cell field height
constant Rect

: new-rect
  Rect create allot does> ;
  
: area ( rect -- area ) 
  dup width @ swap height @ * ;  
  
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


