struct
    cell field: .type
    cell field: .time
    cell field: .payload
    cell field: .time-us
constant: Event

100 constant: EVT_GPIO
70 init-variable: event-timeout

: next-event ( event-struct -- event )
    begin
        dup event-timeout @ wait-event 0=
    while
        pause
    repeat 
    drop ;
