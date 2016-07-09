marker: -ringbuf

struct
    cell field: .i
    cell field: .j
    cell field: .capacity
    cell field: .size
constant: RingBuffer

: ringbuf-new ( capacity -- ringbuffer )
    here tuck
    over cells RingBuffer + allot
    0 over .i !
    0 over .j !
    0 over .size !
    .capacity ! ;

: ringbuf-new: ( capacity ) ( -- ringbuffer )
    create: ringbuf-new drop
    does> ;

: ringbuf-size ( ringbuffer -- n ) .size @ ;

: ringbuf-empty? ( ringbuffer -- bool ) ringbuf-size 0= ;

: ringbuf-full? ( ringbuffer -- bool )
    ['] .size ['] .capacity bi 
    ['] @ bi@ = ;

: slot ( index ringbuffer -- adr )
    RingBuffer + swap cells + ;

: back-slot ( ringbuffer -- adr )
    dup .j @
    swap slot ;

: front-slot ( ringbuffer -- adr )
    dup .i @
    swap slot ;    

: increase-size ( ringbuffer -- ) .size 1 swap +! ;

: added ( ringbuffer -- )
    dup
    dup increase-size
    ['] .capacity ['] .j bi ['] @ bi@
    1+ swap %
    swap .j ! ;

: decrease-size ( ringbuffer -- ) .size -1 swap +! ;

: removed ( ringbuffer -- )
    dup
    dup decrease-size
    ['] .capacity ['] .i bi ['] @ bi@
    1+ swap %
    swap .i ! ;

: ringbuf-enqueue ( element ringbuffer -- )
    dup ringbuf-full? if
        EOVERFLOW throw
    then
    tuck
    back-slot !
    added ;

: ringbuf-dequeue ( ringbuffer -- element )
    dup ringbuf-empty? if
        EUNDERFLOW throw
    then
    dup
    front-slot @
    swap
    removed ;
