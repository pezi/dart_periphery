// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_periphery/dart_periphery.dart';
import 'dart:io';

// https://wiki.seeedstudio.com/Grove-Gesture_v1.0
// Grove Gesture sensor
void main() {
  // Select the right I2C bus number /dev/i2c-?
  // 1 for Raspbery Pi, 0 for NanoPi (Armbian), 2 Banana Pi (Armbian)
  var i2c = I2C(1);
  try {
    var mpu = MPU6050(i2c);
    while (true) {
      print(mpu.getAccelAccelerations());
      print(mpu.getAccelAngles());
      print(mpu.getFilteredAngles());
      sleep(Duration(milliseconds: 1000));
    }
  } finally {
    i2c.dispose();
  }
}
