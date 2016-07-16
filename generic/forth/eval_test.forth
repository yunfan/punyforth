: test:eval-whitespace
    32 whitespace? assert
    10 whitespace? assert
    13 whitespace? assert
    9 whitespace? assert
    65 whitespace? invert assert ;

: test:eval-left-trim
    str: "" left-trim str: "" =str assert
    str: "abc" left-trim str: "abc" =str assert
    str: "abc  " left-trim str: "abc  " =str assert
    str: "   \t \r   \nabc\t\r" left-trim str: "abc\t\r" =str assert ;

: test:eval-find-word
    str: "abc" word-find 3 =assert str: "abc" =str assert
    str: "  abc" word-find 3 =assert str: "abc" =str assert
    str: "abc " word-find 3 =assert str: "abc " =str assert
    str: "\r\t\n abc\t " word-find 3 =assert str: "abc\t " =str assert ;

: test:eval-empty
    str: "" eval-new
    dup eval-next
    eval-done? assert ;
    
: test:eval-whitespace
    str: "\t  \r  \n" eval-new
    dup eval-next
    eval-done? assert ;

: test:eval-simple
    str: "1" eval-new
    dup eval-next 1= assert
    eval-done? assert ;

: test:eval-with-whitepace
    str: "\n    \t1 \r\n\t " eval-new
    dup eval-next 1= assert
    dup eval-next
    eval-done? assert ;

: test:eval-expression
    str: " 1   2  +  " eval-new >r
    rdup r> eval-next
    rdup r> eval-next
    rdup r> eval-next 3 = assert
    rdup r> eval-next
    r> eval-done? assert ;

: IGNORE-test:eval-with-comment \ TODO comments are not working in eval
    str: "( one ) 1 ( two ) 2 + \\ abort " eval-new >r
    rdup r> eval-next
    rdup r> eval-next
    rdup r> eval-next 3 = assert
    rdup r> eval-next
    r> eval-done? assert ;

str: ": double-by-eval dup + ;" eval-new: evaluator

: eval-all ( -- i*x )
    begin
        evaluator eval-done? invert
    while
        cr print: 'evaling next token ' evaluator .start @ type cr
        evaluator eval-next
    repeat
    println: 'eval done' ;

: IGNORE-test:eval-def
    eval-all
    \ 3 
    \ str: "double-by-eval" dup strlen find link>xt execute
    \ 6 =assert
    ;
