#include "FreeRTOS.h"
#include "espressif/esp_common.h"

void forth_abort() { 
    printf("Restarting ESP ..\n");
    sdk_system_restart();
}

