marker -hue

\ HUE Bridge local IP and port
str "192.168.0.12" constant BRIDGE_IP 
80 constant BRIDGE_PORT
\ Base URL containing the HUE API key
str "/api/<YOUR_HUE_API_KEY>/lights/" constant BASE_URL
\ Light bulb ids for each room
str "1" constant HALL
str "2" constant BEDROOM

1024 byte-array buffer-at
0 buffer-at constant buffer

: buffer>asciiz ( size -- )
    0 swap buffer-at c! ;

: receive-into-buffer ( netconn -- )
    1023 buffer receive-into buffer>asciiz ;

: bridge ( -- netconn )
    BRIDGE_PORT BRIDGE_IP tcp-open ;

: on? ( bulb -- bool )
    bridge
        dup str "GET " write
        dup BASE_URL   write
        dup rot        writeln
        dup \r\n       write
        dup receive-into-buffer
        dispose
    buffer str '"on":true' str-includes ;
    
: request-change-state ( bulb netconn -- )
    dup str "PUT "              write
    dup BASE_URL                write
    dup rot                     write
    dup str "/state "           write
    dup str "HTTP/1.1"          writeln
    dup str "Content-Type: "    write
    dup str "application/json"  writeln
    dup str "Accept: */*"       writeln
    dup str "Connection: Close" writeln
    drop ;

: on ( bulb -- ) 
    bridge
        tuck request-change-state
        dup str "Content-length: "       write
        dup str "22"                     writeln
        dup \r\n                         write
        dup str '{"on":true,"bri": 255}' writeln
        dup ['] type-counted             receive
        print "response code: " . cr
        dispose ;
        
: off ( bulb -- )
    bridge
        tuck request-change-state
        dup str "Content-length: " write
        dup str "12"               writeln
        dup \r\n                   write
        dup str '{"on":false}'     writeln
        dup ['] type-counted       receive
        print "response code: " . cr
        dispose ;
        
: toggle-unsafe ( bulb -- | throws:ENETCON )
    dup on? if off else on then ;
    
: toggle ( bulb -- )
    ['] toggle-unsafe catch 
    case
        0 of exit endof
        ENETCON of println "netconn error" endof
        throw
    endcase ;