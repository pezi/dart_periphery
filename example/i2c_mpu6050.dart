// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_periphery/dart_periphery.dart';
import 'dart:io';

// MPU-6050 Six-Axis (Gyro + Accelerometer)
// Datasheet: https://invensense.tdk.com/products/motion-tracking/6-axis/mpu-6050/
void main() {
  // Select the right I2C bus number /dev/i2c-?
  // 1 for Raspberry Pi, 0 for NanoPi (Armbian), 2 Banana Pi (Armbian)
  var i2c = I2C(1);
  try {
    var mpu = MPU6050(i2c);
    var index = 0;
    var wait = 50; // wait 50 ms
    while (true) {
      mpu.updateValues(); // call update with a high frequency to get accurate values
      sleep(Duration(milliseconds: wait));
      index += 50;
      if (index % 1000 == 0) {
        print('AccelAccelerations: ${mpu.getAccelAccelerations()}');
        print('AccelAngles: ${mpu.getAccelAngles()}');
        print('FilteredAngles: ${mpu.getFilteredAngles()}');
        print('GyroAngularSpeedsOffsets: ${mpu.getGyroAngularSpeedsOffsets()}');
        print('GyroAngularSpeeds: ${mpu.getGyroAngularSpeeds()}');
        print('GyroAngles: ${mpu.getGyroAngles()}');
        print('\n');
      }
    }
  } finally {
    i2c.dispose();
  }
}
