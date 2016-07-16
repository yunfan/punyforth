: whitespace? ( char -- bool )
    case
        32 of TRUE exit endof
        13 of TRUE exit endof
        10 of TRUE exit endof
         9 of TRUE exit endof
        drop FALSE     
    endcase ;

: left-trim ( str -- str )
    begin
        dup c@ dup
        ['] 0<> ['] whitespace? bi* and
    while
        1+
    repeat ;

: word-find ( str -- a len )
    left-trim 0 swap
    begin
        dup c@
        ['] 0<> ['] whitespace? bi invert and
    while
        ['] 1+ bi@
    repeat
    over -
    swap ;

struct
    cell field: .start
    cell field: .end
constant: Eval

: eval-new ( str -- evaluator )
    dup
    dup strlen +
    here 
    Eval allot
    tuck .end !
    tuck .start ! ;

: eval-new: ( str "name" ) ( -- evaluator )
    create: eval-new drop
    does> ;

: eval-done? ( evaluator -- bool )
    ['] .start ['] .end bi
    ['] @ bi@ >= ;

: eval-done! ( evaluator -- )
    dup .start @
    swap .end ! ;

: eval-next ( evaluator -- i*x )
    dup eval-done? if drop exit then
    dup >r
    .start @ word-find dup 0= if
        r> eval-done!
        2drop exit
    then
    2dup + r> .start !
    token-eval ;
