0 constant: FLASH_OK
1 constant: FLASH_ERR
2 constant: FLASH_TIMEOUT
3 constant: FLASH_UNKNOWN

( blocks )

exception: EBLOCK
4096       constant:      SIZE
hex: 51000 init-variable: block0
FALSE      init-variable: dirty
SIZE       buffer:        buf
variable:  offs

: check-err ( code -- | EBLOCK )
    dup FLASH_OK <> if
        print: 'SPI FLASH ERROR: ' . cr
        EBLOCK throw 
    then 
    drop ;

: >sector ( block# -- sector# ) SIZE / ;
    
: flush ( -- )
    dirty @ if
        offs @ >sector erase-flash  check-err
        SIZE buf offs @ write-flash check-err
        FALSE dirty !
    then ;
    
: block ( block# -- addr )
    flush
    SIZE * block0 @ + offs !
    SIZE buf offs @ read-flash check-err
    FALSE dirty !
    buf ;
    
: update ( -- ) TRUE dirty ! ;

( screen editor )

128 constant: COLS
32  constant: ROWS

: row   ( y -- addr )   COLS * buf + ;
: ch    ( y x -- addr ) swap row + ;
: type# ( y -- )        dup 10 < if space then . space ;
    
: list ( block# -- )
    block drop
    ROWS 0 do
        i type#
        i row COLS type-counted
    loop ;

\ editor command: blank row
: b ( y -- )
    COLS 2 - 0 do 32 over i ch c! loop
    13 over COLS 2 - ch c!
    10 swap COLS 1-  ch c!
    update ;
    
: copy-row ( dst-y src-y -- )
    COLS 0 do
        2dup i ch c@ swap i ch c!
    loop
    2drop ;
    
\ editor command: delete row
: d ( y -- )
    ROWS 1- swap do i i 1+ copy-row loop
    ROWS 1- b ;

\ editor command: clear screen    
: c ( -- ) ROWS 0 do i b loop ;

\ editor command: overwrite row
: r: ( y "line" -- )
    dup b row
    begin
        key dup line-break? invert
    while
        over c! 1+
    repeat
    2drop ;

\ editor command: prepends empty row before the given y
: p ( y -- )
    dup ROWS 1- do
        i i 1- copy-row
    -1 +loop
    b ;

defer: boot    
: dst ( -- n ) block0 @ SIZE + ;
: heap-size ( -- n ) usedmem align ;
: save-loader ( -- )
    0 block drop c
    0 row dup heap-size >str dup strlen +        
    str: ' heap-start ' over 12 cmove
    12 + dup dst >str dup strlen +        
    str: ' read-flash drop boot' swap 22 cmove 
    update flush ;
        
: turnkey ( -- )
    heap-size SIZE / heap-size SIZE % 0> abs + 0 do
        dst >sector i + erase-flash check-err
    loop
    heap-size heap-start dst write-flash check-err 
    save-loader ;
