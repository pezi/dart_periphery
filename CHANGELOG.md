## 0.9.20
*

## 0.9.19
* Add GPS [Air530](https://github.com/pezi/dart_periphery/blob/main/example/serial_air530.dart)
* Update Dart Version to `3.9.3`
  
## 0.9.18
* Add [AHT20](https://github.com/pezi/dart_periphery/blob/main/example/i2c_ahtx0.dart) temperature and humidity sensor
* Add I2C [AT24C128](https://github.com/pezi/dart_periphery/blob/main/example/i2c_at24c128.dart) 256 KB EEPROM
* Make I2C enum `RegisterWidth` (8/16 bits) public, needed for [AT24C128](https://github.com/pezi/dart_periphery/blob/main/example/i2c_at24c128.dart) EEPROM 16 bit addresses  
* Add [SSD1306](https://github.com/pezi/dart_periphery/blob/main/example/i2c_ssd1306.dart) 128x64 pixel OLED
* Add Java bridge for [SSD1306](https://github.com/pezi/dart_periphery/tree/main/example/i2c_ssd1306_java) 128x64 pixel OLED to simplify image generation. 
* Update c-periphery to `v2.4.3`

## 0.9.17
* Add [SHT4x](https://github.com/pezi/dart_periphery/blob/main/example/i2c_sht4x.dart) temperature and humidity sensor  
* Rework [VL53L0X](https://github.com/pezi/dart_periphery/blob/main/lib/src/hardware/vl53l0x.dart) Time-of-Flight code

## 0.9.16
* Add [VL53L0X](https://github.com/pezi/dart_periphery/blob/main/example/i2c_vl53l0x.dart) Time-of-Flight sensor
* Update to Dart `3.7.0`
* Add platform package switch `linux` only   
* Enable project [WIKI](https://github.com/pezi/dart_periphery/wiki)
* Test dart_periphery on a real [RISC-V Board](https://github.com/pezi/dart_periphery/wiki/BPI_F3)

## 0.9.15

* Add [DS1307/DS3231](https://github.com/pezi/dart_periphery/blob/ps/0.9.19/example/i2c_ds1307.dart) real time clock support
* Set Linux system time - `bool setLinuxLocalTime(DateTime dt)`
* PCF8591 8-bit A/D and D/A converter tested
* Update to Dart 3.6.2

## 0.9.14

* Fix missing TSL2591 initialisation settings
* Add PCF8591 8-bit A/D and D/A converter (NOT TESTED)
* I2C: Change internal data buffers from `Pointer<Int8>` to `Pointer<Uint8>`
* SPI: Fix `List<int> transfer(List<int> data, bool reuseBuffer)`  
* BME280 SPI - fix byte order problem: ` BitOrder.msbLast`
* Update to Dart 3.6.1

## 0.9.13

* Fix I2C `int readByteReg(int address, int register,
      [BitOrder order = BitOrder.msbLast,
      RegisterWidth width = RegisterWidth.bits8])` method - wrong data buffer handling
* Extend extension hat [examples](https://github.com/pezi/dart_periphery/tree/main/example/extension_hats) to GPIO only.                       
* Add extended [button](https://github.com/pezi/dart_periphery/blob/main/example/extension_hats/hat_button_extended.dart) demo.
* Update Dart version reference inside the README to 3.6.0.
* Add Adafruit [TSL2591](https://github.com/pezi/dart_periphery/blob/main/example/i2c_tsl2591.dart) light sensor.

## 0.9.12

* Add section ADC with [example](https://github.com/pezi/dart_periphery/blob/main/example/extension_hats/hat_light_sensor.dart) to README 
* Add [button](https://github.com/pezi/dart_periphery/blob/main/example/extension_hats/hat_button.dart) demo
* Add [PIR motion sensor](https://wiki.seeedstudio.com/Grove-PIR_Motion_Sensor/)
* Add [Light sensor & Led Demo](https://github.com/pezi/dart_periphery/blob/main/example/extension_hats/hat_light_sensor_led.dart)
* SPI: Fix exception - wrong handling of a fixed data list 

## 0.9.11

* Improve extension hat support for [Nano Hat](https://wiki.friendlyelec.com/wiki/index.php/BakeBit_-_NanoHat_Hub), [Grove Base Hat RaspberryPi](https://www.seeedstudio.com/Grove-Base-Hat-for-Raspberry-Pi.html) and [Grove Base Hat RaspberryPi Zero](https://wiki.seeedstudio.com/Grove_Base_Hat_for_Raspberry_Pi_Zero)
* Add [Light sensor](https://github.com/pezi/dart_periphery/blob/main/example/extension_hats/hat_light_sensor.dart) example
* Add [Magnetic switch sensor](https://github.com/pezi/dart_periphery/blob/main/example/extension_hats/hat_magnetic_switch.dart) example
* Add [Magnetic hall sensor ](https://github.com/pezi/dart_periphery/blob/main/example/extension_hats/hat_magnetic_hall.dart) example
* Add [Vibration sensor ](https://github.com/pezi/dart_periphery/blob/main/example/extension_hats/hat_vibration.dart) example

## 0.9.10

* Add [SI1145]( https://www.seeedstudio.com/Grove-Sunlight-Sensor.html) sunlight sensor
* Rework README

## 0.9.9

* Add [SCD30](https://www.seeedstudio.com/Grove-CO2-Temperature-Humidity-Sensor-SCD30-p-2911.html) - CO2, temperature amd humidity sensor
* internal pre-build c-periphery libraries are compressed using the xz format 
  
## 0.9.8

* Fix README

## 0.9.7

* library loader: use dart:ffi Abi instead of uname() for architecture detection
* Fix issue https://github.com/pezi/flutter-pi-sensor-tester/issues/1
* Remove deprecated method: useSharedLibray (typo) -> useSharedLibrary 
* Update Dart version reference inside the README to 3.5.4
* CPU detection - switched from uname() to Dart’s built-in [Abi class](https://api.flutter.dev/flutter/dart-ffi/Abi-class.html)
* I2C: Fix broken int `readWordReg(int address, int register,[BitOrder order = BitOrder.msbLast,RegisterWidth width = RegisterWidth.bits8])` method
* I2C: Add optional `RegisterWidth.bits8` and `RegisterWidth.bits16` parameter to enable 16-bit I2C register - e.g. I2C EEPROM
* Add [MCP9808](https://www.seeedstudio.com/Grove-I2C-High-Accuracy-Temperature-Sensor-MCP9808.html) - high accuracy temperature sensor    
* Add [MLX90615](https://www.seeedstudio.com/Grove-Digital-Infrared-Temperature-Sensor.html) - a non-contact temperature sensor
* add RISC-V support

## 0.9.6

* Add isolate support
* Update Dart version reference inside the readme to 3.4.4.
* [Fix I2C error](https://github.com/pezi/dart_periphery/issues/25)
* Add subproject [flutter-sensor-tester](https://github.com/pezi/flutter-pi-sensor-tester) to the README.md

## 0.9.5

* Rework library loading API and fix some problems.

## 0.9.4

* [pull request](https://github.com/pezi/dart_periphery/pull/20)
* Update Dart version reference inside the readme to 3.0.0.
* Fix typos in README.md
* [issue](https://github.com/pezi/dart_periphery/issues/18)

## 0.9.3

* Fix [issue](https://github.com/pezi/dart_periphery/issues/15#issuecomment-1215737582) 

## 0.9.2

* Update the FFI package, see [issue](https://github.com/pezi/dart_periphery/issues/15) and the Dart version reference inside the readme.  

## 0.9.1

* Various small fixes: documentation, source code format, etc 

## 0.9.0

* **v0.9.0** is an API change release which fixes all the camel case warnings of the source code. When starting this project enums and variables from existing C und Java code were not converted to the camel case.
* [pn532](https://github.com/pezi/dart_periphery/blob/main/example/pn532.dart)-example provided by [UliPranz](https://github.com/pezi/dart_periphery/pull/6), a NFC Reader Module, Thanks to UliPrantz!

## 0.8.29

* Fix documentation

## 0.8.28

* Merge contributions provided by [UliPranz](https://github.com/pezi/dart_periphery/pull/6), a NFC Reader Module, Thanks to UliPrantz!
  
## 0.8.27

* improve documentation, chapter [native libraries](https://pub.dev/packages/dart_periphery#native-libraries) 
* Fix problems with flutter-pi

## 0.8.26

* replace system_info package by native uname() call to detect the cpu architecture.
* add uname() support- see [example](https://github.com/pezi/dart_periphery/blob/main/example/uname.dart).

## 0.8.25-RC

* Add isolate support for SPI, I2C and Serial.

## 0.8.24-beta

* Port test scripts for GPIO and GPIO (sysfs) - fix errors
* Add isolate support for GPIO

## 0.8.23-beta

* Fix SPI.transfer() crash - double call of native free

## 0.8.22-beta

* Switch to Dart 2.12.4
* Remove any glue C library - access the c-periphery library only with FFI.
* Extended flutter-pi support.
* Port test scripts for PWM, Serial, I2C, SPI and Led - fix errors

## 0.8.21-beta

* Fix [MPU6050 sensor](https://github.com/pezi/dart_periphery/blob/main/example/i2c_mpu6050.dart) - second fix
* Add JSON support for BME680, BME280, SGP30 and SHT31

## 0.8.20-beta

* Fix [MPU6050 sensor](https://github.com/pezi/dart_periphery/blob/main/example/i2c_mpu6050.dart) - rework implementation

## 0.8.19-beta

* Rework Dart documentation/API-documentation
* Switch to Dart 2.12.2

## 0.8.18-beta

* Rework Dart documentation/API-documentation

## 0.8.17-beta

* Improve BME280 sensor class, make some methods public.
* Rework BME680, SGP30 sensor

## 0.8.16-beta

* Fix PWM setter/getter for PWM properties

## 0.8.15-beta

* [BME680 support](https://wiki.seeedstudio.com/Grove-Temperature_Humidity_Pressure_Gas_Sensor_BME680/) - see [example](https://github.com/pezi/dart_periphery/blob/main/example/i2c_bme680.dart).

## 0.8.14-beta

* MPU6050 support - Six-Axis (Gyro + Accelerometer) sensor
* Update README.md

## 0.8.12-beta

* [Grove-VOC and eCO2 Gas Sensor(SGP30)](https://wiki.seeedstudio.com/Grove-VOC_and_eCO2_Gas_Sensor-SGP30/) support - see [example](https://github.com/pezi/dart_periphery/blob/main/example/i2c_sgp30.dart).
* [Grove Gesture](https://wiki.seeedstudio.com/Grove-Gesture_v1.0/) support - see [example](https://github.com/pezi/dart_periphery/blob/main/example/i2c_gesture_sensor.dart).
* Reorganize examples

## 0.8.11-beta

* Update FFI code - simplify code
* Fix PWM.disable()
* Fix GPIO.pollMultiple()

## 0.8.10-beta

* Switch to Dart 2.12.0 and ffi: ^1.0.0
* Update dart_periphery to null safety
* Fix example.dart problem
* Fix GPIO.sysfs

## 0.8.9-beta

* Fix SPI.openAdvanced2()
* Fix I2C.readBytes()
* Add first version of MPU6050 support
* Extend ByteBuffer class
* Improve BME280 class

## 0.8.8-beta

* Add correct exception for loading native libraries inside flutter-pi  
* Update README.md for [flutter-pi](https://github.com/ardera/flutter-pi)

## 0.8.7-beta

* Release [MMIO (Memory Mapped I/O) support](https://github.com/pezi/dart_periphery/blob/main/example/mmio_example.dart).

## 0.8.6-beta

* Improve documentation

## 0.8.5-beta

* Add [example/spi_loopback.dart](https://github.com/pezi/dart_periphery/blob/main/example/spi_loopback.dart)
* Fix SPI transfer() implementation.

## 0.8.4-beta

* Add expansion hat support for BakeBit (Friendly Arm), Grove Base Hat and Grove Pi Plus.

## 0.8.3-beta

* Add SHT31 sensor support - temperature and humidity.
* Fix BME280 problem - wrong values for pressure and humidity due the last error.
* Fix i2c writeXXXReg implementation.

## 0.8.0-beta

* Release SPI support.
* BME280/BMP280 sensor support - temperature, pressure and humidity (BME280 only).

## 0.7.6-beta

* Fix C linker problem with periphery_version_info().

## 0.7.5-beta

* Update pupspec.yaml, solve linter error and warnings.
* Release PWM support.

## 0.7.1-beta

* Update pupspec.yaml, solve linter error and warnings.  
* Add method getCperipheryVersion().

## 0.7.0-beta

* Initial development release.
