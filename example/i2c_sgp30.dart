// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_periphery/dart_periphery.dart';
import 'dart:io';

// https://wiki.seeedstudio.com/Grove-VOC_and_eCO2_Gas_Sensor-SGP30/
// The Grove-VOC and eCO2 Gas Sensor(SGP30) is an air quality detection sensor based on the SGP30 chip.
void main() {
  // Select the right I2C bus number /dev/i2c-?
  // 1 for Raspbery Pi, 0 for NanoPi (Armbian), 2 Banana Pi (Armbian)
  var s = SGP30(I2C(1));
  print('Serial number: ${s.getSerialId()}');
  print(s.getFeatureSetVersion());
  sleep(Duration(milliseconds: 1000));
  var count = 0;
  while (true) {
    s.measureIaq();
    print(s.measureRaw());
    sleep(Duration(milliseconds: 1000));
    ++count;
    if (count == 30) {
      count = 0;
      print(s.measureIaq());
    }
  }
}
