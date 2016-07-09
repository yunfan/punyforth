marker: -netcon

1 constant: UDP
2 constant: TCP
8000 constant: ENETCON 
100 constant: RECV_TIMEOUT_MSEC 

\ netcon errors. see: esp-open-rtos/lwip/lwip/src/include/lwip/err.h
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

: check-new ( netcon -- netcon | throws:ENETCON )
    dup 0= if ENETCON throw then ;
    
: netcon-tcp ( -- netcon )
    TCP netcon-new
    RECV_TIMEOUT_MSEC over netcon-set-recvtimeout
    check-new ;
    
: netcon-udp ( -- netcon )
    UDP netcon-new
    RECV_TIMEOUT_MSEC over netcon-set-recvtimeout
    check-new ;
    
: check-error ( errcode --  | throws:ENETCON )
    dup 0<> if
        print: "NETCON error: " . cr
        ENETCON throw 
    then 
    drop ;

: netcon-connect ( port host -- netcon | throws:ENETCON )
    netcon-tcp dup 
    >r
    netcon-connect
    check-error
    r> ;
    
: netcon-bind ( port host netcon -- | throws:ENETCON ) override
    netcon-bind
    check-error ;
    
: netcon-listen ( netcon -- | throws:ENETCON ) override
    netcon-listen
    check-error ;
    
: netcon-tcp-server ( port host -- netcon | throws:ENETCON )
    netcon-tcp
    ['] netcon-bind sip
    dup netcon-listen ;    
    
: netcon-accept ( netcon -- new-netcon | throws:ENETCON) override
    begin
        pause
        dup netcon-accept dup NC_ERR_TIMEOUT <> if
            check-error nip
            RECV_TIMEOUT_MSEC over netcon-set-recvtimeout
            exit
        then
        2drop
    again ;
    
: netcon-write ( netcon str -- | throws:ENETCON ) override
    dup strlen swap rot 
    netcon-write
    check-error ;

: netcon-writeln ( netcon str -- | throws:ENETCON )
    over 
    swap netcon-write 
    \r\n netcon-write ;

: read-into-responsively ( size buffer netcon -- count code )
    begin
        pause
        3dup netcon-recvinto
        dup NC_ERR_TIMEOUT <> if            
            rot drop rot drop rot drop
            exit
        then
        2drop
    again ;

\    
: read-into ( netcon size buffer -- count | throws:ENETCON )
    rot 
    read-into-responsively
    check-error ;
    
: consume-next ( consumer-xt netbuf -- n )
    tuck netbuf-data
    rot execute                         \ execute consumer with stack effect ( buffer size -- ) 
    netbuf-next ;

: consume-netbuf ( consumer-xt netbuf -- netbuf )
    begin   
        2dup consume-next
    0 < until 
    nip ;

: read-responsively ( netcon -- netbuf code )
    begin
        pause
        dup netcon-recv
        dup NC_ERR_TIMEOUT <> if
            rot drop
            exit
        then
        2drop
    again ;

\    
: read-all ( netcon consumer-xt -- code )
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

: netcon-dispose ( netcon -- )
    dup
    netcon-close
    netcon-delete ;
