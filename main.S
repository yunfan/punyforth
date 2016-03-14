#include "generic/data.S"
#include "generic/outerinterpreter.S"
#include "generic/macros.S"
#include "arch/x86/innerinterpreter.S"
#include "arch/x86/primitives.S"
#include "arch/x86/ext.S"
#include "generic/words.S"
#include "arch/x86/init.S"

.global _start

.text
_start: init_forth	
