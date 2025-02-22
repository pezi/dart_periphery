// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_periphery/dart_periphery.dart';
import 'dart:io';

/// VL53L0X is a Time-of-Flight (ToF) laser-ranging module.
/// It can measure absolute distances up to 2 m
///
/// https://wiki.seeedstudio.com/Grove-Time_of_Flight_Distance_Sensor-VL53L0X/
///

void main() {
  // Select the right I2C bus number /dev/i2c-?
  // 1 for Raspberry Pi, 0 for NanoPi (Armbian), 2 Banana Pi (Armbian), 4 BPI-F3
  var i2c = I2C(1);
  var v = VL53L0X(i2c);
  while (true) {
    print("Distance [mm]: ${v.getRange()}");
    sleep(Duration(seconds: 1));
  }
}
