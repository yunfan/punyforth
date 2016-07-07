\ work in progress
\ TODO check line boundary

str: "192.168.0.15" constant: HOST
8080 constant: PORT
    
struct
    cell field: .client
    128  field: .line
    cell field: .position
constant: WorkerSpace

: client ( -- a ) user-space .client ;
: line ( -- a ) user-space .line ;
: position ( -- n ) user-space .position ;

4 mailbox: connections
0 task: server-task

WorkerSpace task: worker-task1
WorkerSpace task: worker-task2

: server ( task -- )       
    activate
    PORT HOST tcp-server-new
    begin
        println: "Waiting for incoming connection"
        dup accept
        connections send
    again 
    deactivate ;

: line-received ( str -- )
    print: "line received: " dup type cr
    str: "GET /" str-starts-with if
        client @
        dup str: "HTTP/1.0 200" writeln
        dup str: "Content-Type: text/html" writeln
        dup str: "Connection: close" writeln
        dup \r\n write
        dup str: "<html><body>" writeln
        dup str: "<h1>ESP8266 web server is working!</h1>" writeln
        dup str: "</body></html>" writeln
        drop
    then 
    println: "response sent" ;
    
: data-received ( buffer size -- )
    0 do
        dup i + c@
        dup 10 = if
            drop            
            0 line position @ + c! \ terminate with zero
            line line-received
            0 position !
        else        
            position @ line + c!
            1 position +!
        then                
    loop
    drop ;
    
: worker ( task -- )
    activate
    begin
        0 position !
        connections receive client !
        print: "Client connected: " client @ . cr
        client @ ['] data-received ['] read-all catch ENETCON = if
            println: "Client lost: " . cr
        else
            println: "Connection closed: " . cr
        then
        client @ dispose
    again
    deactivate ;

: start-server ( -- )
    multi
    server-task server
    worker-task1 worker
    worker-task2 worker ;
    
512 var-task-stack-size !
256 var-task-rstack-size !
    
start-server
