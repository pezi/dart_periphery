// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_periphery/dart_periphery.dart';
import 'dart:io';

/// PCF8591 ADC+DAC combo
///
/// Datasheet: https://cdn-learn.adafruit.com/downloads/pdf/adafruit-pcf8591-adc-dac.pdf
///
void main() {
  // Select the right I2C bus number /dev/i2c-?
  // 1 for Raspberry Pi, 0 for NanoPi (Armbian), 2 Banana Pi (Armbian)
  var i2c = I2C(1);
  var pfc = PFC8591(i2c);
  while (true) {
    // read 8-bit value from pin 0
    print(pfc.read(Pin.a0));
    sleep(Duration(seconds: 1));
  }
}
