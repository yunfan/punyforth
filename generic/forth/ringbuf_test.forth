marker -ringbuf-test

\ initially empty  
5 ringbuffer: buf 
buf size 0 = assert 
buf full? invert assert
buf empty? assert

\ size increases when adding elements
5 ringbuffer: buf 
1 buf enqueue
buf size 1 = assert 
2 buf enqueue
buf size 2 = assert 
buf empty? invert assert
buf full? invert assert

\ size decreases when removing elements
5 ringbuffer: buf 
1 buf enqueue
2 buf enqueue
buf dequeue drop
buf size 1 = assert 
buf dequeue drop
buf size 0 = assert 
buf empty? assert

\ becomes empy again after removing element when it is full
2 ringbuffer: buf 
1 buf enqueue
2 buf enqueue
buf full? assert
buf empty? invert assert
buf dequeue drop
buf dequeue drop
buf empty? assert
buf full? invert assert

\ works as ring buffer
5 ringbuffer: buf 
1 buf enqueue buf dequeue 1 = assert
buf full? invert assert

1 buf enqueue
2 buf enqueue
3 buf enqueue
4 buf enqueue
5 buf enqueue

buf size 5 = assert 
buf full? assert

buf dequeue 1 = assert 
buf dequeue 2 = assert 
buf dequeue 3 = assert 
buf dequeue 4 = assert 
buf dequeue 5 = assert 

buf size 0 = assert 
buf empty? assert

\ over and underflow
2 ringbuffer: buf
: test_underflow ['] dequeue catch EUNDERFLOW = assert ;
buf test_underflow

1 buf enqueue
2 buf enqueue

: test_overflow ['] enqueue catch EOVERFLOW = assert ;
3 buf test_overflow drop

-ringbuf-test
