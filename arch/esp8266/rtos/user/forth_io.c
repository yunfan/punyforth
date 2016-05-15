#include "espressif/esp_common.h"
#include "esp/uart.h"

#define BUFFER_SIZE 1024 // should be multiple of 4
bool _source_read_progress = true;
char *buffer = NULL;
int buffer_offset = -1;
uint32_t source_code_address = 0x51000;

int next_char_from_flash() { // read source stored code from flash memory
    if (buffer == NULL) {
	buffer = malloc(BUFFER_SIZE);
    }
    if (buffer_offset < 0 || buffer_offset >= BUFFER_SIZE) {
        sdk_spi_flash_read(source_code_address, (void *) buffer, BUFFER_SIZE);
        source_code_address += BUFFER_SIZE;
        buffer_offset = 0;
    }
    char next = buffer[buffer_offset++];
    if (next == 0 || next == 0xFF) {
        _source_read_progress = false;
        free(buffer);
	printf("Punyforth ready.\n");
        return 10;
    }
    return next;
}

int forth_getchar() { 
    return _source_read_progress
        ? next_char_from_flash() 
        : getchar();
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
   if (_source_read_progress) {
       return next_char_from_flash();
   }
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

