// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';
import '../../dart_periphery.dart';

// Resources
// https://github.com/adafruit/Adafruit_CircuitPython_TSL2591
// https://github.com/waveshare/TSL2591X-Light-Sensor/blob/master/RaspberryPi%26JetsonNano/c/lib/TSL2591.c

/// Default I2C address of the TSL2591 sensor
const tsl2591DefaultI2Caddress = 0x29;

enum Command {
  commandBit(0xA0),
  enablePowerOff(0x00),
  enablePowerOn(0x01),
  enableAen(0x02),
  enableAien(0x10),
  enableNpien(0x80);

  final int value;
  const Command(this.value);
}

enum Register {
  enable(0x00),
  control(0x01),
  deviceId(0x12),
  chan0Low(0x14),
  chan1Low(0x16);

  final int value;
  const Register(this.value);
}

const maxCount100ms = 0x8FFF;
const maxCount = 0xFFFF;

enum TSL2591Lux {
  df(408.0),
  coefB(1.64),
  coefC(0.59),
  coefD(0.86);

  final double value;
  const TSL2591Lux(this.value);
}

enum Gain {
  low(0x00, 1, "Low gain (1x)"),
  med(0x10, 25, "Medium gain (25x)"),
  high(0x20, 428, "High gain (428x)"),
  max(0x30, 9876, "Max gain (9876x)");

  final int value;
  final int factor;
  final String description;

  const Gain(this.value, this.factor, this.description);

  static Gain fromInt(int value) {
    for (var gain in Gain.values) {
      if (gain.value == value) {
        return gain;
      }
    }
    throw TSL2591exception("Invalid Gain value");
  }
}

enum IntegrationTime {
  time100ms(0x00, 100),
  time200ms(0x01, 200),
  time300ms(0x02, 300),
  time400ms(0x03, 400),
  time500ms(0x04, 500),
  time600ms(0x05, 600);

  final int value;
  final int milliseconds;

  const IntegrationTime(this.value, this.milliseconds);

  static IntegrationTime fromInt(int value) {
    for (var gain in IntegrationTime.values) {
      if (gain.value == value) {
        return gain;
      }
    }
    throw TSL2591exception("Invalid IntegrationTime value");
  }
}

/// [TSL2591] exception
class TSL2591exception implements Exception {
  final String errorMsg;
  @override
  String toString() => errorMsg;

  TSL2591exception(this.errorMsg);
}

/// Data class for raw values.
class RawLuminosity {
  final int channel0;
  final int channel1;
  final IntegrationTime time;
  final Gain gain;

  RawLuminosity(
      {required this.channel0,
      required this.channel1,
      required this.time,
      required this.gain});

  /// Returns the full spectrum (IR + visible) light and return its value
  /// as a 32-bit unsigned number.
  int getFullSpectrum() {
    return (channel1 << 16) | channel0;
  }

  /// Returns the visible light as a 16-bit unsigned number.
  int getInfraRed() {
    return channel1;
  }

  /// Returns the visible light as a 32-bit unsigned number.
  int getVisible() {
    var full = (channel1 << 16) | channel0;
    return full - channel1;
  }

  /// Calculates a lux value from both its infrared and visible light channels.
  ///
  /// Important hint: This value is not calibrated!
  int getLux() {
    var atime = 100.0 * time.value + 100.0;
    late int maxCounts;
    if (time == IntegrationTime.time100ms) {
      maxCounts = maxCount100ms;
    } else {
      maxCounts = maxCount;
    }
    if (channel0 >= maxCounts || channel1 >= maxCounts) {
      throw TSL2591exception(
          "Overflow reading light channels! Try to reduce the gain of the sensor using Gain.low");
    }
    double cpl = (atime * gain.factor) / TSL2591Lux.df.value;
    double lux1 = (channel0 - TSL2591Lux.coefB.value * channel1) / cpl;
    double lux2 = (TSL2591Lux.coefC.value * channel0 -
            TSL2591Lux.coefD.value * channel1) /
        cpl;
    return max(lux1.toInt(), lux2.toInt());
  }
}

/// TSL2591 sensor for visible, IR light, full spectrum and lux
///
/// See for more
/// * [SI1145 example code](https://github.com/pezi/dart_periphery/blob/main/example/i2c_tsl2591.dart)
/// * [Source code](https://github.com/pezi/dart_periphery/blob/main/lib/src/hardware/tsl2591.dart)
/// * [Datasheet](https://cdn-shop.adafruit.com/datasheets/TSL25911_Datasheet_EN_v1.pdf)
class TSL2591 {
  final I2C i2c;
  final int i2cAddress;
  IntegrationTime time;
  Gain gain;

  /// Creates a SI1145 sensor instance that uses the [i2c] bus with
  /// the optional [i2cAddress] with optional
  TSL2591(this.i2c,
      [this.time = IntegrationTime.time100ms,
      this.gain = Gain.med,
      this.i2cAddress = tsl2591DefaultI2Caddress]) {
    _init();
  }

  void _init() {
    if (_readByte(Register.deviceId) != 0x50) {
      throw TSL2591exception("Failed to find TSL2591 sensor");
    }
    setGain(gain);
    setIntegrationTime(time);
    enable();
  }

  /// Puts the sensor in a fully powered enabled mode.
  void enable() {
    _writeByte(
        Register.enable,
        Command.enablePowerOn.value |
            Command.enableAen.value |
            Command.enableAien.value |
            Command.enableNpien.value);
  }

  /// Disables the sensor and go into low power mode.
  void disable() {
    _writeByte(Register.enable, Command.enablePowerOff.value);
  }

  int _readByte(Register register) {
    var data = i2c.readBytesReg(
        i2cAddress, register.value | Command.commandBit.value, 1);
    return data[0];
  }

  void _writeByte(Register register, int value) {
    i2c.writeByteReg(
        i2cAddress, register.value | Command.commandBit.value, value & 0xff);
  }

  int _readWord(Register register) {
    var buf = i2c.readBytesReg(
        i2cAddress, register.value | Command.commandBit.value, 2);
    return ((buf[1] & 0xff) << 8) | (buf[0] & 0xff);
  }

  /// Returns the [Gain].
  Gain getGain() {
    return Gain.fromInt(_readByte(Register.control) & 0x30);
  }

  /// Sets the [Gain].
  void setGain(Gain gain) {
    var value = (_readByte(Register.control) & 0xCF) | gain.value;
    _writeByte(Register.control, value);
    this.gain = gain;
  }

  /// Sets the [IntegrationTime].
  IntegrationTime getIntegrationTime() {
    return IntegrationTime.fromInt(_readByte(Register.control) & 0x07);
  }

  /// Sets the [IntegrationTime].
  void setIntegrationTime(IntegrationTime time) {
    var value = (_readByte(Register.control) & 0xF8) | gain.value;
    _writeByte(Register.control, value);
    this.time = time;
  }

  /// Reads the raw luminosity from the sensor (both IR + visible and IR
  /// only channels) and returns a [RawLuminosity].
  /// [RawLuminosity.channel0] is IR + visible luminosity
  /// and the [RawLuminosity.channel1] is the IR only
  /// Both values are 16-bit unsigned values.
  RawLuminosity getRawLuminosity() {
    return RawLuminosity(
        channel0: _readWord(Register.chan0Low),
        channel1: _readWord(Register.chan1Low),
        time: time,
        gain: gain);
  }
}
