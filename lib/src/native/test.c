#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#include "i2c.h"

#define EEPROM_I2C_ADDR 0x76

int main(void) {
    printf("test\n");
    i2c_t *i2c;

    i2c = i2c_new();

    /* Open the i2c-0 bus */
    if (i2c_open(i2c, "/dev/i2c-1") < 0) {
        fprintf(stderr, "i2c_open(): %s\n", i2c_errmsg(i2c));
        exit(1);
    }

    /* Read byte at address 0x100 of EEPROM */
    uint8_t msg_addr[2] = { 0xF4, 0x39 };
    uint8_t msg_data[1] = { 39 };
    struct i2c_msg msgs[2] =
        {
            /* Write 16-bit address */
            { .addr = EEPROM_I2C_ADDR, .flags = 0, .len = 2, .buf = msg_addr },
            /* Read 8-bit data */
            { .addr = EEPROM_I2C_ADDR, .flags = 0, .len = 1, .buf = msg_data},
        };

    /* Transfer a transaction with two I2C messages */
    if (i2c_transfer(i2c, msgs, 1) < 0) {
        fprintf(stderr, "i2c_transfer(): %s\n", i2c_errmsg(i2c));
        exit(1);
    }

    printf("0x%02x%02x: %d\n", msg_addr[0], msg_addr[1], msg_data[0]);

    i2c_close(i2c);

    i2c_free(i2c);

    return 0;
}