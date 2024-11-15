// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// https://github.com/Sensirion/python-i2c-scd30/tree/master

// https://github.com/agners/micropython-scd30/blob/master/scd30.py
// https://javiercarrascocruz.github.io/i2c-on-linux#3-example-with-a-virtual-device-i2c-stub

import 'package:dart_periphery/src/i2c.dart';
import 'utils/byte_buffer.dart';
import 'dart:typed_data';
import 'dart:io';

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

/// [SDC30] exception
class SDC30exception implements Exception {
  final String errorMsg;
  @override
  String toString() => errorMsg;

  SDC30exception(this.errorMsg);
}

/// SDC30 CO2 & Temperature & Humidity Sensor
/// https://www.seeedstudio.com/Grove-CO2-Temperature-Humidity-Sensor-SCD30-p-2911.html
class SDC30 {
  final I2C i2c;
  final int i2cAddress;

  /// Creates a MCP9808 sensor instance that uses the [i2c] bus with
  /// the optional [i2cAddress].
  SDC30(this.i2c, [this.i2cAddress = sdc30DefaultI2Caddress]) {}

  /// Sets interval between measurements
  /// 2 seconds to 1800 seconds (30 minutes)
  void setMeasurementInterval(int interval) {
    sendCommand(Command.setMeasurementInterval, interval);
  }

  int getMeasurementInterval() {
    return getCommandValue(Command.setMeasurementInterval);
  }

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

  int getFirmwareVersion() {
    return getCommandValue(Command.readFirmwareVersion);
  }

  /// Checks if data is available
  bool isDataAvailable() {
    return readRegister(Command.getDataReady) == 1;
  }

  double floatFromBytes(List<int> bytes, int index) {
    // Create a ByteData from the list of bytes
    final byteData = ByteData(4);
    var offset = 0;
    for (int i = 0; i < 4; i++) {
      byteData.setUint8(i, bytes[index + offset + i]);
      if (i == 1) {
        offset = 1;
      }
    }

    // Convert the bytes to a float (32-bit) and return as double
    return byteData.getFloat32(0, Endian.big);
  }

  void readMeasurement() {
    if (!isDataAvailable()) {
      return;
    }
    var address = <int>[];
    address.add(Command.readMeasurement.value >> 8);
    address.add(Command.readMeasurement.value & 0xFF);
    i2c.writeBytes(sdc30DefaultI2Caddress, address);
    sleep(const Duration(microseconds: 3));
    var data = i2c.readBytes(sdc30DefaultI2Caddress, 18);

    // check crc
    for (var i = 0; i < 18; i += 3) {
      if (_crc8(data, i) != (data[i + 2] & 0xff)) {
        throw SDC30exception('CRC8 error');
      }
    }

    var co2 = floatFromBytes(data, 0);
    var temperature = floatFromBytes(data, 6);
    var humidity = floatFromBytes(data, 12);
    print("$co2 $temperature $humidity");
  }

  // Sends a command along with arguments and CRC
  void sendCommandNoArg(Command command) {
    var data = <int>[];
    data.add(command.value >> 8);
    data.add(command.value & 0xFF);
    data.add(_crc8(data));
    i2c.writeBytes(sdc30DefaultI2Caddress, data);
  }

  /// Reads a word from a [command] register.
  int readRegister(Command command) {
    var address = <int>[];
    address.add(command.value >> 8);
    address.add(command.value & 0xFF);
    i2c.writeBytes(sdc30DefaultI2Caddress, address);
    sleep(const Duration(microseconds: 3));
    var data = i2c.readBytes(sdc30DefaultI2Caddress, 2);
    return (data[0] & 0xff) << 8 | (data[1] & 0xff);
  }

  /// Sends a [command] with an [argument].
  void sendCommand(Command command, int argument) {
    var data = <int>[];
    data.add(command.value >> 8);
    data.add(command.value & 0xFF);
    data.add(argument >> 8);
    data.add(argument & 0xFF);
    data.add(_crc8(data));
    i2c.writeBytes(sdc30DefaultI2Caddress, data);
  }

  int getCommandValue(Command command) {
    var address = <int>[];
    address.add(command.value >> 8);
    address.add(command.value & 0xFF);
    i2c.writeBytes(sdc30DefaultI2Caddress, address);
    sleep(const Duration(microseconds: 3));
    var data = i2c.readBytes(sdc30DefaultI2Caddress, 3);
    if (_crc8(data) != (data[2] & 0xff)) {
      throw SDC30exception('CRC8 error');
    }
    return (data[0] & 0xff) << 8 | (data[1] & 0xff);
  }

  int _crc8(List<int> data, [int index = 0]) {
    int crc = 0xff;
    for (int i = 0; i < 2; ++i) {
      crc ^= data[index + i];
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

void main() {
  // Select the right I2C bus number /dev/i2c-?
  // 1 for Raspberry Pi, 0 for NanoPi (Armbian), 2 Banana Pi (Armbian)
  var i2c = I2C(0);
  try {
    print("test sensor");
    var s = SDC30(i2c);
    // firmware version major: 3; minor: 66;
    print(s.getFirmwareVersion());
    print(s.getMeasurementInterval());
    while (true) {
      sleep(Duration(seconds: 4));
      if (s.isDataAvailable()) {
        s.readMeasurement();
      }
    }
  } finally {
    i2c.dispose();
  }
}
