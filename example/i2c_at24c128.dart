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

  var defaultAT24C128address = 0x50;

  var i2c = I2C(1);

  print('Dart version: ${Platform.version}');
  print("dart_periphery Version: $dartPeripheryVersion");
  print("c-periphery Version   : ${getCperipheryVersion()}");
  print('I2C info: ${i2c.getI2Cinfo()}');
  try {
    var data = "The quick brown fox jumps over the lazy dog";
    // for ASCII data you can use data.codeUnits instead
    var rawData = utf8.encode(data);
    print("Write test string: $data");
    i2c.writeBytesReg(defaultAT24C128address, 0, rawData, BitOrder.msbFirst,
        RegisterWidth.bits16);
    print("wait..");
    sleep(Duration(seconds: 1));
    print("Read written data from EEPROM");
    var decoded = utf8.decode(i2c.readBytesReg(defaultAT24C128address, 0,
        rawData.length, BitOrder.msbFirst, RegisterWidth.bits16));
    print(decoded);
  } finally {
    i2c.dispose();
  }
}
