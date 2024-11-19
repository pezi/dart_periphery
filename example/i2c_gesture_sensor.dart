// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_periphery/dart_periphery.dart';

// Grove gesture sensor
//
// https://wiki.seeedstudio.com/Grove-Gesture_v1.0
//
void main() {
  // Select the right I2C bus number /dev/i2c-?
  // 1 for Raspberry Pi, 0 for NanoPi (Armbian), 2 Banana Pi (Armbian)
  var i2c = I2C(1);

  try {
    print("dart_periphery Version: $dartPeripheryVersion");
    print("c-periphery Version   : ${getCperipheryVersion()}");
    print('I2C info:${i2c.getI2Cinfo()}');
    print("Gesture sensor");

    var gesture = GestureSensor(i2c);
    print('Grove Gesture sensor is running...');
    while (true) {
      var g = gesture.getGesture();
      if (g != Gesture.nothing) {
        print(g.toString());
      }
    }
  } finally {
    i2c.dispose();
  }
}
