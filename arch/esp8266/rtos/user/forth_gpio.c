#include "esp/gpio.h"
#include "espressif/esp_common.h"
#include "forth_evt.h"

#define FORTH_TRUE -1
#define FORTH_FALSE 0

int forth_gpio_mode(int num, int dir) { 
    gpio_direction_t d;
    switch (dir) {
        case 1: d = GPIO_INPUT; break;
        case 2: d = GPIO_OUTPUT; break;
        case 3: d = GPIO_OUT_OPEN_DRAIN; break;
        default: return FORTH_FALSE;
    }
    gpio_enable(num, d); 
    return FORTH_TRUE;
}

void forth_gpio_write(int num, int bool_set) { 
    gpio_write(num, bool_set); 
}

int forth_gpio_read(int num) {
    return gpio_read(num);
}

void forth_gpio_set_interrupt(int num, int int_type) {
    gpio_set_interrupt(num, int_type);
}

void __attribute__((weak)) IRAM gpio_interrupt_handler(void) {
    uint32_t status_reg = GPIO.STATUS;
    GPIO.STATUS_CLEAR = status_reg;   
    uint8_t gpio_idx;
    while ((gpio_idx = __builtin_ffs(status_reg))) {
        gpio_idx--;
        status_reg &= ~BIT(gpio_idx);
        if (FIELD2VAL(GPIO_CONF_INTTYPE, GPIO.CONF[gpio_idx])) {
            int payload = gpio_idx;
            forth_add_event_isr(event_new(EVT_GPIO, payload, xTaskGetTickCountFromISR()));
        }
    }
}
