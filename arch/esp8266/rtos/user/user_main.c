#include "FreeRTOS.h"
#include "espressif/esp_common.h"
#include "espressif/esp_softap.h"
#include "task.h"
#include "espressif/esp8266/esp8266.h"
#include "esp/gpio.h"
#include "punyforth.h"

#define FORTH_TRUE -1
#define FORTH_FALSE 0

static void forth_init(void* dummy) {
    forth_start();   
}

int forth_div(int a, int b) { return a / b; }
int forth_mod(int a, int b) { return a % b; }

int forth_gpio_enable(int num, int dir) { 
    gpio_direction_t d;
    switch (dir) {
        case 1: d = GPIO_INPUT; break;
        case 2: d = GPIO_OUTPUT; break;
        case 3: d = GPIO_OUT_OPEN_DRAIN; break;
        default: return FORTH_FALSE;
    }
    printf("Enabling GPIO %d: %d\n", num, dir);
    gpio_enable(num, d); 
    return FORTH_TRUE;
}

void forth_gpio_write(int num, int value) { 
    printf("Writing GPIO %d <- %d\n", num, value);
    gpio_write(num, value == FORTH_TRUE ? true : false); 
}

void forth_delay(int millis) {
    vTaskDelay(millis / portTICK_RATE_MS);    
}

void forth_putchar(char c) { 
    printf("%c", c);
}

char forth_getchar() { 
    return getchar();	
}

int forth_time() { 
    return xTaskGetTickCount();
}

void forth_abort() { 
    printf("Restarting ESP ..\n");
    sdk_system_restart();
}

void forth_type(char* text, int len) { 
    printf("%.*s", len, text);
}

void user_init(void) {
    printf("Starting PunyForth task ..\n");
    xTaskCreate(forth_init, (signed char*) "punyforth", 256, NULL, 2, NULL); 
    printf("PunyForth started.\n");
}
