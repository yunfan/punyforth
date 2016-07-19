[![Build Status](https://travis-ci.org/zeroflag/punyforth.svg?branch=master)](https://travis-ci.org/zeroflag/punyforth)

# Punyforth

*Please not this is under development*

Punyforth is a simple, stack-based, [FORTH](https://en.wikipedia.org/wiki/Forth_(programming_language)) inspired programming language that primarily targets Internet of Things (IOT) devices, like the [ESP8266](https://en.wikipedia.org/wiki/ESP8266). The ESP8266 is a low-cost Wi-Fi capable chip with a Xtensa LX3 CPU, TCP/IP stack, GPIO pins and 512 KiB to 4 MiB flash memory. It is widely used in IoT applications and home automation projects.

Punyforth also runs on x86 (Linux), ARM (Raspberry PI) but these are *not* the primary supported targets.

### Design goals

* Simple
* Highly interactive 
* Extensible
* Small memory footprint

## Differences between Punyforth and other FORTH systems

Punyforth is heavily inspired by the [FORTH](https://en.wikipedia.org/wiki/Forth_(programming_language)) programming language. It uses the same compilation model (outer interpreter, compiler, modes, dictionary, immediate words, etc) as other FORTH systems. Punyforth is [bootstrapped](http://www.lispcast.com/two-kinds-of-bootstrapping) from a small set of [primitives](arch/x86/primitives.S) written in assembly language. The compiler targets these primitives and compiles [indirect-threaded code](https://en.wikipedia.org/wiki/Threaded_code). Higher level  abstractions are built on top of the primitives therefore most of the system is written in itself (in FORTH).

### Some of the differences
* Punyforth is case sensitive
* Strings are null-terminated
* Strings are created and printed differently (*str: "foobar"*, *print: "foobar"* instead of *s" foobar"*, *." foobar"*)
* Parsing words are ended with a colon character by convention (including *variable:*, *constant:*, *create: does>*)
* Defining a word in terms of itself results recursion by default (use the *override* word to alter this behaviour)

Punyforth supports exception handling, multitasking, socket and GPIO APIs and comes with a UART and a TCP REPL.

## About the language

Punyforth is a simple, imperative, stack-based, concatenative programming language and interactive environment with good metaprogramming support and extensibility.

The Forth environment combines the compiler with an interactive shell (REPL), where the user can define functions called words.

Punyforth does not have local variables, instead values are kept on a stack. This stack is used only for storing data. There is a separate return stack that stores information about nested subroutin calls. Both stacks are first-class in the language.

As a consequence of the stack, Punyforth uses a form of syntax known as Reverse Polish or Postfix Notation.

If you type the following code in the REPL:

```forth

1 2 +

```

The interpreter pushes the number 1 then the number 2 onto the data stack. It executes the word *+*, which pops the two top level items off the stack, calculates their sum, and pushes the result back to the stack.


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

The REPL (also known as the Forth Outer/Text Interpreter) operates in 2 modes. In interpretation mode, it immediately executes the words that the user typed in. In compilation mode (when you start a new word definition), its action depends on the compilation semantic of the current word. In most cases it compiles the execution token (pointer to the word) into the word to be defined. However, if the current word is flagged as immediate, the compiler executes the word at compile time so the word can define its own compilation semantic. This is a bit similar than Lisp macros. Control structures are implemented as immediate words in Forth.

### The syntax

Forth has almost no syntax. It grabs tokens separated by whitespace, looks them up in a dictionary then executes either their compilation or interpretation semantic. If the token is not found in the dictionary, it tries to convert it to a number. Because of the postfix notation there are no precedence rules and parentheses. Punyforth, unlike most other Forth systems, is case-sensitive.

### Extending the dictionary



```forth
: square ( n -- nsquared ) dup * ;

4 square .      \ prints 16
```
Word definitions start with colon character and end with a semicolon. The *n -- nsquared* is the optional stack effect comment.

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
: abs ( n -- absn ) 
  dup 0< if -1 * then ;
  
-10 abs . \ prints 10  
```

#### Case statement

Punyforth also supports switch-case like flow control logic as shown in the following example.

```forth
: day ( n -- )
  case
    1 of print: "Monday" endof
    2 of print: "Tuesday" endof
    3 of print: "Wednesday" endof
    4 of print: "Thursday" endof
    5 of print: "Friday" endof
    6 of print: "Saturday" endof
    7 of print: "Sunday" endof
    print: "Unknown day: " .
  endcase ;
````

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

##### until loop

```forth
begin <loop-body> <bool> until
```
The *begin*...*until* loop repeats until a condition is true. This loop always executes at least one time.

For example:

```forth
: countdown ( n -- )
  begin 
    dup .
    1- dup
  0 < until
  drop ;
  
5 countdown \ prints 543210
```

If you replace *until* with *again* and omit the condition then the loop will run indefinitely.

```forth
begin <loop-body> again
```

##### while loop

```forth
begin .. <bool> while <loop-body> repeat
```
For example:
```forth
: countdown ( n -- )
  begin
    dup 0 >=
  while
    dup . 1-
  repeat
  drop ;
  
5 countdown \ prints 543210
```


You can use the *exit* word to exit from the current word as well from the loop.

Control structres are compile time words therefore they can be used only in compilation mode (inside a word definition).

### Exception handling

If a word faces an error condition it can *throw* an exception. Exceptions are represented as numbers in Punyforth. Your can provide exception handlers to *catch* exceptions. 

For example:

```forth
1099 constant: division_by_zero \ define a constant: for the exception

: div ( q d -- r | throws:division_by_zero ) \ this word throws an exception in case of division by zero
    dup 0= if 
      division_by_zero throw 
    else 
      / 
    then ;

: test-div ( q d -- r )
  ['] div catch dup 0 <> if         \ call div in a "catch block". If no exception was thrown, the error code is 0
      dup division_by_zero = if     \ error code is 1099 indicating division by zero
        print: "Error: division by zero"
      else
        throw                       \ there was an other error, rethrow it
      then
    then drop ; 
```

The word *catch* expects an execution token of a word that potentially throws an exception.

The exeption mechanism in Punyforth follows the "catch everything and re-throw if needed" semantics. The instruction *0 throw* is essentially a no-op and indicates no error.

#### Uncaught exception handler

An uncaught exception causes the program to print out the error and the stack trace to the standard output and terminate.

You can modify this behaviour by overriding the *unhandled* deferred word.

```forth
: my-uncaught-exception-handler ( code -- )
    cr print: "Uncaught exception: " . cr
    abort ;
    
' unhandled is: my-uncaught-exception-handler
```    

The implementation of exceptions is based on the idea of [William Bradley](http://www.complang.tuwien.ac.at/anton/euroforth/ef98/milendorf98.pdf).

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

### Deferred words

 Punyforth relies on a [Hyper Static Global Environment](http://c2.com/cgi/wiki?HyperStaticGlobalEnvironment). This means redefining a word will create a new definition, but the words continue to refer to the definition that existed when they were defined. You can alter this behaviour by using deferred words.

For example

```forth
: myword1 ( -- ) 
  print: 'foo' ;

: myword2 ( -- ) 
  myword1 
  print: 'bar' ;
    
: myword1 ( -- ) \ redefining myword1 to print out baz instead of foo
  print: 'baz' ; 

myword2 \ myword2 will print out foobar, not bazbar
```

Redefinition has no effect on myword2. Let's try it again. This time using the *defer:*/*is:* words.

```forth
defer: myword1

: myword2 ( -- )
  myword1                       \ I can define myword2 in terms of the (yet undefined) myword1  
  print: 'bar' ; 

: printfoo ( -- ) print: 'foo' ;
: printbaz ( -- ) print: 'baz' ;

' myword1 is: printfoo          \ redefine the deferred word to print out foo
myword2                         \ this prints out foorbar

' myword1 is: printbaz          \ redefine the deferred word to print out baz
myword2                         \ this prints out bazbar
```

### Override

### Factor style combinators

Punyforth supports a few [Factor](https://factorcode.org/) style combinators.

* dip ( a xt -- a )
* sip ( a xt -- xt.a a )
* bi ( a xt1 xt2 -- xt1.a xt2.a )
* bi* ( a b xt1 xt2 -- xt1.a xt2.b )
* bi@ ( a b xt -- xt.a xt.b )


### The word *create: does>*

TODO

### About the implementation of *create: does>*

TODO

```forth
: constant: ( n -- ) 
    create: , 
    does> @ ;

: create:
    createheader enterdoes , 0 , ;     \ write enterdoes to the code field and store a dummy addres for the behavior
    
: does>
    r> lastword link>body ! ;          \ store the pointer to the behavior into the body of the lastword

( Examples )

-1 constant: TRUE 
0 constant: FALSE

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
| LNK | 8 | constant: | 1 | CW | xt_create | xt_, | xt_r> | xt_lastword | xt_link>body | xt_! | xt_@ | xt_exit |
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

### Other examples of create: does>

```forth
: array: ( size "name" -- ) ( index -- addr )
    create: cells allot
    does> swap cells + ;
    
10 array: numbers

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
  create: over , + 
  does> @ + ;

struct 
  cell field width 
  cell field height
constant Rect

: new-rect
  Rect create: allot does> ;
  
: area ( rect -- area ) 
  dup width @ swap height @ * ;  
  
new-rect r1
  
3 r1 width !
5 r1 height !  
  
r1 area .  
  
```

### Unit testing

### ESP8266 specific things

#### WIFI

##### Examples

```forth
str: "MyPassword" str: "MySSID" wifi-connect
```    

#### GPIO

##### Examples

```forth
2 constant: PIN
PIN GPIO_OUT gpio-enable
PIN HIGH gpio-write
250 delay
PIN LOW gpio-write
```

#### Netconn

Netconn is a sequential API on top of the [lightweight TCP/IP stack](https://en.wikipedia.org/wiki/LwIP) of [FreeRTOS] (https://en.wikipedia.org/wiki/FreeRTOS). Punyforth provides a forth wrapper around the Netconn API.

**OBSOLETE**

##### Examples

```forth
80 str: "google.com" tcp-open constant: SOCKET
SOCKET str: "GET / HTTP/1.1" writeln
SOCKET write-crlf
SOCKET ['] type-counted receive
```

```forth
1024 byte-array: buffer
80 str: "google.com" tcp-open constant: SOCKET
SOCKET str: "GET / HTTP/1.1" writeln
SOCKET write-crlf
1024 0 buffer SOCKET receive-into
```


#### Flash

#### Storing code in flash

#### OLED display ssd1306 through SPI

#### Tasks (experimental)

Punyforth supports cooperative multitasking which enables users to run more than one task simultaneously. For example one task may wait for input on a socket, while another one receives commands through the serial port. Punyforth never initiates a context switch by its own. Instead, tasks voluntarily yield control periodically using the word *pause*. Tasks are executed in a round robin fashion.

In order to run some code in the background, one must create a new task first, using the *task:* parsing word. A tasks can be activated inside a word. This word usually does something in a loop and calls *pause* periodically to yield controll to other tasks.

```forth
task: mytask

: my-word
  mytask activate
  [...] pause [...]
  deactivate
```

To start the task, first you have to switch to multi tasking mode first by executing the word *multi*. Then simply call the word that was associated to the task.

```forth
multi 
my-word
```

##### Locks

semaphore mutex wait signal

##### Mailboxes

Often tasks need to communicate with each other. A mailbox is a fixed size blocking queue where messages can be left for a task. Receiving from an empty mailbox or sending to a full mailbox blocks the current task.

```forth
\ create a mailbox with size 5
5 mailbox: mailbox1

\ create a task for the consumer
task: task-consumer

\ this word is executed by the task
: consumer ( task -- )
    activate                            \ actiavte task
    begin    
        mailbox1 receive .              \ receive and print one item from the mailbox
        println: "received by consumer"
        pause                           \ allow other tasks to run
    again
    deactivate ;                        \ deactivate task

\ multi                                   \ switch to multitask mode
\ task-consumer consumer                  \ run the consumer
\ 123 mailbox1 send                       \ send some numbers to the consumer
\ 456 mailbox1 send
```

##### Examples

```forth
\ create a task for the counter
task: task-counter

\ this word is executed by the task
: counter ( task -- )
    activate                              \ actiavte task
    100 0 do 
        i . cr 
        500 delay
    loop
    deactivate ;                          \ deactivate task

multi                                     \ switch to multitask mode
task-counter counter                      \ run the consumer
```

#### Misc
