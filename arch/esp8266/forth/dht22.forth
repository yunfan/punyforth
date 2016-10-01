2 constant: PIN \ D4
40 byte-array: bits
5  byte-array: bytes
exception: ETIMEOUT
exception: ECHECKSUM

: _pulse-in ( gpio-state gpio-pin timeout-us -- bool )    
    1 rshift 0 do
        2 us
        2dup gpio-read = if
            2drop TRUE 
            unloop exit
        then
    loop
    2drop FALSE ;
    
: pulse-in ( gpio-state gpio-pin timeout-us -- duration TRUE | FALSE )
    us@ ['] _pulse-in dip 
    swap if
        us@ swap - TRUE
    else
        drop FALSE
    then ;

: wait-for ( gpio-state gpio-pin timeout-us -- | throws:ETIMEOUT )
    pulse-in if
        drop
    else
        ETIMEOUT throw
    then ;
    
: duration ( gpio-state gpio-pin timeout-us -- duration | throws:ETIMEOUT )
    pulse-in invert if
        ETIMEOUT throw
    then ;
    
: init ( -- )
    PIN GPIO_LOW gpio-write
    20000 us
    PIN GPIO_HIGH gpio-write
    GPIO_LOW  PIN 40 wait-for
    GPIO_HIGH PIN 88 wait-for
    GPIO_LOW  PIN 88 wait-for ;
    
: fetch ( -- )    
    40 0 do
        GPIO_HIGH PIN 65 duration 
        GPIO_LOW  PIN 75 duration
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
    128 and 0<> if
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
    