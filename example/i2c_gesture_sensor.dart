// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_periphery/dart_periphery.dart';

// https://wiki.seeedstudio.com/Grove-Gesture_v1.0
// Grove Gesture sensor
void main() {
  // Select the right I2C bus number /dev/i2c-?
  // 1 for Raspbery Pi, 0 for NanoPi (Armbian), 2 Banana Pi (Armbian)
  var i2c = I2C(1);
  try {
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
