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

: str-eval ( str -- i*x )
    word-find token-eval ;


