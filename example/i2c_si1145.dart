// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_periphery/dart_periphery.dart';

/// Grove - Sunlight Sensor is a multi-channel digital light sensor,
/// which has the ability to detect visible light and infrared light.
///
///  https://www.seeedstudio.com/Grove-Sunlight-Sensor.html
void main() {
  // Select the right I2C bus number /dev/i2c-?
  // 1 for Raspberry Pi, 0 for NanoPi (Armbian), 2 Banana Pi (Armbian
  var i2c = I2C(1);
  try {
    print("dart_periphery Version: $dartPeripheryVersion");
    print("c-periphery Version   : ${getCperipheryVersion()}");
    print('I2C info: ${i2c.getI2Cinfo()}');
    print("SI1145 sensor");
    var s = SI1145(i2c);
    print(s.getValues());
  } finally {
    i2c.dispose();
  }
}
