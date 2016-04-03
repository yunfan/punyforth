#include "forth_io.h"

int next_char_from_uart() { return getchar(); }

void set_nextchar(CharSupplier fp) {
    nextchar = fp;
}

int forth_getchar() { 
    return nextchar();	
}

void forth_putchar(char c) { 
    printf("%c", c);
}

void forth_type(char* text) { 
    printf("%s", text);
}

void forth_uart_set_baud(int uart_num, int bps) {
    uart_set_baud(uart_num, bps);
}
