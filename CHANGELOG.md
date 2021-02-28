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