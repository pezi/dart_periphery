// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Resources
// https://github.com/adafruit/Adafruit_CircuitPython_DS1307/blob/main/adafruit_ds1307.py
// https://github.com/brainelectronics/micropython-ds1307/blob/main/ds1307/ds1307.py

import 'package:dart_periphery/dart_periphery.dart';

/// Default address of the [DS1307] sensor.
const int ds1307DefaultI2Caddress = 0x68;

/// [DS1307] oscillator
///
/// 1Hz, 4.096kHz, 8.192kHz or 32.768kHz, or disable the oscillator
enum Oscillator {
  disable(0),
  freq1Hz(1),
  freq4kHz(4),
  freq8kHz(8),
  freq32kHz(32);

  const Oscillator(this.frequency);
  final int frequency;
}

enum LogicLevel {
  low(0),
  high(1);

  const LogicLevel(this.level);
  final int level;
}

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
  bool _halt;

  // Creates a DS1307 rtc instance that uses the [i2c] bus with
  /// the optional [i2cAddress].
  DS1307(this.i2c, [this.i2cAddress = ds1307DefaultI2Caddress])
      : _halt = false {
    // minimal self test
    //
    // read  8-bit register 0x03: bit 0-3 day, bit 4-7 always 0
    var value = i2c.readByteReg(ds1307DefaultI2Caddress, 0x03);
    // bit 4 -7 must be ß!
    if (value & ((0xFF << 3 & 0xFF)) != 0) {
      throw DS1307exception("DS1307 RTC not found");
    }
  }

  /// Returns the RTC time.
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

  /// Sets the RTC to [dateTime].
  void setDateTime(DateTime dateTime) {
    var data = List<int>.filled(7, 0);
    data[0] = dec2bcd(dateTime.second);
    data[1] = dec2bcd(dateTime.minute);
    data[2] = dec2bcd(dateTime.hour);
    data[3] = dec2bcd(dateTime.weekday);
    data[4] = dec2bcd(dateTime.day);
    data[5] = dec2bcd(dateTime.month);
    data[6] = dec2bcd(dateTime.year - 2000);

    // power up oscillator if needed
    if (_halt) {
      data[0] |= (1 << 7);
    }

    i2c.writeBytesReg(ds1307DefaultI2Caddress, DS1307reg.dateTime.reg, data);
  }

  /// Configures the [SQ pin](https://forum.arduino.cc/t/practical-use-of-ds1307-sqw-output/268525)
  /// to output a square [wave] at
  ///
  /// 1Hz, 4.096kHz, 8.192kHz, or 32.768kHz,  or disables
  /// the oscillator, setting the output logic [level] to high or low.
  void setSquareWave(Oscillator wave, LogicLevel level) {
    int rs0 = 0;
    if (wave == Oscillator.freq4kHz || wave == Oscillator.freq32kHz) {
      rs0 = 1;
    }
    int rs1 = 0;
    if (wave == Oscillator.freq8kHz || wave == Oscillator.freq32kHz) {
      rs1 = 1;
    }
    int sqw = 0;
    if (wave != Oscillator.disable) {
      sqw = 1;
    }
    int reg = rs0 | rs1 << 1 | sqw << 4 | level.level << 7;
    i2c.writeByteReg(ds1307DefaultI2Caddress, DS1307reg.controlReg.reg, reg);
  }

  /// Powers up/down the RTC oscillator.
  void haltRTCoscillator(bool halt) {
    var reg = i2c.readByteReg(ds1307DefaultI2Caddress, DS1307reg.dateTime.reg);
    if (halt) {
      reg |= DS1307reg.chipHalt.reg;
    } else {
      reg |= ~DS1307reg.chipHalt.reg;
    }
    _halt = halt;
    i2c.writeByteReg(ds1307DefaultI2Caddress, DS1307reg.dateTime.reg, reg);
  }

  /// Returns the power status of the RTC oscillator
  bool getRTCoscillatorPowerStatus() {
    return _halt;
  }
}
