// Predefined words in binary (compiled) forth

defword "nip",3,nip,1
    .int xt_swap
    .int xt_drop
    .int xt_exit

.ifndef xt_over
defword "over",4,over,1 /* ( a b -- a b a ) */
    .int xt_swap
    .int xt_dup
    .int xt_rot
    .int xt_swap
    .int xt_exit
.endif

defword "2dup",4,dup2,1
    .int xt_over
    .int xt_over
    .int xt_exit    
    
defword "-rot",4,mrot,1 /*( a b c -- c a b ) */
    .int xt_rot, xt_rot
    .int xt_exit

defword "tuck",4,tuck,1 /* ( a b -- b a b ) */
    .int xt_swap, xt_over
    .int xt_exit

defword "rdup",4,rdup,1
    .int xt_rpop                                    // because this is a word there is a return address
    .int xt_rpop, xt_dup, xt_rpush, xt_rpush
    .int xt_rpush                                   // keep the return address
    .int xt_exit

defword "r2dup",5,r2dup,1
    .int xt_rpop                                    // return address
    .int xt_rpop, xt_rpop, xt_dup2
    .int xt_rpush, xt_rpush, xt_rpush, xt_rpush
    .int xt_rpush                                   // restore the return address
    .int xt_exit

defword "rswap",5,rswap,1                           
    .int xt_rpop                                    // careful about the return address
    .int xt_rpop, xt_rpop, xt_swap
    .int xt_rpush, xt_rpush, xt_rpush
    .int xt_exit

defword "depth",5,depth,1
    .int xt_btick, OFFSET FLAT:STACK_ORIG, xt_fetch
    .int xt_spat, xt_minus
    .int xt_btick, 36, xt_plus
    .int xt_cell, xt_divmod, xt_nip
    .int xt_exit

.ifndef xt_gt
defword ">",1,gt,1
    .int xt_swap, xt_lt
    .int xt_exit
.endif

.ifndef xt_eq
defword "=",1,eq,1
    .int xt_dup2
    .int xt_lt, xt_invert, xt_mrot
    .int xt_swap, xt_lt, xt_invert, xt_and          // !(a < b) and !(b < a)
    .int xt_exit
.endif

.ifndef xt_gte
defword ">=",2,gte,1
    .int xt_lt, xt_invert
    .int xt_exit
.endif

.ifndef xt_lte
defword "<=",2,lte,1
    .int xt_swap, xt_lt, xt_invert
    .int xt_exit
.endif

defword "cells",5,cells,1
    .int xt_cell, xt_multiply
    .int xt_exit
   
defword "cell",4,cell,1
    .int xt_btick, CELLS
    .int xt_exit

defword ",",1,comma,1
    .int xt_here, xt_store
    .int xt_here, xt_cell, xt_plus    
    .int xt_btick, OFFSET FLAT:here_var, xt_store   
    .int xt_exit

defword "c,",2,commabyte,1
    .int xt_here, xt_store
    .int xt_here, xt_btick, 1, xt_plus    
    .int xt_btick, OFFSET FLAT:here_var, xt_store   
    .int xt_exit

defword "c@",2,fetchbyte,1
    .int xt_fetch, xt_btick, 255, xt_and
    .int xt_exit

defword "<>",2,noteq,1
    .int xt_eq, xt_invert
    .int xt_exit
    
defword ">in",3,inputbuf,1
    .int xt_btick, OFFSET FLAT:input_buffer
    .int xt_exit
    
defword "#tib",4,inputlen,1
    .int xt_btick, OFFSET FLAT:input_size
    .int xt_exit

defword "tib",3,tib,1
    .int xt_btick, OFFSET FLAT:input_index
    .int xt_exit

defword "state",5,state,1
    .int xt_btick, OFFSET FLAT:state_var
    .int xt_exit

defword "[",1,openbracket,IMMEDIATE
    .int xt_btick, STATE_INTERPRET, xt_btick, state_var, xt_store
    .int xt_exit
    
defword "]",1,closebracket,1
    .int xt_btick, STATE_COMPILE, xt_btick, state_var, xt_store
    .int xt_exit    

defword "literal",7,literal,IMMEDIATE
    .int xt_btick, xt_btick, xt_comma
    .int xt_comma
    .int xt_exit

defword "compare",7,compare,1 /*( a1 len1 a2 len2 - bool ) */
    .int xt_rot, xt_swap                                                          // (a1 a2 len1 len2)
    .int xt_dup2, xt_eq, xt_branch0
    .int compare_length_mismatch - . - CELLS
    .int xt_drop                                                                  // both lengths are equal, leave only one of them  (a1 a2 len)
compare_next_char:   
    .int xt_dup, xt_branch0
    .int compare_equal - . - CELLS
    .int xt_mrot                                                                  // (len a1 a2)
    .int xt_dup2                                                                  // (len a1 a2 a1 a2)
    .int xt_fetchbyte, xt_swap, xt_fetchbyte, xt_eq                               // check if next characters are equal
    .int xt_branch0
    .int compare_not_equal - . - CELLS
    .int xt_btick, 1, xt_plus, xt_swap, xt_btick, 1, xt_plus, xt_swap
    .int xt_rot
    .int xt_btick, 1, xt_minus
    .int xt_branch
    .int compare_next_char - . - CELLS
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

defword "find",4,find,1 /* ( len a -- xt, mode or 0 ) */
    .int xt_swap
    .int xt_lastword
find_try_next_word:                                                               // (a1 len1 link)    
    .int xt_dup
    .int xt_branch0
    .int find_not_found - . - CELLS
    .int xt_dup, xt_swap2, xt_rot                                                 // (link a1 len1 link)
    .int xt_cell, xt_plus                                                       
    .int xt_dup, xt_fetch, xt_swap
    .int xt_cell, xt_plus, xt_swap                                                // (link a1 len1 a2 len2)
    .int xt_over2                                                                 // (link a1 len1 a2 len2 a1 len1)
    .int xt_compare, xt_invert                                                    // (link a1 len1 bool)    
    .int xt_branch0
    .int find_found - . - CELLS
    .int xt_rot                                                                   // (a1 len1 link)
    .int xt_fetch
    .int xt_branch
    .int find_try_next_word - . - CELLS
find_found:                                                                     // found matching word, return its mode and xt
    .int xt_nip                                                                   // (link len)
    .int xt_plus, xt_btick, 2, xt_cells, xt_plus
    .int xt_dup, xt_fetch, xt_swap, xt_cell, xt_plus
    .int xt_swap                                                                  // (xt, mode)
    .int xt_exit
find_not_found:
    .int xt_drop, xt_drop, xt_drop
    .int xt_btick, 0
    .int xt_exit

defword "here",4,here,1
    .int xt_btick, OFFSET FLAT:here_var, xt_fetch
    .int xt_exit
    
defword "allot",5,allot,1
    .int xt_here
    .int xt_swap, xt_here, xt_plus, xt_btick, OFFSET FLAT:here_var, xt_store
    .int xt_exit
    
defword "create",6,create,1
    .int xt_word
    .int xt_btick, OFFSET FLAT:LAST_WORD, xt_fetch, xt_comma                        // store link to previous word
    .int xt_here, xt_cell, xt_minus, xt_btick, OFFSET FLAT:LAST_WORD, xt_store      // update last word
    .int xt_swap, xt_dup, xt_comma                                                  // write length
create_write_next_char:    
    .int xt_dup, xt_branch0
    .int create_name_done - . - CELLS
    .int xt_swap, xt_dup, xt_fetchbyte, xt_here, xt_storebyte
    .int xt_here, xt_btick, 1, xt_plus, xt_btick, OFFSET FLAT:here_var, xt_store
    .int xt_btick, 1, xt_plus                                                       // increment name address
    .int xt_swap, xt_btick, 1, xt_minus                                             // decrement length
    .int xt_branch
    .int create_write_next_char - . - CELLS
create_name_done:
    .int xt_drop, xt_drop
    .int xt_btick, 1, xt_comma                                                      // write mode
    .int xt_btick, OFFSET FLAT:ENTERCOL, xt_comma                                   // write codeword
    .int xt_exit

defword ";",1,semicolon,IMMEDIATE
    .int xt_openbracket
    .int xt_btick, xt_exit, xt_comma
    .int xt_exit

defword ">number",7,tonumber,1                                                    //( len a -- num bool )
    .int xt_swap                                                                  
    .int xt_dup, xt_branch0
    .int tonum_empty - . - CELLS
    .int xt_swap, xt_dup, xt_fetchbyte, xt_btick, 45, xt_eq                       // check sign
    .int xt_branch0
    .int tonum_positive - . - CELLS
    .int xt_swap
    .int xt_btick, 1, xt_minus                                                    // decrement length
    .int xt_dup, xt_rpush                                                         // move length to return stack
    .int xt_plus                                                                  // move to the last char of the number string
    .int xt_btick, 0                                                                
    .int xt_btick, -1                                                             // ( a res mul )
    .int xt_rpop, xt_btick, 1, xt_minus, xt_rpush                                 // decrement length once more because of the negative sign
    .int xt_branch
    .int tonum_loop - . - CELLS    
tonum_positive:
    .int xt_swap
    .int xt_btick, 1, xt_minus                                                    // decrement length
    .int xt_dup, xt_rpush                                                         // move length to return stack
    .int xt_plus                                                                  // move to the last char of the number string
    .int xt_btick, 0                                                                
    .int xt_btick, 1                                                              // ( a res mul )
tonum_loop:    
    .int xt_rot                                                                   // ( res mul a ) 
    .int xt_dup, xt_fetchbyte
    .int xt_dup, xt_btick, 47, xt_gt, xt_branch0                                  // check range
    .int tonum_invalid_digit - . - CELLS
    .int xt_dup, xt_btick, 58, xt_lt, xt_branch0
    .int tonum_invalid_digit - . - CELLS
    .int xt_btick, 48, xt_minus                                                   // ( res mul a digit )
    .int xt_swap, xt_btick, 1, xt_minus, xt_swap                                  // decrement a
    .int xt_swap2                                                                 // ( a digit res mul )
    .int xt_rot                                                                   // ( a res mul digit)
    .int xt_over                                                                  // ( a res mul digit mul )
    .int xt_multiply                                                              // ( a res mul digit*mul )
    .int xt_rot                                                                   // ( a mul digit*mul res )
    .int xt_plus                                                                  // ( a mul res )
    .int xt_swap, xt_btick, 10, xt_multiply                                       // ( a res mul )
    .int xt_rdup, xt_rpop, xt_branch0
    .int tonum_done - . - CELLS
    .int xt_rpop, xt_btick, 1, xt_minus, xt_rpush                                 // decrement length on return stack    
    .int xt_branch
    .int tonum_loop - . - CELLS
tonum_done:
    .int xt_rpop, xt_drop
    .int xt_drop, xt_nip
    .int xt_btick, TRUE
    .int xt_exit
tonum_invalid_digit:                                                            // TODO emit string
    .int xt_tib, xt_fetch, xt_btick, 20, xt_type
    .int xt_rpop, xt_drop
    .int xt_drop, xt_drop
    .int xt_btick, FALSE
    .int xt_exit
tonum_empty:
    .int xt_drop
    .int xt_btick, FALSE
    .int xt_exit

defword "word",4,word,1
    .int xt_btick, 0
word_trim:
    .int xt_drop
    .int xt_key
    .int xt_dup, xt_btick, 32, xt_noteq, xt_branch0
    .int word_trim - . - CELLS
    .int xt_dup, xt_btick, 10, xt_noteq, xt_branch0
    .int word_trim - . - CELLS
    .int xt_dup, xt_btick, 13, xt_noteq, xt_branch0
    .int word_trim - . - CELLS
    .int xt_dup, xt_btick, 9, xt_noteq, xt_branch0
    .int word_trim - . - CELLS
    .int xt_drop
    .int xt_tib, xt_fetch, xt_btick, 1, xt_minus                                    // word start
    .int xt_btick, 0
word_next_char:
    .int xt_drop
    .int xt_key
    .int xt_dup, xt_btick, 32, xt_noteq, xt_branch0
    .int word_boundary - . - CELLS
    .int xt_dup, xt_btick, 10, xt_noteq, xt_branch0
    .int word_boundary - . - CELLS
    .int xt_dup, xt_btick, 13, xt_noteq, xt_branch0
    .int word_boundary - . - CELLS
    .int xt_dup, xt_btick, 19, xt_noteq, xt_branch0
    .int word_boundary - . - CELLS
    .int xt_branch
    .int word_next_char - . - CELLS
word_boundary:
    .int xt_drop
    .int xt_dup, xt_tib, xt_fetch, xt_swap, xt_minus, xt_btick, 1, xt_minus         // word length
    .int xt_swap
    .int xt_exit

defword ":",1,colon,1
    .int xt_closebracket 
    .int xt_create
    .int xt_exit

defword "char",4,char,1
    .int xt_word, xt_nip, xt_fetchbyte
    .int xt_exit

defword "compile_time_only",17,compile_time_only,1    
    .int xt_state, xt_fetch, xt_btick, STATE_COMPILE, xt_eq
    .int xt_branch0
    .int cannot_interpret_compile_only_word - . - CELLS
    .int xt_exit
cannot_interpret_compile_only_word:
    .int xt_btick, OFFSET FLAT:compile_only_warning, xt_btick, 63, xt_type
    .int xt_exit

defword "lastword",8,lastword,1
    .int xt_btick, OFFSET FLAT:LAST_WORD, xt_fetch
    .int xt_exit

defword "enterdoes",9,enterdoes,1
    .int xt_btick, OFFSET FLAT:ENTERDOES 
    .int xt_exit

FINAL_WORD:    
defword "immediate",9,immediate,1
    .int xt_lastword, xt_cell, xt_plus
    .int xt_dup, xt_fetch, xt_plus                                                // add name length
    .int xt_cell, xt_plus
    .int xt_btick, IMMEDIATE, xt_swap, xt_store
    .int xt_exit
   
