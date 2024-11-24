// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_periphery/dart_periphery.dart';
import 'dart:io';

/// BME680 - combined temperature, humidity, pressure and gas sensor.
///
/// https://wiki.seeedstudio.com/Grove-Temperature_Humidity_Pressure_Gas_Sensor_BME680/
///
void main() {
  // Select the right I2C bus number /dev/i2c-?
  // 1 for Raspberry Pi, 0 for NanoPi (Armbian), 2 Banana Pi (Armbian)
  var i2c = I2C(1);
  try {
    print("dart_periphery Version: $dartPeripheryVersion");
    print("c-periphery Version   : ${getCperipheryVersion()}");
    print('I2C info: ${i2c.getI2Cinfo()}');
    print("BME680 sensor");

    var bme680 = BME680(i2c);
    while (true) {
      var result = bme680.getValues();
      bme680.getHumidityOversample();
      print('Temperature: ${result.temperature}');
      print('Humidity: ${result.humidity}');
      print('Pressure: ${result.pressure}');
      print('IAQ: ${result.airQualityScore}');
      sleep(Duration(milliseconds: 1000));
    }
  } finally {
    i2c.dispose();
  }
}
