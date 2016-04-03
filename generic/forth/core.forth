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

: '.' [ char . ] literal ; 
: '"' [ char " ] literal ;
: "'" [ char ' ] literal ;

: 'space' ( -- n ) 32 ;
: cr ( -- ) 'cr' emit 'lf' emit ;
: space ( -- ) 'space' emit ;

: % ( n -- remainder ) /mod drop ; 
: / ( n -- quotient ) /mod nip ;

: [compile] word find drop , ; immediate

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

: ' ( -- addr ) word find drop ; \ find the xt of the next word in the inputstream

: create createheader enterdoes , 0 , ;
: does> r> lastword link>body ! ;

: constant create , does> @ ; 
: variable create 0 , does> ; 

-1 constant TRUE 0 constant FALSE

: array ( size -- ) ( index -- addr )
      create cells allot
      does> swap cells + ;

: struct 0 ;
: field create over , + does> @ + ;

' ['] constant XT_LIT

: lit-zstring-start ( -- address-to-fill-in )
    XT_LIT , here 3 cells + ,       \ compile return value: address of string
    ['] branch ,                    \ compile branch that will skip the string
    here                            \ address of the dummy address 
    0 , ;                           \ dummy address

: lit-zstring-end ( address-to-fill-in -- )
    0 c,                            \ terminate string
    dup here swap - cell - swap ! ; \ calculate and store relative address    

: lit-zstring-body ( separator -- )
    dup
    key dup rot <> if
        begin 
        c, dup
        key dup rot = until
    then
    2drop ;                          \ drop last key and separator

: s"
    compile_time_only
    lit-zstring-start
    '"' lit-zstring-body
    lit-zstring-end
 ; immediate

: s'
    compile_time_only
    lit-zstring-start
    "'" lit-zstring-body
    lit-zstring-end
 ; immediate

: strlen ( zstring -- len )
    dup c@ 0= if 
        drop 
        0 exit 
    then
    0 
    begin
        1+
    2dup + c@ 0= until 
    nip ;

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
    
: .s ( i*x -- i*x )   \ TODO reverse order
    depth 0 do 
        sp@ i cells + @ . space 
    loop ;

: clear-stack ( i*x -- ) 
    depth 0 do . cr loop ;

variable handler 0 handler !       \ stores the address of the nearest exception handler

: uncaught_exception_handler
      ." Uncaught exception: " . cr abort ;

: catch ( xt -- errcode | 0 )
      sp@ cell + >r handler @ >r   \ save current stack pointer and previous handler (RS: sp h)
      rp@ handler !                \ set the currend handler to this
      execute                      \ execute word that potentially throws exception
      r> handler !                 \ word returned without exception, restore previous handler
      r> drop 0 ;                  \ drop the saved sp return 0 indicating no error

: throw ( i*x errcode -- i*x errcode | 0 )
      dup 0= if drop exit then    \ 0 means no error, drop errorcode exit from execute
      handler @ 0= if             \ this was an uncaught exception
          uncaught_exception_handler 
          exit
      then
      handler @ rp!           \ restore rstack, now it is the same as it was before execute
      r> handler !            \ restore next handler
      r> swap >r sp!          \ restore the data stack as it was before the most recent catch
      drop r> ;               \ return to the caller of most recent catch with the errcode

: default_prompt cr ." # " ;  \ FIXME must be one line because there is no smudge bit for hiding the incomplete def

