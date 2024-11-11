// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_periphery/dart_periphery.dart';

///  MLX90615 - digital infrared non-contact temperature sensor
///
/// https://www.seeedstudio.com/Grove-Digital-Infrared-Temperature-Sensor.html
///
void main() {
  // Select the right I2C bus number /dev/i2c-?
  // 1 for Raspberry Pi, 0 for NanoPi (Armbian), 2 Banana Pi (Armbian)
  var i2c = I2C(1);
  try {
    var mlx90615 = MLX90615(i2c);
    print(
        'MLX90615 ambient temperature [t°] ${mlx90615.getAmbientTemperature().toStringAsFixed(2)}');
    print(
        'MLX90615 object temperature [t°] ${mlx90615.getObjectTemperature().toStringAsFixed(2)}');
  } finally {
    i2c.dispose();
  }
}
