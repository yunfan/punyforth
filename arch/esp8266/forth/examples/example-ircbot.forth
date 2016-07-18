marker: -ircbot

2 constant: LED    
512 constant: buffer-size
buffer-size buffer: line-buffer

IRC_ECLOSED constant: 6000

: connect ( -- netconn )
    6667 str: "irc.freenode.net" netcon-connect ;
    
: register ( netconn -- )
    dup str: "NICK hodor169"                        netcon-writeln
        str: "USER hodor169 hodor169 bla :hodor169" netcon-writeln ;
    
: join ( netconn -- ) 
    str: "JOIN #somechan" netcon-writeln ;

: greet ( netconn -- )
    str: "PRIVMSG #somechan :Hodor? ..hoodor!" netcon-writeln ;

: quit ( netconn -- )
    str: "QUIT :hodor" netcon-writeln ;
    
: readln ( netconn -- str )
    buffer-size line-buffer netcon-readln -1 = if
        IRC_ECLOSED throw
    then    
    line-buffer ;
        
: processline ( netcon str -- )
    dup type
    dup str: "PING" str-starts-with if
        over str: "PONG" netcon-writeln
        random 200 % 0= if
            over greet
        then
    then
    dup str: "PRIVMSG" str-includes if
        LED blink
    then 
    2drop ;

0 task: ircbot-task

: run ( -- )    
    connect
    dup register
    dup join
    begin
        dup readln 
        over swap processline        
    again ;

: bot-start ( -- )
    multi
    ircbot-task activate
    begin
        println: "Starting IRC bot"
        ['] run catch dup 0<> if            
            print: 'Exception in irc bot: ' . cr
        else
            drop
        then
        5000 delay
    again
    deactivate ;
