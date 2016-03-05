// This is the outer text interpreter (REPL) implemented in binary forth.

outer_interpreter:
    .int xt_word, xt_dup, xt_branch0       // read next word, check end of input    
    .int end_of_input - . - CELLS
    .int xt_dup2
    .int xt_find, xt_dup, xt_branch0       // dictionary lookup returns (xt mode) or 0 if not found    
    .int not_found_in_dictionary - . - CELLS
    .int xt_invert, xt_branch0             // if immediate word then interpet even if we're in compilation mode
    .int interpret - . - CELLS
    .int xt_state, xt_fetch                // if non immediate word, interpret or compile depending on state    
    .int xt_branch0
    .int interpret - . - CELLS
    .int xt_nip, xt_nip                         
    .int xt_comma                          // compile the xt into the current word definition
    .int xt_branch
    .int outer_interpreter - . - CELLS
interpret:
    .int xt_nip, xt_nip                          
    .int xt_execute
    .int xt_branch
    .int outer_interpreter - . - CELLS
not_found_in_dictionary:                   // word was not found in the dictionary try to convert it to number
    .int xt_drop
    .int xt_tonumber
    .int xt_branch0
    .int invalid_number - . - CELLS
    .int xt_state, xt_fetch, xt_branch0    // depending on state compile number literal or push number to the stack
    .int outer_interpreter - . - CELLS     // we're in interpret mode, number is already on the stack
    .int xt_literal                        // we're in compile mode, compile a literal number
    .int xt_branch
    .int outer_interpreter - . - CELLS
end_of_input:
    .int xt_abort
invalid_number:
    .int xt_lit, '?', xt_emit
    .int xt_lit, 10, xt_emit
    .int xt_abort

