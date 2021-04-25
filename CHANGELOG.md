## 0.8.25-RC 2021-04-26

* Add isolate support for SPI, I2C and Serial.

## 0.8.24-beta 2021-04-23

* Port test scripts for GPIO and GPIO (sysfs) - fix errors
* Add isolate support for GPIO

## 0.8.23-beta 2021-04-18

* Fix SPI.transfer() crash - double call of native free

## 0.8.22-beta 2021-04-17

* Switch to Dart 2.12.4
* Remove any glue C library - access the c-periphery library only with FFI.
* Extended flutter-pi support.
* Port test scripts for PWM, Serial, I2C, SPI and Led - fix errors

## 0.8.21-beta 2021-03-28

* Fix [MPU6050 sensor](https://github.com/pezi/dart_periphery/blob/main/example/i2c_mpu6050.dart) - second fix
* Add JSON support for BME680, BME280, SGP30 and SHT31

## 0.8.20-beta 2021-03-25

* Fix [MPU6050 sensor](https://github.com/pezi/dart_periphery/blob/main/example/i2c_mpu6050.dart) - rework implementation

## 0.8.19-beta 2021-03-19

* Rework Dart doucmentation/API-documentation
* Switch to Dart 2.12.2

## 0.8.18-beta 2021-03-18

* Rework Dart documentation/API-documentation

## 0.8.17-beta 2021-03-17

* Improve BME280 sensor class, make some methods public.
* Rework BME680, SGP30 sensor

## 0.8.16-beta 2021-03-16

* Fix PWM setter/getter for PWM properties

## 0.8.15-beta 2021-03-13

* [BME680 support](https://wiki.seeedstudio.com/Grove-Temperature_Humidity_Pressure_Gas_Sensor_BME680/) - see [example](https://github.com/pezi/dart_periphery/blob/main/example/i2c_bme680.dart).

## 0.8.14-beta 2021-03-11

* MPU6050 support - Six-Axis (Gyro + Accelerometer) sensor
* Update README.md

## 0.8.12-beta 2021-03-09

* [Grove-VOC and eCO2 Gas Sensor(SGP30)](https://wiki.seeedstudio.com/Grove-VOC_and_eCO2_Gas_Sensor-SGP30/) support - see [example](https://github.com/pezi/dart_periphery/blob/main/example/i2c_sgp30.dart).
* [Grove Gesture](https://wiki.seeedstudio.com/Grove-Gesture_v1.0/) support - see [example](https://github.com/pezi/dart_periphery/blob/main/example/i2c_gesture_sensor.dart).
* Reorganize examples

## 0.8.11-beta 2021-03-05

* Update FFI code - simplify code
* Fix PWM.disable()
* Fix GPIO.pollMultiple()

## 0.8.10-beta 2021-03-04

* Switch to Dart 2.12.0 and ffi: ^1.0.0
* Update dart_periphery to null safety
* Fix example.dart problem
* Fix GPIO.sysfs

## 0.8.9-beta 2021-02-29

* Fix SPI.openAdvanced2()
* Fix I2C.readBytes()
* Add first version of MPU6050 support
* Extend ByteBuffer class
* Improve BME280 class

## 0.8.8-beta 2021-02-28

* Add correct exception for loading native libraries inside flutter-pi  
* Update README.md for [flutter-pi](https://github.com/ardera/flutter-pi)

## 0.8.7-beta 2021-02-24

* Release [MMIO (Memory Mapped I/O) support](https://github.com/pezi/dart_periphery/blob/main/example/mmio_example.dart).

## 0.8.6-beta 2021-02-24

* Improve documentation

## 0.8.5-beta 2021-02-21

* Add [example/spi_loopback.dart](https://github.com/pezi/dart_periphery/blob/main/example/spi_loopback.dart)
* Fix SPI transfer() implementation.

## 0.8.4-beta 2021-02-19

* Add expansion hat support for BakeBit (Friendly Arm), Grove Base Hat and Grove Pi Plus.

## 0.8.3-beta 2021-02-18

* Add SHT31 sensor support - temperature and humidity.
* Fix BME280 problem - wrong values for pressure and humidity due the last error.
* Fix i2c writeXXXReg implementation.

## 0.8.0-beta 2021-02-14

* Release SPI support.
* BME280/BMP280 sensor support - temperature, pressure and humidity (BME280 only).

## 0.7.6-beta 2021-02-09

* Fix C linker problem with periphery_version_info().

## 0.7.5-beta 2021-02-09

* Update pupspec.yaml, solve linter error and warnings.
* Release PWM support.

## 0.7.1-beta 2021-02-07

* Update pupspec.yaml, solve linter error and warnings.  
* Add method getCperipheryVersion().

## 0.7.0-beta 2021-02-06

* Initial development release.
