: test:core-whitespace
   32 whitespace? assert
   10 whitespace? assert
   13 whitespace? assert
    9 whitespace? assert
   65 whitespace? invert assert ;

: test:core-left-trim
   str: "" left-trim str: "" =str assert
   str: "abc" left-trim str: "abc" =str assert
   str: "abc  " left-trim str: "abc  " =str assert
   str: "   \t \r   \nabc\t\r" left-trim str: "abc\t\r" =str assert ;

: test:core-find-word
   str: "abc" word-find 3 =assert str: "abc" =str assert
   str: "  abc" word-find 3 =assert str: "abc" =str assert
   str: "abc " word-find 3 =assert str: "abc " =str assert
   str: "\r\t\n abc\t " word-find 3 =assert str: "abc\t " =str assert ;

: test:core-str-eval
   str: "1" str-eval 1 =assert
\   str: " \r\t 1\r  " str-eval 1 =assert
\   str: " 1   2  +  " str-eval 3 =assert
;

