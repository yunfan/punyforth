#include "FreeRTOS.h"
#include "espressif/esp_common.h"

div_t forth_divmod(int a, int b) { return div(a,b); }
int forth_div(int a, int b) { return a / b; }
int forth_mod(int a, int b) { return a % b; }
int forth_random() { return rand(); }
