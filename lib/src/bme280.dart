// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "i2c.dart";

///
class BME280result {
  /// temperature
  final double temperature;

  /// pressure in hPa
  final double pressure;

  /// relative humidity %
  final double humidity;
  BME280result(this.temperature, this.pressure, this.humidity);
}

/// B
///
/// This implementation is derived from https://github.com/ControlEverythingCommunity/BME280
class BME280 {
  static const int I2C_DEFAULT_ADDRESS = 0x76;
  I2C device;
  int i2cAddress;
  int dig_T1;
  int dig_T2;
  int dig_T3;

  int dig_P1;
  int dig_P2;
  int dig_P3;
  int dig_P4;
  int dig_P5;
  int dig_P6;
  int dig_P7;
  int dig_P8;
  int dig_P9;

  int dig_H1;
  int dig_H2;
  int dig_H3;
  int dig_H4;
  int dig_H5;
  int dig_H6;

  BME280(this.device, [this.i2cAddress = I2C_DEFAULT_ADDRESS]);

  void init() {
    // Read 24 bytes of data from address 0x88(136)
    // byte[] b1 = new byte[24];
    List<int> b1 = device.readBytesReg(i2cAddress, 0x88, 24);

    // Convert the data
    // temp coefficients
    dig_T1 = (b1[0] & 0xFF) + ((b1[1] & 0xFF) * 256);
    dig_T2 = (b1[2] & 0xFF) + ((b1[3] & 0xFF) * 256);
    if (dig_T2 > 32767) {
      dig_T2 -= 65536;
    }
    dig_T3 = (b1[4] & 0xFF) + ((b1[5] & 0xFF) * 256);
    if (dig_T3 > 32767) {
      dig_T3 -= 65536;
    }

    // pressure coefficients
    dig_P1 = (b1[6] & 0xFF) + ((b1[7] & 0xFF) * 256);
    dig_P2 = (b1[8] & 0xFF) + ((b1[9] & 0xFF) * 256);
    if (dig_P2 > 32767) {
      dig_P2 -= 65536;
    }
    dig_P3 = (b1[10] & 0xFF) + ((b1[11] & 0xFF) * 256);
    if (dig_P3 > 32767) {
      dig_P3 -= 65536;
    }
    dig_P4 = (b1[12] & 0xFF) + ((b1[13] & 0xFF) * 256);
    if (dig_P4 > 32767) {
      dig_P4 -= 65536;
    }
    dig_P5 = (b1[14] & 0xFF) + ((b1[15] & 0xFF) * 256);
    if (dig_P5 > 32767) {
      dig_P5 -= 65536;
    }
    dig_P6 = (b1[16] & 0xFF) + ((b1[17] & 0xFF) * 256);
    if (dig_P6 > 32767) {
      dig_P6 -= 65536;
    }
    dig_P7 = (b1[18] & 0xFF) + ((b1[19] & 0xFF) * 256);
    if (dig_P7 > 32767) {
      dig_P7 -= 65536;
    }
    dig_P8 = (b1[20] & 0xFF) + ((b1[21] & 0xFF) * 256);
    if (dig_P8 > 32767) {
      dig_P8 -= 65536;
    }
    dig_P9 = (b1[22] & 0xFF) + ((b1[23] & 0xFF) * 256);
    if (dig_P9 > 32767) {
      dig_P9 -= 65536;
    }

    // Read 1 byte of data from address 0xA1(161)
    dig_H1 = device.readByteReg(i2cAddress, 0xA1);

    // Read 7 bytes of data from address 0xE1(225)
    b1 = device.readBytesReg(i2cAddress, 0xE1, 7);

    // Convert the data
    // humidity coefficients
    dig_H2 = (b1[0] & 0xFF) + (b1[1] * 256);
    if (dig_H2 > 32767) {
      dig_H2 -= 65536;
    }
    dig_H3 = b1[2] & 0xFF;
    dig_H4 = ((b1[3] & 0xFF) * 16) + (b1[4] & 0xF);
    if (dig_H4 > 32767) {
      dig_H4 -= 65536;
    }
    dig_H5 = ((b1[4] & 0xFF) >> 4) + ((b1[5] & 0xFF) * 16);
    if (dig_H5 > 32767) {
      dig_H5 -= 65536;
    }
    dig_H6 = b1[6] & 0xFF;
    if (dig_H6 > 127) {
      dig_H6 -= 256;
    }
  }

  BME280result get() {
    // Select control humidity register
    // Humidity over sampling rate = 1
    device.writeByteReg(i2cAddress, 0xF2, 0x01);
    // Select control measurement register
    // Normal mode, temp and pressure over sampling rate = 1
    device.writeByteReg(i2cAddress, 0xF4, 0x27);
    // Select config register
    // Stand_by time = 1000 ms
    device.writeByteReg(i2cAddress, 0xF5, 0xA0);

    // Read 8 bytes of data from address 0xF7(247)
    // pressure msb1, pressure msb, pressure lsb, temp msb1, temp msb, temp lsb,
    // humidity lsb, humidity msb
    List<int> data = device.readBytesReg(i2cAddress, 0xF7, 8);

    // Convert pressure and temperature data to 19-bits
    int adc_p = (((data[0] & 0xFF) * 65536) +
            ((data[1] & 0xFF) * 256) +
            (data[2] & 0xF0)) >>
        4;
    int adc_t = (((data[3] & 0xFF) * 65536) +
            ((data[4] & 0xFF) * 256) +
            (data[5] & 0xF0)) >>
        4;
    // Convert the humidity data
    int adc_h = ((data[6] & 0xFF) * 256 + (data[7] & 0xFF));

    // Temperature offset calculations
    double var1 =
        ((adc_t.toDouble()) / 16384.0 - (dig_T1.toDouble()) / 1024.0) *
            (dig_T2.toDouble());
    double var2 = (((adc_t.toDouble()) / 131072.0 -
                (dig_T1.toDouble()) / 8192.0) *
            ((adc_t.toDouble()) / 131072.0 - (dig_T1.toDouble()) / 8192.0)) *
        (dig_T3.toDouble());
    double t_fine = (var1 + var2).truncateToDouble();
    double cTemp = (var1 + var2) / 5120.0;

    // Pressure offset calculations
    var1 = (t_fine.toDouble() / 2.0) - 64000.0;
    var2 = var1 * var1 * (dig_P6.toDouble()) / 32768.0;
    var2 = var2 + var1 * (dig_P5.toDouble()) * 2.0;
    var2 = (var2 / 4.0) + ((dig_P4.toDouble()) * 65536.0);
    var1 = ((dig_P3.toDouble()) * var1 * var1 / 524288.0 +
            (dig_P2.toDouble()) * var1) /
        524288.0;
    var1 = (1.0 + var1 / 32768.0) * (dig_P1.toDouble());
    double p = 1048576.0 - adc_p.toDouble();
    p = (p - (var2 / 4096.0)) * 6250.0 / var1;
    var1 = (dig_P9.toDouble()) * p * p / 2147483648.0;
    var2 = p * (dig_P8.toDouble()) / 32768.0;
    double pressure = (p + (var1 + var2 + (dig_P7.toDouble())) / 16.0) / 100;

    // Humidity offset calculations
    double var_H = ((t_fine) - 76800.0);
    var_H = (adc_h - (dig_H4 * 64.0 + dig_H5 / 16384.0 * var_H)) *
        (dig_H2 /
            65536.0 *
            (1.0 +
                dig_H6 /
                    67108864.0 *
                    var_H *
                    (1.0 + dig_H3 / 67108864.0 * var_H)));
    double humidity = var_H * (1.0 - dig_H1 * var_H / 524288.0);
    if (humidity > 100.0) {
      humidity = 100.0;
    } else if (humidity < 0.0) {
      humidity = 0.0;
    }

    return new BME280result(cTemp, pressure, humidity);
  }
}
