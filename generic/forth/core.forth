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

: ')' [ char ) ] literal ;
: 'cr' 13 ; 
: 'lf' 10 ; 

: ( begin key ')' = until ; immediate
: \ begin key dup 'cr' = swap 'lf' = or until ; immediate

: dip ( a xt -- a ) swap >r execute r> ;
: sip ( a xt -- xt.a a ) over >r execute r> ;
: bi ( a xt1 xt2 -- xt1.a xt2.a ) ['] sip dip execute ;
: bi* ( a b xt1 xt2 -- xt1.a xt2.b ) ['] dip dip execute ;
: bi@ ( a b xt -- xt.a xt.b ) dup bi* ;

: '"' [ char " ] literal ;
: "'" [ char ' ] literal ;

: 'space' ( -- n ) 32 ;
: cr ( -- ) 'cr' emit 'lf' emit ;
: space ( -- ) 'space' emit ;

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

: create createheader enterdoes , 0 , ;
: does> r> lastword link>body ! ;

: constant create , does> @ ; 
: variable create 0 , does> ; 

-1 constant TRUE 0 constant FALSE

: default-exception-handler ( code -- )
    cr 
    [ char E ] literal emit
    [ char R ] literal dup emit emit
    space
    . cr
    abort ;

variable on-uncaught-exception
variable handler 0 handler !       \ stores the address of the nearest exception handler

: catch ( xt -- errcode | 0 )
      sp@ cell + >r handler @ >r   \ save current stack pointer and previous handler (RS: sp h)
      rp@ handler !                \ set the currend handler to this
      execute                      \ execute word that potentially throws exception
      r> handler !                 \ word returned without exception, restore previous handler
      r> drop 0 ;                  \ drop the saved sp return 0 indicating no error

: throw ( i*x errcode -- i*x errcode | 0 )
      dup 0= if drop exit then    \ 0 means no error, drop errorcode exit from execute
      handler @ 0= if             \ this was an uncaught exception
          on-uncaught-exception @ execute
          exit
      then
      handler @ rp!           \ restore rstack, now it is the same as it was before execute
      r> handler !            \ restore next handler
      r> swap >r sp!          \ restore the data stack as it was before the most recent catch
      drop r> ;               \ return to the caller of most recent catch with the errcode

: array ( size -- ) ( index -- addr )
      create cells allot
      does> swap cells + ;

: struct 0 ;
: field create over , + does> @ + ;

: ' ( -- addr | throws:10 ) \ find the xt of the next word in the inputstream
    word find dup 0= if 10 throw else nip then ;

' ['] constant XT_LIT

' default-exception-handler on-uncaught-exception !

: [compile] ( -- | throws:10 ) ' , ; immediate

: [str ( -- address-to-fill-in )
    XT_LIT , here 3 cells + ,       \ compile return value: address of string
    ['] branch ,                    \ compile branch that will skip the string
    here                            \ address of the dummy address 
    0 , ;                           \ dummy address

: str] ( address-to-fill-in -- )
    0 c,                            \ terminate string
    dup here swap - cell - swap ! ; \ calculate and store relative address    

: c,-until ( separator -- )
    dup
    key dup rot <> if
        begin 
        c, dup
        key dup rot = until
    then
    2drop ;                          \ drop last key and separator

: s"
    compile_time_only
    [str '"' c,-until str]   
 ; immediate

: s'
    compile_time_only
    [str "'" c,-until str]
 ; immediate

: (crlf) [str 'cr' c, 'lf' c, str] ; immediate
: \r\n (crlf) ;

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

: ."
    state @ 0= if            \ interpretation mode 
        begin
            key dup 34 = if
                drop exit
            then
            emit
        again
    else                     \ compilation mode 
        [compile] s" ['] type ,
    then ; immediate
    
: .s ( i*x -- i*x )
    depth 0= if exit then
    ." stack["
    0 depth 2 - do 
        sp@ i cells + @ .
    i 0<> if space then
    -1 +loop 
    ." ] ";

: clear-stack ( i*x -- ) 
    depth 0 do drop loop ;

: marker
    create
        lastword ,
    does>
        @ dup 
    @ var-lastword !
    var-dp ! ;

: print-words ( -- )
    lastword
    begin
       dup 0<>
    while
       dup
       ['] link>name ['] link>len bi 
       @ type-counted cr
       @
    repeat 
    drop ;   

: stack_prompt ( -- ) 
    cr .s ." % " ;

' stack_prompt prompt !
