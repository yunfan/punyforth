: % /mod drop ; : / /mod nip ;

: '.' [ char . ] literal ; : '"' [ char " ] literal ;

: 'F' [ char F ] literal ; : ')' [ char ) ] literal ;

: 'cr' 13 ; : 'lf' 10 ; : 'space' 32 ;

:  cr 'cr' emit 'lf' emit ; : space 'space' emit ;

: [compile] word find drop , ; immediate

: if
       compile_time_only
       ['] branch0 , here 0 , ; immediate

: else
       compile_time_only
       ['] branch , here 0 ,
       swap dup here swap - cell -
       swap ! ; immediate

: then
       compile_time_only
       dup here swap - cell -
       swap ! ; immediate

: .
       dup 0< if 45 emit -1 * then
       10 /mod dup 0= if
           drop 48 + emit
       else
          . 48 + emit
       then ;

: ? @ . ;

: do
       compile_time_only
       ['] >r , ['] >r , ['] rswap ,
       here
   ; immediate
   
: loop
       compile_time_only
       ['] r> , ['] 1+ , ['] >r ,
       ['] r2dup , ['] r> , ['] r> ,
       ['] < , ['] invert , ['] branch0 ,
       here - cell - ,
       ['] r> , ['] r> , ['] drop , ['] drop ,
   ; immediate

: begin
       compile_time_only
       here ; immediate

: again
       compile_time_only
       ['] branch ,
       here - cell - , ; immediate

: until
       compile_time_only
       ['] branch0 ,
       here - cell - , ; immediate

: ( begin key ')' = until ; immediate
: \ begin key dup 'cr' = swap 'lf' = or until ; immediate

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

: s"
    compile_time_only
    ['] litstring ,
    here                    \ length will be placed here 
    0 ,                     \ put a dummy length 
    0                       \ length counter 
    key dup '"' <> if
        begin
            swap 1+ swap    \ increase length 
            c,              \ store character as byte 
        key dup '"' = until
    then
    drop
    swap !  \ overwrite dummy length with the calculated one
 ; immediate

: abs ( n -- |n| ) dup 0< if -1 * then ;
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
    
: .s depth 0 do . cr loop ;

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

