\ work in progress
\ TODO check line boundary

str: "192.168.0.15" constant: HOST
8080 constant: PORT
    
struct
    cell field: .client
    \ 128  field: .line
    \ cell field: .position
constant: WorkerSpace

128 stream-new: line

: client ( -- a ) user-space .client ;

4 mailbox-new: connections
0 task: server-task

WorkerSpace task: worker-task1
WorkerSpace task: worker-task2

: server ( task -- )       
    activate
    PORT HOST netcon-tcp-server
    begin
        println: "Waiting for incoming connection"
        dup netcon-accept
        connections mailbox-send
    again 
    deactivate ;

: line-received ( str -- )
    print: "line received: " dup type cr
    str: "GET /" str-starts-with if
        client @
        dup str: "HTTP/1.0 200" netcon-writeln
        dup str: "Content-Type: text/html" netcon-writeln
        dup str: "Connection: close" netcon-writeln
        dup \r\n netcon-write
        dup str: "<html><body>" netcon-writeln
        dup str: "<h1>ESP8266 web server is working!</h1>" netcon-writeln
        dup str: "</body></html>" netcon-writeln
        drop
        123 throw
    then 
    println: "response sent" ;
    
: data-received ( buffer size -- )
    0 do
        dup i + c@
        dup 10 = if
            drop            
            0 line stream-put-byte
            line stream-buffer line-received
            line stream-reset
        else
            line stream-put-byte
        then                
    loop
    drop ;
    
: worker ( task -- )
    activate
    begin
        line stream-reset
        connections mailbox-receive client !
        print: "Client connected: " client @ . cr
        client @ ['] data-received ['] read-all catch dup ENETCON = if
            println: "Client lost: " . cr
        else
            println: "Connection closed: " . cr
        then
        client @ netcon-dispose
    again
    deactivate ;

: start-server ( -- )
    multi
    server-task server
    \ worker-task1 worker TODO
    worker-task2 worker ;
    
512 var-task-stack-size !
256 var-task-rstack-size !
    
start-server
