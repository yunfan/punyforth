
#include "esp_common.h"
#include "espconn.h"
#include "tcp_shell.h"

#include "ets_sys.h"
#include "os_type.h"
#include "osapi.h"
#include "mem.h"
#include "lwip/stats.h"


#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/queue.h"

LOCAL uint16_t shell_timeout = 3600; // 1 hour timeout

LOCAL struct espconn masterconn;
LOCAL struct espconn *pespconn;

LOCAL int is_connected = 0;
LOCAL xQueueHandle tcp_shell_stdin;

int ICACHE_FLASH_ATTR tcp_shell_is_connected() {
    return is_connected;
}

char ICACHE_FLASH_ATTR tcp_shell_read_char() {
    char ch;
    if (xQueueReceive(tcp_shell_stdin, &ch, portMAX_DELAY) == pdTRUE)
	return ch;
    taskYIELD();
//    if (xQueueReceive(tcp_shell_stdin, &ch, 10) == pdTRUE)
//        return ch;
//    taskYIELD();
}

void ICACHE_FLASH_ATTR tcp_shell_write_char(char ch) {
    espconn_send(pespconn, &ch, 1);
}

void ICACHE_FLASH_ATTR tcp_shell_write_string(char* text, int len) {
    espconn_send(pespconn, text, len);
}

LOCAL void ICACHE_FLASH_ATTR disconnected(void *arg) {
    pespconn = (struct espconn *) arg;
    is_connected = FALSE;
    printf("[Shell] disconnected\n");
}

LOCAL void ICACHE_FLASH_ATTR received(void *arg, char *pusrdata, unsigned short length)
{
    int i;
    for(i=0; i < length; i++) 
        xQueueSend(tcp_shell_stdin, (void*) &pusrdata[i], portMAX_DELAY);
}

LOCAL void ICACHE_FLASH_ATTR sent(void* arg) {}

LOCAL void ICACHE_FLASH_ATTR write_finished(void *arg) {}

LOCAL void ICACHE_FLASH_ATTR connected(void *arg) {
    pespconn = (struct espconn *)arg;
    printf("Establishng TCP Shell..\n");
    espconn_regist_recvcb(pespconn, received);
    espconn_regist_disconcb(pespconn, disconnected);
    espconn_regist_sentcb(pespconn, sent);
    espconn_regist_write_finish(pespconn, write_finished);
    is_connected = TRUE;
    printf("TCP Shell connected\n");
}

void ICACHE_FLASH_ATTR tcp_shell_init(void) {
    tcp_shell_stdin = xQueueCreate(128, sizeof( char));
    masterconn.type = ESPCONN_TCP;
    masterconn.state = ESPCONN_NONE;
    masterconn.proto.tcp = (esp_tcp *)os_zalloc(sizeof(esp_tcp));
    masterconn.proto.tcp->local_port = FORTH_TCP_PORT;
    espconn_regist_connectcb(&masterconn, connected);
    espconn_regist_disconcb(&masterconn, disconnected);
    espconn_accept(&masterconn);
    espconn_regist_time(&masterconn, shell_timeout, 0);
    printf("TCP Shell initialized\n");
}

