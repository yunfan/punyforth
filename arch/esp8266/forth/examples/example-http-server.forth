multi

6 byte-array: buffer-at
0 buffer-at constant: buffer

: buffer>asciiz ( size -- )
    0 swap buffer-at c! ;

: receive-into-buffer ( netconn -- )
    5 buffer receive-into buffer>asciiz ;
    
tcp-new constant: SERVER
8080 str: "192.168.0.15"
SERVER bind
SERVER listen 

4 mailbox: SOCKET_MAILBOX

: start-server ( task -- )       
    activate
    begin
        println: "Accepting socket.."
        SERVER accept
        SOCKET_MAILBOX mailbox-send
    again 
    deactivate ;

: start-connection-handler ( task -- )
    activate
    begin
        println: "Waiting for client"
        SOCKET_MAILBOX mailbox-receive
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
    
task: server-task
task: client-task

server-task start-server
client-task start-connection-handler



