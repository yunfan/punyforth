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
variable:  addr

: check-err ( code -- | EBLOCK )
    dup FLASH_OK <> if
        print: 'SPI FLASH ERROR: ' . cr
        EBLOCK throw 
    then 
    drop ;

: >sector ( block# -- sector# ) SIZE / ;
    
: flush ( -- )
    dirty @ if
        addr @ >sector erase-flash  check-err
        SIZE buf addr @ write-flash check-err
        FALSE dirty !
    then ;
    
: block ( block# -- addr )
    flush
    SIZE * block0 @ + addr !    
    SIZE buf addr @ read-flash check-err
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

\ editor command: delete row by filling it with spaces
: d ( y -- )
    COLS 2 - 0 do 32 over i ch c! loop
    13 over COLS 2 - ch c!
    10 over COLS 1-  ch c!
    drop 
    update ;
    
: copy-row ( dst-y src-y -- )
    COLS 0 do
        2dup i ch c@ swap i ch c!
    loop
    2drop ;
    
\ editor command: kill row
: k ( y -- )
    ROWS 1- swap do i i 1+ copy-row loop
    ROWS 1- d ;

\ editor command: clear screen    
: c ( -- ) ROWS 0 do i d loop ;
        
\ editor command: overwrite row    
: r: ( y "line" -- )
    dup d
    row
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
    d ;