marker: -stream

struct
    cell field: .i
    cell field: .capacity
    cell field: .size
constant: Stream

: stream.new: ( capacity-bytes "name"  -- stream )
    create:
        here 
        over cells Stream + allot
        0 over .i !
        0 over .size !
        .capacity !
    does> ;

: stream.buffer ( stream -- a ) Stream + ;
   
: stream.size ( stream -- n ) .size @ ;

: stream.empty? ( stream -- bool ) stream.size 0= ;

: stream.full? ( stream -- bool )
    ['] .size ['] .capacity bi 
    ['] @ bi@ = ;

: stream.reset ( stream -- )
    0 swap .i ! ;

: next-slot ( stream -- a )
    dup
    dup .i @ + Stream +
    swap .i 1 swap +! ;

: stream.put-byte ( byte stream -- )
    dup stream.full? if
        EOVERFLOW throw
    then
    tuck
    next-slot c!
    .size 1 swap +! ;

: stream.next-byte ( stream -- byte )
    dup stream.empty? if
        EUNDERFLOW throw
    then
    dup next-slot c@
    swap
    .size -1 swap +! ;
