// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_periphery/dart_periphery.dart';

// https://wiki.seeedstudio.com/Grove-Digital_Infrared_Temperature_Sensor/
// https://github.com/Seeed-Studio/Digital_Infrared_Temperature_Sensor_MLX90615
// https://github.com/rcolistete/MicroPython_MLX90615_driver/blob/master/mlx90615_simple.py
// https://acassis.wordpress.com/2018/10/27/checking-the-crc-8-pec-byte-of-mlx90614/

const int eepromSa = 0x10;
const int eepromPwmtRng = 0x11;
const int eepromConfig = 0x12;
const int eepromEmissivity = 0x13;
const int rawIrData = 0x25;
const int ambientTemperature = 0x26;
const int objectTemperature = 0x27;
const int sleep = 0xC6;
const regIdLow = 0x1E;
const regIdHigh = 0x1F;

/// Default address of the [MLX90615] sensor.
const int mlx90615DefaultI2Caddress = 0x5B;

/// [MLX90615] exception
class MLX90615exception implements Exception {
  final String errorMsg;
  @override
  String toString() => errorMsg;

  MLX90615exception(this.errorMsg);
}

enum TemperatureType { ambient, object }

/// [MLX90615] measured data: temperature
class MLX90615result {
  final TemperatureType type;

  /// temperature °C
  final double temperature;

  MLX90615result(this.type, this.temperature);

  @override
  String toString() =>
      'MCP9808result [type=${type.name}, temperature=$temperature]';

  /// Returns a [MLX90615result] as a JSON string. [fractionDigits] controls the
  /// number fraction digits.
  String toJSON([int fractionDigits = 2]) {
    return '{"type":"${type.name}","temperature":"${temperature.toStringAsFixed(fractionDigits)}"}';
  }
}

///  MLX90615 - digital infrared non-contact temperature sensor
///
/// See for more
/// * [MLX90615 example code](https://github.com/pezi/dart_periphery/blob/main/example/i2c_mlx90615.dart)
/// * [Source code](https://github.com/pezi/dart_periphery/blob/main/lib/src/hardware/mlx90615.dart)
/// * [Datasheet](https://files.seeedstudio.com/wiki/Grove-Digital_Infrared_Temperature_Sensor/res/MLX90615.pdf)
/// * This implementation is derived from project [MicroPython_MLX90615_driver](https://github.com/rcolistete/MicroPython_MLX90615_driver/tree/master) including the method documentation.
/// * Only read operations are implemented
class MLX90615 {
  final I2C i2c;
  final int i2cAddress;

  /// Creates a MLX90615 sensor instance that uses the [i2c] bus with
  /// the optional [i2cAddress].
  MLX90615(this.i2c, [this.i2cAddress = mlx90615DefaultI2Caddress]);

  int _crc8(int icrc, int data) {
    int crc = icrc ^ data;
    for (int i = 0; i < 8; i++) {
      crc <<= 1;
      if (crc & 0x0100 != 0) {
        crc ^= 0x07;
      }
      crc &= 0xFF;
    }
    return crc;
  }

  int _read16(int register, bool crcCheck) {
    var data = i2c.readBytesReg(i2cAddress, register, 3);
    for (int i = 0; i < data.length; i++) {
      data[i] = data[i] & 0xff;
    }

    if (crcCheck) {
      var crc = 0;
      crc = _crc8(crc, i2cAddress << 1);
      crc = _crc8(crc, register);
      crc = _crc8(crc, (i2cAddress << 1) + 1);
      crc = _crc8(crc, data[0]);
      crc = _crc8(crc, data[1]);
      if (crc != data[2]) {
        throw MLX90615exception('CRC error reading temperature data');
      }
    }
    return data[0] | data[1] << 8;
  }

  /// Returns a [MLX90615result] with [TemperatureType] type and temperature,
  MLX90615result getValue(TemperatureType type) {
    if (type == TemperatureType.ambient) {
      return MLX90615result(type, getAmbientTemperature());
    }
    return MLX90615result(type, getObjectTemperature());
  }

  /// Reads the ambient temperature in the range -40 - 85 °C
  double getAmbientTemperature([bool crcCheck = true]) {
    var value = _read16(ambientTemperature, crcCheck);
    if (value > 0x7FFF) {
      throw MLX90615exception('Invalid ambient temperature error');
    }
    return (value * 2 - 27315) / 100;
  }

  /// Reads the object temperature in the range -40 - 115 °C
  double getObjectTemperature([bool crcCheck = true]) {
    var value = _read16(objectTemperature, crcCheck);
    if (value > 0x7FFF) {
      throw MCP9808exception('Invalid object temperature error');
    }
    return (value * 2 - 27315) / 100.0;
  }

  /// Reads the unique sensor Id, a 32 bits integer stored in EEPROM
  int getId([bool crcCheck = true]) {
    return _read16(regIdLow, crcCheck) | _read16(regIdHigh, crcCheck);
  }

  /// Reads the EEPROM returning a list of 16 values, each one a 16
  /// bits integer.
  ///
  /// Very useful to save a backup of the EEPROM, including the factory
  /// calibration data. See the MLX90615 datasheet, section 8.3.3 and table 6.
  List<int> readEEPROM([bool crcCheck = true]) {
    var eeprom = <int>[];
    for (int addresss = 0x10; addresss < 0x20; ++addresss) {
      eeprom.add(_read16(addresss, crcCheck) & 0xFF);
    }
    return eeprom;
  }

  /// Reads the emissivity stored in EEPROM, an integer from 5 to 100
  /// corresponding to emissivity from 0.05 to 1.00.
  int readEmissivity([bool crcCheck = true]) {
    var d = _read16(eepromEmissivity, crcCheck);
    if (d >= 32768) {
      d = 32768 - d;
    }
    return (100 * d / 0x4000).round();
  }
}
