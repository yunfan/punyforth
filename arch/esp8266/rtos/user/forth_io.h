#include "espressif/esp_common.h"
#include "esp/uart.h"

#ifndef __FORTH_IO_H__
#define __FORTH_IO_H__

typedef int (*CharSupplier)();

CharSupplier nextchar;

void set_nextchar_supplier(CharSupplier fp);
int next_char_from_uart();
int next_char_from_flash();

#endif
