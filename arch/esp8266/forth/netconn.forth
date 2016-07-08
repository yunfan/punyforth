marker: -netconn

1 constant: UDP
2 constant: TCP
8000 constant: ENETCON 
100 constant: RECV_TIMEOUT_MSEC 

\ netconn errors. see: esp-open-rtos/lwip/lwip/src/include/lwip/err.h
 -1 constant: NC_ERR_MEM         \ Out of memory error.
 -2 constant: NC_ERR_BUF         \ Buffer error.
 -3 constant: NC_ERR_TIMEOUT     \ Timeout.
 -4 constant: NC_ERR_RTE         \ Routing problem.
 -5 constant: NC_ERR_INPROGRESS  \ Operation in progress
 -6 constant: NC_ERR_VAL         \ Illegal value.
 -7 constant: NC_ERR_WOULDBLOCK  \ Operation would block.
 -8 constant: NC_ERR_USE         \ Address in use.
 -9 constant: NC_ERR_ISCONN      \ Already connected.
-10 constant: NC_ERR_ABRT        \ Connection aborted.
-11 constant: NC_ERR_RST         \ Connection reset.
-12 constant: NC_ERR_CLSD        \ Connection closed.
-13 constant: NC_ERR_CONN        \ Not connected.
-14 constant: NC_ERR_ARG         \ Illegal argument.
-15 constant: NC_ERR_IF          \ Low-level netif error.

: check-new-netconn ( netconn -- netconn | throws:ENETCON )
    dup 0= if ENETCON throw then ;
    
: tcp-new ( -- netconn )
    TCP netconn-new
    RECV_TIMEOUT_MSEC over netconn-set-recvtimeout
    check-new-netconn ;
    
: udp-new ( -- netconn )
    UDP netconn-new
    RECV_TIMEOUT_MSEC over netconn-set-recvtimeout
    check-new-netconn ;
    
: check-netconn-error ( errcode --  | throws:ENETCON )
    dup 0<> if
        print: "NETCON error: " . cr
        ENETCON throw 
    then 
    drop ;

: tcp-open ( port host -- netconn | throws:ENETCON )
    tcp-new dup 
    >r
    netconn-connect
    check-netconn-error
    r> ;
    
: bind ( port host netconn -- | throws:ENETCONN )
    netconn-bind
    check-netconn-error ;
    
: listen ( netconn -- | throws:ENETCON )
    netconn-listen
    check-netconn-error ;
    
: tcp-server-new ( port host -- netconn | throws:ENETCON )
    tcp-new
    ['] bind sip
    dup listen ;    
    
: accept ( netconn -- new-netconn | throws:ENETCONN)
    begin
        pause
        dup netconn-accept dup NC_ERR_TIMEOUT <> if
            check-netconn-error nip
            RECV_TIMEOUT_MSEC over netconn-set-recvtimeout
            exit
        then
        2drop
    again ;
    
: write ( netconn str -- | throws:ENETCON )
    dup strlen swap rot 
    netconn-write
    check-netconn-error ;

: writeln ( netconn str -- | throws:ENETCON )
    over 
    swap write 
    \r\n write ;

: read-into-responsively ( size buffer netconn -- count code )
    begin
        pause
        3dup netconn-recvinto
        dup NC_ERR_TIMEOUT <> if            
            rot drop rot drop rot drop
            exit
        then
        2drop
    again ;

: read-into ( netconn size buffer -- count | throws:ENETCON )
    rot 
    read-into-responsively
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

: read-responsively ( netconn -- netbuf code )
    begin
        pause
        dup netconn-recv
        dup NC_ERR_TIMEOUT <> if
            rot drop
            exit
        then
        2drop
    again ;

: read-all ( netconn consumer-xt -- code )
    begin
        2dup swap
        read-responsively 
        dup 0<> if
            >r 4drop r>
            exit
        then
        drop
        ['] consume-netbuf catch dup 0<> if
            \ swap netbuf-del
            nip
            throw
        then
        drop netbuf-del        
    again ;    
              
: dispose ( netconn -- )
    netconn-dispose ;
