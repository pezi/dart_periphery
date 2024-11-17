// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_periphery/dart_periphery.dart';
import 'dart:io';

/// SDC30 - CO2 & Temperature & Humidity Sensor
///
/// https://www.seeedstudio.com/Grove-CO2-Temperature-Humidity-Sensor-SCD30-p-2911.html
///
void main() {
  // Select the right I2C bus number /dev/i2c-?
  // 1 for Raspberry Pi, 0 for NanoPi (Armbian), 2 Banana Pi (Armbian)
  var i2c = I2C(0);
  try {
    var s = SDC30(i2c);
    // firmware version major: 3; minor: 66;
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
