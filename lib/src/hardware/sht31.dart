// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:dart_periphery/dart_periphery.dart';
import 'package:dart_periphery/src/hardware/util.dart';

import '../i2c.dart';
import 'util.dart';
import 'dart:io';

// https://wiki.seeedstudio.com/Grove-TempAndHumi_Sensor-SHT31/
// https://github.com/Seeed-Studio/Grove_SHT31_Temp_Humi_Sensor/blob/master/SHT31.h
// https://github.com/Seeed-Studio/Grove_SHT31_Temp_Humi_Sensor/blob/master/SHT31.cpp
// https://github.com/ControlEverythingCommunity/SHT31/blob/master/Java/SHT31.java
// https://github.com/adafruit/Adafruit_CircuitPython_SHT31D/blob/master/adafruit_sht31d.py

const int SHT31_DEFAULT_I2C_ADDRESS = 0x44;
const int SHT31_ALTERNATIVE_I2C_ADDRESS = 0x45;

const int SHT31_MEAS_HIGHREP_STRETCH = 0x2C06;
const int SHT31_MEAS_MEDREP_STRETCH = 0x2C0D;
const int SHT31_MEAS_LOWREP_STRETCH = 0x2C10;
const int SHT31_MEAS_HIGHREP = 0x2400;
const int SHT31_MEAS_MEDREP = 0x240B;
const int SHT31_MEAS_LOWREP = 0x2416;
const int SHT31_READSTATUS = 0xF32D;
const int SHT31_CLEARSTATUS = 0x3041;
const int SHT31_SOFTRESET = 0x30A2;
const int SHT31_HEATEREN = 0x306D;
const int SHT31_HEATERDIS = 0x3066;
const int SHT31_READSERIALNBR = 0x3780;

/// [SHT31] exception
class SHT31excpetion implements Exception {
  SHT31excpetion(this.errorMsg);
  final String errorMsg;
  @override
  String toString() => errorMsg;
}

/// [SHT31] data container for temperature and humidity.
class SHT31result {
  /// temperature
  final double temperature;

  /// relative humidity %
  final double humidity;

  SHT31result(this.temperature, this.humidity);
}

/// Sensirion SHT31 temperatur and humidity sensor with a high accuracy.
///
/// See for more
/// * [SGP30 example code](https://github.com/pezi/dart_periphery/blob/main/example/i2c_sht31.dart)
/// * [Source code](https://github.com/pezi/dart_periphery/blob/main/lib/src/hardware/sht31.dart)
/// * [Datasheet](https://docs.rs-online.com/6b89/0900766b816bf6a6.pdf)
class SHT31 {
  final I2C i2c;
  final int i2cAddress;

  /// Creates a SHT31 sensor instance that uses the [i2c] bus with
  /// the optional [i2cAddress].
  SHT31(this.i2c, [this.i2cAddress = SHT31_DEFAULT_I2C_ADDRESS]) {
    reset();
  }

  /// Checks if the heater is on.
  bool isHeaterOn() {
    return (getStatus() & 0x2000) != 0;
  }

  /// Enables or disables the [heater] on the sensor to to heat/evaporate any condensation.
  /// This command can destroy the sensor, if the heater runs too long.
  void heater(bool heater) {
    if (heater) {
      _writeCommand(SHT31_HEATEREN);
    } else {
      _writeCommand(SHT31_HEATERDIS);
    }
  }

  /// Resets the sensor.
  void reset() {
    _writeCommand(SHT31_SOFTRESET);
    sleep(Duration(milliseconds: 5));
  }

  /// Returns the status of the sensor.
  int getStatus() {
    _writeCommand(SHT31_READSTATUS);
    sleep(Duration(milliseconds: 5));
    return i2c.readWord(i2cAddress, BitOrder.MSB_FIRST);
  }

  /// Returns the serial number of the sensor.
  int getSerialNumber() {
    _writeCommand(SHT31_READSERIALNBR);
    sleep(Duration(milliseconds: 5));
    var data = i2c.readBytesReg(i2cAddress, 0, 6);
    if (!checkCRC(data)) {
      throw SHT31excpetion('CRC8 error');
    }
    return (data[0] & 0xff) << 24 |
        (data[1] & 0xff) << 16 |
        (data[3] & 0xff) << 8 |
        (data[4] & 0xff);
  }

  void _writeCommand(int cmd) {
    i2c.writeBytes(i2cAddress, [cmd >> 8, cmd & 0xff]);
  }

  // Reads a [SHT31result] from the sensor with a high accuracy in a period of 500 milliseconds.
  SHT31result getValues() {
    _writeCommand(SHT31_MEAS_HIGHREP_STRETCH);

    sleep(Duration(milliseconds: 500));

    var data = i2c.readBytesReg(i2cAddress, 0, 6);
    if (!checkCRC(data)) {
      throw SHT31excpetion('CRC8 error');
    }

    // convert the data
    var temp =
        ((((data[0] & 0xFF) * 256) + (data[1] & 0xFF)) * 175.0) / 65535.0 -
            45.0;

    var humidity =
        ((((data[3] & 0xFF) * 256) + (data[4] & 0xFF)) * 100.0) / 65535.0;
    return SHT31result(temp, humidity);
  }
}
