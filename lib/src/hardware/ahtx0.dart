// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:io';
import 'package:dart_periphery/dart_periphery.dart';

// Resources:
// https://github.com/Chouffy/python_sensor_aht20/blob/main/AHT20.py
// https://github.com/adafruit/Adafruit_CircuitPython_AHTx0/blob/main/adafruit_ahtx0.py

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

  final int command;
  const AHTX0command(this.command);
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

  /// Creates a AHTX0 sensor instance that uses the [i2c] bus with
  /// the optional [i2cAddress].
  AHTX0(this.i2c, [this.i2cAddress = sht31DefaultI2Caddress]) {
    reset();
  }

  /// Resets the sensor.
  void reset() {
    i2c.writeByte(i2cAddress, AHTX0command.softReset.command);
    sleep(Duration(milliseconds: 20));
  }

  // bool cl
}
