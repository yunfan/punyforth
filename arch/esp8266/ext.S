defprimitive "time",4,time,1
    CCALL forth_time
    DPUSH a2
    NEXT

defprimitive "type",4,type,1            // ( a len -- )
    DPOP a3			// string
    DPOP a2			// length
    CCALL forth_type
    NEXT

defprimitive "gpio-enable",11,gpioenable,1
    DPOP a3                     // gpio direction
    DPOP a2                     // gpio num
    CCALL forth_gpio_enable
    NEXT

defprimitive "gpio-write",10,gpiwrite,1
    DPOP a3                     // bool
    DPOP a2                     // gpio num
    CCALL forth_gpio_write
    NEXT

defprimitive "delay",5,delay,1
    DPOP a2                     // millis to wait
    CCALL forth_delay
    NEXT


