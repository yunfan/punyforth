// TODO
defprimitive "time",4,time,1 /* ( -- unixtime ) */
    NEXT

defword "(does)",6,doespar,1
    .int xt_rpop, xt_lastword, xt_link2xt, xt_store
    .int xt_exit

// TODO
defword "does>",5,does,IMMEDIATE
    .int xt_btick, xt_doespar, xt_comma
    .int xt_btick, 3844075524, xt_comma     // LDR PC, [PC, #-4]
    .int xt_enterdoes, xt_comma
    .int xt_exit
