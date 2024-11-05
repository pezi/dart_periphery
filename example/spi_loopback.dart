// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_periphery/dart_periphery.dart';

/// SPI loopback test
void main() {
  // Select the right I2C bus number /dev/i2c-0
  // 1 for Raspberry Pi, 0 for NanoPi
  var spi = SPI(0, 0, SPImode.mode0, 500000);
  try {
    print('SPI info:${spi.getSPIinfo()}');
    var data = <int>[for (int i = 0; i < 10; ++i) i];
    var result = spi.transfer(data, false);
    var index = 0;
    for (var v in data) {
      print('Send $v->Answer ${result[index++]}');
    }
  } finally {
    spi.dispose();
  }
}
