// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'i2c.dart';
import 'spi.dart';
import 'util.dart';

// This code is derived from
// https://github.com/mattjlewis/diozero/blob/master/diozero-core/src/main/java/com/diozero/devices/BME280.java

const int DEFAULT_I2C_ADDRESS_0x76 = 0x76;

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
const int MODE_NORMAL = 2;

const int STANDBY_500_US = 0;
const int STANDBY_62_5_MS = 1;
const int STANDBY_125_MS = 2;
const int STANDBY_250_MS = 3;
const int STANDBY_500_MS = 4;
const int STANDBY_1_S = 5;
const int STANDBY_10_MS = 6;
const int STANDBY_20_MS = 7;

// filter
const int FILTER_OFF = 0;
const int FILTER_2 = 1;
const int FILTER_4 = 2;
const int FILTER_8 = 3;
const int FILTER_16 = 4;

/// Supported models
enum BME280model {
  /// temperature and preassure
  BMP280,

  /// temperature, preassure and humidity
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

/// Data container for temperature, pressure and humidity (BME280 only).
class BME280result {
  /// temperature
  final double temperature;

  /// pressure in hPa
  final double pressure;

  /// relative humidity %
  final double humidity;

  BME280result(this.temperature, this.pressure, this.humidity);
}

/// BME280/BMP280 sensor for temperature, pressure and humidity (BME280 only).
class BME280 {
  I2C i2c;
  SPI spi;
  bool isI2C;
  int i2cAddress;
  BME280model model;

  int digT1;
  int digT2;
  int digT3;
  int digP1;
  int digP2;
  int digP3;
  int digP4;
  int digP5;
  int digP6;
  int digP7;
  int digP8;
  int digP9;
  int digH1;
  int digH2;
  int digH3;
  int digH4;
  int digH5;
  int digH6;

  /// Opens a BME280 or BMP280 sensor conntected with the [i2c] at the [i2cAddress = DEFAULT_I2C_ADDRESS_0x76] .
  BME280(this.i2c, [this.i2cAddress = DEFAULT_I2C_ADDRESS_0x76])
      : isI2C = true {
    _init();
  }

  /// Opens a BME280 or BMP280 sensor connected with the [spi] bus.
  BME280.spi(this.spi) : isI2C = false {
    _init();
  }

  void _init() {
    // get model
    switch (_readByte(ID_REG)) {
      case BMP280_ID:
        model = BME280model.BMP280;
        break;
      case BME280_ID:
        model = BME280model.BME280;
        break;
      default:
        throw BME280exception('Unknown model');
    }
    _readCoefficients();
    _setOperatingModes(OVERSAMPLING_1_MASK, OVERSAMPLING_1_MASK,
        OVERSAMPLING_1_MASK, MODE_NORMAL);
    _setStandbyAndFilterModes(STANDBY_1_S, FILTER_OFF);
  }

  void _readCoefficients() {
    while (_readByte(STATUS_REG) & 0x01 != 0) {
      sleep(Duration(milliseconds: 10));
    }
    var buffer = ByteBuffer(
        _readByteBlock(CALIB_00_REG, model == BME280model.BMP280 ? 24 : 26),
        isI2C);

    // Temperature coefficients
    digT1 = buffer.getInt16() & 0xffff;
    digT2 = buffer.getInt16();
    digT3 = buffer.getInt16();

    // Pressure coefficients
    digP1 = buffer.getInt16() & 0xffff;
    digP2 = buffer.getInt16();
    digP3 = buffer.getInt16();
    digP4 = buffer.getInt16();
    digP5 = buffer.getInt16();
    digP6 = buffer.getInt16();
    digP7 = buffer.getInt16();
    digP8 = buffer.getInt16();
    digP9 = buffer.getInt16();

    if (model == BME280model.BME280) {
      // Skip 1 byte
      buffer.skipBytes(1);
      // Read 1 byte of data from address 0xA1(161)
      digH1 = buffer.getInt8();

      // Read 7 bytes of data from address 0xE1(225)
      buffer = ByteBuffer(_readByteBlock(CALIB_26_REG, 7), isI2C);

      // Humidity coefficients
      digH2 = buffer.getInt16();
      digH3 = buffer.getInt8();
      var b1_3 = buffer.getInt8();
      var b1_4 = buffer.getInt8();
      digH4 = (b1_3 << 4) | (b1_4 & 0xF);
      digH5 = ((b1_4 & 0xF0) >> 4) | (buffer.getInt8() << 4);
      digH6 = buffer.getInt8();
    }
  }

  void _setOperatingModes(int tempOversampling, int pressOversampling,
      int humOversampling, int operatingMode) {
    // Normal mode, temp and pressure oversampling rate = 1
    _writeByte(CTRL_MEAS_REG,
        (tempOversampling << 5) | (pressOversampling << 2) | operatingMode);
    if (model == BME280model.BME280) {
      // Humidity over sampling rate = 1
      _writeByte(CTRL_HUM_REG, humOversampling);
    }
  }

  void _setStandbyAndFilterModes(int standbyDuration, int filterCoefficient) {
    // Stand_by time = 1000 ms, filter off
    _writeByte(CONFIG_REG, (standbyDuration << 5) | (filterCoefficient << 2));
  }

  // Returns'BME280result' with temperature, pressure and humidity (only BME280).
  BME280result getValues() {
    // Read the pressure, temperature, and humidity registers
    var buffer = ByteBuffer(
        _readByteBlock(PRESS_MSB_REG, model == BME280model.BMP280 ? 6 : 8),
        isI2C);

    // Unpack the raw 20-bit unsigned pressure value
    var adc_p = ((buffer.getInt8() & 0xff) << 12) |
        ((buffer.getInt8() & 0xff) << 4) |
        ((buffer.getInt8() & 0xf0) >> 4);
    // Unpack the raw 20-bit unsigned temperature value
    var adc_t = ((buffer.getInt8() & 0xff) << 12) |
        ((buffer.getInt8() & 0xff) << 4) |
        ((buffer.getInt8() & 0xf0) >> 4);

    var adc_h = 0;
    if (model == BME280model.BME280) {
      // Unpack the raw 16-bit unsigned humidity value
      adc_h = ((buffer.getInt8() & 0xff) << 8) | (buffer.getInt8() & 0xff);
    }

    var tvar1 = (((adc_t >> 3) - (digT1 << 1)) * digT2) >> 11;
    var tvar2 =
        (((((adc_t >> 4) - digT1) * ((adc_t >> 4) - digT1)) >> 12) * digT3) >>
            14;
    var t_fine = tvar1 + tvar2;

    var temp = (t_fine * 5 + 128) >> 8;

    var pvar1 = t_fine - 128000;
    var pvar2 = pvar1 * pvar1 * digP6;
    pvar2 = pvar2 + ((pvar1 * digP5) << 17);
    pvar2 = pvar2 + ((digP4) << 35);
    pvar1 = ((pvar1 * pvar1 * digP3) >> 8) + ((pvar1 * digP2) << 12);
    pvar1 = (((1 << 47) + pvar1)) * digP1 >> 33;
    int pressure;
    if (pvar1 == 0) {
      pressure = 0; // Avoid exception caused by division by zero
    } else {
      pressure = 1048576 - adc_p;
      pressure = (((pressure << 31) - pvar2) * 3125) ~/ pvar1;
      pvar1 = (digP9 * (pressure >> 13) * (pressure >> 13)) >> 25;
      pvar2 = (digP8 * pressure) >> 19;
      pressure = ((pressure + pvar1 + pvar2) >> 8) + (digP7 << 4);
    }

    var humidity = 0;
    if (model == BME280model.BME280) {
      var v_x1_u32r = t_fine - 76800;
      v_x1_u32r =
          ((((adc_h << 14) - (digH4 << 20) - (digH5 * v_x1_u32r)) + 16384) >>
                  15) *
              (((((((v_x1_u32r * digH6) >> 10) *
                                      (((v_x1_u32r * digH3) >> 11) + 32768)) >>
                                  10) +
                              2097152) *
                          digH2 +
                      8192) >>
                  14);
      v_x1_u32r = v_x1_u32r -
          (((((v_x1_u32r >> 15) * (v_x1_u32r >> 15)) >> 7) * digH1) >> 4);
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

  /// Resets the device.
  void reset() {
    _writeByte(RESET_REG, 0xB6);
  }

  /// Indicates if data is available.
  bool isDataAvailable() {
    return (_readByte(STATUS_REG) & 0x08) == 0;
  }

  int _readByte(int register) {
    if (isI2C) {
      return i2c.readByteReg(i2cAddress, ID_REG);
    }
    var tx = <int>[register | 0x80, 0];
    spi.transfer(tx, true);
    return tx[1];
  }

  List<int> _readByteBlock(int register, int length) {
    if (isI2C) {
      return i2c.readBytesReg(i2cAddress, register, length);
    }
    var tx = List<int>.filled(length + 1, 0);
    tx[0] = register | 0x80;
    spi.transfer(tx, true);
    return tx;
  }

  void _writeByte(int register, int value) {
    if (isI2C) {
      i2c.writeByteReg(i2cAddress, register, value);
    } else {
      spi.transfer(<int>[register & 0x7f, value], true);
    }
  }
}
