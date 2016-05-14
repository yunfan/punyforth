#include "FreeRTOS.h"
#include "task.h"
#include "espressif/esp_common.h"

int forth_time() { 
    return xTaskGetTickCount();
}

void forth_delay(int millis) {
    vTaskDelay(millis / portTICK_RATE_MS);
}

