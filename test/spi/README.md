Here is the Python code to read the BME280 ID using the SPI interface.

SPI communication is faster and more robust than I2C over longer distances, but it requires more wires (4 data wires + power). We will use the standard spidev library.
1. Prerequisites

    Enable SPI: On a Raspberry Pi, run sudo raspi-config > Interface Options > SPI > Enable.

    Install Library:
    Bash

    pip install spidev

2. Wiring Context

SPI requires specific wiring. The BME280 supports SPI modes '00' and '11'.

    VIN -> 3.3V

    GND -> GND

    SCL (SCK) -> SCLK (Pin 23 / GPIO 11)

    SDA (MOSI) -> MOSI (Pin 19 / GPIO 10)

    SDO (MISO) -> MISO (Pin 21 / GPIO 9)

    CS (CSB) -> CE0 (Pin 24 / GPIO 8) Note: You can also use CE1 if you change the code to device 1.

    Important Hardware Note: On many BME280 breakout boards, the SPI interface is only activated when the CS pin is pulled LOW. If CS is left floating or tied high, the chip defaults to I2C mode.