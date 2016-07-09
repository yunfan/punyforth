marker: -hue

\ HUE Bridge local IP and port
str: "192.168.0.12" constant: BRIDGE_IP 
80 constant: BRIDGE_PORT
\ Base URL containing the HUE API key
str: "/api/<YOUR_HUE_API_KEY>/lights/" constant: BASE_URL
\ Light bulb ids for each room
str: "1" constant: HALL
str: "2" constant: BEDROOM

1024 byte-array: buffer-at
0 buffer-at constant: buffer

: buffer>asciiz ( size -- )
    0 swap buffer-at c! ;

: read-into-buffer ( netconn -- )
    1023 buffer read-into buffer>asciiz ;

: bridge ( -- netconn )
    BRIDGE_PORT BRIDGE_IP netcon-connect ;

: on? ( bulb -- bool )
    bridge
        dup str: "GET " netcon-write
        dup BASE_URL    netcon-write
        dup rot         netcon-writeln
        dup \r\n        netcon-write
        dup read-into-buffer
        netcon-dispose
    buffer str: '"on":true' str-includes ;
    
: request-change-state ( bulb netconn -- )
    dup str: "PUT "              netcon-write
    dup BASE_URL                 netcon-write
    dup rot                      netcon-write
    dup str: "/state "           netcon-write
    dup str: "HTTP/1.1"          netcon-writeln
    dup str: "Content-Type: "    netcon-write
    dup str: "application/json"  netcon-writeln
    dup str: "Accept: */*"       netcon-writeln
    dup str: "Connection: Close" netcon-writeln
    drop ;

: on ( bulb -- ) 
    bridge
        tuck request-change-state
        dup str: "Content-length: "       netcon-write
        dup str: "22"                     netcon-writeln
        dup \r\n                          netcon-write
        dup str: '{"on":true,"bri": 255}' netcon-writeln
        dup ['] type-counted              netcon-consume
        print: "response code: " . cr
        netcon-dispose ;
        
: off ( bulb -- )
    bridge
        tuck request-change-state
        dup str: "Content-length: " netcon-write
        dup str: "12"               netcon-writeln
        dup \r\n                    netcon-write
        dup str: '{"on":false}'     netcon-writeln
        dup ['] type-counted        read
        print: "response code: " . cr
        netcon-dispose ;
        
: toggle-unsafe ( bulb -- | throws:ENETCON )
    dup on? if off else on then ;
    
: toggle ( bulb -- )
    ['] toggle-unsafe catch 
    case
        0 of exit endof
        ENETCON of println: "netconn error" endof
        throw
    endcase ;
