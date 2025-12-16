// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dart_periphery/dart_periphery.dart';

/// BME280 - high-precision, low-power combined humidity, pressure, and
/// temperature sensor
///
///  https://wiki.seeedstudio.com/Grove-Barometer_Sensor-BME280/
///
/// VIN -> 3.3V
/// GND -> GND
/// SCL (SCK) -> SCLK (Pin 23 / GPIO 11)
/// SDA (MOSI) -> MOSI (Pin 19 / GPIO 10)
/// SDO (MISO) -> MISO (Pin 21 / GPIO 9)
/// CS (CSB) -> CE0 (Pin 24 / GPIO 8) Note: You can also use CE1 if you change the code to device 1.

void main() {
  var spi = SPI(0, 0, SPImode.mode0, 1000000);
  try {
    print('Dart version: ${Platform.version}');
    print("dart_periphery Version: $dartPeripheryVersion");
    print("c-periphery Version   : ${getCperipheryVersion()}");
    print('SPI info: ${spi.getSPIinfo()}');
    print("BME280 sensor");

    var bme280 = BME280.spi(spi);
    var r = bme280.getValues();
    print('Temperature [°] ${r.temperature.toStringAsFixed(1)}');
    print('Humidity [%] ${r.humidity.toStringAsFixed(1)}');
    print('Pressure [hPa] ${r.pressure.toStringAsFixed(1)}');
  } finally {
    spi.dispose();
  }
}
