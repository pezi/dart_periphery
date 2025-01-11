// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// https://github.com/adafruit/Adafruit_CircuitPython_PCF8591/blob/main/adafruit_pcf8591/pcf8591.py
// https://github.com/ShuDiamonds/PCF8591/blob/master/PCF8591.py
// https://www.waveshare.com/wiki/Raspberry_Pi_Tutorial_Series:_PCF8591_AD/DA

import 'package:dart_periphery/dart_periphery.dart';

enum Pin { a0, a1, a2, a3 }

/// Default I2C address of the PFC8591 ADC
const int pcf8591DefaultI2Caddress = 0x48;

/// [PFC8591] exception
class PFC8591exception implements Exception {
  final String errorMsg;
  @override
  String toString() => errorMsg;

  PFC8591exception(this.errorMsg);
}

const pfc8591lowerLimit = 2.5;
const pfc8591UpperLimit = 6.0;
const pfc8591enableDAC = 0x40;

class PFC8591 {
  final I2C i2c;
  final int i2cAddress;
  late final double referenceVoltage;
  bool _dacEnabled = false;
  int _dac = 0;

  PFC8591(this.i2c,
      [double refVoltage = 3.3, this.i2cAddress = pcf8591DefaultI2Caddress]) {
    if (refVoltage <= pfc8591lowerLimit || refVoltage >= pfc8591UpperLimit) {
      throw PFC8591exception("Reference voltage must be from 2.5 - 6.0");
    }
    referenceVoltage = refVoltage;
  }

  void setDAC(bool dac) {
    _dacEnabled = dac;
  }

  bool getDAC() {
    return _dacEnabled;
  }

  List<int> _halfRead(Pin pin) {
    var data = [0, 0];
    if (_dacEnabled) {
      data[0] = pfc8591enableDAC;
      data[1] = _dac;
    }
    data[0] |= pin.index & 0x03;
    i2c.writeBytes(i2cAddress, data);
    return i2c.readBytes(i2cAddress, 2);
  }

  //
  int read(Pin pin) {
    _halfRead(pin); // dummy read
    return _halfRead(pin)[1];
  }

  void enableDAC(bool flag) {
    _dacEnabled = flag;
    List<int> data;
    if (flag) {
      data = [pfc8591enableDAC, _dac];
    } else {
      data = [0, 0];
    }
    i2c.writeBytes(i2cAddress, data);
    i2c.readBytes(i2cAddress, 2);
  }

  void write(int value) {
    if (value < 0 || value > 255) {
      throw PFC8591exception("8-bit DAC - valid range: [0,255]");
    }
    if (!_dacEnabled) {
      throw PFC8591exception("DAC support is not enabled");
    }

    var data = [pfc8591enableDAC, value];
    _dac = value;
    i2c.writeBytes(i2cAddress, data);
    i2c.readBytes(i2cAddress, 2);
  }
}
