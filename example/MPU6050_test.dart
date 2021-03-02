// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_periphery/dart_periphery.dart';

import 'package:dart_periphery/src/hardware/util.dart';
import 'dart:io';

// https://github.com/Raspoid/raspoid/blob/master/src/main/com/raspoid/additionalcomponents/MPU6050.java
// https://elektro.turanis.de/html/prj075/index.html#h8

const int MPU6050_ADRESS = 0x68;

const int ACCEL_OFFSET = 200;
const int GYRO_OFFSET = 151; // 151
const int GYRO_SENSITITY = 131; // 131 is sensivity of gyro from data sheet
const double GYRO_SCALE = 0.2; //  0.02 by default - tweak as required
const double LOOP_TIME = 0.15; // 0.

int map(int x, int in_min, int in_max, int out_min, int out_max) =>
    (x - in_min) * (out_max - out_min) ~/ (in_max - in_min) + out_min;

int constrain(int amt, int low, int high) =>
    ((amt) < (low) ? (low) : ((amt) > (high) ? (high) : (amt)));

class MPU6050 {
  final I2C i2c;
  MPU6050(this.i2c) {
    i2c.writeByte(MPU6050_ADRESS, 0x6B);
    i2c.writeByte(MPU6050_ADRESS, 0);
  }

  void getValues() {
    i2c.writeByte(MPU6050_ADRESS, 0x3B);
    var buf = ByteBuffer(i2c.readBytes(MPU6050_ADRESS, 14), ByteBufferSrc.I2C,
        BitOrder.MSB_FIRST);
    var accAngle = <int>[];
    var gyroAngle = <double>[];
    double temperature;
    for (var i = 0; i < 3; ++i) {
      var accCorr = buf.getInt16() - ACCEL_OFFSET;
      accCorr = map(accCorr, -16800, 16800, -90, 90);
      accAngle.add(constrain(accCorr, -90, 90));
    }
    temperature = (buf.getInt16() + 12412.0) / 340.0;
    for (var i = 0; i < 3; ++i) {
      var gyroCorr = ((buf.getInt16() / GYRO_SENSITITY) - GYRO_OFFSET);
      gyroAngle.add((gyroCorr * GYRO_SCALE) * -LOOP_TIME);
    }
    print(
        'ACCEL_X: ${accAngle[0]}  ACCEL_Y: ${accAngle[1]} ACCEL_Z: ${accAngle[2]}');
    print('Temperature: ${temperature.toStringAsFixed(2)}');
    print(
        'GYRO_XOUT: ${gyroAngle[0]}  GYRO_YOUT: ${gyroAngle[1]} GYRO_ZOUT: ${gyroAngle[2]}');
  }
}

void main() {
  var i2c = I2C(1);
  try {
    var mpu = MPU6050(i2c);
    while (true) {
      mpu.getValues();
      sleep(Duration(milliseconds: (LOOP_TIME * 1000).toInt()));
    }
  } finally {
    i2c.dispose();
  }
}
