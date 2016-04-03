#include "forth_io.h"

int next_char_from_uart() { return getchar(); }

void set_nextchar_supplier(CharSupplier fp) {
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

#define BUFFER_SIZE 64
char buffer[BUFFER_SIZE];
int buffer_offset = -1;
uint32_t source_code_address = 0x18000;

int next_char_from_flash() {
    if (buffer_offset < 0 || buffer_offset >= 64) {
        sdk_spi_flash_read(source_code_address, buffer, BUFFER_SIZE);
        source_code_address += BUFFER_SIZE;
        buffer_offset = 0;
    }
    char next = buffer[buffer_offset++];
    if (next == 0 || next == 0xFF) {
        set_nextchar_supplier(&next_char_from_uart);
        return 10;
    }
    return next;
}
