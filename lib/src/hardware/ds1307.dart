// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Resources
// https://github.com/adafruit/Adafruit_CircuitPython_DS1307/blob/main/adafruit_ds1307.py
// https://github.com/brainelectronics/micropython-ds1307/blob/main/ds1307/ds1307.py

import 'package:dart_periphery/dart_periphery.dart';

/// Default address of the [DS1307] sensor.
const int ds1307DefaultI2Caddress = 0x68;

/// [DS1307] register
enum DS1307reg {
  dateTime(0),
  chipHalt(128),
  controlReg(7),
  ramlReg(8);

  const DS1307reg(this.reg);
  final int reg;
}

/// [DS1307] exception
class DS1307exception implements Exception {
  DS1307exception(this.errorMsg);
  final String errorMsg;
  @override
  String toString() => errorMsg;
}

int bcd2dec(int value) {
  return ((value >> 4) * 10) + (value & 0x0F);
}

int dec2bcd(int value) {
  return (value ~/ 10) << 4 | (value % 10);
}

/// DS1307 real time clock
///
/// See for more
/// * [DS1307 example code](https://github.com/pezi/dart_periphery/blob/main/example/i2c_ds1307.dart)
/// * [Source code](https://github.com/pezi/dart_periphery/blob/main/lib/src/hardware/ds1307.dart)
/// * [Datasheet](https://www.analog.com/media/en/technical-documentation/data-sheets/ds1307.pdf)
class DS1307 {
  final I2C i2c;
  final int i2cAddress;

  // Creates a DS1307 rtc instance that uses the [i2c] bus with
  /// the optional [i2cAddress].
  DS1307(this.i2c, [this.i2cAddress = ds1307DefaultI2Caddress]) {
    // minimal self test
    //
    // read  8-bit register 0x03: bit 0-3 day, bit 4-7 always 0
    var value = i2c.readByteReg(ds1307DefaultI2Caddress, 0x03);
    if (value & ((0xFF << 3 & 0xFF)) != 0) {
      throw DS1307exception("DS1307 RTC not found");
    }
  }

  DateTime getDateTime() {
    var data =
        i2c.readBytesReg(ds1307DefaultI2Caddress, DS1307reg.dateTime.reg, 7);
    int year = bcd2dec(data[6]) + 2000;
    int month = bcd2dec(data[5]);
    int day = bcd2dec(data[4]);
    int hour = bcd2dec(data[2]);
    int minute = bcd2dec(data[1]);
    int second = bcd2dec(data[0] & 0x7f);

    // Create a DateTime object with time.
    return DateTime(year, month, day, hour, minute, second);
  }

  void setDateTime(DateTime dateTime) {
    var data = List<int>.filled(7, 0);
    data[0] = dec2bcd(dateTime.second);
    data[1] = dec2bcd(dateTime.minute);
    data[2] = dec2bcd(dateTime.hour);
    data[3] = dec2bcd(dateTime.weekday);
    data[4] = dec2bcd(dateTime.day);
    data[5] = dec2bcd(dateTime.month);
    data[6] = dec2bcd(dateTime.year - 2000);

    i2c.writeBytesReg(ds1307DefaultI2Caddress, DS1307reg.dateTime.reg, data);
  }
}
