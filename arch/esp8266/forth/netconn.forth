marker -netconn

1 constant UDP
2 constant TCP
8000 constant ENETCON 
100 constant RECV_TIMEOUT_MSEC 

\ netconn errors. see: src/include/lwip/err.h
-1 constant ERR_MEM          \ Out of memory error.
-2 constant ERR_BUF          \ Buffer error.
-3 constant ERR_TIMEOUT      \ Timeout.
-4 constant ERR_RTE          \ Routing problem.
-5 constant ERR_INPROGRESS   \ Operation in progress
-6 constant ERR_VAL          \ Illegal value.
-7 constant ERR_WOULDBLOCK   \ Operation would block.
-8 constant ERR_USE          \ Address in use.
-9 constant ERR_ISCONN       \ Already connected.
-10 constant ERR_ABRT        \ Connection aborted.
-11 constant ERR_RST         \ Connection reset.
-12 constant ERR_CLSD        \ Connection closed.
-13 constant ERR_CONN        \ Not connected.
-14 constant ERR_ARG         \ Illegal argument.
-15 constant ERR_IF          \ Low-level netif error.

: check-new-netconn ( netconn -- netconn | throws:ENETCON )
    dup 0= if ENETCON throw then ;
    
: tcp-new ( port host -- netconn )
    TCP netconn-new
    RECV_TIMEOUT_MSEC over netconn-set-recvtimeout
    check-new-netconn ;
    
: udp-new ( port host -- netconn )
    UDP netconn-new
    RECV_TIMEOUT_MSEC over netconn-set-recvtimeout
    check-new-netconn ;

: check-netconn-error ( errcode --  | throws:ENETCON )
    dup 0<> if
        print "NETCON error: " . cr
        ENETCON throw 
    then 
    drop ;

: tcp-open ( port host -- netconn | throws:ENETCON )
    tcp-new dup 
    >r
    netconn-connect
    check-netconn-error
    r> ;
    
: write ( netconn str -- | throws:ENETCON )
    dup strlen swap rot 
    netconn-write
    check-netconn-error ;

: writeln ( netconn str -- | throws:ENETCON )
    over 
    swap write 
    \r\n write ;

: receive-into-responsively ( size buffer netconn -- count code )
    begin
        pause
        3dup netconn-recvinto
        dup ERR_TIMEOUT <> if            
            rot drop rot drop rot drop
            exit
        then
        2drop
    again ;

: receive-into ( netconn size buffer -- count | throws:ENETCON )
    rot 
    receive-into-responsively
    check-netconn-error ;
    
: consume-next ( consumer-xt netbuf -- n )
    tuck netbuf-data
    rot execute                         \ execute consumer with stack effect ( buffer size -- ) 
    netbuf-next ;

: consume-netbuf ( consumer-xt netbuf -- netbuf )
    begin   
        2dup consume-next
    0 < until 
    nip ;

: receive-responsively ( netconn -- netbuf code )
    begin
        pause
        dup netconn-recv
        dup ERR_TIMEOUT <> if
            rot drop
            exit
        then
        2drop
    again ;

: receive ( netconn consumer-xt -- )
    begin
        2dup swap
        receive-responsively 0<> if
            4drop exit
        then
        consume-netbuf
        netbuf-del
    again ;    
              
: dispose ( netconn -- )
    netconn-dispose ;