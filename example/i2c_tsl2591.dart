// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dart_periphery/dart_periphery.dart';

///  TSL2591 sensor for visible, IR light, full spectrum and lux.
///
///  https://www.adafruit.com/product/1980
void main() {
  // Select the right I2C bus number /dev/i2c-?
  // 1 for Raspberry Pi, 0 for NanoPi (Armbian), 2 Banana Pi (Armbian
  var i2c = I2C(1);
  try {
    print("dart_periphery Version: $dartPeripheryVersion");
    print("c-periphery Version   : ${getCperipheryVersion()}");
    print('I2C info: ${i2c.getI2Cinfo()}');
    print("TSL2591 sensor");
    var s = TSL2591(i2c);
    while (true) {
      var result = s.getRawLuminosity();

      print("Lux : ${result.getLux()}");
      print("Full spectrum : ${result.getFullSpectrum()}");
      print("Visible : ${result.getVisible()}");
      print("Infra red: ${result.getInfraRed()}");
      sleep(Duration(milliseconds: 1000));
    }
  } finally {
    i2c.dispose();
  }
}
