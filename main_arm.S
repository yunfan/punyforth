#define _M 

#include "generic/data.S"
#include "generic/outerinterpreter.S"
#include "generic/macros.S"
#include "arch/arm/innerinterpreter.S"
#include "arch/arm/primitives.S"
#include "arch/arm/ext.S"
#include "generic/words.S"
#include "arch/arm/init.S"

.global _start

.text
_start: init_forth	
