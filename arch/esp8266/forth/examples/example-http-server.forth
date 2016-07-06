multi

6 byte-array: buffer-at
0 buffer-at constant: buffer

: buffer>asciiz ( size -- )
    0 swap buffer-at c! ;

: receive-into-buffer ( netconn -- )
    5 buffer receive-into buffer>asciiz ;
    
: tcp-server-new ( port host -- netconn | throws:ENETCON )
    tcp-new
    ['] bind sip
    dup listen ;    
    
8080 str: "192.168.0.15" tcp-server-new constant: server-socket

4 mailbox: client-sockets
task: server-task
task: worker-task1
task: worker-task2

: server ( task -- )       
    activate
    begin
        println: "Accepting socket.."
        server-socket accept
        client-sockets mailbox-send
    again 
    deactivate ;

: worker ( task -- )
    activate
    begin
        println: "Waiting for client"
        client-sockets mailbox-receive
        println: "Client connected"
        dup receive-into-buffer
        buffer type
        buffer str: "GET /" str-starts-with if
            dup str: "HTTP/1.0 200" writeln
            dup str: "Content-Type: text/html" writeln
            dup \r\n write
            dup str: "<h1>Hello World from ESP8266</h1>" writeln
        then    
        dispose
    again
    deactivate ;
    
server-task server
worker-task1 worker
worker-task2 worker



