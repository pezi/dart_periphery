// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dart_periphery/dart_periphery.dart';
import 'utils/byte_buffer.dart';

// Bosch BMx280 pressure and temperature sensor. The BME280 includes an
// additional humidity sensor.
// Different constructors support access via I2C or SPI
// Datasheet: https://cdn-shop.adafruit.com/datasheets/BST-BME280_DS001-10.pdf
//
// This code bases on the diozero project - Thanks to Matthew Lewis!
// https://github.com/mattjlewis/diozero/blob/main/diozero-core/src/main/java/com/diozero/devices/BMx280.java

/// Default I2C address of the BME280 sensor
const int bme280DefaultI2Caddress = 0x76;

/// Alternative I2C address of the BME280 sensor
const int bme280AlternativeI2Caddress = 0x77;

const int calib00reg = 0x88;
const int idReg = 0xD0;
const int resetReg = 0xE0;
const int calib26reg = 0xe1;
const int ctrlHumReg = 0xF2;
const int statusReg = 0xF3;
const int ctrlMeasReg = 0xF4;
const int configReg = 0xF5;
const int pressMsbReg = 0xF7;

// Flags for ctrl_hum and ctrl_meas registers
const int oversampling1Mask = 1;
const int oversampling2Mask = 2;
const int oversampling4Mask = 3;
const int oversampling8Mask = 4;
const int oversampling16Mask = 5;

// operation mode
const int modeSleep = 0;
const int modeForged = 1;
const int modeNormal = 3;

/// [BME280] operation mode
enum OperatingMode { modeSleep, modeForced, modeNormal }

///  0.5 ms
const int standby500us = 0;

/// 62.5 ms
const int standby62p5ms = 1;

/// 125 ms
const int standby125ms = 2;

/// 250 ms
const int standby250ms = 3;

/// 500 ms
const int standby500ms = 4;

/// 1 sec
const int standby1s = 5;

/// 10 ms
const int atandby10ms = 6;

/// 20 ms
const int standby20ms = 7;

/// [BME280] inactive duration in standby mode
enum StandbyDuration {
  standby500us,
  standby62p5ms,
  standby125ms,
  standby250ms,
  standby500ms,
  standby1s,
  standby10ms,
  standby20ms
}

/// [BME280] IIR Filter coefficient
enum FilterCoefficient { filterOff, filter2, filter4, filter8, filter16 }

// filter
const int filterOff = 0;
const int filter2 = 1;
const int filter4 = 2;
const int filter8 = 3;
const int filter16 = 4;

/// Supported [bme280] models
enum BME280model {
  /// temperature and pressure
  bmp280,

  /// temperature, pressure and humidity
  bme280
}

/// BMP280 hardware ID
const int bmp280Id = 0x58;

/// BME280 hardware ID
const int bme280Id = 0x60;

/// [BME280] exception
class BME280exception implements Exception {
  final String errorMsg;
  @override
  String toString() => errorMsg;

  BME280exception(this.errorMsg);
}

/// [BME280] measured data: temperature, pressure and humidity (BME280 only).
class BME280result {
  /// temperature °C
  final double temperature;

  /// pressure in hPa
  final double pressure;

  /// relative humidity %
  final double humidity;

  BME280result(this.temperature, this.pressure, this.humidity);

  @override
  String toString() =>
      'BME280result [temperature=$temperature, pressure=$pressure, humidity=$humidity]';

  /// Returns a [BME280result] as a JSON string. [fractionDigits] controls the number fraction digits.
  String toJSON([int fractionDigits = 2]) {
    return '{"temperature":"${temperature.toStringAsFixed(fractionDigits)}","pressure":"${pressure.toStringAsFixed(fractionDigits)}","humidity":"${humidity.toStringAsFixed(fractionDigits)}"}';
  }
}

/// Bosch BME280/BMP280 sensor for temperature, pressure and
/// humidity (BME280 only).
///
/// See for more
/// * [BM280 example code](https://github.com/pezi/dart_periphery/blob/main/example/i2c_bme280.dart)
/// * [Source code](https://github.com/pezi/dart_periphery/blob/main/lib/src/hardware/bme280.dart)
/// * [Datasheet](https://cdn-shop.adafruit.com/datasheets/BST-BME280_DS001-10.pdf)
/// * This implementation is derived from project [DIOZero](https://github.com/mattjlewis/diozero/blob/main/diozero-core/src/main/java/com/diozero/devices/BMx280.java)
class BME280 {
  late I2C _i2c;
  late SPI _spi;

  /// Sensor uses I2C or SPI bus.
  final bool isI2C;

  /// I2C sensor address
  final int i2cAddress;
  late BME280model _model;

  /// Data bit order, depends on the type of the bus - I2C or SPI.
  final BitOrder bitOrder;

  int _digT1 = 0;
  int _digT2 = 0;
  int _digT3 = 0;
  int _digP1 = 0;
  int _digP2 = 0;
  int _digP3 = 0;
  int _digP4 = 0;
  int _digP5 = 0;
  int _digP6 = 0;
  int _digP7 = 0;
  int _digP8 = 0;
  int _digP9 = 0;
  int _digH1 = 0;
  int _digH2 = 0;
  int _digH3 = 0;
  int _digH4 = 0;
  int _digH5 = 0;
  int _digH6 = 0;

  /// Creates a BME280/BMP280 sensor instance that uses the [i2c] bus with
  /// the optional [i2cAddress].
  ///
  /// Default [bme280DefaultI2Caddress] = 0x76, [bme280AlternativeI2Caddress] = 0x77
  BME280(I2C i2c, [this.i2cAddress = bme280DefaultI2Caddress])
      : _i2c = i2c,
        isI2C = true,
        bitOrder = BitOrder.msbLast {
    _initialize();
  }

  /// Creates a BME280/BMP280 sensor instance that uses the [spi] bus.
  BME280.spi(SPI spi)
      : _spi = spi,
        isI2C = false,
        bitOrder = BitOrder.msbLast,
        i2cAddress = -1 {
    _initialize();
  }

  void _initialize() {
    // get model id
    var id = _readByte(idReg);
    switch (id) {
      case bmp280Id:
        _model = BME280model.bmp280;
        break;
      case bme280Id:
        _model = BME280model.bme280;
        break;
      default:
        throw BME280exception('Unknown modelwith ID: $id');
    }
    _readCoefficients();
    setOperatingModes(OversamplingMultiplier.x1, OversamplingMultiplier.x1,
        OversamplingMultiplier.x1, OperatingMode.modeNormal);
    setStandbyAndFilterModes(
        StandbyDuration.standby1s, FilterCoefficient.filterOff);
  }

  /// Returns the sensor model.
  BME280model getModel() => _model;

  void _readCoefficients() {
    while (_readByte(statusReg) & 0x01 != 0) {
      sleep(Duration(milliseconds: 10));
    }
    var buffer = ByteBuffer(
        _readByteBlock(calib00reg, _model == BME280model.bmp280 ? 24 : 26),
        isI2C ? ByteBufferSrc.i2c : ByteBufferSrc.spi,
        bitOrder);

    // Temperature coefficients
    _digT1 = buffer.getInt16() & 0xffff;
    _digT2 = buffer.getInt16();
    _digT3 = buffer.getInt16();

    // Pressure coefficients
    _digP1 = buffer.getInt16() & 0xffff;
    _digP2 = buffer.getInt16();
    _digP3 = buffer.getInt16();
    _digP4 = buffer.getInt16();
    _digP5 = buffer.getInt16();
    _digP6 = buffer.getInt16();
    _digP7 = buffer.getInt16();
    _digP8 = buffer.getInt16();
    _digP9 = buffer.getInt16();

    if (_model == BME280model.bme280) {
      // Skip 1 byte
      buffer.skipBytes(1);
      // Read 1 byte of data from address 0xA1(161)
      _digH1 = buffer.getInt8() & 0xff;

      // Read 7 bytes of data from address 0xE1(225)
      buffer = ByteBuffer(_readByteBlock(calib26reg, 7),
          isI2C ? ByteBufferSrc.i2c : ByteBufferSrc.spi, bitOrder);

      // Humidity coefficients
      _digH2 = buffer.getInt16();
      _digH3 = buffer.getInt8() & 0xff;
      var b1_3 = buffer.getInt8();
      var b1_4 = buffer.getInt8();
      _digH4 = (b1_3 << 4) | (b1_4 & 0xF);
      _digH5 = ((b1_4 & 0xF0) >> 4) | (buffer.getInt8() << 4);
      _digH6 = buffer.getInt8();
    }
  }

  /// Sets the oversampling multipliers [tempOversampling],[pressOversampling],
  /// [humOversampling] and [operatingMode].
  void setOperatingModes(
      OversamplingMultiplier tempOversampling,
      OversamplingMultiplier pressOversampling,
      OversamplingMultiplier humOversampling,
      OperatingMode operatingMode) {
    if (_model == BME280model.bme280) {
      // Humidity over sampling rate = 1
      _writeByte(ctrlHumReg, humOversampling.index);
    }
    // Normal mode, temp and pressure oversampling rate = 1
    _writeByte(
        ctrlMeasReg,
        ((tempOversampling.index) << 5) |
            ((pressOversampling.index) << 2) |
            (operatingMode == OperatingMode.modeNormal
                ? modeNormal
                : operatingMode.index));
  }

  /// Sets the [standbyDuration] for normal mode and the IIR [filterCoefficient].
  void setStandbyAndFilterModes(
      StandbyDuration standbyDuration, FilterCoefficient filterCoefficient) {
    // Stand_by time = 1000 ms, filter off
    _writeByte(configReg,
        (standbyDuration.index << 5) | (filterCoefficient.index << 2));
  }

  /// Returns [BME280result] with temperature, pressure and humidity (only BME280).
  BME280result getValues() {
    // Read the pressure, temperature, and humidity registers
    var buffer = ByteBuffer(
        _readByteBlock(pressMsbReg, _model == BME280model.bmp280 ? 6 : 8),
        isI2C ? ByteBufferSrc.i2c : ByteBufferSrc.spi,
        bitOrder);

    // Unpack the raw 20-bit unsigned pressure value
    var adcP = ((buffer.getInt8() & 0xff) << 12) |
        ((buffer.getInt8() & 0xff) << 4) |
        ((buffer.getInt8() & 0xf0) >> 4);
    // Unpack the raw 20-bit unsigned temperature value
    var adcT = ((buffer.getInt8() & 0xff) << 12) |
        ((buffer.getInt8() & 0xff) << 4) |
        ((buffer.getInt8() & 0xf0) >> 4);
    var adcH = 0;
    if (_model == BME280model.bme280) {
      // Unpack the raw 16-bit unsigned humidity value
      adcH = ((buffer.getInt8() & 0xff) << 8) | (buffer.getInt8() & 0xff);
    }

    var tvar1 = (((adcT >> 3) - (_digT1 << 1)) * _digT2) >> 11;
    var tvar2 =
        (((((adcT >> 4) - _digT1) * ((adcT >> 4) - _digT1)) >> 12) * _digT3) >>
            14;
    var tFine = tvar1 + tvar2;

    var temp = (tFine * 5 + 128) >> 8;

    var pvar1 = tFine - 128000;
    var pvar2 = pvar1 * pvar1 * _digP6;
    pvar2 = pvar2 + ((pvar1 * _digP5) << 17);
    pvar2 = pvar2 + ((_digP4) << 35);
    pvar1 = ((pvar1 * pvar1 * _digP3) >> 8) + ((pvar1 * _digP2) << 12);
    pvar1 = (((1 << 47) + pvar1)) * _digP1 >> 33;
    int pressure;
    if (pvar1 == 0) {
      pressure = 0; // Avoid exception caused by division by zero
    } else {
      pressure = 1048576 - adcP;
      pressure = (((pressure << 31) - pvar2) * 3125) ~/ pvar1;
      pvar1 = (_digP9 * (pressure >> 13) * (pressure >> 13)) >> 25;
      pvar2 = (_digP8 * pressure) >> 19;
      pressure = ((pressure + pvar1 + pvar2) >> 8) + (_digP7 << 4);
    }

    var humidity = 0;
    if (_model == BME280model.bme280) {
      var vX1u32r = tFine - 76800;
      vX1u32r =
          ((((adcH << 14) - (_digH4 << 20) - (_digH5 * vX1u32r)) + 16384) >>
                  15) *
              (((((((vX1u32r * _digH6) >> 10) *
                                      (((vX1u32r * _digH3) >> 11) + 32768)) >>
                                  10) +
                              2097152) *
                          _digH2 +
                      8192) >>
                  14);
      vX1u32r = vX1u32r -
          (((((vX1u32r >> 15) * (vX1u32r >> 15)) >> 7) * _digH1) >> 4);
      vX1u32r = vX1u32r < 0 ? 0 : vX1u32r;
      vX1u32r = vX1u32r > 419430400 ? 419430400 : vX1u32r;
      humidity = (vX1u32r) >> 12;
    }

    return BME280result(temp / 100.0, pressure / 25600.0, humidity / 1024.0);
  }

  /// Waits [maxIntervals] * [interval] milliseconds for data to
  /// become available.
  bool waitDataAvailable(int interval, int maxIntervals) {
    for (var i = 0; i < maxIntervals; i++) {
      // check data ready
      if (isDataAvailable()) {
        return true;
      }
      Duration(milliseconds: interval);
    }
    return false;
  }

  /// Resets the sensor.
  void reset() {
    _writeByte(resetReg, 0xB6);
  }

  /// Indicates, if data are available.
  bool isDataAvailable() {
    return (_readByte(statusReg) & 0x08) == 0;
  }

  int _readByte(int register) {
    if (isI2C) {
      return _i2c.readByteReg(i2cAddress, register);
    }
    var tx = <int>[register | 0x80, 0];
    _spi.transfer(tx, true);
    return tx[1];
  }

  List<int> _readByteBlock(int register, int length) {
    if (isI2C) {
      return _i2c.readBytesReg(i2cAddress, register, length);
    }
    var tx = List<int>.filled(length + 1, 0);
    tx[0] = register | 0x80;
    _spi.transfer(tx, true);
    return tx;
  }

  void _writeByte(int register, int value) {
    if (isI2C) {
      _i2c.writeByteReg(i2cAddress, register, value);
    } else {
      _spi.transfer(<int>[register & 0x7f, value], true);
    }
  }
}
