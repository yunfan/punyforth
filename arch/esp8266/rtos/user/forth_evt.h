#ifndef __FORTH_EVT_H__
#define __FORTH_EVT_H__

#include "FreeRTOS.h"
#include "task.h"

#define EVT_GPIO 100

struct forth_event {
    int event_type;
    int event_time;
    int event_payload;
    unsigned int event_time_us;
};

void init_event_queue();
void forth_add_event_isr(struct forth_event *event);

#endif
