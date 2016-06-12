marker -ircbot

: connect ( -- netconn )
    6667 s" irc.freenode.net" tcp-open ;
    
: register ( netconn -- )
    dup s" NICK hodor189"                        writeln
        s" USER hodor189 hodor189 bla :hodor189" writeln ;
    
: join ( netconn -- ) 
    s" JOIN #somechan" writeln ;

: greet ( netconn -- )
    s" PRIVMSG #somechan :Hodor? ..hoodor!" writeln ;

: quit ( netconn -- )
    s" QUIT :hodor" writeln ;
    
2 constant LED
connect constant SOCKET
SOCKET register
SOCKET join

: counted>asciiz ( buffer length -- a )
    over swap +
    0 swap c! ;

: data-received ( buffer length -- )
    counted>asciiz
    dup type
    dup s" PING " str-starts-with if
        SOCKET s" PONG" writeln
        random 200 % 0= if
            SOCKET greet
        then
    then
    s' PRIVMSG' str-includes if
        LED blink
    then ;

task: ircbot-task

: start-irc-task ( -- )
    multi
    ircbot-task activate
    SOCKET ['] data-received receive
    deactivate ;

start-irc-task