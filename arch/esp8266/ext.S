defprimitive ">",1,gt,1 
    DPOP a8
    DPOP a9
    movi a10, FALSE
    bge a8, a9, L5
    movi a10, TRUE
L5: DPUSH a10
    NEXT

defprimitive "=",1,eq,1 
    DPOP a8
    DPOP a9
    movi a10, FALSE
    bne a8, a9, L6
    movi a10, TRUE
L6: DPUSH a10
    NEXT

defprimitive "<>",2,noteq,1 
    DPOP a8
    DPOP a9
    movi a10, FALSE
    beq a8, a9, L7
    movi a10, TRUE
L7: DPUSH a10
    NEXT

defprimitive "<=",2,lte,1 
    DPOP a8
    DPOP a9
    movi a10, FALSE
    blt a8, a9, L8
    movi a10, TRUE
L8: DPUSH a10
    NEXT

defprimitive ">=",2,gte,1 
    DPOP a8
    DPOP a9
    movi a10, FALSE
    blt a9, a8, L9
    movi a10, TRUE
L9: DPUSH a10
    NEXT

defprimitive "time",4,time,1
    CCALL forth_time
    DPUSH a2
    NEXT

defprimitive "type",4,type,1    // ( a -- )
    DPOP a2			// string
    CCALL forth_type
    NEXT

defprimitive "uart-set-bps",12,uart_set_bps,1    // ( bps uart_num -- )
    DPOP a2			// uart_num
    DPOP a3			// bps
    CCALL forth_uart_set_baud
    NEXT

defprimitive "gpio-enable",11,gpioenable,1
    DPOP a3                     // gpio direction
    DPOP a2                     // gpio num
    CCALL forth_gpio_enable
    NEXT

defprimitive "gpio-set-interrupt",18,gpiointerrupt,1
    DPOP a3                     // gpio interrupt type
    DPOP a2                     // gpio num
    CCALL forth_gpio_set_interrupt
    NEXT

defprimitive "gpio-write",10,gpiowrite,1
    DPOP a3                     // bool
    DPOP a2                     // gpio num
    CCALL forth_gpio_write
    NEXT

defprimitive "gpio-read",9,gpioread,1
    DPOP a2                     // gpio num
    CCALL forth_gpio_read
    DPUSH a2
    NEXT

defprimitive "delay",5,delay,1
    DPOP a2                     // millis to wait
    CCALL forth_delay
    NEXT

defprimitive "ds18b20",7,ds18b20,1
    DPOP a2                    // gpio num
    DPOP a3                    // sensor num
    CCALL forth_ds18b20_read_all    
    NEXT

defprimitive "netconn-new",11,netconn_new,1
    DPOP a2                    // conn type
    CCALL forth_netconn_new
    DPUSH a2
    NEXT

defprimitive "netconn-connect",15,netconn_connect,1       
    DPOP a2                    // conn
    DPOP a3                    // host
    DPOP a4                    // port
    CCALL forth_netconn_connect
    DPUSH a2
    NEXT

defprimitive "netconn-send",12,netconn_send,1
    DPOP a2                    // conn
    DPOP a3                    // data
    DPOP a4                    // len
    CCALL forth_netconn_send
    DPUSH a2
    NEXT

defprimitive "netconn-write",13,netconn_write,1
    DPOP a2                    // conn
    DPOP a3                    // data
    DPOP a4                    // size
    CCALL forth_netconn_write
    DPUSH a2
    NEXT

defprimitive "netconn-recvinto",16,netconn_recvinto,1
    DPOP a2                    // conn
    DPOP a3                    // buffer
    DPOP a4                    // size
    CCALL forth_netconn_recvinto
    DPUSH a3                   // count read
    DPUSH a2                   // err_t
    NEXT

defprimitive "netbuf-del",10,netbuf_del,1
    DPOP a2                    // netbuf
    CCALL forth_netbufdel
    NEXT

defprimitive "netbuf-next",11,netbuf_next,1
    DPOP a2                    // netbuf
    CCALL forth_netbuf_next
    DPUSH a2
    NEXT

defprimitive "netbuf-data",11,netbuf_data,1
    DPOP a2                    // netbuf
    CCALL forth_netbuf_data
    DPUSH a3                   // buffer
    DPUSH a2                   // size
    NEXT

defprimitive "netconn-recv",12,netconn_recv,1
    DPOP a2                    // netconn
    CCALL forth_netconn_recv
    DPUSH a3                   // netbuf
    DPUSH a2                   // err_t
    NEXT

defprimitive "netconn-dispose",15,netconn_dispose,1
    DPOP a2                    // conn
    CCALL forth_netconn_dispose
    NEXT

defprimitive "task-yield",10,task_yield,1
    CCALL forth_yield
    NEXT

defprimitive "next-event",10,next_event,1
    CCALL forth_next_event
    DPUSH a2
    NEXT

defprimitive "random",6,random,1
    CCALL forth_random
    DPUSH a2
    NEXT

defprimitive "erase-flash",11,erase_flash,1
    DPOP a2                    // sector
    CCALL forth_flash_erase_sector
    DPUSH a2
    NEXT

defprimitive "read-flash",10,read_flash,1
    DPOP a2                    // sector
    DPOP a3                    // buffer
    DPOP a4                    // size
    CCALL forth_flash_read
    DPUSH a2
    NEXT

defprimitive "write-flash",11,write_flash,1
    DPOP a2                    // sector
    DPOP a3                    // buffer
    DPOP a4                    // size
    CCALL forth_flash_write
    DPUSH a2
    NEXT

defprimitive "spi-init",8,spi_init,1
    DPOP a2                    // bus
    DPOP a3                    // mode
    DPOP a4                    // freq_div
    DPOP a5                    // msb
    DPOP a6                    // endianness
    DPOP a7                    // minimal_pins
    CCALL forth_spi_init
    DPUSH a2
    NEXT

defprimitive "spi-send8",9,spi_send8,1
    DPOP a2                    // bus
    DPOP a3                    // data
    CCALL forth_spi_send8
    DPUSH a2
    NEXT

defprimitive "spi-send",8,spi_send,1
    DPOP a2                    // bus
    DPOP a3                    // out_data
    DPOP a4                    // in_data
    DPOP a5                    // size_data
    DPOP a6                    // word_size
    CCALL forth_spi_send
    DPUSH a2
    NEXT
