#include "forth_io.h"

int next_char_from_uart() { return getchar(); }

void set_nextchar_supplier(CharSupplier fp) {
    nextchar = fp;
}

int forth_getchar() { 
    return nextchar();	
}

bool _enter_press = false; // XXX this is ugly, use for breaking out key loop
void forth_push_enter() {
   _enter_press = true;
}
int check_enter() { 
   if (_enter_press) {
       _enter_press = false;
       return 10;
   }
   return -1;
}

int forth_getchar_nowait() {
   char buf[1];
   return sdk_uart_rx_one_char(buf) != 0
       ? check_enter()
       : buf[0];
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

#define BUFFER_SIZE 1024
char *buffer = NULL;
int buffer_offset = -1;
uint32_t source_code_address = 0x18000;

int next_char_from_flash() {
    if (buffer == NULL) {
	buffer = malloc(BUFFER_SIZE);
    }
    if (buffer_offset < 0 || buffer_offset >= BUFFER_SIZE) {
        sdk_spi_flash_read(source_code_address, buffer, BUFFER_SIZE);
        source_code_address += BUFFER_SIZE;
        buffer_offset = 0;
    }
    char next = buffer[buffer_offset++];
    if (next == 0 || next == 0xFF) {
        set_nextchar_supplier(&next_char_from_uart);
        free(buffer);	
        return 10;
    }
    return next;
}
