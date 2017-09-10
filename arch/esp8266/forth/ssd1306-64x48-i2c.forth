\ ssd1306 I2C display driver for 64x48 pixel OLED displays, this is work in progress
\ Tested with wemos oled shield
\ Usage:
\  display-init
\  font5x7 font !
\  10 text-top ! 8 text-left ! "Hello" draw-str display
\ display-clear

64 constant: WIDTH
48 constant: HEIGHT
5 ( D1 SCL ) constant: SCL
4 ( D2 SDA ) constant: SDA
0 ( D3 RST ) constant: RST 
16r3C constant: SLAVE

WIDTH HEIGHT * 8 / constant: SIZE
SIZE 1+ buffer: screen1
16r40 ( control byte ) screen1 !
: screen ( -- buffer ) screen1 1+ ;

exception: EI2C

\ i2c-write-slave in rtos uses uint8_t len parameter
\ this version uses 32bit integer
\ TODO: use updated version of RTOS and delete this word
: i2c-write-slave ( len buffer slave-addr -- bool )
    i2c-start
    1 lshift i2c-write 1 <> if 2drop i2c-stop 0 exit then
    swap 0 do
        dup i + c@ i2c-write 1 <> if
            unloop drop i2c-stop 0 exit
        then
    loop
    drop i2c-stop 1 ;

: wire ( -- )
    SCL GPIO_OUT gpio-mode
    SDA GPIO_OUT gpio-mode    
    RST GPIO_LOW gpio-write ;

: check ( code -- | throws:EI2C ) 1 <> if EI2C throw then ;

create: buf 16r80 c, 0 c,
: cmd ( byte -- | throws:EI2C ) buf 1+ c! 2 buf SLAVE i2c-write-slave check ;

: reset ( -- )
    RST GPIO_HIGH gpio-write 1 ms
    RST GPIO_LOW  gpio-write 10 ms
    RST GPIO_HIGH gpio-write ;

: init ( -- )
   16rAE ( SSD1306_DISPLAYOFF )           cmd
   16rD5 ( SSD1306_SETDISPLAYCLOCKDIV )   cmd
   16r80                                  cmd
   16rA8 ( SSD1306_SETMULTIPLEX )         cmd
   HEIGHT 1-                              cmd
   16rD3 ( SSD1306_SETDISPLAYOFFSET )     cmd
   16r00                                  cmd
   16r40 ( SSD1306_SETSTARTLINE )         cmd
   16r8D ( SSD1306_CHARGEPUMP )           cmd
   16r14                                  cmd
   16r20 ( SSD1306_MEMORYMODE )           cmd
   16r00                                  cmd
   16rA1 ( SSD1306_SEGREMAP )             cmd
   16rC8 ( SSD1306_COMSCANDEC )           cmd
   16rDA ( SSD1306_SETCOMPINS )           cmd
   16r12                                  cmd
   16r81 ( SSD1306_SETCONTRAST )          cmd 
   16rCF                                  cmd
   16rD9 ( SSD1306_SETPRECHARGE )         cmd
   16rF1                                  cmd
   16rDB ( SSD1306_SETVCOMDETECT )        cmd 
   16r40                                  cmd
   16rA4 ( SSD1306_DISPLAYALLON_RESUME )  cmd
   16rA6 ( SSD1306_NORMALDISPLAY )        cmd
   16rAF ( SSD1306_DISPLAYON )            cmd ;

: y>bitmask ( y -- bit-index ) 7 and 1 swap lshift ;
: xy-trunc ( x y -- x' y' ) swap 63 and swap 48 % ;
: xy>i ( x y -- bit-mask buffer-index )
    xy-trunc
    dup 
    y>bitmask -rot
    3 rshift ( 8 / )
    6 lshift ( WIDTH * ) + ;

: or! ( value addr -- ) tuck c@ or swap c! ;
: and! ( value addr -- ) tuck c@ and swap c! ;
: set-pixel ( x y -- )  xy>i screen + or! ;
: unset-pixel ( x y -- ) xy>i screen + swap invert swap and! ;
: pixel-set? ( x y -- ) xy>i screen + c@ and 0<> ;
: hline ( x y width -- ) 0 do 2dup set-pixel { 1+ } dip loop 2drop ;
: rect-fill ( x y width height -- ) 0 do 3dup hline { 1+ } dip loop 3drop ;
: fill-buffer ( value -- ) SIZE 0 do dup i screen + c! loop drop ;

: display ( -- )
    16r21 ( COLUMNADDR ) cmd 
    32                   cmd 
    95                   cmd 
    16r22 ( PAGEADD )    cmd 
    0                    cmd 
    5                    cmd
    SIZE 1+ screen 1- SLAVE i2c-write-slave check ;

: display-clear ( -- ) 0 fill-buffer display ;
: display-init ( -- | throws:ESSD1306 ) wire SDA SCL i2c-init reset init display-clear ;  

\ TODO move these to common place as they're used in the spi driver too
0 init-variable: font
0 init-variable: text-left
0 init-variable: text-top
1 init-variable: font-size

: font-small  ( -- ) 1 font-size ! ;
: font-medium ( -- ) 2 font-size ! ;
: font-big    ( -- ) 3 font-size ! ;
: font-xbig   ( -- ) 4 font-size ! ;
: draw-lf ( -- ) 9 text-top +! ;
: draw-cr ( -- ) 0 text-left ! ;
: dot ( x y -- ) { font-size @ * } bi@ font-size @ dup rect-fill ;
    
: stripe ( bits -- )
    8 0 do
        dup 1 and 1= if
            text-left @ text-top @ i + dot
        then
        1 rshift
    loop
    drop ;

: draw-char ( char -- )
    255 and 5 * font @ +
    5 0 do
        dup c@ stripe 1+
        1 text-left +!
    loop
    1 text-left +!
    drop ;
    
: draw-str ( str -- )
    font @ 0= if 
        println: 'Set a font like: "font5x7 font !"'
        drop exit 
    then
    dup strlen 0 do
        dup i + c@
        case
            10 of draw-lf endof
            13 of draw-cr endof
            draw-char
        endcase
    loop
    drop ;
    
: str-width ( str -- ) strlen 8 * font-size @ * ;
