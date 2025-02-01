// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../dart_periphery.dart';

/// [MCP9808] temperature degree resolution
///
/// Higher values allow for faster measurement, though with reduced accuracy.
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

/// Default address of the [MCP9808] sensor.
const int mcp9808DefaultI2Caddress = 0x18;

/// [MCP9808] exception
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

  /// Returns a [MCP9808result] as a JSON string. [fractionDigits] controls the
  /// number fraction digits.
  String toJSON([int fractionDigits = 2]) {
    return '{"temperature":"${temperature.toStringAsFixed(fractionDigits)}"}';
  }
}

/// MCP9808 - high accuracy temperature sensor
///
/// See for more
/// * [MCP9808 example code](https://github.com/pezi/dart_periphery/blob/main/example/i2c_mcp9808.dart)
/// * [Source code](https://github.com/pezi/dart_periphery/blob/main/lib/src/hardware/mcp9808.dart)
/// * [Datasheet](https://ww1.microchip.com/downloads/aemDocuments/documents/OTH/ProductDocuments/DataSheets/MCP9808-0.5C-Maximum-Accuracy-Digital-Temperature-Sensor-Data-Sheet-DS20005095B.pdf)
/// * Technical resource [seedstudio](https://www.seeedstudio.com/Grove-I2C-High-Accuracy-Temperature-Sensor-MCP9808.html)
/// * Technical resource [digikey forum](https://forum.digikey.com/t/reading-temperature-data-from-a-mcp9808-using-a-raspberry-pi/4962)
class MCP9808 {
  final I2C i2c;
  final int i2cAddress;

  /// Creates a MCP9808 sensor instance that uses the [i2c] bus with
  /// the optional [i2cAddress].
  MCP9808(this.i2c, [this.i2cAddress = mcp9808DefaultI2Caddress]) {
    setResolution(Resolution.celsius_0p0625);
  }

  /// Sets the config.
  void setConfig(int config) {
    i2c.writeWordReg(i2cAddress, setConfigAddress, config, BitOrder.msbFirst);
  }

  /// Sets [upperLimit] limit of sensor.
  void setUpperLimit(int upperLimit) {
    i2c.writeWordReg(
        i2cAddress, setUpperLimitAddress, upperLimit, BitOrder.msbFirst);
  }

  /// Sets [lowerLimit] limit of sensor.
  void setLowerLimit(int lowerLimit) {
    i2c.writeWordReg(
        i2cAddress, setLowerLimitAddress, lowerLimit, BitOrder.msbFirst);
  }

  /// Sets the [Resolution].
  void setResolution(Resolution resolution) {
    i2c.writeByteReg(i2cAddress, setResolutionAddress, resolution.index);
  }

  /// Returns the temperature
  MCP9808result getValue() {
    int data = i2c.readWordReg(
        i2cAddress, ambientTemperatureAddress, BitOrder.msbFirst);
    // data = swapBytes16(data); - done by the BitOrder.msbFirst flag
    if (data & 0x1000 != 0) {
      data = -((data ^ 0x0FFF) + 1);
    } else {
      data = data & 0x0fff;
    }
    return MCP9808result(data / 16.0);
  }
}
