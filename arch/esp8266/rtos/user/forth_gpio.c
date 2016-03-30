#include "esp/gpio.h"
#include "espressif/esp_common.h"

#define FORTH_TRUE -1
#define FORTH_FALSE 0

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

int forth_gpio_read(int num) {
    printf("Reading GPIO %d\n", num);
    return gpio_read(num);
}
