// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dart_periphery/src/hardware/utils/byte_buffer.dart';

import '../../dart_periphery.dart';

// https://wiki.seeedstudio.com/Grove-Digital_Infrared_Temperature_Sensor/
// https://github.com/Seeed-Studio/Digital_Infrared_Temperature_Sensor_MLX90615
// https://github.com/rcolistete/MicroPython_MLX90615_driver/blob/master/mlx90615_simple.py

const int eepromSa = 0x10;

const int eepromPwmtRng = 0x11;
const int eepromConfig = 0x12;
const int eepromEmissivity = 0x13;

const int rawIrData = 0x25;
const int ambientTemperature = 0x26;
const int objectTemperature = 0x27;

const int sleep = 0xC6;

// DEPRECATED! (just emissivity, not the whole EEPROM)
const int defaultEmissivity = 0x4000;
const int defaultAddr = 0x5B;

const regIdLow = 0x1E;
const regIdHigh = 0x1F;

/// [MLX90615] exception
class MLX90615exception implements Exception {
  final String errorMsg;
  @override
  String toString() => errorMsg;

  MLX90615exception(this.errorMsg);
}

/// [MLX90615] measured data: temperature
class MLX90615result {
  /// temperature °C
  final double temperature;

  MLX90615result(this.temperature);

  @override
  String toString() => 'MCP9808result [temperature=$temperature]';

  /// Returns a [MLX90615result] as a JSON string. [fractionDigits] controls the
  /// number fraction digits.
  String toJSON([int fractionDigits = 2]) {
    return '{"temperature":"${temperature.toStringAsFixed(fractionDigits)}"}';
  }
}

class MLX90615 {
  final I2C i2c;
  final int i2cAddress;

  /// Creates a MLX90615 sensor instance that uses the [i2c] bus with
  /// the optional [i2cAddress].
  MLX90615(this.i2c, [this.i2cAddress = mcp9808DefaultI2Caddress]);

  int read16(int register, bool crcCheck) {
    var data = i2c.readBytesReg(i2cAddress, register, 3);
    if (!checkCRC(data)) {
      throw MLX90615exception('CRC error reading temperature data');
    }
    return (data[0] & 0xFF) | (data[1] & 0xFF) << 8;
  }

  double getAmbientTemperature([bool crcCheck = true]) {
    var value = read16(ambientTemperature, crcCheck);
    if (value > 0x7FFF) {
      throw MLX90615exception('Invalid ambient temperature error.');
    }
    return value * 2 - 27315;
  }

  double getObjectTemperature([bool crcCheck = true]) {
    var value = read16(objectTemperature, crcCheck);
    if (value > 0x7FFF) {
      throw MCP9808exception('Invalid ambient temperature error.');
    }
    return value * 2 - 27315;
  }

  int getId([bool crcCheck = true]) {
    return read16(regIdLow, crcCheck) | read16(regIdHigh, crcCheck);
  }

  List<int> readEEPROM([bool crcCheck = true]) {
    var eeprom = <int>[];
    for (int addr = 0x10; addr < 0x20; ++addr) {
      eeprom.add(read16(addr, crcCheck));
    }
    return eeprom;
  }
}
