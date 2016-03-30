#include "FreeRTOS.h"
#include "espressif/esp_common.h"
#include "espressif/esp_softap.h"
#include "task.h"
#include "espressif/esp8266/esp8266.h"
#include "punyforth.h"

static void forth_init(void* dummy) {
    forth_start();   
}

void user_init(void) {
    printf("Starting PunyForth task ..\n");
    xTaskCreate(forth_init, (signed char*) "punyforth", 256, NULL, 2, NULL); 
    printf("PunyForth started.\n");
}
