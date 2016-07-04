marker -punit

: assert ( bool -- | throws:EASSERT ) invert if EASSERT throw then ;
: =assert ( n1 n2 -- | throws:EASSERT )
    2dup <> if 
        swap print '(' . space . print ' <>)' space
        EASSERT throw 
    else
        2drop
    then ;

: test? ( link -- bool )
    ['] link>name
    ['] link>len bi 5 <= if
        FALSE     
    else        
        TRUE
        over 0 + c@ [ char t ] literal = and
        over 1 + c@ [ char e ] literal = and
        over 2 + c@ [ char s ] literal = and
        over 3 + c@ [ char t ] literal = and
        over 4 + c@ [ char : ] literal = and
    then        
    nip ;   

3 byte-array: test-report
: passed ( -- n ) 0 test-report ;
: failed ( -- n ) 1 test-report ;
: errors ( -- n ) 2 test-report ;

: test-run ( link -- )
    dup type-word        
    link>xt ['] execute catch
    case
        0 of 
            cr
            1 passed c+!
        endof 
        EASSERT of 
            println "FAIL" 
            1 failed c+!
        endof
        print "ERROR " . cr
        1 errors c+!
    endcase ;

: test-reset ( -- )
    0 passed c! 0 failed c! 0 errors c! ;

: test-report ( -- )
    passed c@ failed c@ errors c@ + + . print " tests, "
    passed c@ . print " passed, " 
    failed c@ . print " failed, "
    errors c@ . print " errors"
    cr
    errors c@ 0= failed c@ 0= and if
        println "All passed"
    else
        println "There were failures"
    then
    cr ;

: test ( -- )
    cr
    test-reset
    lastword
    begin
        dup 0<>
    while
        dup test? if
            dup test-run
        then
        @
    repeat
    drop
    test-report ;

: test: ( "testname" -- )
    cr test-reset
    word find dup 0<> if
        test-run
    else
        drop println "No such test"
    then ;
