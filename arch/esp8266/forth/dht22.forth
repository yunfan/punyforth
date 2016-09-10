2 constant: PIN \ D4
2 constant: DHT_TIMER_INTERVAL
40 byte-array: bits
5 byte-array: bytes

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
    
: bytes-clear ( -- )
    5 0 do 
        0 i bytes c! 
    loop ;
    
: dht-process ( -- )    
    bytes-clear
    40 0 do        
        i 3 rshift bytes c@ 1 lshift
        i 3 rshift bytes c!        
        i 3 rshift bytes c@ i bit-at or
        i 3 rshift bytes c!
    loop 
    0 bytes c@
    1 bytes c@ +
    2 bytes c@ +
    3 bytes c@ + 255 and
    4 bytes c@ <> if 
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
    } catch os-exit-critical throw
    dht-process
    3 bytes c@ 2 bytes c@ dht-convert
    1 bytes c@ 0 bytes c@ dht-convert ;