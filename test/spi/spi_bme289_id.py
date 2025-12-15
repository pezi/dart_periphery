import spidev
import time

def get_bme280_id_spi():
    # --- Configuration ---
    SPI_BUS = 0
    SPI_DEVICE = 0  # 0 for CE0 (Pin 24), 1 for CE1 (Pin 26)
    
    # BME280 ID Register = 0xD0
    # In SPI, the MSB (bit 7) represents Read(1)/Write(0).
    # 0xD0 is 11010000 in binary, so the Read bit is already set.
    REG_ID = 0xD0 
    
    try:
        # Initialize SPI
        spi = spidev.SpiDev()
        spi.open(SPI_BUS, SPI_DEVICE)
        
        # Set SPI speed and mode
        # BME280 supports up to 10MHz, but 1MHz is safe and reliable.
        spi.max_speed_hz = 1000000 
        spi.mode = 0  # Mode 0 (CPOL=0, CPHA=0) is standard for BME280
        
        # SPI Transaction:
        # We send [Register Address, Dummy Byte]
        # The sensor receives the address in the first cycle
        # and sends the data back during the dummy byte cycle.
        response = spi.xfer2([REG_ID, 0x00])
        
        # The first byte in 'response' is garbage (received while we sent the address).
        # The second byte is our actual data.
        chip_id = response[1]
        
        spi.close()
        return chip_id

    except Exception as e:
        print(f"An error occurred: {e}")
        return None

if __name__ == "__main__":
    print("Reading BME280 Chip ID via SPI...")
    
    id_value = get_bme280_id_spi()
    
    if id_value is not None:
        print(f"Success! Chip ID: {hex(id_value)}")
        
        # Validation
        if id_value == 0x60:
            print("Status: Valid BME280 sensor detected.")
        elif id_value == 0x58:
            print("Status: BMP280 detected (No humidity).")
        elif id_value == 0x00 or id_value == 0xFF:
            print("Status: Invalid ID. Check wiring, specifically the CS pin.")
        else:
            print(f"Status: Unknown ID {hex(id_value)}.")