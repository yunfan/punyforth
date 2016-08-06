4 constant: PIR_PIN         \ D2 leg
Event buffer: event
0 task: detector-task
defer: motion-detected

: motion-detect ( task -- )
    activate
    begin
        event next-event
        event .type @ EVT_GPIO = if
            print: 'motion detected at ' event .time ? cr
            ['] motion-detected catch ?dup if
                ex-type             
            then
        then
    again
    deactivate ;

: lights-on ( -- )
    BEDROOM on? invert if
        BEDROOM on
    then ;

: hue-motion-start ( -- )
    multi
    PIR_PIN GPIO_IN gpio-mode
    PIR_PIN GPIO_INTTYPE_EDGE_POS gpio-set-interrupt
    ['] motion-detected is: lights-on
    detector-task motion-detect ;
    
hue-motion-start    