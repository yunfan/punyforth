\ work in progress

str: "192.168.0.15" constant: HOST
8080 constant: PORT
    
4 mailbox: connections
task: server-task
task: worker-task1
task: worker-task2

\ XXX this is global per worker
128 byte-array: line
0 init-variable: position

\ TODO get rid of me
variable: current-client

: server ( task -- )       
    activate
    PORT HOST tcp-server-new
    begin
        println: "Waiting for incoming connection"
        dup accept connections mailbox-send
    again 
    deactivate ;

: on-line ( str -- )
    dup str: "GET /" str-starts-with if
        current-client @
        dup str: "HTTP/1.0 200" writeln
        dup str: "Content-Type: text/html" writeln
        dup \r\n write
        dup str: "<html><body>" writeln
        dup str: "<h1>ESP8266 web server is working!</h1>" writeln
        dup str: "</body></html>" writeln
        drop
        \ dispose
    then 
    print: "line received: " type cr ;
    
: on-data ( buffer size -- )
    0 do
        dup i + c@
        dup 10 = if
            drop            
            0 position @ line c! \ terminate with zero
            0 line on-line
            0 position !
        else        
            position @ line c!
            1 position +!
        then                
    loop
    drop ;
    
: worker ( task -- )
    activate
    begin
        connections mailbox-receive
        dup current-client !
        print: "Client connected: " dup . cr
        dup ['] on-data ['] read-all catch ENETCON = if
            println: "Client lost: " . cr
        else
            println: "Connection closed: " . cr
        then
    again
    deactivate ;

: start-server ( -- )
    multi
    server-task server
    \ worker-task1 worker
    worker-task2 worker ;
    
512 var-task-stack-size !
256 var-task-rstack-size !
    
start-server
