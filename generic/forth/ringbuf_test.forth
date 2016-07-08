marker: -ringbuf-test

: test:ringbuf-initially-empty  
    5 ringbuf.new
    dup size 0 =assert 
    dup full? invert assert
        empty? assert ;

: test:ringbuf-size-increases-when-adding
    5 ringbuf.new
    1 over enqueue
    dup size 1 =assert 
    2 over enqueue
    dup size 2 =assert 
    dup empty? invert assert
        full? invert assert ;

: test:ringbuf-size-decreases-when-removing
    5 ringbuf.new
    1 over enqueue
    2 over enqueue
    dup dequeue drop
    dup size 1 =assert 
    dup dequeue drop
    dup size 0 =assert 
        empty? assert ;

: test:ringbuf-becomes-empty-after-removing-when-full
    2 ringbuf.new
    1 over enqueue
    2 over enqueue
    dup full? assert
    dup empty? invert assert
    dup dequeue drop
    dup dequeue drop
    dup empty? assert
        full? invert assert ;

: test:ringbuf-has-circular-property
    5 ringbuf.new
    1 over enqueue
    dup dequeue 1 =assert
    dup full? invert assert 
    1 over enqueue
    2 over enqueue
    3 over enqueue
    4 over enqueue
    5 over enqueue
    dup size 5 =assert 
    dup full? assert
    dup dequeue 1 =assert 
    dup dequeue 2 =assert 
    dup dequeue 3 =assert 
    dup dequeue 4 =assert 
    dup dequeue 5 =assert 
    dup size 0 =assert 
        empty? assert ;

: test:ringbuf-over-under-flows
    2 ringbuf.new
    dup ['] dequeue catch EUNDERFLOW =assert 
    1 over enqueue
    2 over enqueue
    3 over ['] enqueue catch EOVERFLOW =assert
    2drop ;
