defword "readchar",8,readchar,REGULAR
    .int xt_xpause, xt_fetch, xt_branch0
    lbl readchar_blocking
readchar_again:
    .int xt_readchar_nowait, xt_dup, xt_btick, -1, xt_eq, xt_branch0
    lbl readchar_available
    .int xt_drop
    .int xt_xpause, xt_fetch, xt_execute
    .int xt_branch
    lbl readchar_again
readchar_available:
    .int xt_exit
readchar_blocking:
    .int xt_readchar_wait
    .int xt_exit

defword "xpause",6,xpause,REGULAR
    .int xt_btick, _M var_pause_xt
    .int xt_exit

defprimitive "readchar-wait",13,readchar_wait,REGULAR
    CCALL forth_getchar
    DPUSH a2
    NEXT    

defprimitive "readchar-nowait",15,readchar_nowait,REGULAR /* ( -- char | -1 ) */
    CCALL forth_getchar_nowait
    DPUSH a2
    NEXT

defprimitive "over",4,over,REGULAR /* ( a b -- a b a ) */
    l32i a8, a15, CELLS
    DPUSH a8
    NEXT

defprimitive ">",1,gt,REGULAR 
    DPOP a8
    DPOP a9
    movi a10, FALSE
    bge a8, a9, L5
    movi a10, TRUE
L5: DPUSH a10
    NEXT

defprimitive "=",1,eq,REGULAR 
    DPOP a8
    DPOP a9
    movi a10, FALSE
    bne a8, a9, L6
    movi a10, TRUE
L6: DPUSH a10
    NEXT

defprimitive "<>",2,noteq,REGULAR 
    DPOP a8
    DPOP a9
    movi a10, FALSE
    beq a8, a9, L7
    movi a10, TRUE
L7: DPUSH a10
    NEXT

defprimitive "<=",2,lte,REGULAR 
    DPOP a8
    DPOP a9
    movi a10, FALSE
    blt a8, a9, L8
    movi a10, TRUE
L8: DPUSH a10
    NEXT

defprimitive ">=",2,gte,REGULAR 
    DPOP a8
    DPOP a9
    movi a10, FALSE
    blt a9, a8, L9
    movi a10, TRUE
L9: DPUSH a10
    NEXT

defprimitive "1+",2,inc,REGULAR
    DPOP a8
    addi a8, a8, 1
    DPUSH a8
    NEXT

defprimitive "1-",2,dec,REGULAR
    DPOP a8
    addi a8, a8, -1
    DPUSH a8
    NEXT

defprimitive "0=",2,eq0,REGULAR
    DPOP a8
    movi a9, FALSE
    movi a10, TRUE
    moveqz a9, a10, a8 // move a10 to a9 if a8 is zero
    DPUSH a9
    NEXT

defprimitive "0<>",3,noteq0,REGULAR
    DPOP a8
    movi a9, FALSE
    movi a10, TRUE
    movnez a9, a10, a8 // move a10 to a9 if a8 is not zero
    DPUSH a9
    NEXT

defprimitive "0<",2,lt0,REGULAR
    DPOP a8
    movi a9, FALSE
    movi a10, TRUE
    movltz a9, a10, a8 // move a10 to a9 if a8 is less than zero
    DPUSH a9
    NEXT

defprimitive "0>",2,gt0,REGULAR
    DPOP a8
    movi a9, TRUE
    movi a10, FALSE
    movltz a9, a10, a8 // move a10 to a9 if a8 is less than zero
    moveqz a9, a10, a8 // move a10 to a9 if a8 is zero
    DPUSH a9
    NEXT

defprimitive "time",4,time,REGULAR
    CCALL forth_time
    DPUSH a2
    NEXT

defprimitive "type",4,type,REGULAR    // ( a -- )
    DPOP a2			// string
    CCALL forth_type
    NEXT

defprimitive "uart-set-bps",12,uart_set_bps,REGULAR    // ( bps uart_num -- )
    DPOP a2			// uart_num
    DPOP a3			// bps
    CCALL forth_uart_set_baud
    NEXT

defprimitive "gpio-enable",11,gpioenable,REGULAR
    DPOP a3                     // gpio direction
    DPOP a2                     // gpio num
    CCALL forth_gpio_enable
    NEXT

defprimitive "gpio-set-interrupt",18,gpiointerrupt,REGULAR
    DPOP a3                     // gpio interrupt type
    DPOP a2                     // gpio num
    CCALL forth_gpio_set_interrupt
    NEXT

defprimitive "gpio-write",10,gpiowrite,REGULAR
    DPOP a3                     // bool
    DPOP a2                     // gpio num
    CCALL forth_gpio_write
    NEXT

defprimitive "gpio-read",9,gpioread,REGULAR
    DPOP a2                     // gpio num
    CCALL forth_gpio_read
    DPUSH a2
    NEXT

defprimitive "delay",5,delay,REGULAR
    DPOP a2                     // millis to wait
    CCALL forth_delay
    NEXT

defprimitive "ds18b20",7,ds18b20,REGULAR
    DPOP a2                    // gpio num
    DPOP a3                    // sensor num
    CCALL forth_ds18b20_read_all    
    NEXT

defprimitive "netconn-set-recvtimeout",23,netconn_set_recvtimeout,REGULAR 
    DPOP a2                    // conn
    DPOP a3                    // recv timeout ms
    CCALL forth_netconn_set_recvtimeout
    NEXT

defprimitive "netconn-new",11,netconn_new,REGULAR
    DPOP a2                    // conn type
    CCALL forth_netconn_new
    DPUSH a2
    NEXT

defprimitive "netconn-connect",15,netconn_connect,REGULAR       
    DPOP a2                    // conn
    DPOP a3                    // host
    DPOP a4                    // port
    CCALL forth_netconn_connect
    DPUSH a2
    NEXT

defprimitive "netconn-send",12,netconn_send,REGULAR
    DPOP a2                    // conn
    DPOP a3                    // data
    DPOP a4                    // len
    CCALL forth_netconn_send
    DPUSH a2
    NEXT

defprimitive "netconn-write",13,netconn_write,REGULAR
    DPOP a2                    // conn
    DPOP a3                    // data
    DPOP a4                    // size
    CCALL forth_netconn_write
    DPUSH a2
    NEXT

defprimitive "netconn-recvinto",16,netconn_recvinto,REGULAR
    DPOP a2                    // conn
    DPOP a3                    // buffer
    DPOP a4                    // size
    CCALL forth_netconn_recvinto
    DPUSH a3                   // count read
    DPUSH a2                   // err_t
    NEXT

defprimitive "netbuf-del",10,netbuf_del,REGULAR
    DPOP a2                    // netbuf
    CCALL forth_netbufdel
    NEXT

defprimitive "netbuf-next",11,netbuf_next,REGULAR
    DPOP a2                    // netbuf
    CCALL forth_netbuf_next
    DPUSH a2
    NEXT

defprimitive "netbuf-data",11,netbuf_data,REGULAR
    DPOP a2                    // netbuf
    CCALL forth_netbuf_data
    DPUSH a3                   // buffer
    DPUSH a2                   // size
    NEXT

defprimitive "netconn-recv",12,netconn_recv,REGULAR
    DPOP a2                    // netconn
    CCALL forth_netconn_recv
    DPUSH a3                   // netbuf
    DPUSH a2                   // err_t
    NEXT

defprimitive "netconn-dispose",15,netconn_dispose,REGULAR
    DPOP a2                    // conn
    CCALL forth_netconn_dispose
    NEXT

defprimitive "task-yield",10,task_yield,REGULAR
    CCALL forth_yield
    NEXT

defprimitive "next-event",10,next_event,REGULAR
    CCALL forth_next_event
    DPUSH a2
    NEXT

defprimitive "random",6,random,REGULAR
    CCALL forth_random
    DPUSH a2
    NEXT

defprimitive "erase-flash",11,erase_flash,REGULAR
    DPOP a2                    // sector
    CCALL forth_flash_erase_sector
    DPUSH a2
    NEXT

defprimitive "read-flash",10,read_flash,REGULAR
    DPOP a2                    // sector
    DPOP a3                    // buffer
    DPOP a4                    // size
    CCALL forth_flash_read
    DPUSH a2
    NEXT

defprimitive "write-flash",11,write_flash,REGULAR
    DPOP a2                    // sector
    DPOP a3                    // buffer
    DPOP a4                    // size
    CCALL forth_flash_write
    DPUSH a2
    NEXT

defprimitive "spi-init",8,spi_init,REGULAR
    DPOP a2                    // bus
    DPOP a3                    // mode
    DPOP a4                    // freq_div
    DPOP a5                    // msb
    DPOP a6                    // endianness
    DPOP a7                    // minimal_pins
    CCALL forth_spi_init
    DPUSH a2
    NEXT

defprimitive "spi-send8",9,spi_send8,REGULAR
    DPOP a2                    // bus
    DPOP a3                    // data
    CCALL forth_spi_send8
    DPUSH a2
    NEXT

defprimitive "spi-send",8,spi_send,REGULAR
    DPOP a2                    // bus
    DPOP a3                    // out_data
    DPOP a4                    // in_data
    DPOP a5                    // size_data
    DPOP a6                    // word_size
    CCALL forth_spi_send
    DPUSH a2
    NEXT

defprimitive "wifi-set-mode",13,wifi_set_mode,REGULAR
    DPOP a2                    // mode
    CCALL forth_wifi_set_opmode
    DPUSH a2                   // c bool
    NEXT

defprimitive "wifi-set-station-config",23,wifi_set_config,REGULAR
    DPOP a2                    // ssid
    DPOP a3                    // password
    CCALL forth_wifi_set_station_config
    DPUSH a2                   // c bool
    NEXT
