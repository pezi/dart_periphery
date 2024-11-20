// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dart_periphery/dart_periphery.dart';

// MCP9808 high accuracy temperature sensor
//
// https://www.seeedstudio.com/Grove-I2C-High-Accuracy-Temperature-Sensor-MCP9808.html
//
void main() {
  // Select the right I2C bus number /dev/i2c-?
  // 1 for Raspberry Pi, 0 for NanoPi (Armbian), 2 Banana Pi (Armbian)
  var i2c = I2C(1);
  try {
    print("dart_periphery Version: $dartPeripheryVersion");
    print("c-periphery Version   : ${getCperipheryVersion()}");
    print('I2C info :${i2c.getI2Cinfo()}');
    print("MCP9808 sensor");

    var sensor = MCP9808(i2c);
    sleep(Duration(milliseconds: 100));
    var r = sensor.getValue();
    print('MCP9808 [t°] ${r.temperature.toStringAsFixed(2)}');
  } finally {
    i2c.dispose();
  }
}
