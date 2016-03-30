#include "espressif/esp_common.h"
#include "ds18b20/ds18b20.h"
#include "onewire/onewire.h"

int forth_ds18b20_read_int(int gpio_num, int sensor_num) {
    return 0;
}

int forth_ds18b20_read_frac(int gpio_num, int sensor_num) {
    return 0;
}

int forth_ds18b20_read_all(int gpio_num, int sensor_num) {
    onewire_init(gpio_num);
    ds_sensor_t sensors[16];
    int amount_sensors = ds18b20_read_all(gpio_num, sensors);
    if (sensor_num >= amount_sensors ) {
        printf("Invalid sensor: %d. Number of sensors: %d", sensor_num, amount_sensors);
        return 0;
    }
    int intpart = (int) sensors[sensor_num].value;
    int fraction = (int)((sensors[sensor_num].value - intpart) * 100);      
    printf("Sensor %d report: %d.%02d", sensor_num, intpart, fraction);
    return 1;
}
