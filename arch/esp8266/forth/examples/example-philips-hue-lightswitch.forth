12 constant: BUTTON_BEDROOM \ D6 pin on nodemcu
14 constant: BUTTON_HALL    \ D5 pin on nodemcu

\ setup gpio buttons
BUTTON_HALL GPIO_IN gpio-enable
BUTTON_HALL GPIO_INTTYPE_EDGE_NEG gpio-set-interrupt
BUTTON_BEDROOM GPIO_IN gpio-enable
BUTTON_BEDROOM GPIO_INTTYPE_EDGE_NEG gpio-set-interrupt

50 constant: DEBOUNCE_TIME \ half sec
variable: last-event-time

: toggle-debounced ( ligth -- )
    time last-event-time @ - DEBOUNCE_TIME > if
        time last-event-time !
        toggle        
    else
        drop
    then ;

: switch-loop ( task -- )
    activate
    time last-event-time !
    begin
        pause
        30 next-event
        case
            BUTTON_HALL of 
                HALL toggle-debounced
            endof
            BUTTON_BEDROOM of 
                BEDROOM toggle-debounced
            endof
            drop
        endcase    
    again 
    deactivate ;

0 task: hue-task
    
: hue-start ( -- )
    multi
    hue-task switch-loop ;
