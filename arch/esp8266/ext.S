defprimitive "time",4,time,1
    CCALL forth_time
    DPUSH a2
    NEXT

defprimitive "type",4,type,1            // ( a len -- )
    DPOP a3			// string
    DPOP a2			// length
    CCALL forth_type
    NEXT

/*
defprimitive "gpio-enable",11,gpioenable,1
    CCALL forth_gpio_enable
    NEXT
*/
