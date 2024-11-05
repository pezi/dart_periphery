// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import '../../dart_periphery.dart';

// Resources:
// https://www.seeedstudio.com/Grove-I2C-High-Accuracy-Temperature-Sensor-MCP9808.html
// https://github.com/Seeed-Studio/grove.py/blob/master/grove/temperature/mcp9808.py
// https://github.com/Seeed-Studio/Grove_Temperature_sensor_MCP9808/blob/master/Seeed_MCP9808.cpp
// https://forum.digikey.com/t/reading-temperature-data-from-a-mcp9808-using-a-raspberry-pi/4962
// https://ww1.microchip.com/downloads/aemDocuments/documents/OTH/ProductDocuments/DataSheets/MCP9808-0.5C-Maximum-Accuracy-Digital-Temperature-Sensor-Data-Sheet-DS20005095B.pdf

enum Resolution {
  celsius_0p5(0.5),
  celsius_0p25(0.25),
  celsius_0p125(0.125),
  celsius_0p0625(0.0625);

  final double value;
  const Resolution(this.value);
}

const setConfigAddress = 0x01;
const setUpperLimitAddress = 0x02;
const setLowerLimitAddress = 0x03;
const setCriticalLimitAddress = 0x04;

const ambientTemperatureAddress = 0x05;
const setResolutionAddress = 0x08;

const int mcp9808DefaultI2Caddress = 0x18;
const SIGN_BIT = 0X10;

// [MCP9808] exception
class MCP9808exception implements Exception {
  final String errorMsg;
  @override
  String toString() => errorMsg;

  MCP9808exception(this.errorMsg);
}

/// [MCP9808] measured data: temperature
class MCP9808result {
  /// temperature °C
  final double temperature;

  MCP9808result(this.temperature);

  @override
  String toString() => 'MCP9808result [temperature=$temperature]';

  /// Returns a [BME280result] as a JSON string. [fractionDigits] controls the
  /// number fraction digits.
  String toJSON([int fractionDigits = 2]) {
    return '{"temperature":"${temperature.toStringAsFixed(fractionDigits)}"}';
  }
}

class MCP9808 {
  final I2C i2c;
  final int i2cAddress;

  /// Creates a MCP9808 sensor instance that uses the [i2c] bus with
  /// the optional [i2cAddress].
  MCP9808(this.i2c, [this.i2cAddress = mcp9808DefaultI2Caddress]) {
    setResolution(Resolution.celsius_0p0625);
  }

  void setConfig(int config) {
    i2c.writeWordReg(i2cAddress, setConfigAddress, config, BitOrder.msbFirst);
  }

  void setUpperLimit(int upperLimit) {
    i2c.writeWordReg(
        i2cAddress, setUpperLimitAddress, upperLimit, BitOrder.msbFirst);
  }

  void setLowerLimit(int lowerLimit) {
    i2c.writeWordReg(
        i2cAddress, setLowerLimitAddress, lowerLimit, BitOrder.msbFirst);
  }

  void setResolution(Resolution resolution) {
    i2c.writeByteReg(i2cAddress, setResolutionAddress, resolution.index);
  }

  int swapBytes16(int value) {
    return ((value & 0xFF) << 8) | ((value >> 8) & 0xFF);
  }

  MCP9808result getValue() {
    int data = i2c.readWordReg(
        i2cAddress, ambientTemperatureAddress, BitOrder.msbFirst);
    data = swapBytes16(data);
    print(data);
    if (data & 0x1000 != 0) {
      data = -((data ^ 0x0FFF) + 1);
    } else {
      data = data & 0x0fff;
    }
    return MCP9808result(data / 16);
  }
}

void main() {
  // Select the right I2C bus number /dev/i2c-?
  // 1 for Raspberry Pi, 0 for NanoPi (Armbian), 2 Banana Pi (Armbian)
  var i2c = I2C(1);
  try {
    var sensor = MCP9808(i2c);
    sleep(Duration(milliseconds: 100));

    var r = sensor.getValue();

    print('MCP9808 [t°] ${r.temperature.toStringAsFixed(2)}');
  } finally {
    i2c.dispose();
  }
}
