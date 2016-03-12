// Predefined words in binary (compiled) forth

defword "nip",3,nip,1
    .int xt_swap
    .int xt_drop
    .int xt_exit
    
defword "2dup",4,dup2,1
    .int xt_over
    .int xt_over
    .int xt_exit    
    
defword "-rot",4,mrot,1                                                           //  ( a b c -- c a b )
    .int xt_rot, xt_rot
    .int xt_exit
    
defword "cells",5,cells,1
    .int xt_lit, CELLS, xt_multiply
    .int xt_exit
    
defword "<>",2,noteq,1
    .int xt_eq, xt_invert
    .int xt_exit
    
defword ">in",3,inputbuf,1
    .int xt_lit, OFFSET FLAT:input_buffer
    .int xt_exit
    
defword "#tib",4,inputlen,1
    .int xt_lit, OFFSET FLAT:input_size
    .int xt_exit

defword "tib",3,tib,1
    .int xt_lit, OFFSET FLAT:input_index
    .int xt_exit

defword "state",5,state,1
    .int xt_lit, OFFSET FLAT:state_var
    .int xt_exit

defword "[",1,openbracket,IMMEDIATE
    .int xt_lit, STATE_INTERPRET, xt_lit, state_var, xt_store
    .int xt_exit
    
defword "]",1,closebracket,1
    .int xt_lit, STATE_COMPILE, xt_lit, state_var, xt_store
    .int xt_exit    

defword "compare",7,compare,1                                                     // ( a1 len1 a2 len2 - bool )
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
    .int xt_lit, 1, xt_plus, xt_swap, xt_lit, 1, xt_plus, xt_swap
    .int xt_rot
    .int xt_lit, 1, xt_minus
    .int xt_branch
    .int compare_next_char - . - CELLS
compare_equal:    
    .int xt_drop, xt_drop, xt_drop
    .int xt_lit, TRUE
    .int xt_exit
compare_not_equal:
    .int xt_drop, xt_drop, xt_drop
    .int xt_lit, FALSE
    .int xt_exit
compare_length_mismatch:    
    .int xt_drop, xt_drop, xt_drop, xt_drop
    .int xt_lit, FALSE
    .int xt_exit

defword "find",4,find,1                                                          // ( len a -- xt, mode or 0 )                            
    .int xt_swap
    .int xt_lastword
find_try_next_word:                                                             // (a1 len1 link)    
    .int xt_dup
    .int xt_branch0
    .int find_not_found - . - CELLS
    .int xt_dup, xt_swap2, xt_rot                                                 // (link a1 len1 link)
    .int xt_lit, 1, xt_cells, xt_plus                                                       
    .int xt_dup, xt_fetch, xt_swap
    .int xt_lit, 1, xt_cells, xt_plus, xt_swap                                    // (link a1 len1 a2 len2)
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
    .int xt_plus, xt_lit, 2, xt_cells, xt_plus
    .int xt_dup, xt_fetch, xt_swap, xt_lit, 1, xt_cells, xt_plus
    .int xt_swap                                                                  // (xt, mode)
    .int xt_exit
find_not_found:
    .int xt_drop, xt_drop, xt_drop
    .int xt_lit, 0
    .int xt_exit

defword "here",4,here,1
    .int xt_lit, OFFSET FLAT:here_var, xt_fetch
    .int xt_exit
    
defword "allot",5,allot,1
    .int xt_here, xt_plus, xt_lit, OFFSET FLAT:here_var, xt_store
    .int xt_exit
    
defword "create",6,create,1
    .int xt_word
    .int xt_lit, OFFSET FLAT:LAST_WORD, xt_fetch, xt_comma                        // store link to previous word
    .int xt_here, xt_lit, 1, xt_cells, xt_minus, xt_lit, OFFSET FLAT:LAST_WORD, xt_store      // update last word
    .int xt_swap, xt_dup, xt_comma                                                // write length
create_write_next_char:    
    .int xt_dup, xt_branch0
    .int create_name_done - . - CELLS
    .int xt_swap, xt_dup, xt_fetchbyte, xt_here, xt_storebyte
    .int xt_here, xt_lit, 1, xt_plus, xt_lit, OFFSET FLAT:here_var, xt_store
    .int xt_lit, 1, xt_plus                                                       // increment name address
    .int xt_swap, xt_lit, 1, xt_minus                                             // decrement length
    .int xt_branch
    .int create_write_next_char - . - CELLS
create_name_done:
    .int xt_drop, xt_drop
    .int xt_lit, 1, xt_comma                                                      // write mode
    .int xt_lit, OFFSET FLAT:ENTERCOL, xt_comma                                   // write codeword
    .int xt_exit

defword ";",1,semicolon,IMMEDIATE
    .int xt_lit, STATE_INTERPRET, xt_lit, state_var, xt_store
    .int xt_lit, xt_exit, xt_comma
    .int xt_exit

defword "variable",8,variable,1
    .int xt_lit, 1, xt_cells, xt_allot
    .int xt_create
    .int xt_literal
    .int xt_lit, xt_exit, xt_comma
    .int xt_exit

defword ">number",7,tonumber,1                                                    //( len a -- num bool )
    .int xt_swap                                                                  
    .int xt_dup, xt_branch0
    .int tonum_empty - . - CELLS
    .int xt_swap, xt_dup, xt_fetchbyte, xt_lit, 45, xt_eq                         // check sign
    .int xt_branch0
    .int tonum_positive - . - CELLS
    .int xt_swap
    .int xt_lit, 1, xt_minus                                                      // decrement length
    .int xt_dup, xt_rpush                                                         // move length to return stack
    .int xt_plus                                                                  // move to the last char of the number string
    .int xt_lit, 0                                                                
    .int xt_lit, -1                                                               // ( a res mul )
    .int xt_rpop, xt_lit, 1, xt_minus, xt_rpush                                   // decrement length once more because of the negative sign
    .int xt_branch
    .int tonum_loop - . - CELLS    
tonum_positive:
    .int xt_swap
    .int xt_lit, 1, xt_minus                                                      // decrement length
    .int xt_dup, xt_rpush                                                         // move length to return stack
    .int xt_plus                                                                  // move to the last char of the number string
    .int xt_lit, 0                                                                
    .int xt_lit, 1                                                                // ( a res mul )
tonum_loop:    
    .int xt_rot                                                                   // ( res mul a ) 
    .int xt_dup, xt_fetchbyte
    .int xt_dup, xt_lit, 47, xt_gt, xt_branch0                                    // check range
    .int tonum_invalid_digit - . - CELLS
    .int xt_dup, xt_lit, 58, xt_lt, xt_branch0
    .int tonum_invalid_digit - . - CELLS
    .int xt_lit, 48, xt_minus                                                     // ( res mul a digit )
    .int xt_swap, xt_lit, 1, xt_minus, xt_swap                                    // decrement a
    .int xt_swap2                                                                 // ( a digit res mul )
    .int xt_rot                                                                   // ( a res mul digit)
    .int xt_over                                                                  // ( a res mul digit mul )
    .int xt_multiply                                                              // ( a res mul digit*mul )
    .int xt_rot                                                                   // ( a mul digit*mul res )
    .int xt_plus                                                                  // ( a mul res )
    .int xt_swap, xt_lit, 10, xt_multiply                                         // ( a res mul )
    .int xt_rdup, xt_rpop, xt_branch0
    .int tonum_done - . - CELLS
    .int xt_rpop, xt_lit, 1, xt_minus, xt_rpush                                   // decrement length on return stack    
    .int xt_branch
    .int tonum_loop - . - CELLS
tonum_done:
    .int xt_rpop, xt_drop
    .int xt_drop, xt_nip
    .int xt_lit, TRUE
    .int xt_exit
tonum_invalid_digit:                                                            // TODO emit string
    .int xt_tib, xt_fetch, xt_lit, 20, xt_type
    .int xt_rpop, xt_drop
    .int xt_drop, xt_drop
    .int xt_lit, FALSE
    .int xt_exit
tonum_empty:
    .int xt_drop
    .int xt_lit, FALSE
    .int xt_exit

defword "word",4,word,1
    .int xt_lit, 0
word_trim:
    .int xt_drop
    .int xt_key
    .int xt_dup, xt_lit, 32, xt_noteq, xt_branch0
    .int word_trim - . - CELLS
    .int xt_dup, xt_lit, 10, xt_noteq, xt_branch0
    .int word_trim - . - CELLS
    .int xt_dup, xt_lit, 13, xt_noteq, xt_branch0
    .int word_trim - . - CELLS
    .int xt_dup, xt_lit, 9, xt_noteq, xt_branch0
    .int word_trim - . - CELLS
    .int xt_drop
    .int xt_tib, xt_fetch, xt_lit, 1, xt_minus                                    // word start
    .int xt_lit, 0
word_next_char:
    .int xt_drop
    .int xt_key
    .int xt_dup, xt_lit, 32, xt_noteq, xt_branch0
    .int word_boundary - . - CELLS
    .int xt_dup, xt_lit, 10, xt_noteq, xt_branch0
    .int word_boundary - . - CELLS
    .int xt_dup, xt_lit, 13, xt_noteq, xt_branch0
    .int word_boundary - . - CELLS
    .int xt_dup, xt_lit, 19, xt_noteq, xt_branch0
    .int word_boundary - . - CELLS
    .int xt_branch
    .int word_next_char - . - CELLS
word_boundary:
    .int xt_drop
    .int xt_dup, xt_tib, xt_fetch, xt_swap, xt_minus, xt_lit, 1, xt_minus         // word length
    .int xt_swap
    .int xt_exit

defword ":",1,colon,1
    .int xt_lit, STATE_COMPILE, xt_lit, OFFSET FLAT:state_var, xt_store
    .int xt_create
    .int xt_exit

defword "char",4,char,1
    .int xt_word, xt_nip, xt_fetchbyte
    .int xt_exit

defword "compile_time_only",17,compile_time_only,1    
    .int xt_state, xt_fetch, xt_lit, STATE_COMPILE, xt_eq
    .int xt_branch0
    .int cannot_interpret_compile_only_word - . - CELLS
    .int xt_exit
cannot_interpret_compile_only_word:
    .int xt_lit, 'I', xt_emit
    .int xt_exit

defword "lastword",8,lastword,1
    .int xt_lit, OFFSET FLAT:LAST_WORD, xt_fetch
    .int xt_exit

defword "enterdoes",9,enterdoes,1
    .int xt_lit, OFFSET FLAT:ENTERDOES 
    .int xt_exit

FINAL_WORD:    
defword "immediate",9,immediate,1
    .int xt_lastword, xt_lit, 1, xt_cells, xt_plus
    .int xt_dup, xt_fetch, xt_plus                                                // add name length
    .int xt_lit, 1, xt_cells, xt_plus
    .int xt_lit, IMMEDIATE, xt_swap, xt_store
    .int xt_exit
    
ENTERCOL:                   // codeword for word (colon) definitions
    mov [ebp], esi          // save esi (forth instruction pointer) to the return stack
    add ebp, CELLS
    add eax, CELLS          // eax points to the ENTERCOL, skip this cell
    mov esi, eax            // set the instruction pointer to the body of this word
    NEXT

ENTERDOES:
    mov [ebp], esi          // save esi to return stack
    add ebp, CELLS
    mov esi, [eax]          // [eax] points to ENTERDOES call in assembly
    add esi, 6              // length of the embedded assembly code is 6, after that there are the forth code
    add eax, CELLS          // eax points to the codeword of the defined word, after that there is the param. field
    push eax
    NEXT
