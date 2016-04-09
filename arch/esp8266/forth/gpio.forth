0 constant GPIO_INTTYPE_NONE
1 constant GPIO_INTTYPE_EDGE_POS
2 constant GPIO_INTTYPE_EDGE_NEG
3 constant GPIO_INTTYPE_EDGE_ANY
4 constant GPIO_INTTYPE_LEVEL_LOW
5 constant GPIO_INTTYPE_LEVEL_HIGH

2 constant PIN2       \ GPIO 2 (D4 leg on ESP devboard)
2 constant BUTTON
1 constant GPIO_IN
2 constant GPIO_OUT

\ PIN2 GPIO_OUT gpio-enable

: blink ( n -- )
    0 do
        PIN2 TRUE gpio-write
        1000 delay
        PIN2 FALSE gpio-write
        1000 delay
    loop ;
    
\ 10 blink    
