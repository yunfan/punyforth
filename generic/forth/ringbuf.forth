marker -ringbuf

struct
    cell field: .i
    cell field: .j
    cell field: .capacity
    cell field: .size
constant: RingBuffer

: ringbuffer: ( capacity ) ( -- ringbuffer )
    create:
        here 
        over cells RingBuffer + allot
        0 over .i !
        0 over .j !
        0 over .size !
        .capacity !
    does> ;

: size ( ringbuffer -- n ) .size @ ;

: empty? ( ringbuffer -- bool ) size 0= ;

: full? ( ringbuffer -- bool )
    ['] .size ['] .capacity bi 
    ['] @ bi@ = ;

: ringbuffer-slot ( index ringbuffer -- adr )
    RingBuffer + swap cells + ;

: ringbuffer-back-slot ( ringbuffer -- adr )
    dup .j @
    swap ringbuffer-slot ;

: ringbuffer-front-slot ( ringbuffer -- adr )
    dup .i @
    swap ringbuffer-slot ;    

: ringbuffer-increase-size ( ringbuffer -- ) .size 1 swap +! ;

: ringbuffer-added ( ringbuffer -- )
    dup
    dup ringbuffer-increase-size
    ['] .capacity ['] .j bi ['] @ bi@
    1+ swap %
    swap .j ! ;

: ringbuffer-decrease-size ( ringbuffer -- ) .size -1 swap +! ;

: ringbuffer-removed ( ringbuffer -- )
    dup
    dup ringbuffer-decrease-size
    ['] .capacity ['] .i bi ['] @ bi@
    1+ swap %
    swap .i ! ;

: enqueue ( element ringbuffer -- )
    dup full? if
        EOVERFLOW throw
    then
    tuck
    ringbuffer-back-slot !
    ringbuffer-added ;

: dequeue ( ringbuffer -- element )
    dup empty? if
        EUNDERFLOW throw
    then
    dup
    ringbuffer-front-slot @
    swap
    ringbuffer-removed ;
