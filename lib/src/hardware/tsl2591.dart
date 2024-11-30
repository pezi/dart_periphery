// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import '../../dart_periphery.dart';

// Resources
// https://github.com/adafruit/Adafruit_CircuitPython_TSL2591

const tsl2591DefaultI2Caddress = 0x29;

enum Command {
  commandBit(0xA0),
  enablePowerOff(0x00),
  enablePowerOn(0x01),
  enableAen(0x02),
  enableAien(0x10),
  enableNpien(0x80),
  registerEnable(0x00),
  registerControl(0x01),
  registerDeviceId(0x12),
  registerChan0Low(0x14),
  registerChan1Low(0x16);

  final int value;
  const Command(this.value);
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
  time100ms(0x00),
  time200ms(0x01),
  time300ms(0x02),
  time400ms(0x03),
  time500ms(0x04),
  time600ms(0x05);

  final int value;

  const IntegrationTime(this.value);

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

  int getFullSpectrum() {
    return (channel1 << 16) | channel0;
  }

  int getInfraRed() {
    return channel1;
  }

  int getVisible() {
    var full = (channel1 << 16) | channel0;
    return full - channel1;
  }

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
  /// the optional [i2cAddress].
  TSL2591(this.i2c,
      [this.time = IntegrationTime.time100ms,
      this.gain = Gain.med,
      this.i2cAddress = tsl2591DefaultI2Caddress]) {
    _init();
  }

  void _init() {
    if (_readByte(Command.registerDeviceId) != 0x45) {
      throw TSL2591exception("Failed to find TSL2591 sensor");
    }
    enable();
  }

  void enable() {
    _writeByte(
        Command.registerEnable,
        Command.enablePowerOn.value |
            Command.enableAen.value |
            Command.enableAien.value |
            Command.enableNpien.value);
  }

  void disable() {
    _writeByte(Command.registerEnable, Command.enablePowerOff.value);
  }

  Gain getGain() {
    return Gain.fromInt(_readByte(Command.registerControl) & 0x30);
  }

  void setGain(Gain gain) {
    var value = (_readByte(Command.registerControl) & 0xCF) | gain.value;
    this.gain = Gain.fromInt(value);
  }

  int _readByte(Command cmd) {
    return i2c.readByteReg(
        i2cAddress, (cmd.value | Command.commandBit.value) & 0xff);
  }

  void _writeByte(Command cmd, int value) {
    i2c.writeByteReg(i2cAddress, (cmd.value | Command.commandBit.value) & 0xff,
        value & 0xff);
  }

  IntegrationTime getIntegrationTime() {
    return IntegrationTime.fromInt(_readByte(Command.registerControl) & 0x07);
  }

  void setIntegrationTime(IntegrationTime gain) {
    var value = (_readByte(Command.registerControl) & 0xF8) | gain.value;
    time = IntegrationTime.fromInt(value);
  }

  RawLuminosity getRawLuminosity() {
    return RawLuminosity(
        channel0: _readWord(Command.registerChan0Low),
        channel1: _readWord(Command.registerChan1Low),
        time: time,
        gain: gain);
  }

  int _readWord(Command cmd) {
    var buf = i2c.readBytesReg(
        i2cAddress, (cmd.value | Command.commandBit.value) & 0xff, 2);
    return ((buf[1] & 0xff) << 8) | (buf[0] & 0xff);
  }
}
