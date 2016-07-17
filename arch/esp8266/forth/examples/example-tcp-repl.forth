str: "192.168.0.15" constant: HOST
1983 constant: PORT
    
variable: client
128 byte-array: buf
0 buf constant: line 
    
1 mailbox-new: connections
0 task: server-task
0 task: worker-task

: eval ( str -- i*x ) \ experimental, non thread safe
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
        println: "Waiting for incoming connection"
        dup netcon-accept
        connections mailbox-send
    again 
    deactivate ;

: handle-client ( -- )        
    begin
        client @ str: " % " netcon-write
        client @ 128 line netcon-readln -1 <>
        line str: "quit" =str invert and
    while
        print: 'evaluate: ' line type cr
        line eval
    repeat ;
        
: worker ( task -- )
    activate
    begin
        connections mailbox-receive client !
        print: "Client connected: " client @ . cr
        ['] handle-client catch dup 0<> if
            print: 'error while handling client: ' client @ .
            print: ' exception: ' . cr
        else
            drop
        then
        client @ netcon-dispose
    again
    deactivate ;

: start-server ( -- )
    multi
    server-task server
    worker-task worker ;

start-server
