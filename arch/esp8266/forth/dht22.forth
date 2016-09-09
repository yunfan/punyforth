2 constant: PIN \ D4
2 constant: DHT_TIMER_INTERVAL
40 byte-array: bits
5 byte-array: measurement

exception: ETIMEOUT
exception: ECHECKSUM

: pin-state-duration ( pin-state timeout -- duration TRUE | FALSE )
    0 do
        DHT_TIMER_INTERVAL us
        PIN gpio-read over = if
            drop i TRUE 
            unloop exit
        then
        DHT_TIMER_INTERVAL 
    +loop 
    drop FALSE ;

: pin-wait ( pin-state timeout -- | throws:ETIMEOUT )
    pin-state-duration if
        drop
    else
        ETIMEOUT throw
    then ;
    
: duration ( pin-state timeout -- duration | throws:ETIMEOUT )
    pin-state-duration invert if
        ETIMEOUT throw
    then ;
    
: dht-init ( -- )    
    PIN GPIO_LOW gpio-write
    20000 us
    PIN GPIO_HIGH gpio-write
    GPIO_LOW 40 pin-wait
    GPIO_HIGH 88 pin-wait
    GPIO_LOW 88 pin-wait ;
    
: dht-fetch ( -- )    
    40 0 do
        GPIO_HIGH 65 duration 
        GPIO_LOW 70 duration
        < i bits c!
    loop ;

: bit-at ( i -- bit )
    bits c@ if 1 else 0 then ;
    
: measurement-clear ( -- )
    5 0 do 
        0 i measurement c! 
    loop ;
    
: dht-process ( -- )    
    measurement-clear
    40 0 do        
        i 8 / measurement c@ 1 lshift
        i 8 / measurement c!
        
        i 8 / measurement c@ i bit-at or
        i 8 / measurement c!
    loop 
    0 measurement c@
    1 measurement c@ +
    2 measurement c@ +
    3 measurement c@ + 255 and
    4 measurement c@ <> if 
        ECHECKSUM throw 
    then ;
    
: dht-convert ( lsb msb -- data )
    { hex: 7F and 8 lshift or } keep
    dup 128 and 0= if
        drop
    else
        0 swap -
    then ;
    
: dht-measure ( -- celsius-times-10 humidity%-times-10 )
    PIN GPIO_OUT_OPEN_DRAIN gpio-mode
    os-enter-critical
    { 
        dht-init 
        dht-fetch
        dht-process        
        3 measurement c@ 2 measurement c@ dht-convert
        1 measurement c@ 0 measurement c@ dht-convert
    } catch ?dup 0<> if ex-type then    
    os-exit-critical ;
