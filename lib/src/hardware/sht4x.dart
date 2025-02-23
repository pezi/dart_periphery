// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:io';

import 'package:dart_periphery/dart_periphery.dart';

// Resources:
// https://github.com/adafruit/Adafruit_CircuitPython_SHT4x/blob/main/adafruit_sht4x.py

/// Default I2C address of the [SHT4x] sensor
const int sht4xDefaultI2Caddress = 0x44;

/// [SHT4x] commands
enum SHT4xcommand {
  readSerialNumber(0x89),
  softReset(0x94);

  final int command;
  const SHT4xcommand(this.command);
}

/// [SHT4x] sensor mode
enum Mode {
  noHeatHighPrecision(0xFD, "No heater, high precision", 10),
  noHeatMediumPrecision(0xF6, "No heater, medium precision", 5),
  noHeatLowPrecision(0xE0, "No heater, low precision", 2),
  highHeat1s(0x39, "High heat, 1 second", 1100),
  highHeat100mx(0x32, "High heat, 0.1 second", 110),
  medHeat1s(0x2F, "Med heat, 1 second", 1100),
  medHeat100ms(0x24, "Med heat, 0.1 second", 110),
  lowHeat1s(0x1E, "Low heat, 1 second", 1100),
  lowHeat100ms(0x15, "Low heat, 0.1 second", 1100);

  final int command;
  final String description;
  final int delay;
  const Mode(this.command, this.description, this.delay);
}

/// [SHT4x] exception
class SHT4xexception implements Exception {
  SHT4xexception(this.errorMsg);
  final String errorMsg;
  @override
  String toString() => errorMsg;
}

/// [SHT4x] measured data: temperature and humidity sensor.
class SHT4xresult {
  /// temperature °C
  final double temperature;

  /// relative humidity %
  final double humidity;

  SHT4xresult(this.temperature, this.humidity);

  /// Returns a [SHT4xresult] as a JSON string. [fractionDigits] controls the number of fraction digits.
  String toJSON([int fractionDigits = 2]) {
    return '{"temperature":"${temperature.toStringAsFixed(fractionDigits)}","humidity":"${humidity.toStringAsFixed(fractionDigits)}"}';
  }
}

/// Sensirion SHT4x temperature and humidity sensor with a high accuracy.
///
/// See for more
/// * [SHT31 example code](https://github.com/pezi/dart_periphery/blob/main/example/i2c_sht4x.dart)
/// * [Source code](https://github.com/pezi/dart_periphery/blob/main/lib/src/hardware/sht4x.dart)
/// * [Datasheet](https://sensirion.com/media/documents/33FD6951/662A593A/HT_DS_Datasheet_SHT4x.pdf)
class SHT4x {
  final I2C i2c;
  final int i2cAddress;
  Mode _mode = Mode.noHeatHighPrecision;

  /// Creates a SHT4x sensor instance that uses the [i2c] bus with
  /// the optional [i2cAddress].
  SHT4x(this.i2c, [this.i2cAddress = sht31DefaultI2Caddress]) {
    reset();
  }

  /// Resets the sensor.
  void reset() {
    i2c.writeByte(i2cAddress, SHT4xcommand.softReset.command);
    sleep(Duration(milliseconds: 1));
  }

  Mode getMode() {
    return _mode;
  }

  void setMode(Mode mode) {
    _mode = mode;
  }

  /// Returns the serial number of the sensor.
  int getSerialNumber() {
    i2c.writeByte(i2cAddress, SHT4xcommand.readSerialNumber.command);
    sleep(Duration(milliseconds: 1));
    var data = i2c.readBytes(i2cAddress, 6);
    if (!checkCRC(data)) {
      throw SHT4xexception('CRC8 error');
    }
    return (data[0] & 0xff) << 24 |
        (data[1] & 0xff) << 16 |
        (data[3] & 0xff) << 8 |
        (data[4] & 0xff);
  }

  /// Reads a [SHT4xresult] from the sensor with a accuracy depending on the
  /// [Mode] setting.
  SHT4xresult getValues() {
    i2c.writeByte(i2cAddress, _mode.command);
    sleep(Duration(milliseconds: _mode.delay));
    var data = i2c.readBytes(i2cAddress, 6);
    if (!checkCRC(data)) {
      throw SHT31exception('CRC8 error');
    }
    var temp =
        ((((data[0] & 0xFF) << 8) + (data[1] & 0xFF)) * 175.0) / 65535.0 - 45.0;
    var humidity =
        ((((data[3] & 0xFF) << 8) + (data[4] & 0xFF)) * 125.0) / 65535.0 - 6.0;
    return SHT4xresult(temp, humidity);
  }
}
