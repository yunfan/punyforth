4 constant: PIR_PIN         \ D2 leg
Event buffer: event
0 task: detector-task
defer: motion-detected

80 constant: DEBOUNCE_TIME \ 0.8 sec
0 init-variable: last-event-time

: pir-event? ( event -- bool )
    { .type @ EVT_GPIO = }
    { .payload @ PIR_PIN = } bi and ;

: recent-event? ( event -- bool )
    time swap .time @ - 100 < ;
    
: motion-detect ( task -- )
    activate
    begin
        println: 'waiting event'
        event next-event
        event pir-event?
        event recent-event? and
        if
            print: 'motion detected at ' event .time ? cr
            ['] motion-detected catch ?dup if
                ex-type
            then
        else
            println: 'event dropped'            
        then
    again
    deactivate ;

: lights-on ( -- )
    time last-event-time @ - DEBOUNCE_TIME < if
        println: 'skipping because of debounce'
        exit
    then
    BEDROOM on? invert if
        BEDROOM on
    then 
    time last-event-time ! ;

: lights-off ( -- )
    time last-event-time @ - DEBOUNCE_TIME < if
        println: 'skipping because of debounce'
        exit
    then
    BEDROOM on? if
        BEDROOM off
    then 
    time last-event-time ! ;    

: hue-motion-start ( -- )
    multi
    PIR_PIN GPIO_IN gpio-mode
    PIR_PIN GPIO_INTTYPE_EDGE_POS gpio-set-interrupt
    ['] motion-detected is: lights-on
    detector-task motion-detect ;
    
hue-motion-start