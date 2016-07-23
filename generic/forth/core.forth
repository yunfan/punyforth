: interpret? state @ 0= ;
: backref, here - cell - , ;

: begin immediate compile-time
    here ; 

: again immediate compile-time
    ['] branch , backref, ;

: until immediate compile-time
    ['] branch0 , backref, ;

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

: prepare-forward-ref ( -- a) here 0 , ;
: resolve-forward-ref ( a -- ) dup here swap - cell - swap ! ;

: if immediate compile-time
    ['] branch0 , prepare-forward-ref ;

: else immediate compile-time
    ['] branch , prepare-forward-ref swap
    resolve-forward-ref ;

: then immediate compile-time
    resolve-forward-ref ;

: . ( n -- )
    dup 0< if 45 emit -1 * then
    10 /mod dup 0= if
        drop 48 + emit
    else
        . 48 + emit
    then ;

: ? ( a -- ) @ . ;

: do immediate compile-time
    ['] swap , ['] >r , ['] >r ,
    here ; \ prepare backref

: bounds ( start len -- limit start )
    over + swap ;

: loop immediate compile-time
    ['] r> , ['] 1+ , ['] >r ,
    ['] r2dup , ['] r> , ['] r> ,
    ['] >= , ['] branch0 , backref,
    ['] r> , ['] r> , ['] 2drop , ;

: +loop-terminate? ( n limit i -- bool )
    swap 1+
    - dup rot + xor 0 < ;          \ (index-limit) and (index-limit+n) have different sign?

: +loop immediate compile-time     
    ['] dup ,
    ['] r> , ['] + , ['] >r ,
    ['] r2dup , ['] r> , ['] r> ,
    ['] +loop-terminate? ,
    ['] branch0 , backref,
    ['] r> , ['] r> , ['] 2drop , ;

: unloop r> r> r> 2drop >r ;

: while immediate compile-time
    ['] branch0 , prepare-forward-ref ;

: repeat immediate compile-time
    swap
    ['] branch , backref, 
    resolve-forward-ref ;

: case ( -- branch-counter ) immediate compile-time 0 ;

: of immediate compile-time
    ['] over , ['] = ,
    ['] branch0 , prepare-forward-ref 
    ['] drop , ;

: endof immediate compile-time
    swap 1+ swap                            \ increase number of branches
    ['] branch , prepare-forward-ref swap
    resolve-forward-ref
    swap ;                                  \ keep branch counter at TOS

: endcase ( #branches #branchesi*a -- ) immediate compile-time
    0 do
        resolve-forward-ref
    loop ;

: override immediate ( -- ) lastword hide ;

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

: { immediate compile-time
    ['], here 3 cells + ,
    ['] branch , prepare-forward-ref
    entercol , ;

: } immediate compile-time
    ['] exit , 
    resolve-forward-ref ;

: ' ( -- xt | throws:ENOTFOUND ) \ find the xt of the next word in the inputstream
    word find dup
    0= if 
        ENOTFOUND throw
    else 
        link>xt 
    then ;

' handler ' single-handler defer!

: compile-imm: ( -- | throws:ENOTFOUND ) ' , ; immediate \ force compile semantics of an immediate word

: is: immediate
    interpret? if
        ' defer!
    else        
        ['], ' , ['] defer! ,
    then ;

: array: ( size "name" -- ) ( index -- addr )
    create: cells allot
    does> swap cells + ;

: byte-array: ( size "name" -- ) ( index -- addr )
    create: allot
    does> swap + ;
    
: buffer: ( size "name" -- ) ( -- addr )
    create: allot does> ;
    
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

: whitespace? ( char -- bool )
    case
        32 of TRUE exit endof
        13 of TRUE exit endof
        10 of TRUE exit endof
        9 of TRUE exit endof
        drop FALSE     
    endcase ;

: line-break? ( char -- bool )
    dup 10 = swap 13 = or ;

: c,-until ( separator -- )
    begin
        key 2dup <>
    while
        dup line-break? if
            drop
        else
            eschr c, 
        then
    repeat        
    2drop ;                          \ drop last key and separator

: separator ( -- char )
    begin
        key dup whitespace?        
    while
        drop
    repeat ;

: str: ( "<separator>string content<separator>" ) immediate
    separator
    interpret? if
        align! here swap c,-until 0 c,
    else
        [str swap c,-until str]
    then ;

: strlen ( str -- len )
    0 swap
    begin
        dup c@ 0<>
    while
    ['] 1+ bi@
    repeat 
    drop ;

: =str ( str1 str2 -- bool )
    begin
        2dup ['] c@ bi@
        2dup ['] 0<> bi@ and
        -rot = and        
    while
        ['] 1+ bi@
    repeat
    ['] c@ bi@ ['] 0= bi@ and ;

: str-starts? ( str substr -- bool )
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

: str-in? ( str substr -- bool )
    begin
        2dup str-starts? if
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

: hex: immediate
    word hex>int'
    interpret? invert if ['], , then ;

: print: ( "<separator>string<separator>" ) immediate
    interpret? if
        separator
        begin
            key 2dup <>
        while
            eschr emit
        repeat
        2drop           
    else
        compile-imm: str: ['] type ,
    then ;
  
: println: ( "<separator>string<separator>" ) immediate
    interpret? if
        str: "print:" 6 find link>xt execute cr \ XXX
    else
        compile-imm: str: ['] type , ['] cr ,
    then ;

defer: s0 ' s0 is: _s0
defer: r0 ' r0 is: _r0

: depth ( -- n ) s0 sp@ - cell / 1- ;
: rdepth ( -- n ) r0 rp@ - cell / 1- ;

: marker: ( "name" -- )
    create:
        lastword ,
    does>
        @ dup 
    @ var-lastword !
    var-dp ! ;

: link-type ( link -- )
    ['] link>name ['] link>len bi
    type-counted ;

: help ( -- )
    lastword
    begin
        dup 0<>
    while
        dup link-type cr @
    repeat
    drop ;

: stack-print ( -- )
    depth 0= if exit then
    depth 10 > if
        print: "stack[.. "
    else        
        print: "stack["
    then 
    0 depth 2 - 9 min do \ maximalize depth to print
        sp@ i cells + @ .
        i 0<> if space then
    -1 +loop 
    print: "] " ;

: stack-clear ( i*x -- )
    depth 0 do drop loop ;

: stack-show ( -- )
    {
        depth 0< if EUNDERFLOW throw then
        cr stack-print print: "% " 
    } prompt ! ;

: stack-hide ( -- ) 0 prompt ! ;

: heap? ( a -- bool ) heap-start over heap-end between? ;

: traceback ( code -- )
    cr print: "Exeption: " .
    print: " rdepth: " rdepth . cr
    rdepth 3 do
        print: "  at "
        rp@ i cells + @                     \ i. return address
        heap? if
            cell - @                        \ instruction before the return address 
            lastword    
            begin
                dup 0<>
            while
                2dup
                link>xt = if dup link-type space then               
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
    depth 0> if stack-print then
    abort ; 

' unhandled is: traceback

stack-show
