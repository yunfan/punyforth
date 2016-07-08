-marker: -stream-test

4 stream.new: stream
: test:stream-initially-empty
    stream stream.empty? assert ;

4 stream.new: stream
: test:stream-becomes-non-empty-after-add
    51 stream stream.put-byte
    stream stream.empty? invert assert ;

0 stream.new: stream
: test:stream-with-zero-length-is-both-full-and-empty
    stream stream.full? assert 
    stream stream.empty? assert ;

2 stream.new: stream
: test:stream-full-becomes-empty-after-remove
    1 stream stream.put-byte
    2 stream stream.put-byte
    stream stream.reset
    stream stream.full? assert
    stream stream.next-byte drop
    stream stream.next-byte drop
    stream stream.empty? assert ;

8 stream.new: stream
: test:stream-written-byte-can-be-read-back
    12 stream stream.put-byte
    23 stream stream.put-byte
    34 stream stream.put-byte
    stream stream.reset
    stream stream.next-byte 12 =assert
    stream stream.next-byte 23 =assert
    stream stream.next-byte 34 =assert ;

8 stream.new: stream
: test:stream-can-be-converted-to-buffer
    45 stream stream.put-byte
    87 stream stream.put-byte
    stream stream.buffer 0 + c@ 45 =assert
    stream stream.buffer 1 + c@ 87 =assert ;

0 stream.new: stream
: test:stream-underflow-when-removing-empty
    stream ['] stream.next-byte catch EUNDERFLOW =assert ;

1 stream.new: stream
: test:stream-underflow-when-removing-empty
    1 stream stream.put-byte
    stream ['] stream.put-byte catch EOVERFLOW =assert ;
