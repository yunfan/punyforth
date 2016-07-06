multi

str: "192.168.0.15" constant: HOST
8080 constant: PORT

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
    
4 mailbox: connections
task: server-task
task: worker-task1
task: worker-task2

: server ( task -- )       
    activate
    PORT HOST tcp-server-new
    begin
        println: "Waiting for incoming connection"
        dup accept connections mailbox-send
    again 
    deactivate ;

: worker ( task -- )
    activate
    begin
        connections mailbox-receive
        print: "Client connected: " dup . cr
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



