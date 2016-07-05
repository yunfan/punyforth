marker: -ringbuf-test

5 ringbuffer: buf
: test:initially-empty  
    buf size 0 =assert 
    buf full? invert assert
    buf empty? assert ;

5 ringbuffer: buf
: test:size-increases-when-adding
    1 buf enqueue
    buf size 1 =assert 
    2 buf enqueue
    buf size 2 =assert 
    buf empty? invert assert
    buf full? invert assert ;

5 ringbuffer: buf 
: test:size-decreases-when-removing
    1 buf enqueue
    2 buf enqueue
    buf dequeue drop
    buf size 1 =assert 
    buf dequeue drop
    buf size 0 =assert 
    buf empty? assert ;

2 ringbuffer: buf 
: test:becomes-empy-after-removing-when-full
    1 buf enqueue
    2 buf enqueue
    buf full? assert
    buf empty? invert assert
    buf dequeue drop
    buf dequeue drop
    buf empty? assert
    buf full? invert assert ;

5 ringbuffer: buf 
: test:has-circular-property
    1 buf enqueue buf dequeue 1 =assert
    buf full? invert assert 
    1 buf enqueue
    2 buf enqueue
    3 buf enqueue
    4 buf enqueue
    5 buf enqueue
    buf size 5 =assert 
    buf full? assert
    buf dequeue 1 =assert 
    buf dequeue 2 =assert 
    buf dequeue 3 =assert 
    buf dequeue 4 =assert 
    buf dequeue 5 =assert 
    buf size 0 =assert 
    buf empty? assert ;

2 ringbuffer: buf
: expect-underflow ['] dequeue catch EUNDERFLOW =assert ;
: expect-overflow ['] enqueue catch EOVERFLOW =assert ;
: test:over-under-flows
    buf expect-underflow
    1 buf enqueue
    2 buf enqueue
    3 buf expect-overflow drop ;

test
-ringbuf-test
