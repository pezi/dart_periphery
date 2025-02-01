// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../dart_periphery.dart';

// Resources
// https://github.com/adafruit/Adafruit_CircuitPython_DS1307/blob/main/adafruit_ds1307.py
// https://github.com/brainelectronics/micropython-ds1307/blob/main/ds1307/ds1307.py

/// Default address of the [DS1307] sensor.
const int ds1307DefaultI2Caddress = 0x68;

/// [DS1307] exception
class DS1307exception implements Exception {
  DS1307exception(this.errorMsg);
  final String errorMsg;
  @override
  String toString() => errorMsg;
}

/// DS1307 real time clock
///
/// See for more
/// * [SHT31 example code](https://github.com/pezi/dart_periphery/blob/main/example/i2c_ds1307.dart)
/// * [Source code](https://github.com/pezi/dart_periphery/blob/main/lib/src/hardware/ds1307.dart)
/// * [Datasheet](https://www.analog.com/media/en/technical-documentation/data-sheets/ds1307.pdf)
class DS1307 {
  final I2C i2c;
  final int i2cAddress;

  // Creates a SHT31 sensor instance that uses the [i2c] bus with
  /// the optional [i2cAddress].
  DS1307(this.i2c, [this.i2cAddress = ds1307DefaultI2Caddress]) {
    var value = i2c.readByteReg(ds1307DefaultI2Caddress, 0x07);
    if (value & 0x6C != 0) {
      throw DS1307exception("Unable to find DS1307 at i2c address 0x68.");
    }
    value = i2c.readByteReg(ds1307DefaultI2Caddress, 0x03);
    if (value & 0x6C != 0xF8) {
      throw DS1307exception("Unable to find DS1307 at i2c address 0x68.");
    }
  }
}
