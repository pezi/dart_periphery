// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import '../i2c.dart';
import '../spi.dart';
import 'util.dart';
import 'bosch.dart';

// Bosch BMx280 pressure and temperature sensor. The BME280 includes an additional humidity sensor.
// Different constructors suppor access via I2C or SPI
// Datasheet: https://cdn-shop.adafruit.com/datasheets/BST-BME280_DS001-10.pdf
//
// This code bases on the diozero project - Thanks to Matthew Lewis!
// https://github.com/mattjlewis/diozero/blob/master/diozero-core/src/main/java/com/diozero/devices/BME280.java

const int BME280_DEFAULT_I2C_ADDRESS = 0x76;
const int BME280_ALTERNATIVE_I2C_ADDRESS = 0x77;

const int CALIB_00_REG = 0x88;
const int ID_REG = 0xD0;
const int RESET_REG = 0xE0;
const int CALIB_26_REG = 0xe1;
const int CTRL_HUM_REG = 0xF2;
const int STATUS_REG = 0xF3;
const int CTRL_MEAS_REG = 0xF4;
const int CONFIG_REG = 0xF5;
const int PRESS_MSB_REG = 0xF7;

// Flags for ctrl_hum and ctrl_meas registers
const int OVERSAMPLING_1_MASK = 1;
const int OVERSAMPLING_2_MASK = 2;
const int OVERSAMPLING_4_MASK = 3;
const int OVERSAMPLING_8_MASK = 4;
const int OVERSAMPLING_16_MASK = 5;

// operation mode
const int MODE_SLEEP = 0;
const int MODE_FORCED = 1;
const int MODE_NORMAL = 3;

/// BME280 operation mode
enum OperatingMode { MODE_SLEEP, MODE_FORCED, MODE_NORMAL }

const int STANDBY_500_US = 0;
const int STANDBY_62_5_MS = 1;
const int STANDBY_125_MS = 2;
const int STANDBY_250_MS = 3;
const int STANDBY_500_MS = 4;
const int STANDBY_1_S = 5;
const int STANDBY_10_MS = 6;
const int STANDBY_20_MS = 7;

/// BME280 inactive duration in standby mode
enum StandbyDuration {
  STANDBY_500_US,
  STANDBY_62_5_MS,
  STANDBY_125_MS,
  STANDBY_250_MS,
  STANDBY_500_MS,
  STANDBY_1_S,
  STANDBY_10_MS,
  STANDBY_20_MS
}

/// BME280 IIR Filter coefficient
enum FilterCoefficient { FILTER_OFF, FILTER_2, FILTER_4, FILTER_8, FILTER_16 }

// filter
const int FILTER_OFF = 0;
const int FILTER_2 = 1;
const int FILTER_4 = 2;
const int FILTER_8 = 3;
const int FILTER_16 = 4;

/// Supported models
enum BME280model {
  /// temperature and pressure
  BMP280,

  /// temperature, pressure and humidity
  BME280
}

/// BMP280 hardware ID
const int BMP280_ID = 0x58;

/// BME280 hardware ID
const int BME280_ID = 0x60;

/// BME280 exception
class BME280exception implements Exception {
  final String errorMsg;
  @override
  String toString() => errorMsg;

  BME280exception(this.errorMsg);
}

/// [BME280] data container for temperature, pressure and humidity (BME280 only).
class BME280result {
  /// temperature
  final double temperature;

  /// pressure in hPa
  final double pressure;

  /// relative humidity %
  final double humidity;

  BME280result(this.temperature, this.pressure, this.humidity);
}

/// Bosch BME280/BMP280 sensor for temperature, pressure and humidity (BME280 only).
///
/// See for more
/// * [BM280 example code](https://github.com/pezi/dart_periphery/blob/main/example/i2c_bme280.dart)
/// * [Source code](https://github.com/pezi/dart_periphery/blob/main/lib/src/hardware/bme280.dart)
/// * [Datasheet](https://cdn-shop.adafruit.com/datasheets/BST-BME280_DS001-10.pdf)
/// * This implementation is derived from project [DIOZero](https://github.com/mattjlewis/diozero/blob/master/diozero-core/src/main/java/com/diozero/devices/BME280.java)
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
  /// Default [BME280_DEFAULT_I2C_ADDRESS] = 0x76, [BME280_ALTERNATIVE_I2C_ADDRESS] = 0x77
  BME280(I2C i2c, [this.i2cAddress = BME280_DEFAULT_I2C_ADDRESS])
      : _i2c = i2c,
        isI2C = true,
        bitOrder = BitOrder.MSB_LAST {
    _initialize();
  }

  /// Creates a BME280/BMP280 sensor instance that uses the [spi] bus.
  BME280.spi(SPI spi)
      : _spi = spi,
        isI2C = false,
        bitOrder = spi.bitOrder,
        i2cAddress = -1 {
    _initialize();
  }

  void _initialize() {
    // get model
    switch (_readByte(ID_REG)) {
      case BMP280_ID:
        _model = BME280model.BMP280;
        break;
      case BME280_ID:
        _model = BME280model.BME280;
        break;
      default:
        throw BME280exception('Unknown model');
    }
    _readCoefficients();
    setOperatingModes(OversamplingMultiplier.X1, OversamplingMultiplier.X1,
        OversamplingMultiplier.X1, OperatingMode.MODE_NORMAL);
    setStandbyAndFilterModes(
        StandbyDuration.STANDBY_1_S, FilterCoefficient.FILTER_OFF);
  }

  /// Returns the sensor model.
  BME280model getModel() => _model;

  void _readCoefficients() {
    while (_readByte(STATUS_REG) & 0x01 != 0) {
      sleep(Duration(milliseconds: 10));
    }
    var buffer = ByteBuffer(
        _readByteBlock(CALIB_00_REG, _model == BME280model.BMP280 ? 24 : 26),
        isI2C ? ByteBufferSrc.I2C : ByteBufferSrc.SPI,
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

    if (_model == BME280model.BME280) {
      // Skip 1 byte
      buffer.skipBytes(1);
      // Read 1 byte of data from address 0xA1(161)
      _digH1 = buffer.getInt8() & 0xff;

      // Read 7 bytes of data from address 0xE1(225)
      buffer = ByteBuffer(_readByteBlock(CALIB_26_REG, 7),
          isI2C ? ByteBufferSrc.I2C : ByteBufferSrc.SPI, bitOrder);

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

  /// Sets the oversampling multipliers [tempOversampling],[pressOversampling],[humOversampling] and [operatingMode].
  void setOperatingModes(
      OversamplingMultiplier tempOversampling,
      OversamplingMultiplier pressOversampling,
      OversamplingMultiplier humOversampling,
      OperatingMode operatingMode) {
    if (_model == BME280model.BME280) {
      // Humidity over sampling rate = 1
      _writeByte(CTRL_HUM_REG, humOversampling.index + 1);
    }
    // Normal mode, temp and pressure oversampling rate = 1
    _writeByte(
        CTRL_MEAS_REG,
        ((tempOversampling.index) << 5) |
            ((pressOversampling.index) << 2) |
            (operatingMode == OperatingMode.MODE_NORMAL
                ? MODE_NORMAL
                : operatingMode.index));
  }

  /// Sets the [standbyDuration] for normal mode and the IIR [filterCoefficient].
  void setStandbyAndFilterModes(
      StandbyDuration standbyDuration, FilterCoefficient filterCoefficient) {
    // Stand_by time = 1000 ms, filter off
    _writeByte(CONFIG_REG,
        (standbyDuration.index << 5) | (filterCoefficient.index << 2));
  }

  /// Returns [BME280result] with temperature, pressure and humidity (only BME280).
  BME280result getValues() {
    // Read the pressure, temperature, and humidity registers
    var buffer = ByteBuffer(
        _readByteBlock(PRESS_MSB_REG, _model == BME280model.BMP280 ? 6 : 8),
        isI2C ? ByteBufferSrc.I2C : ByteBufferSrc.SPI,
        bitOrder);

    // Unpack the raw 20-bit unsigned pressure value
    var adc_p = ((buffer.getInt8() & 0xff) << 12) |
        ((buffer.getInt8() & 0xff) << 4) |
        ((buffer.getInt8() & 0xf0) >> 4);
    // Unpack the raw 20-bit unsigned temperature value
    var adc_t = ((buffer.getInt8() & 0xff) << 12) |
        ((buffer.getInt8() & 0xff) << 4) |
        ((buffer.getInt8() & 0xf0) >> 4);
    var adc_h = 0;
    if (_model == BME280model.BME280) {
      // Unpack the raw 16-bit unsigned humidity value
      adc_h = ((buffer.getInt8() & 0xff) << 8) | (buffer.getInt8() & 0xff);
    }

    var tvar1 = (((adc_t >> 3) - (_digT1 << 1)) * _digT2) >> 11;
    var tvar2 = (((((adc_t >> 4) - _digT1) * ((adc_t >> 4) - _digT1)) >> 12) *
            _digT3) >>
        14;
    var t_fine = tvar1 + tvar2;

    var temp = (t_fine * 5 + 128) >> 8;

    var pvar1 = t_fine - 128000;
    var pvar2 = pvar1 * pvar1 * _digP6;
    pvar2 = pvar2 + ((pvar1 * _digP5) << 17);
    pvar2 = pvar2 + ((_digP4) << 35);
    pvar1 = ((pvar1 * pvar1 * _digP3) >> 8) + ((pvar1 * _digP2) << 12);
    pvar1 = (((1 << 47) + pvar1)) * _digP1 >> 33;
    int pressure;
    if (pvar1 == 0) {
      pressure = 0; // Avoid exception caused by division by zero
    } else {
      pressure = 1048576 - adc_p;
      pressure = (((pressure << 31) - pvar2) * 3125) ~/ pvar1;
      pvar1 = (_digP9 * (pressure >> 13) * (pressure >> 13)) >> 25;
      pvar2 = (_digP8 * pressure) >> 19;
      pressure = ((pressure + pvar1 + pvar2) >> 8) + (_digP7 << 4);
    }

    var humidity = 0;
    if (_model == BME280model.BME280) {
      var v_x1_u32r = t_fine - 76800;
      v_x1_u32r =
          ((((adc_h << 14) - (_digH4 << 20) - (_digH5 * v_x1_u32r)) + 16384) >>
                  15) *
              (((((((v_x1_u32r * _digH6) >> 10) *
                                      (((v_x1_u32r * _digH3) >> 11) + 32768)) >>
                                  10) +
                              2097152) *
                          _digH2 +
                      8192) >>
                  14);
      v_x1_u32r = v_x1_u32r -
          (((((v_x1_u32r >> 15) * (v_x1_u32r >> 15)) >> 7) * _digH1) >> 4);
      v_x1_u32r = v_x1_u32r < 0 ? 0 : v_x1_u32r;
      v_x1_u32r = v_x1_u32r > 419430400 ? 419430400 : v_x1_u32r;
      humidity = (v_x1_u32r) >> 12;
    }

    return BME280result(temp / 100.0, pressure / 25600.0, humidity / 1024.0);
  }

  /// Waits [maxIntervals] * [interval] milliseconds for data to become available.
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
    _writeByte(RESET_REG, 0xB6);
  }

  /// Indicates, if data are available.
  bool isDataAvailable() {
    return (_readByte(STATUS_REG) & 0x08) == 0;
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
