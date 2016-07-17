marker: -tcprepl

str: "192.168.0.15" constant: HOST
1983 constant: PORT
    
0 init-variable: client
128 byte-array: buf
0 buf constant: line 
    
1 mailbox-new: connections
0 task: repl-server-task
0 task: repl-worker-task

: type-interceptor ( str -- )
    client @ 0<> if
        client @ swap netcon-write
    else
        _type
    then ;
    
2 byte-array: emit-buffer 
0 1 emit-buffer c!
: emit-interceptor ( char -- )
    client @ 0<> if
        0 emit-buffer c!
        client @ 0 emit-buffer netcon-write
    else
        _emit
    then ;
    
: eval ( str -- i*x )
    0 #tib !
    tib >in ! 
    dup strlen 0 do 
        dup i + c@ chr>in
    loop
    13 chr>in 10 chr>in
    drop
    push-enter ;

: server ( task -- )       
    activate
    PORT HOST netcon-tcp-server
    begin
        print: 'PunyREPL server started on port ' PORT . 
        print: ' on host ' HOST type cr
        dup netcon-accept
        connections mailbox-send
    again 
    deactivate ;

: command-loop ( -- )   
    client @ str: "PunyREPL ready. Type quit to exit.\r\n" netcon-write
    push-enter
    begin        
        client @ 128 line netcon-readln -1 <>
        line str: "quit" =str invert and
    while
        line strlen 0<> if
            line eval
        then
    repeat ;
        
: worker ( task -- )
    activate
    begin
        connections mailbox-receive client !
        print: "Client connected: " client @ . cr
        ['] command-loop catch dup 0<> if
            print: 'error while handling client: ' client @ .
            print: ' exception: ' . cr
        else
            drop
        then
        client @ netcon-dispose
        0 client !
    again
    deactivate ;

: start-repl ( -- )
    println: 'Starting PunyREPL server..'
    multi    
    ['] type-interceptor xtype !
    ['] emit-interceptor xemit !
    repl-server-task server
    repl-worker-task worker ;
