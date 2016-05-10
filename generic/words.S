// Predefined words in binary (compiled) forth

defword "nip",3,nip,REGULAR
    .int xt_swap
    .int xt_drop
    .int xt_exit

defword "2drop",5,"drop2",REGULAR
    .int xt_drop
    .int xt_drop
    .int xt_exit

defword "4drop",5,"drop4",REGULAR
    .int xt_drop2
    .int xt_drop2
    .int xt_exit

.ifndef xt_over
defword "over",4,over,REGULAR /* ( a b -- a b a ) */
    .int xt_swap
    .int xt_dup
    .int xt_rot
    .int xt_swap
    .int xt_exit
.endif

defword "2dup",4,dup2,REGULAR
    .int xt_over
    .int xt_over
    .int xt_exit    
    
defword "-rot",4,mrot,REGULAR /*( a b c -- c a b ) */
    .int xt_rot, xt_rot
    .int xt_exit

defword "tuck",4,tuck,REGULAR /* ( a b -- b a b ) */
    .int xt_swap, xt_over
    .int xt_exit

defword "rdup",4,rdup,REGULAR
    .int xt_rpop                                    // because this is a word there is a return address
    .int xt_rpop, xt_dup, xt_rpush, xt_rpush
    .int xt_rpush                                   // keep the return address
    .int xt_exit

defword "r2dup",5,r2dup,REGULAR
    .int xt_rpop                                    // return address
    .int xt_rpop, xt_rpop, xt_dup2
    .int xt_rpush, xt_rpush, xt_rpush, xt_rpush
    .int xt_rpush                                   // restore the return address
    .int xt_exit

defword "rswap",5,rswap,REGULAR                           
    .int xt_rpop                                    // careful about the return address
    .int xt_rpop, xt_rpop, xt_swap
    .int xt_rpush, xt_rpush, xt_rpush
    .int xt_exit

defword "depth",5,depth,REGULAR
    .int xt_btick, _M STACK_ORIG, xt_fetch
    .int xt_spat, xt_minus, xt_dec
    .int xt_cell, xt_divmod, xt_nip
    .int xt_exit

.ifndef xt_gt
defword ">",1,gt,REGULAR
    .int xt_swap, xt_lt
    .int xt_exit
.endif

.ifndef xt_eq
defword "=",1,eq,REGULAR
    .int xt_dup2
    .int xt_lt, xt_invert, xt_mrot
    .int xt_swap, xt_lt, xt_invert, xt_and          // !(a < b) and !(b < a)
    .int xt_exit
.endif

.ifndef xt_gte
defword ">=",2,gte,REGULAR
    .int xt_lt, xt_invert
    .int xt_exit
.endif

.ifndef xt_lte
defword "<=",2,lte,REGULAR
    .int xt_swap, xt_lt, xt_invert
    .int xt_exit
.endif

.ifndef xt_eq0
defword "0=",2,eq0,REGULAR
    .int xt_btick, 0, xt_eq
    .int xt_exit
.endif

.ifndef xt_noteq0
defword "0<>",3,noteq0,REGULAR
    .int xt_btick, 0, xt_noteq
    .int xt_exit
.endif

.ifndef xt_eq1
defword "1=",2,eq1,REGULAR
    .int xt_btick, 1, xt_eq
    .int xt_exit
.endif

.ifndef xt_lt0
defword "0<",2,lt0,REGULAR
    .int xt_btick, 0, xt_lt
    .int xt_exit
.endif

.ifndef xt_gt0
defword "0>",2,gt0,REGULAR
    .int xt_btick, 0, xt_gt
    .int xt_exit
.endif

.ifndef xt_inc
defword "1+",2,inc,REGULAR
    .int xt_btick, 1, xt_plus
    .int xt_exit
.endif

.ifndef xt_dec
defword "1-",2,dec,REGULAR
    .int xt_btick, 1, xt_minus
    .int xt_exit
.endif

defword "cells",5,cells,REGULAR
    .int xt_cell, xt_multiply
    .int xt_exit
   
defword "cell",4,cell,REGULAR
    .int xt_btick, CELLS
    .int xt_exit

defword ",",1,comma,REGULAR
    .int xt_here, xt_store
    .int xt_here, xt_cell, xt_plus    
    .int xt_var_dp, xt_store   
    .int xt_exit

defword "c,",2,commabyte,REGULAR
    .int xt_dp, xt_storebyte
    .int xt_dp, xt_inc 
    .int xt_var_dp, xt_store   
    .int xt_exit

.ifndef xt_fetchbyte
defword "c@",2,fetchbyte,REGULAR
    .int xt_fetch, xt_btick, 255, xt_and
    .int xt_exit
.endif

.ifndef xt_noteq
defword "<>",2,noteq,REGULAR
    .int xt_eq, xt_invert
    .int xt_exit
.endif

defword ">in",3,toin,REGULAR
    .int xt_btick, _M input_index
    .int xt_exit
    
defword "#tib",4,inputlen,REGULAR
    .int xt_btick, _M input_size
    .int xt_exit

defword "tib",3,tib,REGULAR
    .int xt_btick, _M input_buffer
    .int xt_exit

defword "state",5,state,REGULAR
    .int xt_btick, _M state_var
    .int xt_exit

defword "[",1,openbracket,IMMEDIATE
    .int xt_btick, STATE_INTERPRET, xt_btick, state_var, xt_store
    .int xt_exit
    
defword "]",1,closebracket,REGULAR
    .int xt_btick, STATE_COMPILE, xt_btick, state_var, xt_store
    .int xt_exit    

defword "literal",7,literal,IMMEDIATE
    .int xt_btick, xt_btick, xt_comma
    .int xt_comma
    .int xt_exit

defword "compare",7,compare,REGULAR /*( a1 len1 a2 len2 - bool ) */
    .int xt_rot, xt_swap                                                          // (a1 a2 len1 len2)
    .int xt_dup2, xt_eq, xt_branch0 
    lbl compare_length_mismatch
    .int xt_drop                                                                  // both lengths are equal, leave only one of them  (a1 a2 len)
compare_next_char:   
    .int xt_dup, xt_branch0
    lbl compare_equal
    .int xt_mrot                                                                  // (len a1 a2)
    .int xt_dup2                                                                  // (len a1 a2 a1 a2)
    .int xt_fetchbyte, xt_swap, xt_fetchbyte, xt_eq                               // check if next characters are equal
    .int xt_branch0
    lbl compare_not_equal
    .int xt_inc, xt_swap, xt_inc, xt_swap
    .int xt_rot
    .int xt_dec
    .int xt_branch
    lbl compare_next_char
compare_equal:    
    .int xt_drop, xt_drop, xt_drop
    .int xt_btick, TRUE
    .int xt_exit
compare_not_equal:
    .int xt_drop, xt_drop, xt_drop
    .int xt_btick, FALSE
    .int xt_exit
compare_length_mismatch:    
    .int xt_drop, xt_drop, xt_drop, xt_drop
    .int xt_btick, FALSE
    .int xt_exit

defword "find",4,find,REGULAR /* ( a len -- xt mode | 0 ) */
    .int xt_lastword
find_try_next_word:                                                               // (a1 len1 link)    
    .int xt_dup
    .int xt_branch0
    lbl find_not_found
    .int xt_dup, xt_swap2, xt_rot                                                 // (link a1 len1 link)
    .int xt_dup
    .int xt_link2len, xt_swap 
    .int xt_link2name, xt_swap                                                    // (link a1 len1 a2 len2)
    .int xt_over2                                                                 // (link a1 len1 a2 len2 a1 len1)
    .int xt_compare, xt_invert                                                    // (link a1 len1 bool)    
    .int xt_branch0
    lbl find_found
    .int xt_rot                                                                   // (a1 len1 link)
    .int xt_fetch
    .int xt_branch
    lbl find_try_next_word
find_found:                                                         // found matching word, return its mode and xt
    .int xt_drop, xt_drop                                           // ( link )
    .int xt_dup, xt_link2xt 
    .int xt_swap, xt_link2flags                                     // ( xt flags )
    .int xt_exit
find_not_found:
    .int xt_drop, xt_drop, xt_drop
    .int xt_btick, 0
    .int xt_exit

defword "align",5,align,REGULAR
    .int xt_btick, 3, xt_plus, xt_btick, 3, xt_invert, xt_and
    .int xt_exit

defword "here",4,here,REGULAR
    .int xt_dp, xt_align
    .int xt_exit
    
defword "dp",2,dp,REGULAR
    .int xt_var_dp, xt_fetch
    .int xt_exit

defword "var-dp",6,var_dp,REGULAR
    .int xt_btick, _M var_dp
    .int xt_exit

defword "freemem",7,freemem,REGULAR
    .int xt_btick, _M end_dictionary, xt_dp, xt_minus
    .int xt_exit

defword "allot",5,allot,REGULAR /* ( n -- ) */
    .int xt_here, xt_plus, xt_align, xt_var_dp, xt_store
    .int xt_exit
    
defword "createheader",12,createheader,REGULAR
    .int xt_word, xt_swap
    .int xt_btick, _M LAST_WORD, xt_fetch, xt_comma                        // store link to previous word
    .int xt_here, xt_cell, xt_minus, xt_btick, _M LAST_WORD, xt_store      // update last word
    .int xt_swap, xt_dup, xt_btick, _M REGULAR, xt_or, xt_commabyte        // write length + flags
create_write_next_char:    
    .int xt_dup, xt_branch0
    lbl create_name_done
    .int xt_swap, xt_dup, xt_fetchbyte, xt_commabyte
    .int xt_inc                                                            // increment name address
    .int xt_swap, xt_dec                                                   // decrement length
    .int xt_branch
    lbl create_write_next_char
create_name_done:
    .int xt_drop, xt_drop
    .int xt_here, xt_var_dp, xt_store                                      // align after name
    .int xt_exit

defword ";",1,semicolon,IMMEDIATE
    .int xt_openbracket
    .int xt_btick, xt_exit, xt_comma
    .int xt_exit

defword ">number",7,tonumber,REGULAR /* ( a len -- num bool ) */
    .int xt_dup, xt_branch0
    lbl tonum_empty 
    .int xt_swap, xt_dup, xt_fetchbyte, xt_btick, 45, xt_eq                       // check sign
    .int xt_branch0
    lbl tonum_positive
    .int xt_swap
    .int xt_dec                                                                   // decrement length
    .int xt_dup, xt_rpush                                                         // move length to return stack
    .int xt_plus                                                                  // move to the last char of the number string
    .int xt_btick, 0                                                                
    .int xt_btick, -1                                                             // ( a res mul )
    .int xt_rpop, xt_dec, xt_rpush                                                // decrement length once more because of the negative sign
    .int xt_branch
    lbl tonum_loop
tonum_positive:
    .int xt_swap
    .int xt_dec                                                                   // decrement length
    .int xt_dup, xt_rpush                                                         // move length to return stack
    .int xt_plus                                                                  // move to the last char of the number string
    .int xt_btick, 0                                                                
    .int xt_btick, 1                                                              // ( a res mul )
tonum_loop:    
    .int xt_rot                                                                   // ( res mul a ) 
    .int xt_dup, xt_fetchbyte
    .int xt_dup, xt_btick, 47, xt_gt, xt_branch0                                  // check range
    lbl tonum_invalid_digit
    .int xt_dup, xt_btick, 58, xt_lt, xt_branch0
    lbl tonum_invalid_digit
    .int xt_btick, 48, xt_minus                                                   // ( res mul a digit )
    .int xt_swap, xt_dec, xt_swap                                                 // decrement a
    .int xt_swap2                                                                 // ( a digit res mul )
    .int xt_rot                                                                   // ( a res mul digit)
    .int xt_over                                                                  // ( a res mul digit mul )
    .int xt_multiply                                                              // ( a res mul digit*mul )
    .int xt_rot                                                                   // ( a mul digit*mul res )
    .int xt_plus                                                                  // ( a mul res )
    .int xt_swap, xt_btick, 10, xt_multiply                                       // ( a res mul )
    .int xt_rdup, xt_rpop, xt_branch0
    lbl tonum_done
    .int xt_rpop, xt_dec, xt_rpush                                                // decrement length on return stack    
    .int xt_branch
    lbl tonum_loop
tonum_done:
    .int xt_rpop, xt_drop
    .int xt_drop, xt_nip
    .int xt_btick, TRUE
    .int xt_exit
tonum_invalid_digit:
    .int xt_rpop, xt_drop4, xt_drop
    .int xt_btick, FALSE
    .int xt_exit
tonum_empty:
    .int xt_drop2
    .int xt_btick, FALSE
    .int xt_exit

defword "word",4,word,REGULAR /* ( -- a len ) */
    .int xt_btick, 0
word_trim:
    .int xt_drop
    .int xt_key
    .int xt_dup, xt_btick, 32, xt_noteq, xt_branch0
    lbl word_trim
    .int xt_dup, xt_btick, 10, xt_noteq, xt_branch0
    lbl word_trim
    .int xt_dup, xt_btick, 13, xt_noteq, xt_branch0
    lbl word_trim
    .int xt_dup, xt_btick, 9, xt_noteq, xt_branch0
    lbl word_trim
    .int xt_drop
    .int xt_toin, xt_fetch, xt_dec                                               // word start
    .int xt_btick, 0
word_next_char:
    .int xt_drop
    .int xt_key
    .int xt_dup, xt_btick, 32, xt_noteq, xt_branch0
    lbl word_boundary
    .int xt_dup, xt_btick, 10, xt_noteq, xt_branch0
    lbl word_boundary
    .int xt_dup, xt_btick, 13, xt_noteq, xt_branch0
    lbl word_boundary
    .int xt_dup, xt_btick, 19, xt_noteq, xt_branch0
    lbl word_boundary
    .int xt_branch
    lbl word_next_char
word_boundary:
    .int xt_drop
    .int xt_dup, xt_toin, xt_fetch, xt_swap, xt_minus, xt_dec                    // word length
    .int xt_exit

defword ":",1,colon,REGULAR
    .int xt_closebracket 
    .int xt_createheader
    .int xt_btick, _M ENTERCOL, xt_comma                                         // codeword is ENTERCOL
    .int xt_exit

defword "char",4,char,REGULAR
    .int xt_word, xt_drop, xt_fetchbyte
    .int xt_exit

.ifndef xt_type
defword "type",4,type,REGULAR            // ( zstring -- )
type_next_char:
    .int xt_dup, xt_fetchbyte, xt_eq0, xt_invert, xt_branch0
    lbl type_done
    .int xt_dup, xt_fetchbyte, xt_emit
    .int xt_inc
    .int xt_branch
    lbl type_next_char
type_done:
    .int xt_drop
    .int xt_exit
.endif    

.ifndef xt_typecounted
defword "type-counted",12,typecounted,REGULAR            // ( addr count -- )
type_counted_next_char:
    .int xt_dup, xt_branch0
    lbl type_counted_done
    .int xt_dec
    .int xt_swap, xt_dup
    .int xt_fetchbyte, xt_emit
    .int xt_inc
    .int xt_swap
    .int xt_branch
    lbl type_counted_next_char
type_counted_done:
    .int xt_drop2
    .int xt_exit
.endif    

defword "chr>in",6,char_toin,REGULAR /* (chr -- ) */
    .int xt_inputlen, xt_fetch, xt_btick, INPUT_BUFFER_SIZE, xt_lt, xt_branch0
    lbl inbuf_overflow
    .int xt_toin, xt_fetch, xt_storebyte                          // store one char in inputbuffer
    .int xt_toin, xt_fetch, xt_inc, xt_toin, xt_store             // increment input index
    .int xt_inputlen, xt_fetch, xt_inc, xt_inputlen, xt_store     // incrment input size
    .int xt_exit
inbuf_overflow:
    .int xt_btick, _M inbuf_overflow_error, xt_type
    .int xt_abort

defword "in>char",7,char_fromin,REGULAR /* ( -- chr ) */
    .int xt_toin, xt_fetch, xt_fetchbyte                          // fetch next character from inputbuffer
    .int xt_toin, xt_fetch, xt_inc, xt_toin, xt_store             // increment input index
    .int xt_exit

defword "prompt",6,prompt,REGULAR
    .int xt_btick, _M var_prompt_xt
    .int xt_exit

defword "show_prompt",11,show_prompt,REGULAR
    .int xt_prompt, xt_fetch, xt_dup
    .int xt_branch0
    lbl show_default_prompt
    .int xt_execute
    .int xt_exit
show_default_prompt:
    .int xt_drop
    .int xt_btick, _M prompt_str, xt_type
    .int xt_exit

defword "key",3,key,REGULAR
    .int xt_tib, xt_inputlen, xt_fetch, xt_plus
    .int xt_toin, xt_fetch, xt_swap, xt_gte   
    .int xt_branch0
    lbl read_one_char_from_buffer    
    .int xt_btick, 0, xt_inputlen, xt_store                                        // reset inputlen
    .int xt_tib, xt_toin, xt_store                                                 // reset inputbuffer
    .int xt_show_prompt
refill_buffer:
    .int xt_readchar, xt_dup, xt_char_toin
    .int xt_btick, 10, xt_eq, xt_branch0
    lbl refill_buffer
    .int xt_tib, xt_toin, xt_store
read_one_char_from_buffer:
    .int xt_char_fromin
    .int xt_exit

defword "compile_time_only",17,compile_time_only,REGULAR    
    .int xt_state, xt_fetch, xt_btick, STATE_COMPILE, xt_eq
    .int xt_branch0
    lbl cannot_interpret_compile_only_word
    .int xt_exit
cannot_interpret_compile_only_word:
    .int xt_btick, _M compile_only_warning, xt_type
    .int xt_exit

defword "var-lastword",12,var_lastword,REGULAR
    .int xt_btick, _M LAST_WORD
    .int xt_exit

defword "lastword",8,lastword,REGULAR
    .int xt_var_lastword, xt_fetch
    .int xt_exit

defword "enterdoes",9,enterdoes,REGULAR
    .int xt_btick, _M ENTERDOES 
    .int xt_exit

defword "link>flb",8,link2flb,REGULAR /* ( a1 -- a2 ) */
    .int xt_cell, xt_plus
    .int xt_exit

defword "link>len",8,link2len,REGULAR /* ( a1 -- len ) */
    .int xt_link2flb, xt_fetchbyte, xt_btick, 0b00111111, xt_and
    .int xt_exit

defword "link>flags",10,link2flags,REGULAR /* ( a1 -- flags ) */
    .int xt_link2flb, xt_fetchbyte, xt_btick, 0b11000000, xt_and
    .int xt_exit

defword "link>name",9,link2name,REGULAR /* ( a1 -- a2 ) */
    .int xt_cell, xt_plus, xt_inc 
    .int xt_exit

defword "link>xt",7,link2xt,REGULAR /* ( a1 -- a2 ) */
    .int xt_dup, xt_link2name, xt_swap
    .int xt_link2len, xt_plus, xt_align
    .int xt_exit

defword "link>body",9,link2body,REGULAR /* ( a1 -- a2 ) */
    .int xt_link2xt, xt_cell, xt_plus
    .int xt_exit

FINAL_WORD:    
defword "immediate",9,immediate,REGULAR
    .int xt_btick, IMMEDIATE, xt_lastword, xt_link2len, xt_or
    .int xt_lastword, xt_link2flb, xt_storebyte
    .int xt_exit

