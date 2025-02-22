// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_periphery/dart_periphery.dart';

/// SHT31 - temperature and humidity sensor
///
/// https://wiki.seeedstudio.com/Grove-TempAndHumi_Sensor-SHT31
///
void main() {
  // Select the right I2C bus number /dev/i2c-?
  // 1 for Raspberry Pi, 0 for NanoPi (Armbian), 2 Banana Pi (Armbian), 4 BPI-F3
  var i2c = I2C(1);
  try {
    print("dart_periphery Version: $dartPeripheryVersion");
    print("c-periphery Version   : ${getCperipheryVersion()}");
    print('I2C info: ${i2c.getI2Cinfo()}');
    print("SHT31 sensor");

    var sht31 = SHT31(i2c);
    print(sht31.getStatus());
    print('Serial number ${sht31.getSerialNumber()}');
    print('Sensor heater active: ${sht31.isHeaterOn()}');

    var r = sht31.getValues();
    print('SHT31 [t°] ${r.temperature.toStringAsFixed(2)}');
    print('SHT31 [%°] ${r.humidity.toStringAsFixed(2)}');
  } finally {
    i2c.dispose();
  }
}
