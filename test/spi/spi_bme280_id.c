#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <linux/spi/spidev.h>
#include <string.h>

// Configuration
#define SPI_DEVICE "/dev/spidev0.0"  // SPI Bus 0, Chip Select 0 (Pin 24)
#define SPI_SPEED 1000000            // 1 MHz
#define REG_ID 0xD0                  // BME280 Chip ID Register

int main() {
    int fd;
    int ret;
    
    // SPI Mode 0 (CPOL=0, CPHA=0) is standard for BME280
    uint8_t mode = 0;
    uint8_t bits = 8;
    uint32_t speed = SPI_SPEED;

    // 1. Open the SPI Device
    fd = open(SPI_DEVICE, O_RDWR);
    if (fd < 0) {
        perror("Error: Could not open SPI device. Is SPI enabled?");
        return 1;
    }

    // 2. Configure SPI (Mode, Bits, Speed)
    // Set Write Mode
    if (ioctl(fd, SPI_IOC_WR_MODE, &mode) < 0) {
        perror("Error setting SPI mode");
        close(fd);
        return 1;
    }
    
    // Set Bits per Word
    if (ioctl(fd, SPI_IOC_WR_BITS_PER_WORD, &bits) < 0) {
        perror("Error setting bits per word");
        close(fd);
        return 1;
    }
    
    // Set Max Speed
    if (ioctl(fd, SPI_IOC_WR_MAX_SPEED_HZ, &speed) < 0) {
        perror("Error setting max speed");
        close(fd);
        return 1;
    }

    // 3. Prepare the SPI Transaction
    // Byte 0: Register Address (0xD0)
    // Byte 1: Dummy byte (0x00) to clock out the response
    uint8_t tx_buffer[] = { REG_ID, 0x00 };
    uint8_t rx_buffer[sizeof(tx_buffer)] = { 0 };

    struct spi_ioc_transfer tr = {
        .tx_buf = (unsigned long)tx_buffer,
        .rx_buf = (unsigned long)rx_buffer,
        .len = sizeof(tx_buffer),
        .speed_hz = speed,
        .delay_usecs = 0,
        .bits_per_word = bits,
        .cs_change = 0,
    };

    // 4. Send/Receive Data
    // SPI_IOC_MESSAGE(1) tells the driver we are sending 1 structure
    ret = ioctl(fd, SPI_IOC_MESSAGE(1), &tr);
    if (ret < 1) {
        perror("Error sending SPI message");
        close(fd);
        return 1;
    }

    // 5. Parse Result
    // rx_buffer[0] is garbage (received while we sent the address)
    // rx_buffer[1] is the actual data received while we sent the dummy byte
    uint8_t chip_id = rx_buffer[1];

    printf("SPI Transaction Complete.\n");
    printf("Read Chip ID: 0x%02X\n", chip_id);

    if (chip_id == 0x60) {
        printf("Result: Valid BME280 Sensor.\n");
    } else if (chip_id == 0x58) {
        printf("Result: BMP280 Sensor detected (no humidity).\n");
    } else {
        printf("Result: Unknown or invalid ID.\n");
    }

    // 6. Cleanup
    close(fd);
    return 0;
}