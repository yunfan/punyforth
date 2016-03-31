defprimitive "time",4,time,1
    CCALL forth_time
    DPUSH a2
    NEXT

defprimitive "type",4,type,1    // ( a -- )
    DPOP a2			// string
    CCALL forth_type
    NEXT

defprimitive "gpio-enable",11,gpioenable,1
    DPOP a3                     // gpio direction
    DPOP a2                     // gpio num
    CCALL forth_gpio_enable
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

/*
defprimitive "netconn-recv",12,netconn_recv,1
    DPOP a2                    // conn
    CCALL forth_netconn_recv
    DPUSH a3                   // buffer
    DPUSH a4                   // size
    DPUSH a2                   // err_t
    NEXT
*/

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
