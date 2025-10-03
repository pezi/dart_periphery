// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dart_periphery/dart_periphery.dart';

/// SGP30 sensor - VOC and eCO2 gas, air quality detection sensor
///
/// https://wiki.seeedstudio.com/Grove-VOC_and_eCO2_Gas_Sensor-SGP30/
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
    print("SGP30 sensor");

    var s = SGP30(i2c);
    print('Serial number: ${s.getSerialId()}');
    print(s.getFeatureSetVersion());
    sleep(Duration(milliseconds: 1000));
    var count = 0;
    while (true) {
      print(s.measureIaq());
      print(s.measureRaw());
      sleep(Duration(milliseconds: 1000));
      ++count;
      if (count == 30) {
        count = 0;
        print(s.measureIaq());
      }
    }
  } finally {
    i2c.dispose();
  }
}
