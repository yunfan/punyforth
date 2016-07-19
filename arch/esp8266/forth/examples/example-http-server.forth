\ server listens on this port
80 constant: PORT

\ task local variables    
struct
    cell field: .client
    128  field: .line
constant: WorkerSpace

\ access to task local variables from worker tasks
: client ( -- a ) user-space .client ;
: line ( -- a ) user-space .line ;

\ a mailbox used for communication between server and worker tasks
4 mailbox-new: connections
0 task: server-task

\ worker task allocations
WorkerSpace task: worker-task1
WorkerSpace task: worker-task2

: server ( task -- )
    activate
    PORT wifi-ip netcon-tcp-server
    begin
        println: "Waiting for incoming connection"
        dup netcon-accept
        connections mailbox-send      \ send the client connection to one of the worker tasks
    again 
    deactivate ;
    
\ index page as a mult line string
str: "
HTTP/1.0 200\r\n
Content-Type: text/html\r\n
Connection: close\r\n
\r\n
<html>
    <body>
        <h1>ESP8266 web server is working!</h1>
    </body>
</html>" constant: HTML
    
: send-response ( request-str -- )
    str: "GET /" str-starts-with if
        client @ HTML netcon-write
        println: 'response sent for GET request'
    then ;
    
: handle-client ( -- )    
    client @ 128 line netcon-readln    
    print: 'line received: ' line type print: ' length=' . cr
    line send-response ;
        
: worker ( task -- )
    activate
    begin
        connections mailbox-receive client !       \ receive client connection from the server task
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
    multi                      \ switch to multi task mode then start the server + worker taks
    server-task server
    worker-task1 worker
    worker-task2 worker ;

start-server
