// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_periphery/dart_periphery.dart';

/// SHT4x - temperature and humidity sensor
///
/// https://wiki.seeedstudio.com/Grove-SHT4x
///
void main() {
  // Select the right I2C bus number /dev/i2c-?
  // 1 for Raspberry Pi, 0 for NanoPi (Armbian), 2 Banana Pi (Armbian), 4 BPI-F3
  var i2c = I2C(1);
  try {
    print("dart_periphery Version: $dartPeripheryVersion");
    print("c-periphery Version   : ${getCperipheryVersion()}");
    print('I2C info: ${i2c.getI2Cinfo()}');
    print("SHT4x sensor");

    var sht4x = SHT4x(i2c);
    print('Serial number: ${sht4x.getSerialNumber()}');
    print("Current mode ${sht4x.getMode().getInfo()}");

    // default mode - set other [Mode] for e.g. heating
    // sht4x.setMode(Mode.noHeatHighPrecision);

    var r = sht4x.getValues();
    print('SHT4x [t°] ${r.temperature.toStringAsFixed(2)}');
    print('SHT4x [%°] ${r.humidity.toStringAsFixed(2)}');
  } finally {
    i2c.dispose();
  }
}
