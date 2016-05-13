#include "espressif/esp_common.h"
#include "FreeRTOS.h"
#include "task.h"
#include "queue.h"
#include "forth_evt.h"

static xQueueHandle event_queue;

void init_event_queue() {
    event_queue = xQueueCreate(8, sizeof(struct forth_event));
}

struct forth_event event_new(int event_type, int event_payload, int time) {
    struct forth_event event = {
        .event_type = event_type,
        .event_time = time,
        .event_payload = event_payload
    };
    return event;
}

void forth_add_event_isr(struct forth_event event) {
    xQueueSendToBackFromISR(event_queue, &event, NULL);
}

int forth_wait_event(int timeout_ms, void* buffer) {
    return (xQueueReceive(event_queue, buffer, timeout_ms / portTICK_RATE_MS) == pdTRUE) ? 1 : 0;
}
