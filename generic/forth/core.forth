: interpret-mode? state @ 0= ;
: prepare-backward-ref here ;
: resolve-backward-ref here - cell - , ;

: begin
       compile_time_only
       prepare-backward-ref ; immediate

: again
       compile_time_only
       ['] branch , resolve-backward-ref ; immediate

: until
       compile_time_only
       ['] branch0 , resolve-backward-ref ; immediate

: char: word drop c@ ;

: ( begin key [ char: ) ] literal = until ; immediate
: \ begin key dup 13 = swap 10 = or until ; immediate

: dip ( a xt -- a ) swap >r execute r> ;
: sip ( a xt -- xt.a a ) over >r execute r> ;
: bi ( a xt1 xt2 -- xt1.a xt2.a ) ['] sip dip execute ;
: bi* ( a b xt1 xt2 -- xt1.a xt2.b ) ['] dip dip execute ;
: bi@ ( a b xt -- xt.a xt.b ) dup bi* ;

: 3dup ( a b c -- a b c a b c) dup 2over rot ;
: 3drop ( a b c -- ) 2drop drop ;

: cr ( -- ) 13 emit 10 emit ;
: space ( -- ) 32 emit ;

: % ( n -- remainder ) /mod drop ; 
: / ( n -- quotient ) /mod nip ;

: prepare-forward-ref here 0 , ;
: resolve-forward-ref dup here swap - cell - swap ! ;

: if
       compile_time_only
       ['] branch0 , prepare-forward-ref ; immediate

: else
       compile_time_only
       ['] branch , prepare-forward-ref swap
       resolve-forward-ref ; immediate

: then
       compile_time_only
       resolve-forward-ref ; immediate       

: . ( n -- )
       dup 0< if 45 emit -1 * then
       10 /mod dup 0= if
           drop 48 + emit
       else
          . 48 + emit
       then ;

: ? ( a -- ) @ . ;

: do
       compile_time_only
       ['] swap , ['] >r , ['] >r ,
       prepare-backward-ref
   ; immediate

: bounds ( start len -- limit start )
    over + swap ;

: loop
       compile_time_only
       ['] r> , ['] 1+ , ['] >r ,
       ['] r2dup , ['] r> , ['] r> ,
       ['] >= , ['] branch0 , resolve-backward-ref
       ['] r> , ['] r> , ['] 2drop ,
   ; immediate

: +loop-terminate? ( n limit i -- bool )
    swap 1+
    - dup rot + xor 0 < ;          \ (index-limit) and (index-limit+n) have different sign?

: +loop
    compile_time_only     
    ['] dup ,
    ['] r> , ['] + , ['] >r ,
    ['] r2dup , ['] r> , ['] r> ,
    ['] +loop-terminate? ,
    ['] branch0 , resolve-backward-ref
    ['] r> , ['] r> , ['] 2drop ,
 ; immediate

: while
    compile_time_only
    ['] branch0 , prepare-forward-ref ; immediate

: repeat
    compile_time_only
    swap
    ['] branch , resolve-backward-ref 
    resolve-forward-ref ; immediate

: case
    compile_time_only 
    0 ; immediate                           \ init branchcounter

: of
    compile_time_only
    ['] over , ['] = ,
    ['] branch0 , prepare-forward-ref 
    ['] drop , ; immediate  

: endof 
    compile_time_only
    swap 1+ swap                            \ increase number of branches
    ['] branch , prepare-forward-ref swap
    resolve-forward-ref
    swap ; immediate                        \ keep branch counter at TOS

: endcase
    compile_time_only
    0 do
        resolve-forward-ref
    loop ; immediate

: override ( -- ) lastword hide ; immediate

: create: createheader enterdoes , 0 , ;
: does> r> lastword link>body ! ;

: constant: create: , does> @ ; 
: init-variable: create: , does> ;
: variable: 0 init-variable: ; 

-1 constant: TRUE 
 0 constant: FALSE

0  constant: EOK
85 constant: EUNDERFLOW
86 constant: EOVERFLOW
65 constant: EASSERT
40 constant: ENOTFOUND
67 constant: ECONVERT
69 constant: EESCAPE

: ['], ['] ['] , ;

: +! ( n var -- ) dup @ rot + swap ! ;
: c+! ( n var -- ) dup c@ rot + swap c! ;

: xt>body ( xt -- a ) 2 cells + ;

: defer: ( "name" -- )
    create: ['] abort ,
    does> @ execute ;

: defer! ( dst-xt src-xt -- ) swap xt>body ! ;

defer: unhandled
defer: handler
0 init-variable: var-handler            \ stores the address of the nearest exception handler
: single-handler ( -- a ) var-handler ; \ single threaded global handler

: catch ( xt -- errcode | 0 )
      sp@ >r handler @ >r          \ save current stack pointer and previous handler (RS: sp h)
      rp@ handler !                \ set the currend handler to this
      execute                      \ execute word that potentially throws exception
      r> handler !                 \ word returned without exception, restore previous handler
      r> drop 0 ;                  \ drop the saved sp return 0 indicating no error

: throw ( i*x errcode -- i*x errcode | 0 )
      dup 0= if drop exit then     \ 0 means no error, drop errorcode exit from execute
      handler @ 0= if              \ this was an uncaught exception
          unhandled
          exit
      then
      handler @ rp!           \ restore rstack, now it is the same as it was before execute
      r> handler !            \ restore next handler
      r> swap >r sp!          \ restore the data stack as it was before the most recent catch
      drop r> ;               \ return to the caller of most recent catch with the errcode

: ' ( -- xt | throws:ENOTFOUND ) \ find the xt of the next word in the inputstream
    word find dup
    0= if 
        ENOTFOUND throw
    else 
        link>xt 
    then ;

' handler ' single-handler defer!

: compile-imm: ( -- | throws:ENOTFOUND ) ' , ; immediate \ force compile semantics of an immediate word

: is:
    interpret-mode? if
        ' defer!
    else        
        ['], ' , ['] defer! ,
    then ; immediate

: array: ( size "name" -- ) ( index -- addr )
      create: cells allot
      does> swap cells + ;

: byte-array: ( size "name" -- ) ( index -- addr )
    create: allot
    does> swap + ;
    
: struct 0 ;
: field: create: over , + does> @ + ;

: [str ( -- address-to-fill-in )
    ['], here 3 cells + ,           \ compile return value: address of string
    ['] branch ,                    \ compile branch that will skip the string
    here                            \ address of the dummy address 
    0 , ;                           \ dummy address

: str] ( address-to-fill-in -- )
    0 c,                            \ terminate string
    dup here swap - cell - swap ! ; \ calculate and store relative address    

: eschr ( char -- char ) \ read next char from stdin
    dup [ char: \ ] literal = if
        drop key case
            [ char: r ] literal of 13 endof
            [ char: n ] literal of 10 endof
            [ char: t ] literal of 9  endof
            [ char: \ ] literal of 92 endof
            EESCAPE throw
        endcase
    then ;

: c,-until ( separator -- )
    begin
        key 2dup <>
    while
        eschr c, 
    repeat        
    2drop ;                          \ drop last key and separator

: separator ( -- char )
    begin
        key dup 
        32 = over 9 = or  
    while
        drop
    repeat ;

: str: ( "<separator>string content<separator>" )
    separator
    interpret-mode? if
        align! here swap c,-until 0 c,
    else
        [str swap c,-until str]
    then        
 ; immediate

: strlen ( str -- len )
    0 swap
    begin
        dup c@ 0<>
    while
    ['] 1+ bi@
    repeat 
    drop ;

: str-starts-with ( str substr -- bool )
    begin
        2dup ['] c@ bi@
        dup 0= if                       \ end of substr
            4drop TRUE exit
        then
        swap
        dup 0= if                       \ end of str
            4drop FALSE exit 
        then
        <> if                           \ character mismatch
            2drop FALSE exit 
        then
        ['] 1+ bi@
    again ;

: str-includes ( str substr -- bool )
    begin
        2dup str-starts-with if
            2drop TRUE exit
        then
        swap dup c@ 0= if
            2drop FALSE exit 
        then
        1+ swap
    again ;

: abs ( n -- n ) dup 0< if -1 * then ;
: max ( a b -- max ) 2dup < if nip else drop then ;
: min ( a b -- min ) 2dup < if drop else nip then ;
: between? ( min-inclusive num max-inclusive -- bool ) over >=  -rot <= and ;

: hexchar>int ( char -- n | throws:ECONVERT )
    48 over 57 between? if 48 - exit then
    65 over 70 between? if 55 - exit then
    97 over 102 between? if 87 - exit then
    ECONVERT throw ;

: hex>int' ( str len -- n | throws:ECONVERT )
    dup 0= if ECONVERT throw then
    dup 1- 2 lshift 0 swap
    2swap 0 do
        dup >r
        c@ hexchar>int
        over lshift rot +
        swap 4 -
        r> 1+
    loop 
    2drop ;

: hex>int ( str -- n | throws:ECONVERT ) dup strlen hex>int' ;

: hex:
    word hex>int'
    interpret-mode? invert if ['], , then 
  ; immediate

: print: ( "<separator>string<separator>" )
    interpret-mode? if
        separator
        begin
            key 2dup <>
        while
            eschr emit
        repeat
        2drop           
    else
        compile-imm: str: ['] type ,
    then ; immediate
  
: println: ( "<separator>string<separator>" )
    interpret-mode? if
        str: "print:" 6 find link>xt execute cr \ XXX
    else
        compile-imm: str: ['] type , ['] cr ,
    then ; immediate

: print-stack ( -- )
    depth 0= if exit then
    print: "stack["
    0 depth 2 - do 
        sp@ i cells + @ .
    i 0<> if space then
    -1 +loop 
    print: "] ";

: clear-stack ( i*x -- ) 
    depth 0 do drop loop ;

: marker: ( "name" -- )
    create:
        lastword ,
    does>
        @ dup 
    @ var-lastword !
    var-dp ! ;

: each-word ( xt -- )
    lastword
    begin
        dup 0<>
    while
        2dup swap execute
        @
    repeat
    2drop ;

: type-word ( link -- )
    ['] link>name ['] link>len bi
    type-counted space ;    

: print-words ( -- ) ['] type-word each-word ;

: stack_prompt ( -- ) 
    depth 0< if EUNDERFLOW throw then
    cr print-stack
    print: "% " ;

' stack_prompt prompt !

: in-heap? ( a -- bool ) heap-start over heap-end between? ;

: traceback ( code -- )
    cr print: "Unhandled exeption: " .
    print: " rdepth: " rdepth . cr
    rdepth 1+  3 do
        print: "  at "
        rp@ i cells + @                     \ i. return address
        in-heap? if
            cell - @                        \ instruction before the return address 
            lastword    
            begin
                dup 0<>
            while
                2dup
                link>xt = if dup type-word then
                @
            repeat
            [ char: ( ] literal emit
            drop .
            [ char: ) ] literal emit
            cr
        else
            print: "??? (" . println: ")"     \ not valid return address, could be doloop var
        then            
    loop
    depth 0> if print-stack then
    abort ; 

' unhandled is: traceback

