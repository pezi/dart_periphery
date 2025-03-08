// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:io';
import 'package:dart_periphery/dart_periphery.dart';

// Resources:
// https://github.com/Chouffy/python_sensor_aht20/blob/main/AHT20.py
// https://github.com/adafruit/Adafruit_CircuitPython_AHTx0/blob/main/adafruit_ahtx0.py
// https://github.com/enjoyneering/AHTxx/blob/main/src/AHTxx.cpp

/// Default I2C address of the [AHTX0] sensor
const int ahtx0DefaultI2Caddress = 0x38;

/// [AHTX0] commands
enum AHTX0command {
  aht10Calibrate(0xE1),
  aht20Calibrate(0xBE),
  triggerReading(0xAC),
  softReset(0xBA),
  statusBusy(0x80),
  statusCalibrated(0x08);

  final int cmd;
  const AHTX0command(this.cmd);
}

/// [AHTX0] exception
class AHTX0exception implements Exception {
  AHTX0exception(this.errorMsg);
  final String errorMsg;
  @override
  String toString() => errorMsg;
}

/// [AHTX0] measured data: temperature and humidity sensor.
class AHTX0result {
  /// temperature °C
  final double temperature;

  /// relative humidity %
  final double humidity;

  AHTX0result(this.temperature, this.humidity);

  /// Returns a [AHTX0result] as a JSON string. [fractionDigits] controls the number of fraction digits.
  String toJSON([int fractionDigits = 2]) {
    return '{"temperature":"${temperature.toStringAsFixed(fractionDigits)}","humidity":"${humidity.toStringAsFixed(fractionDigits)}"}';
  }
}

///  AHT10, AHT20 temperature and humidity sensor.
///
/// See for more
/// * [AHTX0 example code](https://github.com/pezi/dart_periphery/blob/main/example/i2c_ahtx0.dart)
/// * [Source code](https://github.com/pezi/dart_periphery/blob/main/lib/src/hardware/ahtx0.dart)
/// * [Datasheet](https://files.seeedstudio.com/wiki/Grove-AHT20_I2C_Industrial_Grade_Temperature_and_Humidity_Sensor/AHT20-datasheet-2020-4-16.pdf)
class AHTX0 {
  final I2C i2c;
  final int i2cAddress;
  bool isAHT20 = false;

  /// Creates a AHTX0 sensor instance that uses the [i2c] bus with
  /// the optional [i2cAddress].
  AHTX0(this.i2c, [this.i2cAddress = ahtx0DefaultI2Caddress]) {
    reset();
    _calibrate();
  }

  /// Resets the sensor.
  void reset() {
    i2c.writeByte(i2cAddress, AHTX0command.softReset.cmd);
    sleep(Duration(milliseconds: 20));
  }

  int _getStatus() {
    return i2c.readByte(i2cAddress);
  }

  void _calibrate() {
    bool calibarionFailed = false;
    // Newer AHT20's may not succeed with old command, so wrapping in try/except
    try {
      i2c.writeBytesReg(
          i2cAddress, AHTX0command.aht10Calibrate.cmd, [0x08, 0x00]);
    } on Exception {
      calibarionFailed = true;
    }
    if (calibarionFailed) {
      sleep(Duration(milliseconds: 10));
      i2c.writeBytesReg(
          i2cAddress, AHTX0command.aht20Calibrate.cmd, [0x08, 0x00]);
      isAHT20 = true;
    }
    int start = DateTime.now().millisecond;
    while (_getStatus() & AHTX0command.statusBusy.cmd != 0) {
      if (DateTime.now().millisecond - start > 3000) {
        throw AHTX0exception(
            "Sensor remained busy 3 seconds. Could not be calibrated");
      }
      sleep(Duration(milliseconds: 10));
    }
    if (_getStatus() & AHTX0command.statusCalibrated.cmd == 0) {
      throw AHTX0exception("Could not calibrate sensor");
    }
  }

  /// Reads a [AHTX0result] from the sensor.
  AHTX0result getValues() {
    i2c.writeBytesReg(
        i2cAddress, AHTX0command.triggerReading.cmd, [0x08, 0x00]);
    while (_getStatus() & AHTX0command.statusBusy.cmd == 1) {
      sleep(Duration(milliseconds: 10));
    }
    var data = i2c.readBytes(i2cAddress, isAHT20 ? 7 : 6);
    if (isAHT20) {
      if (crc8(data.sublist(0, 6)) != data[6]) {
        throw AHTX0exception("CRC8 error");
      }
    }
    var humidity =
        ((data[1] << 12) | (data[2] << 4) | (data[3] >> 4)) * 100.0 / 0x100000;
    var temperature = (((data[3] & 0xF) << 16) | (data[4] << 8) | data[5]) *
            200.0 /
            0x100000 -
        50;
    return AHTX0result(temperature, humidity);
  }
}
