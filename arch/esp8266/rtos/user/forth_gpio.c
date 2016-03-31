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

void forth_gpio_set_interrupt(int num, int int_type) {
    printf("Setting GPIO %d interrupt %d\n", num, int_type);
    gpio_set_interrupt(num, int_type);
}

void gpio_interrupt_handler(void) {
    uint32_t status_reg = GPIO.STATUS;
    GPIO.STATUS_CLEAR = status_reg;   
    uint8_t gpio_idx;
    while ((gpio_idx = __builtin_ffs(status_reg))) {
        gpio_idx--;
        status_reg &= ~BIT(gpio_idx);
        if (FIELD2VAL(GPIO_CONF_INTTYPE, GPIO.CONF[gpio_idx])) {
            printf("GPIO %d FIRED\n", gpio_idx);
        }      
    }
}
