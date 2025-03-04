// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_periphery/dart_periphery.dart';
import 'dart:convert';

/// AT24C128 256 KB EEPROM
///
///  https://ww1.microchip.com/downloads/en/DeviceDoc/doc0670.pdf
///
void main() {
  // Select the right I2C bus number /dev/i2c-?
  // 1 for Raspberry Pi, 0 for NanoPi (Armbian), 2 Banana Pi (Armbian), 4 BPI-F3
  var i2c = I2C(1);
  try {
    var data = "The quick brown fox jumps over the lazy dog";

    i2c.writeBytesReg(0x50, 0, data.codeUnits);
  } finally {
    i2c.dispose();
  }
}
