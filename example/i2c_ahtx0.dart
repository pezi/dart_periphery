// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dart_periphery/dart_periphery.dart';
import 'package:dart_periphery/src/hardware/ahtx0.dart';

//// AHT10, AHT20 temperature and humidity sensor.
///
/// https://botland.store/multifunctional-sensors/17199-aht20-temperature-and-humidity-sensor-i2c-adafruit-4566-5904422364311.html
void main(List<String> args) {
  // Select the right I2C bus number /dev/i2c-?
  // 1 for Raspberry Pi, 0 for NanoPi (Armbian), 2 Banana Pi (Armbian), 4 BPI-F3
  var i2c = I2C(1);

  try {
    print("dart_periphery Version: $dartPeripheryVersion");
    print("c-periphery Version   : ${getCperipheryVersion()}");
    print('I2C info: ${i2c.getI2Cinfo()}');
    print("AHT1X sensor");
    var athx0 = AHTX0(i2c);
    while (true) {
      try {
        var v = athx0.getValues();
        print('AHT1X [t°] ${v.temperature.toStringAsFixed(2)}');
        print('AHT1X [%°] ${v.humidity.toStringAsFixed(2)}');
        sleep(Duration(seconds: 5));
      } on Exception catch (e) {
        print(e.toString());
      }
    }
  } finally {
    i2c.dispose();
  }
}
