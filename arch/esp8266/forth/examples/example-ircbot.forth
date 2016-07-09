marker: -ircbot

: connect ( -- netconn )
    6667 str: "irc.freenode.net" netcon-connect ;
    
: register ( netconn -- )
    dup str: "NICK hodor189"                        netcon-writeln
        str: "USER hodor189 hodor189 bla :hodor189" netcon-writeln ;
    
: join ( netconn -- ) 
    str: "JOIN #somechan" netcon-writeln ;

: greet ( netconn -- )
    str: "PRIVMSG #somechan :Hodor? ..hoodor!" netcon-writeln ;

: quit ( netconn -- )
    str: "QUIT :hodor" netcon-writeln ;
    
2 constant: LED
connect constant: SOCKET
SOCKET register
SOCKET join

: counted>asciiz ( buffer length -- a )
    over swap +
    0 swap c! ;

: data-received ( buffer length -- )
    counted>asciiz
    dup type
    dup str: "PING" str-starts-with if
        SOCKET str: "PONG" netcon-writeln
        random 200 % 0= if
            SOCKET greet
        then
    then
    str: "PRIVMSG" str-includes if
        LED blink
    then ;

0 task: ircbot-task

: start-irc-task ( -- )
    multi
    ircbot-task activate
    SOCKET ['] data-received netcon-consume
    print: "response code: " . cr
    deactivate ;

start-irc-task
