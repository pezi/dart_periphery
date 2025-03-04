// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dart_periphery/dart_periphery.dart';
import 'dart:convert';

/// AT24C128 256 KB EEPROM
///
///  https://ww1.microchip.com/downloads/en/DeviceDoc/doc0670.pdf
///  https://www.youtube.com/watch?v=SgJ0_HUsxOU
void main() {
  // Select the right I2C bus number /dev/i2c-?
  // 1 for Raspberry Pi, 0 for NanoPi (Armbian), 2 Banana Pi (Armbian), 4 BPI-F3
  var i2c = I2C(1);
  try {
    // Be aware, this demo uses a ASCII (8-bit String)
    // User utf8.encode()
    var data = "The quick brown fox jumps over the lazy dog";
    var rawData = utf8.encode(data);
    print("Write test string:  $data");
    i2c.writeBytesReg(
        0x50, 0, rawData, BitOrder.msbFirst, RegisterWidth.bits16);
    print("wait..");
    sleep(Duration(seconds: 1));
    print("Read written data from EEPROM");
    var decoded = utf8.decode(i2c.readBytesReg(
        0x50, 0, rawData.length, BitOrder.msbFirst, RegisterWidth.bits16));
    print(decoded);
  } finally {
    i2c.dispose();
  }
}
