marker -tasks

4000 constant TASK_ERROR

\ Task status
0 constant PAUSED
1 constant SKIPPED

\ available resources per task
128 variable! task_stack_size
64  variable! task_rstack_size

variable var-last-task
0 var-last-task !

: last-task ( -- task ) var-last-task @ ;
: last-task! ( task -- ) var-last-task ! ;

variable var-current-task
0 var-current-task !

: current-task ( -- task ) var-current-task @ ;
: current-task! ( task -- ) var-current-task ! ;

struct
    cell field .next
    cell field .status
    cell field .sp
    cell field .rp
    cell field .ip
constant Task

\ initialize main task
here Task allot constant MAIN_TASK
MAIN_TASK MAIN_TASK .next !
SKIPPED MAIN_TASK .status !
MAIN_TASK last-task!
MAIN_TASK current-task!

: alloc-data-stack ( -- a )
    task_stack_size @ allot here ;

: alloc-return-stack ( -- a )
    task_rstack_size @ allot here ;

: task: ( "name" ) ( -- task )
    create
        here                                 \ task header begins here
        Task allot                           \ make room for task header
        SKIPPED             over .status !   \ new status is SKIPPED
        last-task .next @   over .next !     \ this.next = last-task.next
        dup last-task .next !                \ last-task.next = this
        alloc-data-stack    over .sp !       \ this.sp = allocated
        alloc-return-stack  over .rp !       \ this.sp = allocated
        last-task!                           \ last-task = this
    does> ;

: task-choose-next ( -- )    
    current-task
    begin        
        .next @ dup
        .status @ PAUSED =
    until ;

: task-save-context ( sp ip rp -- ) \ XXX temporal coupling
    current-task .rp !
    current-task .ip !
    current-task .sp ! ;

: task-restore-context ( -- )    
    current-task .sp @ sp!
    current-task .rp @ rp!
    current-task .ip @ >r ;

: task-run ( task -- )
    current-task!
    SKIPPED current-task .status !
    task-restore-context ;

: pause ( -- )
    PAUSED current-task .status !
    sp@ r> rp@ task-save-context
    task-choose-next task-run ;

: activate ( task -- )
    \ TODO if already active
    r> over .ip !
    PAUSED current-task .status !   \ pause current task
    sp@ cell + r> rp@ task-save-context        
    task-run ;

: stop ( task -- )
    SKIPPED swap .status ! 
    task-choose-next task-run ;

: deactivate ( -- )
    current-task stop ;

: semaphore: ( -- ) variable! ;
: mutex: ( -- ) 1 semaphore: ;

: wait ( semaphore -- )
    begin
        pause
        dup @ 0<>
    until
    -1 swap +! ;

: signal ( semaphore -- )
    1 swap +! 
    pause ;
 
: multi ( -- ) \ switch to multi-task mode
    ['] pause xpause ! ;

: single ( -- ) \ switch to signle-task mode
    0 xpause ! ;

multi    