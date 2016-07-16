#include "espressif/esp_common.h"
#include "FreeRTOS.h"
#include "string.h"

#ifndef MIN
#define MIN(a,b) ((a) < (b) ? (a) : (b))
#endif

int forth_wifi_set_opmode(int mode) {
    return sdk_wifi_set_opmode(mode);
}

int forth_wifi_set_station_config(char* ssid, char* pass) {
    struct sdk_station_config config;
    memset(config.ssid, 0, 32);
    memset(config.password, 0, 64);
    memcpy(config.ssid, ssid, MIN(32, strlen(ssid)));
    memcpy(config.password, pass, MIN(64, strlen(pass)));
    return sdk_wifi_station_set_config(&config);
}

void forth_wifi_get_ip_str(char * buffer, int size) {
    struct ip_info wifi_info;
    sdk_wifi_get_ip_info(0, &wifi_info);
    struct ip_addr ip = wifi_info.ip; 
    snprintf(buffer, size, IPSTR, IP2STR(&ip));

}
