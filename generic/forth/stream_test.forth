-marker: -stream-test

: test:stream-initially-empty
    4 stream.new stream.empty? assert ;

: test:stream-becomes-non-empty-after-add
    4 stream.new
    51 over stream.put-byte
    stream.empty? invert assert ;

: test:stream-with-zero-length-is-both-full-and-empty
    0 stream.new stream.full? assert 
    0 stream.new stream.empty? assert ;

: test:stream-full-becomes-empty-after-remove
    2 stream.new
    1 over stream.put-byte
    2 over stream.put-byte
    dup stream.reset
    dup stream.full? assert
    dup stream.next-byte drop
    dup stream.next-byte drop
        stream.empty? assert ;

: test:stream-written-byte-can-be-read-back
    8 stream.new
    12 over stream.put-byte
    23 over stream.put-byte
    34 over stream.put-byte
    dup stream.reset
    dup stream.next-byte 12 =assert
    dup stream.next-byte 23 =assert
        stream.next-byte 34 =assert ;

: test:stream-can-be-converted-to-buffer
    8 stream.new
    45 over stream.put-byte
    87 over stream.put-byte
    dup stream.buffer 0 + c@ 45 =assert
        stream.buffer 1 + c@ 87 =assert ;

: test:stream-underflow-when-removing-empty
    0 stream.new
    ['] stream.next-byte catch EUNDERFLOW =assert ;

: test:stream-underflow-when-removing-empty
    1 stream.new
    1 over stream.put-byte
    ['] stream.put-byte catch EOVERFLOW =assert ;
