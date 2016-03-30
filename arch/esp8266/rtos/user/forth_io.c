#include "espressif/esp_common.h"

void forth_putchar(char c) { 
    printf("%c", c);
}

char forth_getchar() { 
    return getchar();	
}

void forth_type(char* text) { 
    printf("%s", text);
}

