// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_periphery/dart_periphery.dart';
import 'dart:io';

/// SCD30 - CO2, temperature and humidity sensor
///
/// https://www.seeedstudio.com/Grove-CO2-Temperature-Humidity-Sensor-SCD30-p-2911.html
///
void main() {
  // Select the right I2C bus number /dev/i2c-?
  // 1 for Raspberry Pi, 0 for NanoPi (Armbian), 2 Banana Pi (Armbian), 4 BPI-F3
  var i2c = I2C(1);
  try {
    print('Dart version: ${Platform.version}');
    print("dart_periphery Version: $dartPeripheryVersion");
    print("c-periphery Version   : ${getCperipheryVersion()}");
    print('I2C info: ${i2c.getI2Cinfo()}');
    print("SCD30 sensor");

    var s = SCD30(i2c);
    var firmware = s.getFirmwareVersion();
    print("Firmware: ${firmware >> 8}.${firmware & 0xff}");
    while (true) {
      sleep(Duration(seconds: 4));
      var v = s.getValues();
      if (v.available) {
        print(v);
      }
    }
  } finally {
    i2c.dispose();
  }
}
