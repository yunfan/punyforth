.set CELLS,4
.set link,0                                 // points to the last defined word
.set STATE_COMPILE,1
.set STATE_INTERPRET,0
.set IMMEDIATE,-1
.set TRUE,-1
.set FALSE,0

.data

STACK_ORIG:   .int 0
var0:         .int 0
state_var:    .int STATE_INTERPRET
LAST_WORD:    .int FINAL_WORD
input_index:  .int 0
input_buffer:           
              // standard library, loops and conditionals are implemented in forth
.ascii "\n    : 0= 0 = ; : 1+ 1 + ; : 1- 1 - ;"              
.ascii "\n    : % /mod drop ; : / /mod nip ;"                                        
.ascii "\n    : '.' [ char . ] literal ; : '\"' [ char \" ] literal ;"                   
.ascii "\n    : 'F' [ char F ] literal ; : ')' [ char ) ] literal ;"                     
.ascii "\n    : cr 10 emit ; : space 32 emit ; "                                         
.ascii "\n    : [compile] word find drop , ; immediate"                                  

.ascii "\n    : if"                                                                  
.ascii "\n           compile_time_only"                                              
.ascii "\n           lit branch0 ,"                                                  
.ascii "\n           here >r"                                                        
.ascii "\n           0 ,"                                                            
.ascii "\n           rswap ; immediate"                                              
.ascii "\n    : else"                                                                
.ascii "\n           compile_time_only"                                              
.ascii "\n           rswap"                                                          
.ascii "\n           lit branch , here >r , 0 ,"                                     
.ascii "\n           rswap"                                                          
.ascii "\n           r> dup"                                                         
.ascii "\n           here swap - 1 cells -"                                          
.ascii "\n           swap !"                                                         
.ascii "\n           rswap ; immediate"
.ascii "\n    : then"                                                                
.ascii "\n           compile_time_only"                                              
.ascii "\n           rswap"                                                          
.ascii "\n           r> dup"                                                         
.ascii "\n           here swap - 1 cells -"                                          
.ascii "\n           swap ! ; immediate"                                             

.ascii "\n    : ."                                                                   
.ascii "\n           dup 0 < if 45 emit -1 * then"                                           
.ascii "\n           10 /mod dup 0= if"                                                  
.ascii "\n               drop 48 + emit"                                                         
.ascii "\n           else"                                                                   
.ascii "\n              . 48 + emit"                                                             
.ascii "\n           then ;"                                                                     

.ascii "\n    : ? @ . ;"                                                                                 

.ascii "\n    : do"                                                                  
.ascii "\n           compile_time_only"                                              
.ascii "\n           lit >r , lit >r , lit rswap ,"                                  
.ascii "\n           here >r rswap"                                                  
.ascii "\n       ; immediate"                                                            
.ascii "\n    : loop"                                                                
.ascii "\n           compile_time_only"                                              
.ascii "\n           lit r> , lit 1+ , lit >r ,"                                     
.ascii "\n           lit r2dup , lit r> , lit r> ,"                                  
.ascii "\n           lit < , lit invert , lit branch0 ,"                             
.ascii "\n           rswap r> here - 1 cells - ,"                                    
.ascii "\n           lit r> , lit r> , lit drop , lit drop ,"                                
.ascii "\n       ; immediate"                                                                    

.ascii "\n    : begin"                                                               
.ascii "\n           compile_time_only"                                              
.ascii "\n           here >r rswap ; immediate"                                      
.ascii "\n    : again"                                                               
.ascii "\n           compile_time_only"                                              
.ascii "\n           lit branch ,"                                                   
.ascii "\n           rswap r> here - 1 cells - , ; immediate"                        
.ascii "\n    : until"                                                               
.ascii "\n           compile_time_only"                                              
.ascii "\n           lit branch0 ,"                                                  
.ascii "\n           rswap r> here - 1 cells - , ; immediate"                        

.ascii "\n    : ( begin key ')' = until ; immediate"                                 

.ascii "\n    : (does)" 
.ascii "\n          rdup r> 1 cells +                        ( address of the embedded assembly code )"
.ascii "\n          lastword 1 cells + dup @ + 2 cells + ! ; ( replace codeword of the last word )"

.ascii "\n    : does>"
.ascii "\n           lit (does) ,"
.ascii "\n           lit exit ,"
.ascii "\n           104 c,        ( opcode of PUSH )"
.ascii "\n           dodoes ,      ( address of dodoes )"
.ascii "\n           195 c,        ( opcode of RETN )"
.ascii "\n      ; immediate "

.ascii "\n    : constant word create , does> @ ; "

.ascii "\n    -1 constant TRUE 0 constant FALSE"

.ascii "\n    : array ( size -- ) ( index -- addr )"
.ascii "\n          word create cells allot"
.ascii "\n          does> cells + ;"

.ascii "\n    : struct 0 ;" 
.ascii "\n    : field word create over , + does> @ + ;"

.ascii "\n    : s\""                                                                 
.ascii "\n        compile_time_only"                                                 
.ascii "\n        lit litstring ,"                                                   
.ascii "\n        here                    ( length will be placed here )"            
.ascii "\n        0 ,                     ( put a dummy length )"                    
.ascii "\n        0                       ( length counter )"                        
.ascii "\n        key dup '\"' <> if"                                                
.ascii "\n            begin"                                                         
.ascii "\n                swap 1+ swap    ( increase length )"                       
.ascii "\n                c,              ( store character as byte )"                 
.ascii "\n            key dup '\"' = until"                                          
.ascii "\n        then"                                                              
.ascii "\n        drop"                                                              
.ascii "\n        swap !  ( overwrite dummy length with the calculated one )"        
.ascii "\n     ; immediate"                                                          

.ascii "\n    : abs ( n -- |n| ) dup 0 < if -1 * then ;"                             
.ascii "\n    : max ( a b -- max ) 2dup < if nip else drop then ;"                   
.ascii "\n    : min ( a b -- min ) 2dup < if drop else nip then ;"                   

.ascii "\n    : .\""                                                                 
.ascii "\n        state @ 0= if            ( interpretation mode )"                  
.ascii "\n            begin"                                                         
.ascii "\n                key dup 34 = if"                                           
.ascii "\n                    drop exit"                                             
.ascii "\n                then"                                                      
.ascii "\n                emit"                                                      
.ascii "\n            again"                                                         
.ascii "\n        else                     ( compilation mode )"                     
.ascii "\n            [compile] s\" lit type ,"                                                
.ascii "\n        then ; immediate"                                                  
.ascii "\n    : .s depth 0 do . cr loop ;"                                           

.ascii "\n    : factorial ( n -- n! )"                                               
.ascii "\n           dup 0= if"                                                      
.ascii "\n               drop 1"                                                     
.ascii "\n           else"                                                           
.ascii "\n               dup 1 = if"                                                 
.ascii "\n                   drop 1"                                                 
.ascii "\n               else"                                                       
.ascii "\n                   dup 1- factorial *"                                     
.ascii "\n               then"                                                       
.ascii "\n           then ;"                                                         

.ascii "\n    variable test_count"                                                   
.ascii "\n    : assert ( bool -- )"                                                  
.ascii "\n           test_count @ 1+ test_count ! '.' emit"                          
.ascii "\n           TRUE <> if 'F' emit test_count ? then ;"                        
.ascii "\n    : selftest ( -- )"                                                     
.ascii "\n       .\" testing\""                                                     
.ascii "\n       0 test_count !"                                                     
.ascii "\n       12 3 min 3 = assert"                                                
.ascii "\n       -3 7 min -3 = assert"                                               
.ascii "\n       -3 -7 min -7 = assert"                                              
.ascii "\n       132 33 max 132 = assert"                                            
.ascii "\n       -33 77 max 77 = assert"                                             
.ascii "\n       -389 -27 max -27 = assert"                                          
.ascii "\n       0 1- -1 = assert"                                                   
.ascii "\n       -10 1+ -9 = assert"                                                 
.ascii "\n       -10 4 < assert"                                                     
.ascii "\n       -10 -4 < assert"                                                    
.ascii "\n       324 12 > assert"                                                    
.ascii "\n       -24 -212 > assert"                                                  
.ascii "\n       24 -2 > assert"                                                     
.ascii "\n       -12 2 / 6 + 0 = assert"                                             
.ascii "\n       -123 abs 123 = assert 32 abs 32 = assert 0 abs 0 = assert"          
.ascii "\n       -42 abs 42 abs = assert"                                            
.ascii "\n       -12 -3 * 36 = assert -3 4 * -12 = assert 2 -4 * -8 = assert"        
.ascii "\n       -12 -3 + -15 = assert -3 4 + 1 = assert 2 -4 + -2 = assert"         
.ascii "\n       -12 -3 - -9 = assert -3 4 - -7 = assert 2 -4 - 6 = assert"          
.ascii "\n       12 -6 / -2 = assert -36 6 / -6 = assert -4 -2 / 2 = assert "        
.ascii "\n       4 4 >= assert 5 4 >= assert -4 -10 >= assert 4 5 >= invert assert"  
.ascii "\n       6 6 <= assert 3 9 <= assert -9 -5 <= assert 10 2 <= invert assert"          
.ascii "\n       12 3 /mod 4 = assert 0 = assert 12 4 / 3 = assert"                  
.ascii "\n       13 5 /mod 2 = assert 3 = assert 14 6 % 2 = assert"                  
.ascii "\n       TRUE if TRUE assert else FALSE assert then"                         
.ascii "\n       FALSE if FALSE assert else TRUE assert then"                        
.ascii "\n       2 TRUE if dup * then 4 = assert"                                    
.ascii "\n       2 FALSE if dup * then 2 = assert"                                                   
.ascii "\n       0 11 1 do i + loop 55 = assert"                                                 
.ascii "\n       0 8 2 do 9 3 do i j + + loop loop 360 = assert"                                     
.ascii "\n       9 factorial 362880 = assert"                                                              
.ascii "\n       2 10 begin 1- swap 2 * swap dup 0= until drop 2048 = assert"        
.ascii "\n       1 0 or 1 = assert 0 1 or 1 = assert"                                    
.ascii "\n       1 1 or 1 = assert 0 0 or 0 = assert"                                
.ascii "\n       1 0 and 0 = assert 0 1 and 0 = assert"                                  
.ascii "\n       1 1 and 1 = assert 0 0 and 0 = assert"                              
.ascii "\n       1 0 xor 1 = assert 0 1 xor 1 = assert"                                  
.ascii "\n       1 1 xor 0 = assert 0 0 xor 0 = assert"                                      
.ascii "\n       10 2 < 3 1 > or if 1 else 0 then 1 = assert"                        
.ascii "\n       3 10 < 3 11 > and if 1 else 0 then 0 = assert"                      
.ascii "\n       -98 45 < 33 11 > and if 1 else 0 then 1 = assert"                           
.ascii "\n  test_count ? .\"  OK\" cr ;"
.ascii "\n    selftest .\" Puny FORTH ready\" cr "

// TODO exceptions, stack underflow, ?-nel ne lepjen ki a repl
// TODO word create -> create

input_size:  .int . - input_buffer
here_var:    .int 0
dictionary:  .space 8192
rstack:      .space 256
prompt_str:  .ascii "\n % " 
