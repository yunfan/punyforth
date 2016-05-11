\ work in progress
\ TODO check line boundary

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

: line-received ( str -- )
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
        println: 'response sent for GET request'
    then ;
    
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
        connections mailbox-receive client !
        print: "Client connected: " client @ . cr
        client @ 128 line ['] netcon-readln catch 
        dup 0<> if            
            print: "error while reading client: " . cr
        else
            drop
            print: 'line received: ' line type print: ' length=' . cr
            line line-received  \ TODO catch errors here
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
