// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_periphery/dart_periphery.dart';
import 'dart:io';

// MPU-6050 Six-Axis (Gyro + Accelerometer)
// Datasheet: https://invensense.tdk.com/products/motion-tracking/6-axis/mpu-6050/
void main() {
  // Select the right I2C bus number /dev/i2c-?
  // 1 for Raspbery Pi, 0 for NanoPi (Armbian), 2 Banana Pi (Armbian)
  var i2c = I2C(2);
  try {
    var mpu = MPU6050(i2c);
    print(
        'First GyroAngularSpeedsOffsets: ${mpu.getGyroAngularSpeedsOffsets()}');

    for (var i = 0; i < 3; ++i) {
      mpu.updateValues();

      print('AccelAccelerations: ${mpu.getAccelAccelerations()}');
      print('AccelAngles: ${mpu.getAccelAngles()}');
      print('GyroAngularSpeedsOffsets: ${mpu.getGyroAngularSpeedsOffsets()}');
      print('GyroAngularSpeeds: ${mpu.getGyroAngularSpeeds()}');
      print('\n');

      /*
      print('FilteredAngles: ${mpu.getFilteredAngles()}');
      print('GyroAngles: ${mpu.getGyroAngles()}');
      print('GyroAngularSpeeds: ${mpu.getGyroAngularSpeeds()}');
      print('GyroAngularSpeedsOffsets: ${mpu.getGyroAngularSpeedsOffsets()}');
      */
      sleep(Duration(milliseconds: 1000));
    }
  } finally {
    i2c.dispose();
  }
}
