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
/// Source: https://github.com/adafruit/Adafruit_CircuitPython_VL53L0X/tree/main/examples

void main(List<String> args) {
  // Select the right I2C bus number /dev/i2c-?
  // 1 for Raspberry Pi, 0 for NanoPi (Armbian), 2 Banana Pi (Armbian), 4 BPI-F3
  var i2c = I2C(1);
  try {
    print('Dart version: ${Platform.version}');
    print("dart_periphery Version: $dartPeripheryVersion");
    print("c-periphery Version   : ${getCperipheryVersion()}");
    print('I2C info: ${i2c.getI2Cinfo()}');
    print("VL53L0X sensor");

    var v = VL53L0X(i2c);
    if (args.length != 1) {
      print("missing parameter: simple or continous");
    }
    if (args.first == 'simple') {
      print("Simple mode");
      while (true) {
        print("Distance [mm]: ${v.getRange()}");
        sleep(Duration(seconds: 1));
      }
    } else {
      print("Continuous mode");
      // Optionally adjust the measurement timing budget to change speed and accuracy.
      // See the example here for more details:
      //   https://github.com/pololu/vl53l0x-arduino/blob/master/examples/Single/Single.ino
      // For example a higher speed but less accurate timing budget of 20ms:
      // vl53.measurement_timing_budget = 20000
      // Or a slower but more accurate timing budget of 200ms:
      v.setMeasurementTimingBudget(200000);
      v.startContinuous();
      try {
        while (true) {
          // try to adjust the sleep time (simulating program doing something else)
          // and see how fast the sensor returns the range
          sleep(Duration(microseconds: 100));
          var time = DateTime.now().millisecondsSinceEpoch;
          var range = v.getRange();
          var div = DateTime.now().millisecondsSinceEpoch - time;
          print("Range: $range mm $div ms");
        }
      } on Exception catch (e) {
        print('Exception details:\n $e');
      } finally {
        v.startContinuous();
      }
    }
  } finally {
    i2c.dispose();
  }
}
