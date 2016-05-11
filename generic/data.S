.data
.align 4

.set CELLS,4
.set link,0                    // points to the last defined word
.set STATE_COMPILE,1
.set STATE_INTERPRET,0
.set IMMEDIATE,128
.set HIDDEN,64
.set REGULAR,0
.set TRUE,-1
.set FALSE,0
.set INPUT_BUFFER_SIZE,128
.set MAX_WORD_LEN,63

STACK_ORIG:   .int 0
var0:         .int 0
state_var:    .int STATE_INTERPRET
LAST_WORD:    .int FINAL_WORD
input_index:  .int 0
input_buffer: .space INPUT_BUFFER_SIZE,' '
.align 4,32
input_size:   .int . - input_buffer
var_dp:       .int 0                   // data pointer
var_prompt_xt:.int 0
var_pause_xt: .int 0
dictionary:   .space 28672
end_dictionary:
rstack_space: .space 320
rstack:
stack_space:  .space 576 // used only by ESP port
stack:
prompt_str:   .asciz "\n % "
compile_only_warning:  .asciz "\nCompile time only word cannot be used in interpretation mode.\n"
undef_word_error:      .asciz "\nUndefined word: "
inbuf_overflow_error:  .asciz "\nInput overflow\n"
word_overflow_error:  .asciz "\nName too long: "
