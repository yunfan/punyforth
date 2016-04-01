1 constant UDP
2 constant TCP
8000 constant ENETCON 
 
: check-new-netconn ( netconn -- netconn | throws:ENETCON )
    dup 0 = if ENETCON throw then ;
    
: tcp-new ( port host -- netconn )
    TCP netconn-new
    check-new-netconn ;
    
: udp-new ( port host -- netconn )
    UDP netconn-new
    check-new-netconn ;

: check-netconn-error ( errcode --  | throws:ENETCON )
    dup 0 <> if
        ." NETCON error: " .
        ENETCON throw 
    then 
    drop ;

: tcp-open ( port host -- netconn | throws:ENETCON )
    tcp-new
    dup >r
    netconn-connect
    check-netconn-error
    r> ;
    
: write ( netconn str -- netconn | throws:ENETCON )
    over >r
    dup strlen swap rot netconn-write
    check-netconn-error
    r> ;

: writeln ( netconn str -- netconn | throws:ENETCON )
    write \r\n write ;
                                
: receive-into ( netconn size buffer -- netconn count | throws:ENETCON )   
    rot dup >r  
    netconn-recvinto
    check-netconn-error
    r> swap ;
    
: consume-next ( consumer-xt netbuf -- n )
    tuck netbuf-data
    rot execute                         \ execute consumer with stack effect ( buffer size -- ) 
    netbuf-next ;

: consume-netbuf ( consumer-xt netbuf -- netbuf )
    begin   
        2dup consume-next
    0 < until 
    nip ;
        
: receive ( netconn consumer -- netconn )
    begin
        2dup swap
        netconn-recv 0 <> if
            2drop drop 
            exit
        then
        consume-netbuf
        netbuf-del
    again ;    
              
: dispose ( netconn -- )
    netconn-dispose ;    