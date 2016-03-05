
REPL:
REPL_loop:
    .int xt_word                                                                  // read next word, check end of input
    .int xt_dup, xt_branch0
    .int end_of_input - . - CELLS
    .int xt_dup2
    .int xt_find                                                                  // returns 0 if not found, (xt, mode) otherwise mode is either -1 or +1
    .int xt_dup
    .int xt_branch0
    .int not_found_in_dictionary - . - CELLS
    .int xt_invert, xt_branch0                                                    // if immediate word then interpet even if we're in compilation mode
    .int interpret - . - CELLS
    .int xt_state, xt_fetch                                                       // if non immediate word, interpret or compile depending on state    
    .int xt_branch0
    .int interpret - . - CELLS
    .int xt_nip, xt_nip                          
    .int xt_comma                                                                 // compile the xt into the dictionary
    .int xt_branch
    .int REPL_loop - . - CELLS
interpret:
    .int xt_nip, xt_nip                          
    .int xt_execute
    .int xt_branch
    .int REPL_loop - . - CELLS
not_found_in_dictionary:
    .int xt_drop
    .int xt_tonumber
    .int xt_branch0
    .int invalid_number - . - CELLS
    .int xt_state, xt_fetch, xt_branch0                                           // check state
    .int REPL_loop - . - CELLS                                                    // we're in interpret mode, number is already on the stack
    .int xt_literal                                                               // we're in compile mode, compile a literal number
    .int xt_branch
    .int REPL_loop - . - CELLS
end_of_input:
    .int xt_abort
invalid_number:
    .int xt_lit, '?', xt_emit
    .int xt_lit, 10, xt_emit
    .int xt_abort
immediate_in_interpret_mode:
    .int xt_lit, 'I', xt_emit
    .int xt_lit, 10, xt_emit
    .int xt_abort

