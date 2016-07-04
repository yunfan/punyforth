marker: -lightswitch

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

: start-light-switch-task ( task -- )
    activate
    time last-event-time !
    begin
        pause
        50 next-event
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

512 var-task-stack-size !
256 var-task-rstack-size !

task: light-switch-task
    
: light-switch-start ( -- )
    multi
    light-switch-task 
    start-light-switch-task ;
    
light-switch-start
