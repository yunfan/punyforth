.data
.align 4

.set CELLS,4
.set link,0                    // points to the last defined word
.set STATE_COMPILE,1
.set STATE_INTERPRET,0
.set IMMEDIATE,-1
.set TRUE,-1
.set FALSE,0
.set INPUT_BUFFER_SIZE,128

STACK_ORIG:   .int 0
var0:         .int 0
state_var:    .int STATE_INTERPRET
LAST_WORD:    .int FINAL_WORD
input_index:  .int 0
input_buffer: .space INPUT_BUFFER_SIZE
.align 4,32
input_size:   .int . - input_buffer
var_dp:       .int 0                   // data pointer
dictionary:   .space 28672
end_dictionary:
rstack_space: .space 128
rstack:
stack_space:  .space 1024 // TODO used only by ESP port
stack:
prompt_str:   .asciz "\n % "
prompt_word_name:      .asciz "default_prompt"
compile_only_warning:  .asciz "\nCompile time only word cannot be used in interpretation mode.\n"
undef_word_error:      .asciz "\nUndefined word: "
inbuf_overflow_error:  .asciz "\nInput buffer overflow\n"
user_exception_handler_name:      .asciz "on-uncaught-exception"
