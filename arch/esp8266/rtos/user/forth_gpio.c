#include "esp/gpio.h"
#include "pwm.h"
#include "espressif/esp_common.h"
#include "forth_evt.h"
#include "esplibs/libmain.h"
#include "limits.h"
#include "punycommons.h"

void forth_gpio_mode(int num, int dir) { 
    gpio_direction_t d;
    switch (dir) {
        case 1: d = GPIO_INPUT; break;
        case 2: d = GPIO_OUTPUT; break;
        case 3: d = GPIO_OUT_OPEN_DRAIN; break;
        default: return;
    }
    gpio_enable(num, d); 
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

void forth_pwm_freq(int freq) {
    pwm_set_freq((uint16_t) (freq & 0xFFFF));
}

void forth_pwm_duty(int duty) {
    pwm_set_duty((uint16_t) (duty & 0xFFFF));
}

void __attribute__((weak)) IRAM gpio_interrupt_handler(void) {
    uint32_t status_reg = GPIO.STATUS;
    GPIO.STATUS_CLEAR = status_reg;   
    uint8_t gpio_idx;
    while ((gpio_idx = __builtin_ffs(status_reg))) {
        gpio_idx--;
        status_reg &= ~BIT(gpio_idx);
        if (FIELD2VAL(GPIO_CONF_INTTYPE, GPIO.CONF[gpio_idx])) {
            struct forth_event event = {
                .event_type = EVT_GPIO,
                .event_time_ms = xTaskGetTickCountFromISR() * portTICK_RATE_MS,
                .event_time_us = sdk_system_get_time(),
                .event_payload = gpio_idx
            };
            forth_add_event_isr(&event);
        }
    }
}

#define WAIT_FOR_PIN_STATE(state) \
    while (gpio_read(pin) != (state)) { \
        if (xthal_get_ccount() - start_cycle_count > timeout_cycles) { \
            return 0; \
        } \
    }

// max timeout is 26 seconds at 80Mhz clock or 13 at 160Mhz
int forth_pulse_in(int pin, int state, int timeout_us) {
    uint32_t timeout_cycles = MIN(abs(timeout_us), INT_MAX / sdk_os_get_cpu_frequency()) * sdk_os_get_cpu_frequency();
    uint32_t start_cycle_count = xthal_get_ccount();
    WAIT_FOR_PIN_STATE(!state);
    WAIT_FOR_PIN_STATE(state);
    uint32_t pulse_start_cycle_count = xthal_get_ccount();
    WAIT_FOR_PIN_STATE(!state);
    return (xthal_get_ccount() - pulse_start_cycle_count) / sdk_os_get_cpu_frequency();
}

