#include "espressif/esp_common.h"
#include "FreeRTOS.h"
#include "task.h"
#include "queue.h"
#include "forth_evt.h"

static xQueueHandle event_queue;

void init_event_queue() {
    event_queue = xQueueCreate(64, sizeof(int));
}

void forth_add_event_isr(int* event) {
    xQueueSendToBackFromISR(event_queue, event, NULL);
}

int forth_next_event() {
    int message;
    xQueueReceive(event_queue, &message, portMAX_DELAY);
    return message;
}
