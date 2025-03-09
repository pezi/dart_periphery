// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dart_periphery/dart_periphery.dart';

/// H 00495 T 01234 Z 06399
///          11111111112222
///012345678901234567890123
(double, double, double) convert(String raw) {
  var humidity = int.parse(raw.substring(3, 8)) / 10.0;
  var temperature = (int.parse(raw.substring(11, 16)) - 1000) / 10.0;
  var co2 = int.parse(raw.substring(19)) / 10.0;
  return (humidity, temperature, co2);
}

/// COZIR CO2 Sensor
///
/// [COZIR CO2 Sensor](https://co2meters.com/Documentation/Manuals/Manual_GC_0024_0025_0026_Revised8.pdf)
///
void main() {
  var s = Serial('/dev/serial0', Baudrate.b9600);
  try {
    print('Dart version: ${Platform.version}');
    print("dart_periphery Version: $dartPeripheryVersion");
    print("c-periphery Version   : ${getCperipheryVersion()}");
    print('Serial interface info: ${s.getSerialInfo()}');
    print('Serial test - COZIR CO2 Sensor');

    // Return firmware version and sensor serial number - two lines
    s.writeString('Y\r\n');
    var event = s.read(256, 1000);
    print(event.toString());

    // Request temperature, humidity and CO2 level.
    s.writeString('M 4164\r\n');
    // Select polling mode
    s.writeString('K 2\r\n');
    // print any response
    event = s.read(256, 1000);
    print('Response ${event.toString()}');
    sleep(Duration(seconds: 1));
    for (var i = 0; i < 20; ++i) {
      s.writeString('Q\r\n');
      event = s.read(256, 1000);
      var tupple = convert(event.toString());
      print(
          "H: ${tupple.$1.toStringAsFixed(1)} T: ${tupple.$2.toStringAsFixed(1)} CO2:${tupple.$3.toInt()}");
      sleep(Duration(seconds: 5));
    }
  } finally {
    s.dispose();
  }
}
