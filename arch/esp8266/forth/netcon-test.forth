4567 constant: ECHO_PORT
wifi-ip constant: ECHO_HOST

struct
    cell field: .client
    128  field: .line
constant: WorkerSpace

: client ( -- a ) user-space .client ;
: line ( -- a ) user-space .line ;

4 mailbox-new: connections
0 task: echo-server-task
WorkerSpace task: echo-worker-task1
WorkerSpace task: echo-worker-task2

: echo-server ( task -- )
    activate
    ECHO_PORT ECHO_HOST netcon-tcp-server
    begin
        print: "Waiting for clients on host " ECHO_HOST type print: " on port " ECHO_PORT . cr
        dup netcon-accept
        connections mailbox-send
    again 
    deactivate ;

: echo-worker ( task -- )
    activate
    begin
        connections mailbox-receive client !
        {
            client @ 128 line netcon-readln
            print: 'echoing back: ' line type print: ' len=' . cr
            client @ line netcon-writeln    
        } catch dup 0<> if
            print: 'error while echoing client: ' client @ .
            print: ' exception: ' . cr
        else
            drop
        then
        client @ netcon-dispose
    again
    deactivate ;

: start-echo-server ( -- )
    multi
    echo-server-task echo-server
    echo-worker-task1 echo-worker
    echo-worker-task2 echo-worker ;

str: "Hahooo" constant: request
128 buffer: response

: test:netcon-echo \ TODO netcon-connect is blocking -> cant connect to itself
    start-echo-server
    ECHO_PORT ECHO_HOST netcon-connect
    dup request netcon-writeln
    dup 128 response netcon-readln
    request strlen =assert
    netcon-dispose
    request response =str assert ;
