// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_periphery/dart_periphery.dart';

/// DS1307 real time clock
///
/// https://wiki.seeedstudio.com/Grove-RTC
///
/// Hint: Be aware that many DS1307 modules in circulation operate
/// exclusively at 5V.
void main() {
  // Select the right I2C bus number /dev/i2c-?
  // 1 for Raspberry Pi, 0 for NanoPi (Armbian), 2 Banana Pi (Armbian)
  var i2c = I2C(1);
  try {
    print("dart_periphery Version: $dartPeripheryVersion");
    print("c-periphery Version   : ${getCperipheryVersion()}");
    print('I2C info: ${i2c.getI2Cinfo()}');
    print("DS1307 real time clock");

    var rtc = DS1307(i2c);
    print(rtc.getDateTime());
  } finally {
    i2c.dispose();
  }
}
