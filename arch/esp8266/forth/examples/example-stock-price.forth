\ stock price display with servo control
\ see it in action: https://youtu.be/4ad7dZmnoH8

464 constant: buffer-len
buffer-len buffer: buffer

4 constant: SERVO \ d2
SERVO GPIO_OUT gpio-mode

\ servo control
: short  19250 750  ; immediate
: medium 18350 1650 ; immediate
: long   17200 2800 ; immediate
: pulse ( off-cycle-us on-cycle-us -- ) immediate
  ['], SERVO , ['], GPIO_HIGH , ['] gpio-write ,
  ['], ( on cycle ) , ['] us ,
  ['], SERVO , ['], GPIO_LOW , ['] gpio-write ,
  ['], ( off cycle ) , ['] us , ;

: down   ( -- ) 30 0 do short  pulse loop ;
: midway ( -- ) 30 0 do medium pulse loop ;
: up     ( -- ) 30 0 do long   pulse loop ;

: parse-code ( buffer -- code | throws:ECONVERT )
    9 + 3 >number invert if
        ECONVERT throw
    then ;
    
exception: EHTTP
    
: read-code ( netconn -- http-code | throws:EHTTP )
    buffer-len buffer netcon-readln
    0 <= if EHTTP throw then
    buffer str: "HTTP/" str-starts? if
        buffer parse-code
    else
        EHTTP throw
    then ;
   
: skip-headers ( netconn -- netconn )
    begin
        dup buffer-len buffer netcon-readln -1 <>
    while
        buffer strlen 0= if exit then
    repeat
    EHTTP throw ;
   
: read-resp ( netconn -- response-code )
    dup read-code
    swap skip-headers
    buffer-len buffer netcon-readln
    print: 'len=' . cr ;
    
: log ( response-code -- response-code ) dup print: 'HTTP:' . space buffer type cr ;
: consume ( netcon -- )
    dup read-resp log
    swap netcon-dispose
    200 <> if EHTTP throw then ;
        
: connect ( -- netconn ) 80 str: "finance.google.com" TCP netcon-connect ;
\ : connect ( -- netconn ) 1701 str: "192.168.0.32" TCP netcon-connect ;
    
: stock-fetch ( bulb -- bool )
    connect
    dup str: "GET /finance/info?client=ig&q=NASDAQ:HDP HTTP/1.0\r\n\r\n" netcon-write
    consume ;

: str-find ( str substr -- i | -1 )
    0 -rot
    begin
        2dup str-starts? if
            2drop exit
        then
        swap dup c@ 0= if
            3drop -1 exit 
        then
        1+ swap
        rot 1+ -rot
    again ;
  
exception: ESTOCK

: marker-index ( str substr -- i | ESTOCK ) str-find dup -1 = if ESTOCK throw then ;
: find ( marker-str -- addr )
    buffer over marker-index
    swap strlen + buffer + ( begin addr )
    dup str: '"' marker-index ( end addr )
    over + 0 swap c! ;

: trend ( str -- )
    c@ case
        [ char: + ] literal of 
            up 
        endof
        [ char: - ] literal of 
            down 
        endof
        drop midway
    endcase ;
    
: center ( str -- ) DISPLAY_WIDTH swap str-width - 2 / font-size @ / text-left ! ;
: spacer ( -- ) draw-lf draw-cr 2 text-top +! ;
: stock-draw ( -- )    
    stock-fetch
    str: ',"c" : "' find \ change tag
    dup trend
    str: ',"l" : "' find \ price tag
    dup center draw-str
    spacer
    dup center draw-str ;

: error-draw ( exception -- )
    display-clear
    0 text-left ! 0 text-top !
    str: "Err: " draw-str 
    case
        ENETCON of str: "NET"  draw-str endof
        EHTTP   of str: "HTTP" draw-str endof
        ESTOCK  of str: "API"  draw-str endof
        str: "Other" draw-str
        ex-type        
    endcase 
    display ;
    
: show ( -- )
    display-clear
    3 text-top  ! 
    0 text-left !    
    stock-draw
    display ;

0 task: stock-task
0 init-variable: last-refresh

: expired? ( -- bool ) ms@ last-refresh @ - 3 60 1000 * * > ;

: stock-start ( task -- )
    activate
    begin
        last-refresh @ 0= expired? or if            
            ms@ last-refresh !            
            { show } catch ?dup 0<> if 
                error-draw 
            then            
            throw
        then
        pause
    again ;

font-medium
font5x7 font !
display-init
multi stock-task stock-start