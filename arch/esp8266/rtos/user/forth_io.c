#include "espressif/esp_common.h"
#include "esp/uart.h"

void forth_putchar(char c) { 
    printf("%c", c);
}

char forth_getchar() { 
    return getchar();	
}

void forth_type(char* text) { 
    printf("%s", text);
}

void forth_uart_set_baud(int uart_num, int bps) {
    uart_set_baud(uart_num, bps);
}
