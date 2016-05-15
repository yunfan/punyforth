#include "FreeRTOS.h"
#include "espressif/esp_common.h"
#include "espressif/esp_softap.h"
#include "task.h"
#include "esp/uart.h"
#include "espressif/esp8266/esp8266.h"
#include "punyforth.h"
#include "forth_evt.h"

static void forth_init(void* dummy) {
    forth_start();   
}

void user_init(void) {
    uart_set_baud(0, 115200);
    printf("Punyforth loading..\n");
    init_event_queue();
    xTaskCreate(forth_init, (signed char*) "punyforth", 640, NULL, 2, NULL); 
}
