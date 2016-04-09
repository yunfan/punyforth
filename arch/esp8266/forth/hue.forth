: type-counted-string ( buffer size -- )    
    dup 0= if 2drop then
    begin
        swap dup c@ emit 1+ swap
    1- dup 0= until
    2drop ;
    
1024 array buffer
variable buffer-size    
    
: http-request s" PUT /api/214ed0954241f46c3d2b05fe7a1019a8/lights/1/state HTTP/1.1" ;

: bridge-open ( -- netconn )
    80 s" 192.168.0.12" tcp-open ;
    
: is-on? ( -- )    
    bridge-open
        s" GET /api/214ed0954241f46c3d2b05fe7a1019a8/lights/1" writeln 
        \r\n write
        1023 0 buffer receive-into buffer-size !
        dispose      
    0 buffer-size @ buffer !
    0 buffer s' "on":true' str-includes ;    
    
: turn-light-on ( -- ) 
    bridge-open
        http-request               writeln
        s" Content-Type:"          write 
        s" application/json"       writeln
        s" Content-length: "       write
        s" 22"                     writeln
        \r\n                       write
        s' {"on":true,"bri": 255}' writeln
        \ ['] type-counted-string receive
        1023 0 buffer receive-into
        0 buffer swap type-counted-string
        dispose ;
        
: turn-light-off ( -- ) 
    bridge-open
        http-request              writeln
        s" Content-Type:"         write
        s" application/json"      writeln
        s" Content-length: "      write
        s" 21"                    writeln
        \r\n                      write        
        s' {"on":false,"bri": 0}' writeln
        dispose ;        
        
: toggle-light ( -- )
    is-on? if
        turn-light-off
    else
        turn-light-on
    then ;
        
: toogle ( -- )
    ['] toggle-light catch dup ENETCON = if
        drop ." netconn error"
    else
        throw
    then ;