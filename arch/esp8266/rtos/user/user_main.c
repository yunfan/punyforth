#include "user_config.h"
#include "espressif/esp_common.h"
#include "espressif/esp_softap.h"
#include "freertos/task.h"
#include "freertos/FreeRTOS.h"
#include "espressif/esp8266/esp8266.h"
#include "gpio.h"
#include "tcp_shell.h"
#include "punyforth.h"

static xTaskHandle tasks[8];

static void ICACHE_FLASH_ATTR forth_init(void* dummy) {
    forth_start();   
}

int ICACHE_FLASH_ATTR forth_div(int a, int b) { return a / b; }
int ICACHE_FLASH_ATTR forth_mod(int a, int b) { return a % b; }

/*
void ICACHE_FLASH_ATTR forth_gpio_enable(int num, int dir) { 
    gpio_direction_t d;
    switch (dir) {
        case 1: d = GPIO_INPUT; break;
        case 2: d = GPIO_OUTPUT; break;
        case 3: d = GPIO_OUT_OPEN_DRAIN; break
    }
    gpio_enable(num, d); 
}

void ICACHE_FLASH_ATTR forth_gpio_write(int num, int value) { 
    gpio_write(num, value == 0 ? false : true); 
}
*/

void ICACHE_FLASH_ATTR forth_putchar(char c) { 
    printf("%c", c);
    if (tcp_shell_is_connected()) {
        tcp_shell_write_char(c);
    }
}

char ICACHE_FLASH_ATTR forth_getchar() { 
    return tcp_shell_read_char();
}

int ICACHE_FLASH_ATTR forth_time() { 
    return xTaskGetTickCount();
}

void ICACHE_FLASH_ATTR forth_abort() { 
    printf("Restarting ESP ..");
//    sdk_system_restart();
}

void ICACHE_FLASH_ATTR forth_type(char* text, int len) { 
    printf("%.*s", len, text);
    if (tcp_shell_is_connected()) {
        tcp_shell_write_string(text, len);
    }
}

void ICACHE_FLASH_ATTR user_init(void) {
    tcp_shell_init();
    printf("Starting PunyForth task ..\n");
    xTaskCreate(forth_init, "punyforth", 256, NULL, 2, &tasks[0]); 
    printf("PunyForth started\n");
}

