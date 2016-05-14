#include "FreeRTOS.h"
#include "task.h"
#include "espressif/esp_common.h"

int forth_time() { 
    return xTaskGetTickCount();
}

void forth_delay(int millis) {
    vTaskDelay(millis / portTICK_RATE_MS);
}

/**
 * Delay microseconds
 *
 * sdk os_delay_us has only 16bits, so mask them
 */
void forth_delay_us(unsigned int microseconds) {
    sdk_os_delay_us(microseconds & 0x0ffff);
}

