2 constant: PIN \ D4
1 constant: DHT_INTERVAL
40 byte-array: bits
5  byte-array: bytes
exception: ETIMEOUT
exception: ECHECKSUM

: pin-change ( pin-new-state timeout -- duration TRUE | FALSE )
    0 do
        DHT_INTERVAL us
        PIN gpio-read over = if
            drop i TRUE 
            unloop exit
        then
        DHT_INTERVAL
    +loop
    drop FALSE ;

: wait-for ( pin-state timeout -- | throws:ETIMEOUT )
    pin-change if
        drop
    else
        ETIMEOUT throw
    then ;
    
: duration ( pin-state timeout -- duration | throws:ETIMEOUT )
    pin-change invert if
        ETIMEOUT throw
    then ;
    
: init ( -- )
    PIN GPIO_LOW gpio-write
    20000 us
    PIN GPIO_HIGH gpio-write
    GPIO_LOW 40 wait-for
    GPIO_HIGH 88 wait-for
    GPIO_LOW 88 wait-for ;
    
: fetch ( -- )    
    40 0 do
        GPIO_HIGH 65 duration 
        GPIO_LOW 75 duration
        < i bits c!
    loop ;

: measure ( -- )
    os-enter-critical
    { init fetch } catch 
    os-exit-critical 
    throw ;    

: bit-at ( i -- bit )
    bits c@ if 1 else 0 then ;
    
: bytes-clear ( -- )
    5 0 do 
        0 i bytes c! 
    loop ;
    
: process ( -- )
    bytes-clear
    40 0 do        
        i 3 rshift bytes c@ 1 lshift
        i 3 rshift bytes c!        
        i 3 rshift bytes c@ i bit-at or
        i 3 rshift bytes c!
    loop ;

: checksum ( -- )    
    0 bytes c@
    1 bytes c@ +
    2 bytes c@ +
    3 bytes c@ + 255 and ;
    
: validate ( -- | throws:ECHECKSUM )
    checksum 4 bytes c@ <> if 
        ECHECKSUM throw 
    then ;

: convert ( lsb-byte msb-byte -- value )
    { hex: 7F and 8 lshift or } keep
    dup 128 and 0= if
        drop
    else
        0 swap -
    then ;
    
: humidity ( -- humidity%-x-10 ) 1 bytes c@ 0 bytes c@ convert ;
: temperature ( -- celsius-x-10 ) 3 bytes c@ 2 bytes c@ convert ;
    
\ measures temperature and humidity using DHT22 sensor
\ temperature and humidity values are multiplied with 10
: dht-measure ( -- celsius-x-10 humidity%-x-10 )
    PIN GPIO_OUT_OPEN_DRAIN gpio-mode
    measure
    process
    validate
    temperature humidity ;
    