\ work in progress

str: "192.168.0.15" constant: HOST
8080 constant: PORT
    
struct
    cell field: .client
    128  field: .line
constant: WorkerSpace

: client ( -- a ) user-space .client ;
: line ( -- a ) user-space .line ;

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

: send-response ( request-str -- )
    str: "GET /" str-starts-with if
        client @
        dup str: "HTTP/1.0 200\r\n" netcon-write
        dup str: "Content-Type: text/html\r\n" netcon-write
        dup str: "Connection: close\r\n\r\n" netcon-write
        dup str: "<html><body>" netcon-writeln
        dup str: "<h1>ESP8266 web server is working!</h1>" netcon-writeln
        dup str: "</body></html>" netcon-writeln
        drop
        println: 'response sent for GET request'
    then ;
    
: handle-client ( -- )    
    client @ 128 line netcon-readln    
    print: 'line received: ' line type print: ' length=' . cr
    line send-response ;
        
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
    worker-task1 worker
    worker-task2 worker ;

start-server
