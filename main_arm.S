#include "arch/x86/defs.S"
#include "generic/data.S"
#include "generic/macros.S"
#include "generic/outerinterpreter.S"
#include "arch/arm/innerinterpreter.S"
#include "arch/arm/primitives.S"
#include "arch/arm/ext.S"
#include "generic/words.S"
#include "arch/arm/init.S"

.global main

.text
main: init_forth	
