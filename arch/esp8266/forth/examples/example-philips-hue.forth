marker: -hue

\ HUE Bridge local IP and port
str: "192.168.0.12" constant: BRIDGE_IP 
80 constant: BRIDGE_PORT
\ Base URL containing the HUE API key
str: "/api/<YOUR_HUE_API_KEY>/lights/" constant: BASE_URL
\ Light bulb ids for each room
str: "1" constant: HALL
str: "2" constant: BEDROOM

1024 constant: buffer-len
buffer-len byte-array: buffer-at
0 buffer-at constant: buffer

: buffer>asciiz ( size -- )
    0 swap buffer-at c! ;

: read-into-buffer ( netconn -- )
    buffer-len buffer netcon-read buffer>asciiz ;

: parse-http-code ( buffer -- code | throws:ECONVERSION )    
    9 + 3 >number invert if
        ECONVERSION throw
    then ;
    
2048 constant: EHTTP
    
: read-http-code ( netconn -- http-code | throws:EHTTP )
    buffer-len buffer netcon-readln
    0 <= if EHTTP throw then           
    buffer str: "HTTP/" str-starts-with if
        buffer parse-http-code        
    else
        EHTTP throw
    then ;
   
: skip-http-headers ( netconn -- netconn )   
    begin
        dup buffer-len buffer netcon-readln -1 <>
    while
        print: 'skipping header: ' buffer type cr
        buffer strlen 0= if
            println: 'end of header detected'
            exit
        then
    repeat ;
   
: read-http-resp ( netconn -- response-code )    
    dup read-http-code
    swap skip-http-headers    
    buffer-len buffer netcon-readln      
    print: 'body len=' . cr ; \ TODO why -1?
    
: log-http-resp ( response-code -- response-code )
    dup print: 'HTTP:' . space buffer type cr ;
        
: consume&dispose ( netcon -- )      
    dup read-http-resp log-http-resp
    swap netcon-dispose
    200 <> if EHTTP throw then ;
        
: bridge ( -- netconn )
    BRIDGE_PORT BRIDGE_IP netcon-connect ;

: on? ( bulb -- bool )
    bridge
        dup str: "GET " netcon-write
        dup BASE_URL    netcon-write
        dup rot         netcon-writeln
        dup \r\n        netcon-write
        consume&dispose
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
        netcon-dispose ;
        
: off ( bulb -- )
    bridge
        tuck request-change-state
        dup str: "Content-length: " netcon-write
        dup str: "12"               netcon-writeln
        dup \r\n                    netcon-write
        dup str: '{"on":false}'     netcon-writeln
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
