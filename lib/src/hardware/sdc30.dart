// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_periphery/src/i2c.dart';

import '../../dart_periphery.dart';

enum Command {
  continuousMeasurement(0x0010),
  setMeasurementInterval(0x4600),
  getDataReady(0x0202),
  readMeasurement(0x0300),
  automaticSelfCalibration(0x5306),
  setForcedRecalibrationFactor(0x5204),
  setTemperatureOffset(0x5403),
  setAltitudeCompensation(0x5102),
  reset(0xD304), // Soft reset
  stopMeasurement(0x0104),
  readFirmwareVersion(0xD100);

  final int value;
  const Command(this.value);
}

const int sdc30DefaultI2Caddress = 0x61;

/// SDC30 CO2 & Temperature & Humidity Sensor
/// https://www.seeedstudio.com/Grove-CO2-Temperature-Humidity-Sensor-SCD30-p-2911.html
class SDC30 {
  final I2C i2c;
  final int i2cAddress;

  /// Creates a MCP9808 sensor instance that uses the [i2c] bus with
  /// the optional [i2cAddress].
  SDC30(this.i2c, [this.i2cAddress = sdc30DefaultI2Caddress]) {}

  /// Enables or disables the ASC
  void setAutoSelfCalibration(bool enable) {
    sendCommand(Command.automaticSelfCalibration, enable ? 1 : 0);
  }

  /// Sets the forced recalibration factor. See 1.3.7.
  /// The reference CO2 concentration has to be within the range 400 ppm ≤ cref(CO2) ≤ 2000 ppm.
  void setForcedRecalibrationFactor(int concentration) {
    if (concentration < 400 || concentration > 2000) {
      return; // Error check.
    }
    return sendCommand(Command.setForcedRecalibrationFactor, concentration);
  }

  // Sends a command along with arguments and CRC
  void sendCommandNoArg(Command cmd) {
    i2c.writeBytesReg(sdc30DefaultI2Caddress, cmd.value, [], BitOrder.msbFirst,
        RegisterWidth.bits16);
  }

  void sendCommand(Command cmd, int arg) {
    var args = <int>[];
    args.add(arg >> 8);
    args.add(arg & 0xFF);
    args.add(crc8(args));
    i2c.writeBytesReg(sdc30DefaultI2Caddress, cmd.value, [], BitOrder.msbFirst,
        RegisterWidth.bits16);
  }

  int crc8(List<int> data) {
    int crc = 0xff;
    for (int v in data) {
      crc ^= v;
      for (int i = 0; i < 8; ++i) {
        if (crc & 0x80 != 0) {
          crc = ((crc << 1) ^ 0x31) & 0xFF;
        } else {
          crc <<= 1;
        }
      }
    }
    return crc;
  }
}
