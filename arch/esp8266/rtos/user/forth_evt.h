#ifndef __FORTH_EVT_H__
#define __FORTH_EVT_H__

void init_event_queue();
void forth_add_event_isr(int* event);

#endif
